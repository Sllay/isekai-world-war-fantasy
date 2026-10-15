class_name PlayerTuning
extends Resource

@export var speed := 6.0
@export var acceleration := 24.0
@export var deceleration := 30.0
@export var air_acceleration := 8.0
@export var gravity := 24.0
@export var jump_speed := 9.0
@export var terminal_speed := 45.0
@export var floor_angle_degrees := 46.0
@export var floor_snap := 0.3
@export var camera_distance := 11.0
@export_range(20, 75) var camera_inclination := 48.0
@export var follow_smoothing := 12.0
@export var rotation_smoothing := 18.0
@export var touch_radians_per_pixel := 0.012
@export var mouse_radians_per_pixel := 0.008
@export var controller_radians_per_second := 3.5
@export var stick_deadzone := 0.18
