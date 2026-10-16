class_name PlayerActionAdapter
extends RefCounted

# Player slot mapping, not part of the generic executor. Later loadouts own this.
var primary_id := "combat.action.basic_strike"
var secondary_id := "combat.action.basic_heal"
var executor: ActionExecutor
var default_target: Callable
var move_dodge: Callable
var dodge_direction: Callable

func consume(intent: PlayerIntent) -> void:
	var defenses := intent.consume_defenses()
	if defenses.guard_ended:
		executor.combat.end_guard(executor.owner_id)
	if defenses.guard_started and not defenses.guard_ended:
		executor.activate("combat.action.basic_guard")
	if defenses.dodge:
		var code := executor.activate("combat.action.basic_dodge")
		if code == "STARTED" and move_dodge.is_valid() and dodge_direction.is_valid():
			var definition := executor.catalog.lookup("combat.action.basic_dodge")
			move_dodge.call(dodge_direction.call(), definition.effects[0].movement_distance)
	if defenses.parry:
		executor.activate("combat.action.basic_parry")
	if defenses.interrupt:
		var chosen := intent.target_entity_id
		if chosen.is_empty() and default_target.is_valid():
			chosen = default_target.call()
		executor.activate("combat.action.basic_interrupt", ActionTarget.new(chosen))
	var commands := intent.consume_actions()
	if commands.z != 0:
		executor.cancel()
		return
	var target := ActionTarget.new(intent.target_entity_id)
	target.direction = intent.aim_direction
	target.point = intent.aim_point
	if target.entity_id.is_empty() and default_target.is_valid():
		target.entity_id = default_target.call()
	# Stable slot order; a second simultaneous request rejects ACTION_ACTIVE.
	if commands.x != 0:
		executor.activate(primary_id, target)
	if commands.y != 0:
		executor.activate(secondary_id, target)
