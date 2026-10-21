class_name PlayerAuthorityAdapter
extends RefCounted

var gateway: AuthorityGateway
var last_guard := false

func consume(avatar: PlayerAvatar, target_id: String, target_position: Variant) -> void:
	var input := avatar.intent
	var axis := Vector3(input.movement.x, 0, input.movement.y).rotated(Vector3.UP, avatar.orbit.yaw)
	var facing := avatar.state.facing
	var horizontal_aim := Vector3(input.aim_direction.x, 0, input.aim_direction.z)
	if horizontal_aim.is_finite() and horizontal_aim.length_squared() > 0.001:
		facing = horizontal_aim.normalized()
	elif target_position is Vector3:
		var toward: Vector3 = target_position - avatar.state.position
		toward.y = 0
		if toward.length_squared() > 0.001:
			facing = toward.normalized()
	elif axis.length_squared() > 0.001:
		facing = axis.normalized()
	gateway.request("move", {"axis": Vector2(axis.x, axis.z).limit_length(), "facing": facing, "jump": input.consume_jump()})
	if input.guard != last_guard:
		gateway.request("guard", {"enabled": input.guard})
		last_guard = input.guard
	var commands := input.consume_actions()
	if commands.z != 0:
		gateway.request("cancel")
	elif input.dodge_action:
		gateway.request("dodge")
	else:
		if commands.x != 0:
			_request_action("primary", target_id, input)
		if commands.y != 0:
			_request_action("skill_2", target_id, input)
		if input.strong_action:
			_request_action("skill_1", target_id, input)
		if input.skill_slot >= 1 and input.skill_slot <= 3:
			_request_action("skill_%d" % input.skill_slot, target_id, input)
	input.skill_slot = 0
	input.strong_action = false
	input.dodge_action = false

func _request_action(slot: String, target: String, input: PlayerIntent) -> void:
	gateway.request("action", {"slot": slot, "target": target, "direction": input.aim_direction, "point": input.aim_point})
