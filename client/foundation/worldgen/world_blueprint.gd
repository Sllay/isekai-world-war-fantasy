class_name WorldBlueprint
extends RefCounted

const GENERATOR_ID := "worldgen.chapter_one"
const GENERATOR_VERSION := 1
const CONTENT_SCHEMA_VERSION := 1
const REGION_ID := "region.home_valley"
const RESOURCE_PROFILES := ["resource.profile.common_tree", "resource.profile.mountain_tree", "resource.profile.stone", "resource.profile.iron_ore"]
const SPAWN_PROFILES := ["spawn.profile.villager", "spawn.profile.traveler_bot"]
const BIOMES := ["biome.chapter1.grassland", "biome.chapter1.woodland"]
const SURFACES := ["material.terrain.grass", "material.terrain.rock"]

# Logical creation tick, not wall time: independent processes produce equal data.
static func create(world_id: String, seed_value: int, chunk_size: int = 32, coord_limit: int = 4, authored_resources: Array = []) -> Dictionary:
	var value := {"schema_version": 1, "world_id": world_id, "world_seed": seed_value, "generator_id": GENERATOR_ID, "generator_version": GENERATOR_VERSION, "content_schema_version": CONTENT_SCHEMA_VERSION, "created_tick": 0, "chunk_size": chunk_size, "coord_limit": coord_limit, "authored_resources": authored_resources.duplicate(true), "regions": {REGION_ID: {"region_id": REGION_ID, "origin_mm": [0, 0, 0], "climate": "climate.temperate", "biomes": BIOMES.duplicate(), "adjacent": [], "water": "water.drainage.south", "roads": "road.corridor.valley", "landmark": "landmark.home_valley", "resource_profiles": RESOURCE_PROFILES.duplicate(), "spawn_profiles": SPAWN_PROFILES.duplicate(), "faction_influence": {"faction.home_valley": 100}}}}
	return value if valid(value) else {}

static func valid(value: Dictionary) -> bool:
	value = WorldGenIds.normalize(value)
	if not WorldGenIds.keys(value, ["schema_version", "world_id", "world_seed", "generator_id", "generator_version", "content_schema_version", "created_tick", "chunk_size", "coord_limit", "authored_resources", "regions"]): return false
	if value.schema_version != 1 or not value.world_id is String or not CoreIds.valid(value.world_id) or not WorldGenIds.integer(value.world_seed, -9007199254740991, 9007199254740991): return false
	if value.generator_id != GENERATOR_ID or value.generator_version != GENERATOR_VERSION or value.content_schema_version != CONTENT_SCHEMA_VERSION or value.created_tick != 0: return false
	# A grid always has eight cells; sizes remain configurable without magic steps.
	if not WorldGenIds.integer(value.chunk_size, 8, 128) or int(value.chunk_size) % 8 != 0 or not WorldGenIds.integer(value.coord_limit, 1, 8): return false
	if not value.regions is Dictionary or value.regions.size() != 1 or not value.regions.get(REGION_ID) is Dictionary: return false
	if not value.authored_resources is Array or value.authored_resources.size() > 16: return false
	var seen := {}
	for entry: Variant in value.authored_resources:
		if not entry is Dictionary or not WorldGenIds.keys(entry, ["node_id", "profile_id", "region_id", "position_mm"]) or not entry.node_id is String or not CoreIds.valid(entry.node_id) or entry.profile_id not in RESOURCE_PROFILES or entry.region_id != REGION_ID or not entry.position_mm is Array or entry.position_mm.size() != 3 or seen.has(entry.node_id): return false
		for component: Variant in entry.position_mm:
			if not WorldGenIds.integer(component, -48000, 48000): return false
		if entry.position_mm[1] < -5000 or entry.position_mm[1] > 20000: return false
		seen[entry.node_id] = true
	var region: Dictionary = value.regions[REGION_ID]
	if not WorldGenIds.keys(region, ["region_id", "origin_mm", "climate", "biomes", "adjacent", "water", "roads", "landmark", "resource_profiles", "spawn_profiles", "faction_influence"]): return false
	return region.region_id == REGION_ID and region.origin_mm == [0, 0, 0] and region.climate == "climate.temperate" and region.biomes == BIOMES and region.adjacent == [] and region.water == "water.drainage.south" and region.roads == "road.corridor.valley" and region.landmark == "landmark.home_valley" and region.resource_profiles == RESOURCE_PROFILES and region.spawn_profiles == SPAWN_PROFILES and region.faction_influence == {"faction.home_valley": 100}

static func contains(value: Dictionary, coord: Vector2i, region_id: String = REGION_ID) -> bool:
	return value.regions.has(region_id) and absi(coord.x) <= value.coord_limit and absi(coord.y) <= value.coord_limit

static func protected_chunk(value: Dictionary, coord: Vector2i) -> bool:
	var size: int = value.chunk_size
	return coord.x * size < 48 and (coord.x + 1) * size > -48 and coord.y * size < 48 and (coord.y + 1) * size > -48

static func authored_in(value: Dictionary, coord: Vector2i, region_id: String) -> Array:
	var result: Array = []
	var size_mm: int = value.chunk_size * 1000
	for entry: Dictionary in value.authored_resources:
		if entry.region_id == region_id and Vector2i(floori(float(entry.position_mm[0]) / size_mm), floori(float(entry.position_mm[2]) / size_mm)) == coord: result.append(entry.duplicate(true))
	return result
