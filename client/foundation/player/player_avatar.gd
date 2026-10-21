class_name PlayerAvatar
extends Node3D

# Region owns attachment and placement; this adapter only composes Player nodes.
var state: PlayerState
var tuning := preload("res://foundation/player/default_tuning.tres") as PlayerTuning
var intent := PlayerIntent.new()
var motor := PlayerMotor.new()
var orbit := PlayerCamera.new()
var presentation := preload("res://foundation/player/fallback_presentation.gd").new()
var input := PlayerInput.new()

func _ready() -> void:
	input.intent = intent
	input.tuning = tuning
	add_child(input)
	motor.state = state
	motor.intent = intent
	motor.tuning = tuning
	motor.name = "PlayerBody"
	add_child(motor)
	orbit.state = state
	orbit.intent = intent
	orbit.tuning = tuning
	add_child(orbit)
	add_child(presentation)

func _physics_process(_delta: float) -> void:
	if input.pointer_aim:
		var point: Variant = PlayerAimAdapter.project(orbit.camera, input.pointer_position, state.position)
		if point is Vector3:
			PlayerAimAdapter.apply(intent, point, state.position)
	if not motor.authority_step.is_valid():
		motor.movement_yaw = orbit.yaw
	presentation.present(state, orbit.yaw)

func development_state() -> Dictionary:
	return {"entity_id": state.entity_id, "position": state.position, "velocity": state.velocity, "grounded": state.grounded, "movement_intent": state.intent, "presentation_direction": presentation.direction, "mirrored": presentation.mirrored, "camera_yaw": orbit.yaw}
