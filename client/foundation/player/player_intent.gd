class_name PlayerIntent
extends RefCounted

var movement := Vector2.ZERO
var jump := false
var camera_delta := 0.0

func consume_jump() -> bool:
	var result := jump
	jump = false
	return result

func consume_camera() -> float:
	var result := camera_delta
	camera_delta = 0.0
	return result
