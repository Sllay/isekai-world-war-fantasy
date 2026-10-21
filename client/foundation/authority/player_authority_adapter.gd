class_name PlayerAuthorityAdapter
extends RefCounted

var gateway: AuthorityGateway
var last_guard := false

func consume(avatar: PlayerAvatar, target_id: String, target_position: Variant) -> void:
	var input := avatar.intent
	var axis := Vector3(input.movement.x, 0, input.movement.y).rotated(Vector3.UP, avatar.orbit.yaw)
	var facing := avatar.state.facing
	if input.aim_direction.is_finite() and input.aim_direction.length_squared() > 0.001:
		facing = Vector3(input.aim_direction.x, 0, input.aim_direction.z).normalized()
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
			gateway.request("action", {"slot": "primary", "target": target_id})
		if commands.y != 0:
			gateway.request("action", {"slot": "heal", "target": target_id})
		if input.strong_action:
			gateway.request("action", {"slot": "strong", "target": target_id})
	input.strong_action = false
	input.dodge_action = false
