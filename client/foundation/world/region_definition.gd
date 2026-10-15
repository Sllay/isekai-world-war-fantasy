class_name RegionDefinition
extends Resource

@export var region_id: String
@export var schema_version := 1
@export var origin := Vector3.ZERO
@export var chunk_size := 32.0
@export var default_entry := "entry.arrival"
@export var entries: Dictionary[String, Vector3] = {}
@export var scene: PackedScene
# Content metadata references only; no biome/faction/weather implementations.
@export var metadata_ids: Dictionary[String, String] = {}

func valid() -> bool:
	if not CoreIds.valid(region_id) or schema_version != 1 or not origin.is_finite() or not is_finite(chunk_size) or chunk_size <= 0 or scene == null or not scene.can_instantiate():
		return false
	if not entries.has(default_entry):
		return false
	for id in entries:
		if not CoreIds.valid(id) or not entries[id].is_finite():
			return false
	for key in metadata_ids:
		if not CoreIds.valid(key) or not CoreIds.valid(metadata_ids[key]):
			return false
	return true

func to_local_position(world_position: Vector3) -> Vector3:
	return world_position - origin

func to_world_position(local_position: Vector3) -> Vector3:
	return origin + local_position

# Horizontal half-open bounds [min, max) in region-local X/Z coordinates.
func chunk_bounds(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell.x, cell.y) * chunk_size, Vector2.ONE * chunk_size)

func chunk_at(local_position: Vector3) -> Vector2i:
	return Vector2i(floori(local_position.x / chunk_size), floori(local_position.z / chunk_size))

func chunk_id(local_position: Vector3) -> String:
	var cell := chunk_at(local_position)
	return "%s:%d:%d" % [region_id, cell.x, cell.y]
