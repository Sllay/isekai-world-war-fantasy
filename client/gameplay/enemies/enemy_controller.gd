class_name EnemyController
extends RefCounted

enum State { IDLE, ACQUIRE, APPROACH, ATTACK, RECOVER, DISENGAGE, RETURN_HOME, DEFEATED }
var actor: EnemyActor
var targeting: TargetingService
# Movement port receives world destination and a tick duration. Navigation may
# replace the direct-terrain adapter without changing combat decisions.
var move_toward: Callable
var state := State.IDLE
var target_id := ""
var _last_tick := -1

func reset() -> void:
	state = State.IDLE
	target_id = ""
	_last_tick = -1

func tick() -> void:
	var now := actor.actions.combat.clock.tick
	if now <= _last_tick:
		return
	_last_tick = now
	actor.actions.advance()
	if actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED:
		state = State.DEFEATED
		target_id = ""
		return
	var tuning := actor.archetype
	if state == State.RETURN_HOME:
		_move(actor.home)
		if actor.position.distance_to(actor.home) < 0.1:
			state = State.IDLE
		return
	if actor.position.distance_to(actor.home) > tuning.leash_distance or (not target_id.is_empty() and not targeting.valid_hostile(actor.entity_id, target_id, tuning.leash_distance)):
		state = State.DISENGAGE
	if state == State.DISENGAGE:
		actor.actions.cancel()
		target_id = ""
		state = State.RETURN_HOME
		return
	if state == State.IDLE:
		state = State.ACQUIRE
	if state == State.ACQUIRE:
		var candidates := targeting.hostiles(actor.entity_id, tuning.awareness_range)
		if candidates.is_empty():
			state = State.IDLE
			return
		target_id = candidates[0]
		state = State.APPROACH
	if actor.actions.phase == ActionExecutor.Phase.CASTING:
		state = State.ATTACK
		return
	if actor.actions.phase == ActionExecutor.Phase.RECOVERY:
		state = State.RECOVER
		return
	if not targeting.valid_hostile(actor.entity_id, target_id, tuning.leash_distance):
		state = State.DISENGAGE
		return
	var definition := actor.actions.catalog.lookup(tuning.action_id)
	var target: Vector3 = targeting.position_of(target_id)
	state = State.APPROACH
	if actor.position.distance_to(target) > definition.max_range - tuning.range_margin:
		_move(target)
		return
	if actor.actions.remaining_cooldown(tuning.action_id) == 0:
		if actor.actions.activate(tuning.action_id, ActionTarget.new(target_id)) == "STARTED":
			state = State.ATTACK

func _move(destination: Vector3) -> void:
	if move_toward.is_valid() and actor.actions.movement_allowed():
		move_toward.call(destination, actor.actions.combat.clock.step_seconds)

func development_state() -> Dictionary:
	return {"entity_id": actor.entity_id, "archetype_id": actor.archetype.archetype_id, "health": actor.combatant.health, "lifecycle": Combatant.Lifecycle.keys()[actor.combatant.lifecycle], "ai_state": State.keys()[state], "target_id": target_id, "home_distance": actor.position.distance_to(actor.home), "leash_distance": actor.archetype.leash_distance, "position": actor.position, "action": actor.actions.development_state()}
