class_name ActionEvent
extends CoreEvent

var owner_id := ""
var target_id := ""
var target_ids: Array[String] = []
var aim_direction := Vector3.ZERO
var aim_point := Vector3.ZERO
var action_id := ""
var execution_id := ""
var reason := ""

func _init() -> void:
	source_module = "foundation.combat"
