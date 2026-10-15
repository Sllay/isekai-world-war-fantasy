class_name PlayerCamera
extends Node3D

var state: PlayerState
var intent: PlayerIntent
var tuning: PlayerTuning
var yaw := 0.0
var target_yaw := 0.0
var camera := Camera3D.new()

func _ready() -> void:
	position = state.position
	add_child(camera)
	camera.current = true
	camera.near = 0.1
	camera.far = 200.0

func _physics_process(delta: float) -> void:
	target_yaw = wrapf(target_yaw + intent.consume_camera(), -PI, PI)
	yaw = lerp_angle(yaw, target_yaw, 1.0 - exp(-tuning.rotation_smoothing * delta))
	position = position.lerp(state.position, 1.0 - exp(-tuning.follow_smoothing * delta))
	var pitch := deg_to_rad(clampf(tuning.camera_inclination, 20, 75))
	var offset := Vector3(0, sin(pitch), cos(pitch)) * clampf(tuning.camera_distance, 3, 30)
	camera.position = offset.rotated(Vector3.UP, yaw)
	camera.look_at(global_position + Vector3.UP)
