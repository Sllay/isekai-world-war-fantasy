class_name ActionEvent
extends CoreEvent

var owner_id := ""
var target_id := ""
var action_id := ""
var execution_id := ""
var reason := ""

func _init() -> void:
	source_module = "foundation.combat"
