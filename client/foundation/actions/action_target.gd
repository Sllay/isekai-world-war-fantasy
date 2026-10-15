class_name ActionTarget
extends RefCounted

# Value request boundary. DIRECTION/POINT are reserved, not executed in v1.
var entity_id := ""
var direction := Vector3.ZERO
var point := Vector3.ZERO

func _init(entity := "") -> void:
	entity_id = entity

func copy() -> ActionTarget:
	var result := ActionTarget.new(entity_id)
	result.direction = direction
	result.point = point
	return result
