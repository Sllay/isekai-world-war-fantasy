class_name RuntimePlayerHost
extends Node3D

# Slice 3 replaces this host with Region-owned spawning. No world identity here.
var state: PlayerState
var tuning := preload("res://foundation/player/default_tuning.tres") as PlayerTuning
var intent := PlayerIntent.new()
var motor := PlayerMotor.new()
var orbit := PlayerCamera.new()
var presentation := preload("res://foundation/player/fallback_presentation.gd").new()

func _ready() -> void:
	var input := PlayerInput.new()
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
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	add_child(light)
	_ground(Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	_ground(Vector3(4, 0.5, -4), Vector3(4, 1, 4))
	var slope := _ground(Vector3(-4, 0, -4), Vector3(3, 0.3, 7))
	slope.rotation_degrees.x = -20

func _ground(at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	body.add_child(visual)
	add_child(body)
	return body

func _physics_process(_delta: float) -> void:
	motor.movement_yaw = orbit.yaw
	presentation.present(state, orbit.yaw)

func development_state() -> Dictionary:
	return {"entity_id": state.entity_id, "position": state.position, "velocity": state.velocity, "grounded": state.grounded, "movement_intent": state.intent, "presentation_direction": presentation.direction, "mirrored": presentation.mirrored, "camera_yaw": orbit.yaw}
