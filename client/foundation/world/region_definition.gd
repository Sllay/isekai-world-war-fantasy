class_name RegionDefinition
extends Resource

@export var region_id: String
@export var schema_version := 1
@export var origin := Vector3.ZERO
@export var chunk_size := 32.0
@export var default_entry := "entry.arrival"
@export var entries: Dictionary[String, Vector3] = {}
# Region-local resilience constraints, independent of Player gameplay.
@export var recovery_y := -12.0
@export var safety_bounds := Rect2() # empty means no authored horizontal bound
@export var safety_surface := PackedVector2Array() # (z, y), same authored terrain profile
@export var actor_spawns: Dictionary[String, Vector3] = {}
@export var scene: PackedScene
# Content metadata references only; no biome/faction/weather implementations.
@export var metadata_ids: Dictionary[String, String] = {}

func valid() -> bool:
	if not CoreIds.valid(region_id) or schema_version != 1 or not origin.is_finite() or not is_finite(chunk_size) or chunk_size <= 0 or scene == null or not scene.can_instantiate():
		return false
	if not is_finite(recovery_y) or not safety_bounds.position.is_finite() or not safety_bounds.size.is_finite() or safety_bounds.size.x < 0 or safety_bounds.size.y < 0:
		return false
	for id in actor_spawns:
		if not CoreIds.valid(id) or not safe_position(to_world_position(actor_spawns[id])):
			return false
	for i in range(safety_surface.size()):
		if not safety_surface[i].is_finite() or (i > 0 and safety_surface[i - 1].x <= safety_surface[i].x):
			return false
	if not entries.has(default_entry):
		return false
	for id in entries:
		if not CoreIds.valid(id) or not entries[id].is_finite() or not safe_position(to_world_position(entries[id])):
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

func safe_position(value: Vector3) -> bool:
	var local := to_local_position(value)
	return value.is_finite() and local.y > recovery_y and (not safety_bounds.has_area() or safety_bounds.has_point(Vector2(local.x, local.z)))

func approved_surface(value: Vector3) -> bool:
	if not safe_position(value):
		return false
	var local := to_local_position(value)
	for i in range(safety_surface.size() - 1):
		var a := safety_surface[i]
		var b := safety_surface[i + 1]
		if local.z <= maxf(a.x, b.x) and local.z >= minf(a.x, b.x):
			var y := lerpf(a.y, b.y, (local.z - a.x) / (b.x - a.x))
			return local.y >= y - 0.05 and local.y <= y + 0.25
	return false
