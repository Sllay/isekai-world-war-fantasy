class_name CombatService
extends RefCounted

var entities: CoreEntityIds
var data: CoreDataRegistry
var events: CoreEventBus
var clock: CoreClock
var diagnostics: CoreDiagnostics
var target_policy := CombatTargetPolicy.new()
var damage_policy: Callable
var _combatants: Dictionary[String, Combatant] = {}
var _transaction_active := false

func register(entity_id: String, profile_id: String) -> Combatant:
	var profile := data.lookup(profile_id)
	if _transaction_active or not entities.contains(entity_id) or _combatants.has(entity_id) or CombatDefinitions.valid_profile(profile) != OK:
		return null
	var state := Combatant.new(entity_id, profile)
	_combatants[entity_id] = state
	return state

func unregister(entity_id: String) -> Error:
	if _transaction_active:
		return ERR_BUSY
	return OK if _combatants.erase(entity_id) else ERR_DOES_NOT_EXIST

func combatant(entity_id: String) -> Combatant:
	return _combatants.get(entity_id) if entities.contains(entity_id) else null

# Owner restore rebinds the *same* capability object after Core/Player restore.
func restore_owned(state: Combatant, entity_id: String, snapshot: Dictionary) -> void:
	_combatants.erase(state.entity_id)
	state.entity_id = entity_id
	state.restore(snapshot, data.lookup(state.profile_id))
	_combatants[entity_id] = state

func relationship(source_id: String, target_id: String) -> CombatTargetPolicy.Relationship:
	if target_policy == null or combatant(source_id) == null or combatant(target_id) == null:
		return CombatTargetPolicy.Relationship.INVALID
	if source_id == target_id:
		return CombatTargetPolicy.Relationship.SELF
	var relation := target_policy.relationship(source_id, target_id)
	return relation if relation in CombatTargetPolicy.Relationship.values() else CombatTargetPolicy.Relationship.INVALID

func damage(request: DamageRequest) -> CombatResult:
	return _apply(request, false)

func heal(request: HealingRequest) -> CombatResult:
	return _apply(request, true)

func _apply(request: CombatRequest, healing: bool) -> CombatResult:
	var result := CombatResult.new()
	if request == null:
		result.code = "INVALID_REQUEST"
		return result
	result.transaction_id = request.transaction_id
	result.source_entity = request.source_entity
	result.target_entity = request.target_entity
	if _transaction_active:
		return _reject(result, "BUSY")
	if request._resolved:
		return _reject(result, "REQUEST_CONSUMED")
	if not CombatNumbers.integer(request.amount, 0, CombatNumbers.MAX_UNITS):
		return _reject(result, "INVALID_AMOUNT")
	result.requested = int(request.amount)
	if not request.valid_metadata():
		return _reject(result, "INVALID_METADATA")
	if not healing:
		var hit := request as DamageRequest
		if data.lookup(hit.damage_type_id).get("kind") != "damage" or (hit.has_impact and not hit.impact_position.is_finite()):
			return _reject(result, "INVALID_DAMAGE_METADATA")
	var source := combatant(request.source_entity)
	var target := combatant(request.target_entity)
	if source == null or target == null:
		return _reject(result, "TARGET_UNAVAILABLE")
	if not Combatant.valid(source.capture(), data.lookup(source.profile_id)) or not Combatant.valid(target.capture(), data.lookup(target.profile_id)):
		return _reject(result, "INVALID_COMBAT_STATE")
	if source.lifecycle != Combatant.Lifecycle.ALIVE or target.lifecycle != Combatant.Lifecycle.ALIVE:
		return _reject(result, "COMBATANT_DEFEATED")
	if target_policy == null:
		return _reject(result, "POLICY_UNAVAILABLE")
	_transaction_active = true
	result.relationship = relationship(request.source_entity, request.target_entity)
	var allowed := target_policy.allows_healing(result.relationship, request as HealingRequest) if healing else target_policy.allows_damage(result.relationship, request as DamageRequest)
	if not allowed:
		_transaction_active = false
		return _reject(result, "RELATIONSHIP_REJECTED")
	var scale := source.attributes.value(CombatModifier.Stat.HEAL_SCALE if healing else CombatModifier.Stat.DAMAGE_SCALE)
	@warning_ignore("integer_division")
	result.evaluated = mini(result.requested * scale / CombatNumbers.SCALE, CombatNumbers.MAX_UNITS)
	var mitigation := {"amount": result.evaluated, "resource_cost": 0, "defense": "NONE"}
	if not healing and damage_policy.is_valid():
		var decision: Variant = damage_policy.call(request, result.evaluated)
		if not decision is Dictionary or not CombatNumbers.integer(decision.get("amount"), 0, result.evaluated) or not CombatNumbers.integer(decision.get("resource_cost"), 0, target.resource) or decision.get("defense") not in ["NONE", "DODGED", "GUARDED", "GUARD_FAILED"]:
			_transaction_active = false
			return _reject(result, "INVALID_MITIGATION")
		mitigation = decision
	result.prevented = result.evaluated - int(mitigation.amount)
	result.defense = mitigation.defense
	result.health_before = target.health
	result.actual = mini(int(mitigation.amount), target.max_health() - target.health if healing else target.health)
	result.overage = int(mitigation.amount) - result.actual
	result.health_after = target.health + (result.actual if healing else -result.actual)
	result.defeated = result.health_after == 0
	result.accepted = true
	result.code = "APPLIED" if result.actual > 0 else "NO_CHANGE"
	# Commit once, before publishing any facts. Reentrant mutation is rejected.
	request._resolved = true
	target.resource -= int(mitigation.resource_cost)
	target.health = result.health_after
	if result.defeated:
		target.lifecycle = Combatant.Lifecycle.DEFEATED
	if result.defense != "NONE":
		var defended := DefenseResolved.new()
		defended.outcome = result.defense
		defended.prevented = result.prevented
		defended.resource_cost = int(mitigation.resource_cost)
		_stamp(defended, result, clock.tick)
		_publish(defended)
	if result.actual == 0:
		_transaction_active = false
		return result
	_transaction_active = true
	var tick := clock.tick
	var facts: Array[CombatEvent] = []
	if healing:
		var fact := HealingApplied.new()
		fact.actual = result.actual
		fact.overheal = result.overage
		fact.action_id = request.action_id
		_stamp(fact, result, tick)
		facts.append(fact)
	else:
		var fact := DamageApplied.new()
		var hit := request as DamageRequest
		fact.actual = result.actual
		fact.evaluated = result.evaluated
		fact.overkill = result.overage
		fact.damage_type_id = hit.damage_type_id
		fact.action_id = request.action_id
		fact.tags = request.tags.duplicate()
		fact.relationship = result.relationship
		fact.has_impact = hit.has_impact
		fact.impact_position = hit.impact_position
		_stamp(fact, result, tick)
		facts.append(fact)
	var changed := HealthChanged.new()
	changed.before = result.health_before
	changed.after = result.health_after
	changed.max_before = target.max_health()
	changed.max_after = target.max_health()
	_stamp(changed, result, tick)
	facts.append(changed)
	if result.defeated:
		var defeated := CombatantDefeated.new()
		_stamp(defeated, result, tick)
		facts.append(defeated)
	for fact in facts:
		if _publish(fact) != OK:
			result.code = "APPLIED_EVENT_DELIVERY_FAILED"
	_transaction_active = false
	return result

