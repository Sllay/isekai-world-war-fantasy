class_name ActionExecutor
extends RefCounted

enum Phase { IDLE, CASTING, COMMIT, RECOVERY, CANCELLED }
var combat: CombatService
var catalog: ActionCatalog
var owner_id := ""
# Pure world-space lookup: stable entity ID -> Vector3, or null if unavailable.
var position_of: Callable
var phase := Phase.IDLE
var deadline := 0
var current: ActionDefinition
var target_id := ""
var execution_id := ""
var last_result := "NONE"
var last_activation_result := "NONE"
var effect_results: Array[CombatResult] = []
var _cooldowns: Dictionary[String, int] = {}
var _busy := false
var _committed := false
var _processed_tick := -1

func _init(service: CombatService = null, definitions: ActionCatalog = null, owner := "") -> void:
	combat = service
	catalog = definitions
	owner_id = owner

func remaining_cooldown(action_id: String) -> int:
	return maxi(0, _cooldowns.get(action_id, 0) - combat.clock.tick)

# Availability is per-action and separate from active execution. Later charges
# can replace this query/commit policy without adding phases to execution.
func activate(action_id: String, target: ActionTarget = null) -> String:
	if _busy:
		return "BUSY"
	advance()
	_busy = true
	var definition := catalog.lookup(action_id)
	var chosen := owner_id if definition != null and definition.target_mode == ActionDefinition.TargetMode.SELF else (target.entity_id if target != null else "")
	var code := _validate(definition, chosen, true)
	if code != "OK":
		last_result = code
		last_activation_result = code
		_busy = false
		return code
	current = definition
	target_id = chosen
	execution_id = CoreIds.generate()
	_committed = false
	effect_results.clear()
	phase = Phase.CASTING
	deadline = combat.clock.tick + current.cast_ticks
	last_result = "STARTED"
	last_activation_result = "STARTED"
	_emit(ActionStarted.new(), combat.clock.tick)
	_busy = false
	advance()
	return "STARTED"

func _validate(definition: ActionDefinition, chosen: String, starting: bool) -> String:
	var owner := combat.combatant(owner_id)
	if owner == null:
		return "OWNER_UNAVAILABLE"
	if owner.lifecycle != Combatant.Lifecycle.ALIVE:
		return "OWNER_DEFEATED"
	if definition == null:
		return "UNKNOWN_ACTION"
	if starting and phase not in [Phase.IDLE, Phase.CANCELLED]:
		return "ACTION_ACTIVE"
	if starting and remaining_cooldown(definition.action_id) > 0:
		return "COOLDOWN"
	if definition.resource_cost > 0 and (owner.resource_id != definition.resource_id or owner.resource < definition.resource_cost):
		return "INSUFFICIENT_RESOURCE"
	var target := combat.combatant(chosen)
	if target == null:
		return "TARGET_UNAVAILABLE"
	if target.lifecycle != Combatant.Lifecycle.ALIVE:
		return "TARGET_DEFEATED"
	if definition.target_mode == ActionDefinition.TargetMode.ENTITY:
		if not position_of.is_valid():
			return "POSITION_UNAVAILABLE"
		var origin: Variant = position_of.call(owner_id)
		var destination: Variant = position_of.call(chosen)
		if not origin is Vector3 or not destination is Vector3 or not origin.is_finite() or not destination.is_finite():
			return "POSITION_UNAVAILABLE"
		if origin.distance_squared_to(destination) > definition.max_range * definition.max_range:
			return "OUT_OF_RANGE"
	return ActionEffectRunner.validate(combat, definition, owner_id, chosen)

