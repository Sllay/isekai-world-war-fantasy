class_name CombatDefense
extends RefCounted

# Transient authority-owned defense windows; never animation-driven or persisted.
const GUARD_COST := 4
const DODGE_COST := 8
var combat: CombatService
var position_of: Callable
var facing_of: Callable
var states: Dictionary = {}
var _damage_token := -1

func bind(service: CombatService) -> void:
	combat = service
	combat.damage_policy = resolve
	_damage_token = combat.events.subscribe(DamageApplied, _hit)

func state(id: String) -> Dictionary:
	if not states.has(id):
		states[id] = {"guard": false, "dodge_until": 0, "dodge_ready": 0, "stagger_until": 0, "stagger_ready": 0}
	return states[id]

func staggered(id: String) -> bool:
	return combat.clock.tick < int(state(id).stagger_until)

func dodging(id: String) -> bool:
	return combat.clock.tick < int(state(id).dodge_until)

func set_guard(id: String, enabled: bool) -> String:
	var actor := combat.combatant(id)
	if actor == null or actor.lifecycle != Combatant.Lifecycle.ALIVE:
		return "DEFEATED"
	state(id).guard = enabled and not staggered(id) and not dodging(id)
	return "GUARD" if state(id).guard else "RELEASED"

func dodge(id: String) -> String:
	if staggered(id) or combat.clock.tick < int(state(id).dodge_ready):
		return "DEFENSE_UNAVAILABLE"
	if combat.spend_resource(id, DODGE_COST) != OK:
		return "INSUFFICIENT_RESOURCE"
	state(id).guard = false
	state(id).dodge_until = combat.clock.tick + 4
	state(id).dodge_ready = combat.clock.tick + 20
	return "DODGE"

# Pure mitigation decision. CombatService validates and commits cost and HP once.
func resolve(hit: DamageRequest, amount: int) -> Dictionary:
	var result := {"amount": amount, "resource_cost": 0, "defense": "NONE"}
	if amount == 0:
		return result
	if hit.dodgeable and dodging(hit.target_entity):
		return {"amount": 0, "resource_cost": 0, "defense": "DODGED"}
	if not state(hit.target_entity).guard or not hit.blockable:
		return result
	var actor := combat.combatant(hit.target_entity)
	var source: Variant = position_of.call(hit.source_entity) if position_of.is_valid() else null
	var target: Variant = position_of.call(hit.target_entity) if position_of.is_valid() else null
	var facing: Variant = facing_of.call(hit.target_entity) if facing_of.is_valid() else null
	if not source is Vector3 or not target is Vector3 or not facing is Vector3:
		result.defense = "GUARD_FAILED"
		return result
	var toward: Vector3 = source - target
	toward.y = 0
	if actor.resource < GUARD_COST or facing.dot(toward.normalized()) < 0.25 or staggered(hit.target_entity):
		result.defense = "GUARD_FAILED"
		return result
	return {"amount": ceili(amount * 0.25), "resource_cost": GUARD_COST, "defense": "GUARDED"}

func _hit(fact: DamageApplied) -> void:
	if fact.actual <= 0 or "combat.tag.strong" not in fact.tags:
		return
	var id := fact.target_entity
	if combat.clock.tick < int(state(id).stagger_ready) or state(id).guard or combat.combatant(id).lifecycle != Combatant.Lifecycle.ALIVE:
		return
	state(id).stagger_until = combat.clock.tick + 6
	state(id).stagger_ready = combat.clock.tick + 20
	state(id).guard = false

func dispose() -> void:
	combat.events.unsubscribe(_damage_token)
	combat.damage_policy = Callable()
	states.clear()

func capture(id: String) -> Dictionary:
	var current := state(id)
	return {"dodge_ready": maxi(0, int(current.dodge_ready) - combat.clock.tick), "stagger_ready": maxi(0, int(current.stagger_ready) - combat.clock.tick)}

static func valid_snapshot(value: Variant) -> bool:
	return value is Dictionary and value.size() == 2 and CombatNumbers.integer(value.get("dodge_ready"), 0, 20) and CombatNumbers.integer(value.get("stagger_ready"), 0, 20)

func restore(id: String, value: Dictionary) -> void:
	states.erase(id)
	state(id).dodge_ready = combat.clock.tick + int(value.dodge_ready)
	state(id).stagger_ready = combat.clock.tick + int(value.stagger_ready)
