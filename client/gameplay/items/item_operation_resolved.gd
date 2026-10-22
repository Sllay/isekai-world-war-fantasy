class_name ItemOperationResolved
extends CoreEvent

var owner_id := ""
var code := ""
var revision := 0

func _init() -> void:
	source_module = "gameplay.items_resources"