# Call after every simulation tick. No wall-clock or animation time is observed.
func advance() -> void:
	if _busy:
		return
	_busy = true
	var tick := combat.clock.tick
	if tick < _processed_tick:
		_busy = false
		return
	_processed_tick = tick
	if phase in [Phase.CASTING, Phase.RECOVERY]:
		var owner := combat.combatant(owner_id)
		if owner == null or owner.lifecycle != Combatant.Lifecycle.ALIVE:
			_cancel("OWNER_UNAVAILABLE", tick)
	if phase == Phase.CASTING and tick >= deadline:
		var code := _validate(current, target_id, false)
		if code != "OK":
			_cancel(code, tick)
		elif not _committed:
			# Revalidate at commit; no spend or cooldown on windup cancellation.
			if combat.spend_resource(owner_id, current.resource_cost) != OK:
				_cancel("RESOURCE_COMMIT_FAILED", tick)
			else:
				_committed = true
				phase = Phase.COMMIT
				if current.cooldown_ticks > 0:
					_cooldowns[current.action_id] = tick + current.cooldown_ticks
				effect_results = ActionEffectRunner.execute(combat, current, owner_id, target_id, execution_id)
				last_result = "COMMITTED"
				_emit(ActionCommitted.new(), tick)
				phase = Phase.RECOVERY
				deadline = tick + current.recovery_ticks
	if phase == Phase.RECOVERY and tick >= deadline:
		last_result = "COMPLETED"
		phase = Phase.IDLE
		_emit(ActionCompleted.new(), tick)
		current = null
	_busy = false

func cancel() -> String:
	return _request_cancel(false)

func interrupt() -> String:
	return _request_cancel(true)

func _request_cancel(external: bool) -> String:
	if _busy:
		return "BUSY"
	advance()
	if phase != Phase.CASTING:
		return "NOT_CANCELLABLE_PHASE"
	if not (current.interruptible if external else current.cancellable):
		return "NOT_INTERRUPTIBLE" if external else "NOT_CANCELLABLE"
	_busy = true
	_cancel("INTERRUPTED" if external else "VOLUNTARY", combat.clock.tick)
	_busy = false
	return "CANCELLED"

func _cancel(reason: String, tick: int) -> void:
	phase = Phase.CANCELLED
	last_result = reason
	_emit(ActionCancelled.new(), tick, reason)
	current = null
	deadline = tick

func movement_allowed() -> bool:
	return current == null or phase != Phase.CASTING or current.cast_while_moving

func turning_allowed() -> bool:
	return current == null or phase != Phase.CASTING or current.turn_while_casting

func _emit(event: ActionEvent, tick: int, reason := "") -> void:
	event.tick = tick
	event.owner_id = owner_id
	event.target_id = target_id
	event.action_id = current.action_id
	event.execution_id = execution_id
	event.correlation_id = execution_id
	event.reason = reason
	if combat.events.publish(event) != OK:
		combat.diagnostics.record("error", "foundation.combat", "action_event_delivery_failed", {"execution_id": execution_id})

func capture() -> Dictionary:
	var remaining: Dictionary = {}
	for id in _cooldowns:
		if remaining_cooldown(id) > 0:
			remaining[id] = remaining_cooldown(id)
	return {"cooldowns": remaining}

func valid_snapshot(value: Dictionary) -> bool:
	if value.size() != 1 or not value.get("cooldowns") is Dictionary or value.cooldowns.size() > catalog.ids().size():
		return false
	for id in value.cooldowns:
		if not id is String:
			return false
		var definition := catalog.lookup(id)
		if definition == null or not CombatNumbers.integer(value.cooldowns[id], 1, definition.cooldown_ticks):
			return false
	return true

func restore(value: Dictionary) -> void:
	# Active casts/recovery and input never resume. Committed cost/effects remain
	# in Combatant state; persisted remaining cooldown prevents reload bypass.
	phase = Phase.IDLE
	current = null
	target_id = ""
	execution_id = ""
	deadline = 0
	_committed = false
	_busy = false
	_processed_tick = combat.clock.tick
	last_result = "RESTORED"
	last_activation_result = "NONE"
	effect_results.clear()
	_cooldowns.clear()
	for id in value.cooldowns:
		_cooldowns[id] = combat.clock.tick + int(value.cooldowns[id])

func development_state() -> Dictionary:
	var cooldowns: Dictionary = {}
	for id in catalog.ids():
		cooldowns[id] = remaining_cooldown(id)
	return {"action_id": current.action_id if current != null else "", "phase": Phase.keys()[phase], "remaining_ticks": maxi(0, deadline - combat.clock.tick) if current != null else 0, "cooldowns": cooldowns, "last_result": last_result, "last_activation_result": last_activation_result, "target_id": target_id, "effect_codes": effect_results.map(func(result: CombatResult) -> String: return result.code)}
