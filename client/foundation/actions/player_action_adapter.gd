class_name PlayerActionAdapter
extends RefCounted

# Player slot mapping, not part of the generic executor. Later loadouts own this.
var primary_id := "combat.action.basic_strike"
var secondary_id := "combat.action.basic_heal"
var executor: ActionExecutor
var default_target: Callable

func consume(intent: PlayerIntent) -> void:
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
