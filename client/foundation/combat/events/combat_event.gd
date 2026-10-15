class_name CombatEvent
extends CoreEvent

var source_entity := ""
var target_entity := ""
var transaction_id := ""

func _init() -> void:
	source_module = "foundation.combat"