func _reject(result: CombatResult, code: String) -> CombatResult:
	result.code = code
	return result

func _stamp(event: CombatEvent, request: CombatResult, tick: int) -> void:
	event.tick = tick
	event.source_entity = request.source_entity
	event.target_entity = request.target_entity
	event.transaction_id = request.transaction_id
	event.correlation_id = request.transaction_id

func _publish(event: CombatEvent) -> Error:
	var error := events.publish(event)
	if error != OK:
		diagnostics.record("error", "foundation.combat", "event_delivery_failed", {"error": error, "transaction_id": event.transaction_id})
	return error

func add_modifier(entity_id: String, modifier: CombatModifier) -> Error:
	return _modify(entity_id, modifier, "")

func remove_modifier(entity_id: String, source_id: String) -> Error:
	return _modify(entity_id, null, source_id)

func _modify(entity_id: String, modifier: CombatModifier, removing: String) -> Error:
	var state := combatant(entity_id)
	if _transaction_active or state == null:
		return ERR_BUSY if _transaction_active else ERR_DOES_NOT_EXIST
	var previous := state.health
	var max_before := state.max_health()
	var error := state.attributes.remove(removing) if not removing.is_empty() else state.attributes.add(modifier)
	if error != OK:
		return error
	state.health = mini(state.health, state.max_health())
	state.resource = mini(state.resource, state.max_resource())
	if previous != state.health or max_before != state.max_health():
		var changed := HealthChanged.new()
		changed.source_entity = entity_id
		changed.target_entity = entity_id
		changed.before = previous
		changed.after = state.health
		changed.max_before = max_before
		changed.max_after = state.max_health()
		changed.tick = clock.tick
		_transaction_active = true
		_publish(changed)
		_transaction_active = false
	return OK

# Tick/scheduler owners can call these; no frame-based regeneration is run here.
func restore_resource(entity_id: String, amount: float) -> int:
	var state := combatant(entity_id)
	if _transaction_active or state == null or state.lifecycle != Combatant.Lifecycle.ALIVE or not Combatant.valid(state.capture(), data.lookup(state.profile_id)) or not CombatNumbers.integer(amount, 0, CombatNumbers.MAX_UNITS):
		return -1
	var actual := mini(int(amount), state.max_resource() - state.resource)
	state.resource += actual
	return actual

func spend_resource(entity_id: String, amount: float) -> Error:
	var state := combatant(entity_id)
	if _transaction_active or state == null or state.lifecycle != Combatant.Lifecycle.ALIVE or not Combatant.valid(state.capture(), data.lookup(state.profile_id)) or not CombatNumbers.integer(amount, 0, CombatNumbers.MAX_UNITS) or amount > state.resource:
		return ERR_INVALID_PARAMETER
	state.resource -= int(amount)
	return OK
