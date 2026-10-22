extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func run() -> void:
	if "--hash-only" in OS.get_cmdline_user_args():
		var fixture := WorldBlueprint.create("world.primary", 77231)
		var output := WorldGenesis.new().generate(fixture, Vector2i(2, 0), 0)
		print("P3_DETERMINISM_PROOF ", JSON.stringify({"blueprint_hash": WorldGenIds.digest(fixture), "base_hash": output.record.base_hash, "resources": output.record.base.resources.map(func(entry: Dictionary) -> String: return entry.node_id), "actors": output.record.base.spawns.map(func(entry: Dictionary) -> String: return entry.actor_id)}))
		quit(0)
		return
	var blueprint := WorldBlueprint.create("world.primary", 77231)
	check(WorldBlueprint.valid(blueprint), "blueprint validates deterministic creation metadata")
	check(WorldBlueprint.valid(JSON.parse_string(JSON.stringify(blueprint))), "blueprint validates independent JSON integer representation")
	check(blueprint == WorldBlueprint.create("world.primary", 77231), "same seed/version produces same blueprint")
	check(blueprint.generator_version == 1 and blueprint.content_schema_version == 1 and blueprint.created_tick == 0, "generator/content/logical genesis version explicit")
	var changed := blueprint.duplicate(true)
	changed.generator_version = 2
	check(not WorldBlueprint.valid(changed), "incompatible generator never silently reinterprets old world")
	changed = blueprint.duplicate(true)
	changed.chunk_size = 31
	check(not WorldBlueprint.valid(changed), "invalid chunk grid configuration rejected")
	var overflow := blueprint.duplicate(true)
	overflow.world_seed = 1e100
	check(not WorldBlueprint.valid(overflow), "overflowing numeric metadata rejects before integer coercion")
	check(WorldBlueprint.create("display name", 1).is_empty(), "display names cannot become stable world identity")
	var a := WorldGenesis.new()
	var b := WorldGenesis.new()
	var generated := a.generate(blueprint, Vector2i(2, 0), 0)
	var independently := b.generate(blueprint, Vector2i(2, 0), 0)
	check(generated.ok and independently.ok and generated.record == independently.record, "isolated generators produce equal canonical output")
	check(a.generation_invocation_count == 1 and b.generation_invocation_count == 1, "generation invocation hook counts only chunk generation")
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(generated.record, "", true, true))
	check(ChunkRecord.valid(serialized, blueprint) and serialized.base_hash == WorldGenIds.digest(serialized.base), "canonical integer descriptors survive JSON/process numeric conversion")
	check(serialized.base_hash == independently.record.base_hash, "canonical hash identical for independent generation")
	var resources: Array = generated.record.base.resources
	var spawns: Array = generated.record.base.spawns
	check(resources.size() == 2 and spawns.size() == 2, "small outside-region resource/spawn profiles")
	check(resources[0].node_id == independently.record.base.resources[0].node_id and spawns[0].actor_id == independently.record.base.spawns[0].actor_id, "stable generated resource and actor IDs")
	check(CoreIds.valid(resources[0].node_id) and CombatNumbers.stable_entity(spawns[0].actor_id), "generated IDs satisfy existing data/entity contracts")
	check(WorldGenIds.stream(blueprint, WorldBlueprint.REGION_ID, Vector2i(2, 0), "terrain") != WorldGenIds.stream(blueprint, WorldBlueprint.REGION_ID, Vector2i(2, 0), "spawn"), "domain streams separated")
	var other_seed := WorldBlueprint.create("world.primary", 77232)
	check(a.generate(other_seed, Vector2i(2, 0), 0).record.base.resources != resources, "changing seed changes derived feature identities/output")
	var adjacent: Dictionary = a.generate(blueprint, Vector2i(3, 0), 0).record
	var heights: Array = generated.record.base.terrain.heights_mm
	var adjacent_heights: Array = adjacent.base.terrain.heights_mm
	for z in range(9):
		check(heights[z * 9 + 8] == adjacent_heights[z * 9], "adjacent terrain shares global edge sample %d" % z)
	check(heights.max() != heights.min(), "outside geographic variation has real elevation")
	check(generated.record.base.navigation.portals.size() == 4 and generated.record.base.ecology.population_capacity == 2, "generation supplies navigation and ecological gameplay data")
	check(not a.generate(blueprint, Vector2i(5, 0), 0).ok and not a.generate(changed, Vector2i.ZERO, 0).ok, "invalid world bounds/profile fail before generation")
	var center: Dictionary = a.generate(blueprint, Vector2i(-1, -1), 0).record
	check(center.base.resources.is_empty() and center.base.spawns.is_empty(), "protected authored center does not duplicate P1/P2 content")
	check(center.base.terrain.heights_mm[4 * 9] == 3000 and center.base.terrain.heights_mm[7 * 9] == 0, "authored ridge and ramp kinks retained at four-meter samples")
	var content := ResourceCatalog.defaults()
	var authored: Array = []
	for node in content.nodes:
		authored.append({"node_id": node.node_id, "profile_id": node.profile_id, "region_id": node.region_id, "position_mm": [roundi(node.position.x * 1000), roundi(node.position.y * 1000), roundi(node.position.z * 1000)]})
	var constrained := WorldBlueprint.create("world.primary", 77231, 32, 4, authored)
	var existing := a.generate(constrained, Vector2i(-1, 0), 0)
	check(existing.ok and existing.record.base.resources == authored, "generation bakes existing P2 resource data without duplicating definitions")
	for mutation in ["world_id", "region_id", "generator_version", "base_hash"]:
		var invalid_metadata: Dictionary = generated.record.duplicate(true)
		if mutation == "generator_version": invalid_metadata[mutation] = 9
		else: invalid_metadata[mutation] = "invalid.reference"
		check(not ChunkRecord.valid(invalid_metadata, blueprint), "invalid persisted %s rejected without regeneration" % mutation)
	var invalid: Dictionary = generated.record.duplicate(true)
	invalid.base.resources[0].profile_id = "resource.profile.missing"
	invalid.base_hash = WorldGenIds.digest(invalid.base)
	check(not ChunkRecord.valid(invalid, blueprint), "unknown resource reference rejects even recomputed checksum")
	invalid = generated.record.duplicate(true)
	invalid.base.spawns[0].actor_id = CoreIds.generate()
	invalid.base_hash = WorldGenIds.digest(invalid.base)
	check(not ChunkRecord.valid(invalid, blueprint), "forged generated actor ID rejects even recomputed checksum")
	invalid = generated.record.duplicate(true)
	invalid.base.terrain.heights_mm[0] += 1
	check(not ChunkRecord.valid(invalid, blueprint), "corrupted baked terrain checksum rejects")
	print("P3 world generation tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
