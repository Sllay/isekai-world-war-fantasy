class_name ItemWorkCommitted
extends CoreEvent

var actor_id := ""
var cause := ""
var subject_id := ""
var sequence := 0

func _init() -> void:
	source_module = "gameplay.items_resources"
