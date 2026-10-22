class_name WorldGenesis
extends RefCounted

var generation_invocation_count := 0
var last_generation_us := 0

func generate(blueprint: Dictionary, coord: Vector2i, tick: int, region_id: String = WorldBlueprint.REGION_ID) -> Dictionary:
	if not WorldBlueprint.valid(blueprint): return {"ok": false, "code": "GENERATOR_INCOMPATIBLE"}
	if not WorldBlueprint.contains(blueprint, coord, region_id) or tick < 0 or tick > 9007199254740991: return {"ok": false, "code": "CHUNK_OUTSIDE_WORLD"}
	var started := Time.get_ticks_usec()
	generation_invocation_count += 1
	var size: int = blueprint.chunk_size
	var step := int(float(size) / (ChunkRecord.GRID_SIZE - 1))
	var heights: Array = []
	for z in range(ChunkRecord.GRID_SIZE):
		for x in range(ChunkRecord.GRID_SIZE):
			heights.append(height_mm(blueprint, coord.x * size + x * step, coord.y * size + z * step))
	var terrain_stream := WorldGenIds.stream(blueprint, region_id, coord, "terrain").substr(0, 8).hex_to_int()
	var biome: String = WorldBlueprint.BIOMES[terrain_stream % WorldBlueprint.BIOMES.size()]
	var surface: String = WorldBlueprint.SURFACES[1 if absi(coord.x) + absi(coord.y) > 5 else 0]
	var resources: Array = WorldBlueprint.authored_in(blueprint, coord, region_id)
	var resource_stream := WorldGenIds.stream(blueprint, region_id, coord, "resources").substr(0, 8).hex_to_int()
	var procedural_count := 0 if WorldBlueprint.protected_chunk(blueprint, coord) else 2
	for i in range(procedural_count):
		var point := _point(blueprint, coord, 2 + i * 3, 2 + int((resource_stream + i) % 3))
		resources.append({"node_id": WorldGenIds.feature(blueprint, region_id, coord, "resource", i), "profile_id": WorldBlueprint.RESOURCE_PROFILES[0 if i == 0 else 2 + resource_stream % 2], "region_id": region_id, "position_mm": point})
	var spawns: Array = []
	for i in range(procedural_count):
		spawns.append({"spawn_id": WorldGenIds.feature(blueprint, region_id, coord, "spawn", i), "actor_id": WorldGenIds.entity(blueprint, region_id, coord, "actor", i), "profile_id": WorldBlueprint.SPAWN_PROFILES[i], "region_id": region_id, "position_mm": _point(blueprint, coord, 3 + i * 2, 5), "capacity": 1, "repopulation_ticks": -1})
	var portals: Array = []
	for offset: Vector2i in [Vector2i(0, 4), Vector2i(8, 4), Vector2i(4, 0), Vector2i(4, 8)]: portals.append(_point(blueprint, coord, offset.x, offset.y))
	var base := {"terrain": {"grid_size": ChunkRecord.GRID_SIZE, "size_mm": size * 1000, "heights_mm": heights, "biome_id": biome, "surface_id": surface}, "resources": resources, "spawns": spawns, "landmarks": [{"id": WorldGenIds.feature(blueprint, region_id, coord, "landmark"), "profile_id": "landmark.waypoint", "position_mm": _point(blueprint, coord, 4, 4)}], "navigation": {"walkable": true, "portals": portals}, "ecology": {"population_capacity": spawns.size(), "resource_capacity": resources.size(), "profile_id": "ecology.temperate.foundation"}}
	var record := ChunkRecord.make(blueprint, coord, tick, base, region_id)
	var valid_record := ChunkRecord.valid(record, blueprint)
	last_generation_us = Time.get_ticks_usec() - started
	return {"ok": true, "code": "GENERATED", "record": record} if valid_record else {"ok": false, "code": "GENERATED_DATA_INVALID"}

static func _point(blueprint: Dictionary, coord: Vector2i, x: int, z: int) -> Array:
	var step := int(float(blueprint.chunk_size) / 8.0)
	var px: int = coord.x * int(blueprint.chunk_size) + x * step
	var pz: int = coord.y * int(blueprint.chunk_size) + z * step
	return [px * 1000, height_mm(blueprint, px, pz), pz * 1000]

# Seamless global field sampled at chunk boundaries, not independent chunk noise.
# The authored P1/P2 ridge remains an explicit terrain constraint in the center.
static func height_mm(blueprint: Dictionary, x: int, z: int) -> int:
	var authored := 0
	if z <= -16: authored = 3000
	elif z < -4: authored = (-4 - z) * 250
	var distance := maxi(absi(x), absi(z))
	if distance <= 48: return authored
	var seed_value: int = int(blueprint.world_seed)
	var mountain_bias := int(WorldGenIds.digest([seed_value, blueprint.generator_version, "height"]).substr(0, 4).hex_to_int() % 3) - 1
	var fade := mini(distance - 48, 48)
	var slope := ((x + 256) % 64 - 32) * mountain_bias + ((z + 256) % 96 - 48)
	return clampi(authored + slope * fade, -3000, 12000)
