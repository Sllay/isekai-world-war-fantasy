class_name PlayerIntent
extends RefCounted

var movement := Vector2.ZERO
var jump := false
var camera_delta := 0.0
# Slots are semantic, independent from hardware and action content IDs.
var primary_action := false
var secondary_action := false
var cancel_action := false
var target_entity_id := ""
var aim_direction := Vector3.ZERO
var aim_point := Vector3.ZERO

func consume_actions() -> Vector3i:
	var result := Vector3i(int(primary_action), int(secondary_action), int(cancel_action))
	primary_action = false
	secondary_action = false
	cancel_action = false
	return result


func consume_jump() -> bool:
	var result := jump
	jump = false
	return result

func consume_camera() -> float:
	var result := camera_delta
	camera_delta = 0.0
	return result

var select_target := false
var strong_action := false
var dodge_action := false
var guard := false
