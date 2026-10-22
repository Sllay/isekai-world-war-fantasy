class_name ChunkRecord
extends RefCounted

const GRID_SIZE := 9
const BASE_KEYS := ["terrain", "resources", "spawns", "landmarks", "navigation", "ecology"]

static func make(blueprint: Dictionary, coord: Vector2i, tick: int, base: Dictionary, region_id: String = WorldBlueprint.REGION_ID) -> Dictionary:
	return {"schema_version": 1, "chunk_id": WorldGenIds.chunk(region_id, coord), "world_id": blueprint.world_id, "region_id": region_id, "coord": [coord.x, coord.y], "generator_id": blueprint.generator_id, "generator_version": blueprint.generator_version, "created_tick": tick, "base": base.duplicate(true), "base_hash": WorldGenIds.digest(base), "revision": 0, "lifecycle": "PERSISTED", "delta": {"removed_resources": [], "spawn_claims": []}}

static func valid(value: Dictionary, blueprint: Dictionary) -> bool:
	value = WorldGenIds.normalize(value)
	blueprint = WorldGenIds.normalize(blueprint)
	if not WorldBlueprint.valid(blueprint) or not WorldGenIds.keys(value, ["schema_version", "chunk_id", "world_id", "region_id", "coord", "generator_id", "generator_version", "created_tick", "base", "base_hash", "revision", "lifecycle", "delta"]): return false
	if value.schema_version != 1 or value.world_id != blueprint.world_id or value.generator_id != blueprint.generator_id or value.generator_version != blueprint.generator_version or not value.region_id is String: return false
	if not value.coord is Array or value.coord.size() != 2: return false
	for axis: Variant in value.coord:
		if not WorldGenIds.integer(axis, -blueprint.coord_limit, blueprint.coord_limit): return false
	var coord := Vector2i(int(value.coord[0]), int(value.coord[1]))
	if not WorldBlueprint.contains(blueprint, coord, value.region_id) or value.chunk_id != WorldGenIds.chunk(value.region_id, coord): return false
	if not WorldGenIds.integer(value.created_tick, 0, 9007199254740991) or not WorldGenIds.integer(value.revision, 0, 1000000000) or value.lifecycle not in ["PERSISTED", "MODIFIED"] or not value.base is Dictionary or not value.base_hash is String: return false
	if not valid_base(value.base, blueprint, coord, value.region_id) or value.base_hash != WorldGenIds.digest(value.base) or not value.delta is Dictionary or not valid_delta(value.delta, value.base): return false
	return (value.revision == 0 and value.lifecycle == "PERSISTED" and value.delta.removed_resources.is_empty() and value.delta.spawn_claims.is_empty()) or (value.revision > 0 and value.lifecycle == "MODIFIED")

static func valid_base(base: Dictionary, blueprint: Dictionary, coord: Vector2i, region_id: String) -> bool:
	if not WorldGenIds.keys(base, BASE_KEYS) or not base.terrain is Dictionary: return false
	var terrain: Dictionary = base.terrain
	if not WorldGenIds.keys(terrain, ["grid_size", "size_mm", "heights_mm", "biome_id", "surface_id"]) or terrain.grid_size != GRID_SIZE or terrain.size_mm != blueprint.chunk_size * 1000 or terrain.biome_id not in WorldBlueprint.BIOMES or terrain.surface_id not in WorldBlueprint.SURFACES or not terrain.heights_mm is Array or terrain.heights_mm.size() != GRID_SIZE * GRID_SIZE: return false
	for height: Variant in terrain.heights_mm:
		if not WorldGenIds.integer(height, -5000, 20000): return false
	var authored := WorldBlueprint.authored_in(blueprint, coord, region_id)
	var procedural_count := 0 if WorldBlueprint.protected_chunk(blueprint, coord) else 2
	if not base.resources is Array or base.resources.size() != authored.size() + procedural_count or not base.spawns is Array or base.spawns.size() != procedural_count: return false
	for i in range(authored.size()):
		if base.resources[i] != authored[i]: return false
	for i in range(procedural_count):
		var entry: Variant = base.resources[authored.size() + i]
		if not entry is Dictionary or not WorldGenIds.keys(entry, ["node_id", "profile_id", "region_id", "position_mm"]) or entry.node_id != WorldGenIds.feature(blueprint, region_id, coord, "resource", i) or entry.profile_id not in WorldBlueprint.RESOURCE_PROFILES or entry.region_id != region_id or not valid_point(entry.position_mm, blueprint, coord): return false
	for i in range(base.spawns.size()):
		var entry: Variant = base.spawns[i]
		if not entry is Dictionary or not WorldGenIds.keys(entry, ["spawn_id", "actor_id", "profile_id", "region_id", "position_mm", "capacity", "repopulation_ticks"]) or entry.spawn_id != WorldGenIds.feature(blueprint, region_id, coord, "spawn", i) or entry.actor_id != WorldGenIds.entity(blueprint, region_id, coord, "actor", i) or entry.profile_id != WorldBlueprint.SPAWN_PROFILES[i] or entry.region_id != region_id or not valid_point(entry.position_mm, blueprint, coord) or entry.capacity != 1 or entry.repopulation_ticks != -1: return false
	if not base.landmarks is Array or base.landmarks.size() != 1 or not base.landmarks[0] is Dictionary: return false
	var landmark: Dictionary = base.landmarks[0]
	if not WorldGenIds.keys(landmark, ["id", "profile_id", "position_mm"]) or landmark.id != WorldGenIds.feature(blueprint, region_id, coord, "landmark") or landmark.profile_id != "landmark.waypoint" or not valid_point(landmark.position_mm, blueprint, coord): return false
	if not base.navigation is Dictionary or not WorldGenIds.keys(base.navigation, ["walkable", "portals"]) or base.navigation.walkable != true or not base.navigation.portals is Array or base.navigation.portals.size() != 4: return false
	for point: Variant in base.navigation.portals:
		if not valid_point(point, blueprint, coord, true): return false
	return base.ecology is Dictionary and WorldGenIds.keys(base.ecology, ["population_capacity", "resource_capacity", "profile_id"]) and base.ecology.population_capacity == base.spawns.size() and base.ecology.resource_capacity == base.resources.size() and base.ecology.profile_id == "ecology.temperate.foundation"

static func valid_point(point: Variant, blueprint: Dictionary, coord: Vector2i, inclusive: bool = false) -> bool:
	if not point is Array or point.size() != 3: return false
	for component: Variant in point:
		if not WorldGenIds.integer(component, -2000000, 2000000): return false
	var size_mm: int = blueprint.chunk_size * 1000
	var max_offset := 0 if inclusive else 1
	return point[0] >= coord.x * size_mm and point[0] <= (coord.x + 1) * size_mm - max_offset and point[2] >= coord.y * size_mm and point[2] <= (coord.y + 1) * size_mm - max_offset and point[1] >= -5000 and point[1] <= 20000

static func valid_delta(delta: Dictionary, base: Dictionary) -> bool:
	if not WorldGenIds.keys(delta, ["removed_resources", "spawn_claims"]): return false
	for key: String in ["removed_resources", "spawn_claims"]:
		if not delta[key] is Array or delta[key].size() > 16: return false
		var allowed: Array = []
		for entry: Dictionary in (base.resources if key == "removed_resources" else base.spawns): allowed.append(entry.node_id if key == "removed_resources" else entry.spawn_id)
		var seen := {}
		for id: Variant in delta[key]:
			if not id is String or id not in allowed or seen.has(id): return false
			seen[id] = true
	return true
