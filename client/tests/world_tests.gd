extends SceneTree

const CONTENT = preload("res://world/primary_world.tres")
const WORLD_SCENE = preload("res://world/world.tscn")
var checks := 0
var failures := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var registry := CoreModuleRegistry.new()
	var core := CoreRuntimeServicesModule.new()
	var player := PlayerModule.new()
	var world := WorldModule.new(CONTENT)
	var regions := RegionModule.new()
	for module in [regions, player, world, core]:
		registry.add(module)
	check(registry.boot() == OK, "declared dependencies boot in order regardless of registration order")
	check(registry.order.find(world) < registry.order.find(regions) and registry.order.find(player) < registry.order.find(regions), "one-way module ownership")
	check(world.state.world_id == CONTENT.world_id and world.state.schema_version == 1, "stable explicit world identity")
	check(world.state.world_seed == CONTENT.world_seed, "explicit world seed")
	var directory := regions.directory
	var definition := CONTENT.regions[0]
	var record := directory.record(definition.region_id)
	check(record != null and record.definition.region_id == "region.home_valley", "stable region identity")
	check(record.world == world.state and world.state.clock == core.clock, "world membership and borrowed Core clock")
	core.clock.advance(0.2)
	check(record.simulation_tick() == core.clock.tick and record.simulation_tick() > 0, "region uses live Core time")
	check(player.capabilities.capability("foundation.location") == directory.location, "Region supplies borrowed Player capability")
	check(player.requires == ["core.runtime"] and not world.requires.has("foundation.regions"), "Player and World do not depend on Region")
	check(directory.add(definition) != OK, "duplicate region rejected")
	var invalid := definition.duplicate() as RegionDefinition
	invalid.region_id = "not a region id"
	check(directory.add(invalid) != OK, "invalid region ID rejected")
	var duplicate_world := CONTENT.duplicate() as WorldDefinition
	duplicate_world.regions = CONTENT.regions.duplicate()
	duplicate_world.regions.append(definition)
	check(not duplicate_world.valid(), "duplicate definitions rejected before boot")
	check(record.lifecycle == RegionState.Lifecycle.UNLOADED, "initial unloaded state")
	check(record.transition(RegionState.Lifecycle.LOADED) != OK, "invalid lifecycle transition rejected")
	var original_position := player.state.position
	check(directory.enter(definition.region_id, definition.default_entry, player.state) != OK and player.state.position == original_position, "cannot spawn into unloaded region")
	var coordinates := definition.duplicate() as RegionDefinition
	coordinates.origin = Vector3(100, 7, -200)
	var local := Vector3(-0.01, 4, 32)
	check(coordinates.to_local_position(coordinates.to_world_position(local)).is_equal_approx(local), "region-local coordinate round trip")
	check(coordinates.chunk_at(local) == Vector2i(-1, 1), "negative and exact-boundary chunk coordinates")
	check(coordinates.chunk_id(local) == "region.home_valley:-1:1", "region-scoped future chunk ID")
	check(coordinates.chunk_bounds(Vector2i(-1, 1)) == Rect2(-32, 32, 32, 32), "half-open chunk bounds")
	var scene := WORLD_SCENE.instantiate() as WorldScene
	scene.directory = directory
	scene.player = player.state
	root.add_child(scene)
	check(scene.open_region(definition.region_id, "entry.missing") != OK and scene.active_region == null, "invalid entry leaves region unloaded")
	check(scene.open_current() == OK, "production Region scene loads and spawns")
	check(record.lifecycle == RegionState.Lifecycle.LOADED and directory.location.region_id == definition.region_id, "loaded lifecycle and location")
	check(player.state.position == definition.entries[definition.default_entry], "entry applies authoritative placement")
	check(scene.active_region.avatar.get_parent() == scene.active_region.get_node("Actors"), "Region owns physical Player attachment")
	check(scene.open_current() == ERR_ALREADY_IN_USE, "duplicate active attachment rejected")
	var stable_player_id := player.state.entity_id
	for i in 60:
		await physics_frame
	check(player.state.grounded and absf(player.state.position.y) < 0.05, "production terrain collision")
	var avatar := scene.active_region.avatar
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	for i in 300:
		await physics_frame
	key.pressed = false
	Input.parse_input_event(key)
	for i in 25:
		await physics_frame
	check(player.state.position.z < -16 and player.state.position.y > 2.9 and player.state.grounded, "keyboard traverses real ramp onto raised ridge")
	avatar.intent.camera_delta = 0.9
	for i in 30:
		await physics_frame
	check(avatar.orbit.yaw > 0.8 and avatar.orbit.camera.global_position.is_finite(), "camera healthy in production region")
	var diagnostic := scene.development_state()
	check(diagnostic.world_id == CONTENT.world_id and diagnostic.current_region_id == definition.region_id and diagnostic.player_entity_id == stable_player_id and diagnostic.region_lifecycle == "LOADED", "structured World/Region/Player diagnostics")
	var snapshot := core.saves.capture(registry, world.state.world_id, world.state.world_seed)
	var encoded: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	check(world.validate_state(encoded.sections[world.id].state) == OK and regions.validate_state(encoded.sections[regions.id].state) == OK, "versioned JSON state validation")
	var bad := world.capture_state()
	bad.current_region_id = "region.missing"
	check(world.validate_state(bad) != OK, "unknown persisted region rejected")
	bad = regions.capture_state()
	bad.regions[definition.region_id].world_id = "world.other"
	check(regions.validate_state(bad) != OK, "wrong world membership rejected")
	bad = regions.capture_state()
	bad.regions[definition.region_id].schema_version = 99
	check(regions.validate_state(bad) != OK, "unknown region schema rejected")
	bad = regions.capture_state()
	bad.regions[definition.region_id].last_entry_id = "entry.unknown"
	check(regions.validate_state(bad) != OK, "invalid persisted entry rejected")
	var saved_position := player.state.position
	scene.close_region()
	check(record.lifecycle == RegionState.Lifecycle.UNLOADED and directory.location.region_id.is_empty() and scene.active_region == null, "unload releases residency and player attachment")
	check(record.last_entry_id == definition.default_entry, "unload retains canonical region state")
	player.state.position = Vector3(100, 50, 100)
	world.state.world_seed = 123
	record.last_entry_id = ""
	check(core.saves.restore(registry, encoded) == OK, "module snapshot restore")
	check(world.state.world_id == CONTENT.world_id and world.state.world_seed == CONTENT.world_seed and record.last_entry_id == definition.default_entry and player.state.position == saved_position, "stable identities and region state survive restore")
	check(scene.open_current(true) == OK and player.state.position == saved_position and player.state.entity_id == stable_player_id, "resume reattaches without applying entry defaults")
	for i in 3:
		scene.close_region()
		check(scene.open_current(true) == OK, "repeated region load/unload")
	scene.close_region()
	scene.free()
	registry.shutdown()
	check(player.capabilities.capability("foundation.location") == null, "module disposal releases capability")
	for i in 2:
		var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
		runtime.save_slot = LocalSaveSlot.new("test.world", "user://world-suite-no-save-%s.json" % CoreIds.generate())
		root.add_child(runtime)
		check(runtime.registry.state == CoreModuleRegistry.State.RUNNING and runtime.registry.order.size() == 8, "production runtime initializes eight expected modules")
		check(runtime.world_scene.active_region.record.lifecycle == RegionState.Lifecycle.LOADED, "production runtime opens real Region")
		for frame in 10:
			await physics_frame
		check(runtime.world.state.clock == runtime.core.clock and runtime.world.state.clock.tick > 0, "runtime advances only shared Core clock")
		runtime.free()
	var cycle := CoreModuleRegistry.new()
	var circular_world := WorldModule.new(CONTENT)
	circular_world.requires.append("foundation.regions")
	cycle.add(CoreRuntimeServicesModule.new())
	cycle.add(PlayerModule.new())
	cycle.add(circular_world)
	cycle.add(RegionModule.new())
	check(cycle.validate() != OK, "circular World/Region dependencies rejected")
	cycle.shutdown()
	print("World tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
