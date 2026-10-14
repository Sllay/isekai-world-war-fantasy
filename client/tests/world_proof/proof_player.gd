class_name ProofPlayer
extends CharacterBody3D

@export var input_source: ProofInput
@export var camera_rig: Node3D
@export var speed := 4.0
@export var acceleration := 18.0
@export var jump_speed := 5.0
@export var gravity := 14.0
var physics_frames := 0
var jumps := 0

func _physics_process(delta: float) -> void:
	physics_frames += 1
	var intent := input_source.movement()
	var direction := Vector3(intent.x, 0.0, intent.y).rotated(Vector3.UP, camera_rig.rotation.y)
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta
	if input_source.consume_jump() and is_on_floor():
		velocity.y = jump_speed
		jumps += 1
	move_and_slide()
	if position.y < -8.0:
		position = Vector3(0, 0.1, 1)
		velocity = Vector3.ZERO

func _mcp_state() -> Dictionary:
	return {"position": position, "velocity": velocity, "grounded": is_on_floor(),
		"physics_frames": physics_frames, "jumps": jumps}
