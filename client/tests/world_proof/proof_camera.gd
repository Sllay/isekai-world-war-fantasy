class_name ProofCamera
extends Node3D

@export var target: Node3D
@export var input_source: ProofInput
@export var orbit_speed := 1.6
@export var follow_response := 12.0
var yaw_goal := 0.0

func _physics_process(delta: float) -> void:
	yaw_goal += input_source.orbit() * orbit_speed * delta
	input_source.set_touch_orbit(0.0)
	rotation.y = lerp_angle(rotation.y, yaw_goal, 1.0 - exp(-follow_response * delta))
	global_position = global_position.lerp(target.global_position, 1.0 - exp(-follow_response * delta))

func _mcp_state() -> Dictionary:
	return {"yaw": rotation.y, "yaw_goal": yaw_goal, "position": global_position}
