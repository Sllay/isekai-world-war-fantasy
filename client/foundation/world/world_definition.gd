class_name WorldDefinition
extends Resource

@export var world_id: String
@export var world_seed: int
@export var initial_region_id: String
@export var regions: Array[RegionDefinition] = []

func valid() -> bool:
	if not CoreIds.valid(world_id) or absf(float(world_seed)) > 9007199254740991.0:
		return false
	var ids: Dictionary = {}
	for region in regions:
		if region == null or not region.valid() or ids.has(region.region_id):
			return false
		ids[region.region_id] = true
	return ids.has(initial_region_id)

func region(id: String) -> RegionDefinition:
	for definition in regions:
		if definition.region_id == id:
			return definition
	return null
