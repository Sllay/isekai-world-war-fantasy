class_name ResourceNodeDefinition
extends Resource

@export var node_id := ""
@export var profile_id := ""
@export var region_id := ""
@export var position := Vector3.ZERO

func valid() -> bool:
	return CoreIds.valid(node_id) and CoreIds.valid(profile_id) and CoreIds.valid(region_id) and position.is_finite() and absf(position.x) <= 1000000 and absf(position.y) <= 1000000 and absf(position.z) <= 1000000
