extends SceneTree

const RUNTIME = preload("res://scenes/runtime/game_runtime.tscn")
var checks := 0
var failures := 0
var directory: String
var path: String

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	directory = OS.get_cmdline_user_args()[0]
	path = directory.path_join("unit-slot.json")
	call_deferred("run")

func start_runtime(slot_path: String = "") -> Node:
	var runtime := RUNTIME.instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.persistence", path if slot_path.is_empty() else slot_path)
	root.add_child(runtime)
	return runtime

func write_json(value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func run() -> void:
	var runtime := start_runtime()
	check(runtime.startup_error == OK and runtime.persistence.startup_mode == "new_game", "no slot starts new game")
	check(runtime.persistence.last_resume_code == "NO_SAVE" and not FileAccess.file_exists(path), "NO_SAVE distinct; startup does not write implicitly")
	check(runtime.world_scene.active_region != null, "new game owns real Region residency")
	var original_id: String = runtime.player.state.entity_id
	runtime.player.state.position = Vector3(2, 3.01, -24)
	runtime.player.state.velocity = Vector3(0.2, 0, 0.1)
	runtime.core.clock.advance(2)
	check(runtime.save_game() == OK and FileAccess.file_exists(path), "save active runtime to actual disk")
	check(runtime.world_scene.active_region != null, "save leaves Region active")
	var good: Dictionary = runtime.core.saves.read_snapshot(path)
	var position: Vector3 = runtime.player.state.position
	var tick: int = runtime.core.clock.tick
	var original_json := JSON.stringify(good)
	check(not runtime.persistence.integrity.prepare(good).is_empty() and JSON.stringify(good) == original_json, "complete snapshot validates without mutation")
	check(good.sections.size() == 6 and good.format_version == 1, "six versioned module sections including items/resources")
	check(not JSON.stringify(good).contains("Camera") and not good.sections["foundation.regions"].state.regions["region.home_valley"].has("lifecycle"), "snapshot excludes residency and visual state")
	runtime.free()
	runtime = start_runtime()
	check(runtime.startup_error == OK and runtime.persistence.startup_mode == "resume", "fresh runtime reads disk on startup")
	check(runtime.player.state.entity_id == original_id and runtime.player.state.position == position, "identity and non-entry position restored")
	check(runtime.core.clock.tick == tick and runtime.world.state.clock == runtime.core.clock, "exact shared clock restore before advancing")
	check(runtime.world_scene.active_region != null and runtime.regions.directory.location.region_id == "region.home_valley", "restored region attaches existing player")
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "repeated active save/resume")
	good = runtime.core.saves.read_snapshot(path)
	var before: Dictionary = runtime.core.saves.capture(runtime.registry, runtime.world.state.world_id, runtime.world.state.world_seed)
	var resident: RegionScene = runtime.world_scene.active_region
	var cases: Array[Dictionary] = []
	var bad := good.duplicate(true)
	bad.format_version = 999
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections.erase("foundation.player")
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.player"].state.entity_id = CoreIds.generate()
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.player"].state.entity_id = "broken-id"
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.world"].state.current_region_id = "region.unknown"
	cases.append(bad)
	bad = good.duplicate(true)
	bad.world_id = "world.other"
	cases.append(bad)
	bad = good.duplicate(true)
	bad.world_seed += 1
	cases.append(bad)
	bad = good.duplicate(true)
	bad.world_seed += 1
	bad.sections["foundation.world"].state.world_seed += 1
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.world"].version = 999
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.regions"].state.regions["region.home_valley"].world_id = "world.other"
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["core.runtime"].state.entities.ids.append(original_id)
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.regions"].state.regions["region.home_valley"].region_id = "region.other"
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.regions"].state.regions["region.home_valley"].schema_version = 999
	cases.append(bad)
	bad = good.duplicate(true)
	bad.game_version = "999.0.0"
	cases.append(bad)
	bad = good.duplicate(true)
	bad.modules["foundation.player"] = "999.0.0"
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.player"].version = -1
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["foundation.player"].state.position[0] = 1e300
	cases.append(bad)
	bad = good.duplicate(true)
	bad.sections["core.runtime"].state.clock.tick = 1e18
	cases.append(bad)
	for index in cases.size():
		write_json(cases[index])
		var bytes := FileAccess.get_file_as_string(path)
		check(runtime.resume_game() != OK and runtime.persistence.last_resume_code == "SAVE_INVALID", "invalid save case %d rejected" % index)
		check(runtime.core.saves.capture(runtime.registry, runtime.world.state.world_id, runtime.world.state.world_seed) == before and runtime.world_scene.active_region == resident, "invalid save case %d causes no canonical or residency mutation" % index)
		check(runtime.save_game() != OK and FileAccess.get_file_as_string(path) == bytes, "invalid slot case %d protected against overwrite" % index)
	write_json(good)
	check(runtime.resume_game() == OK and not runtime.persistence.writes_blocked, "valid repaired slot unblocks persistence")
	for broken in ["{garbage}", JSON.stringify(good).left(70), "[]", ""]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(broken)
		file.close()
		check(runtime.resume_game() != OK and runtime.world_scene.active_region != null, "malformed/truncated save preserves live residency")
		var fresh := start_runtime()
		check(fresh.startup_error != OK and fresh.persistence.startup_mode == "resume" and fresh.world_scene.active_region == null, "corrupt startup blocks instead of creating new game")
		check(fresh.save_game() != OK and FileAccess.get_file_as_string(path) == broken, "blocked startup cannot overwrite corrupted bytes")
		fresh.free()
	write_json(good)
	check(runtime.resume_game() == OK, "recover after corruption tests")
	# Retry a blocked startup through the same runtime API after repairing its slot.
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("{")
	corrupt.close()
	var blocked := start_runtime()
	write_json(good)
	check(blocked.resume_game() == OK and blocked.is_processing() and blocked.startup_error == OK, "repaired startup resumes clock processing")
	blocked.free()
	# A directory at the temporary sibling causes a deterministic write-open error.
	DirAccess.make_dir_absolute(path + ".tmp")
	var previous_bytes := FileAccess.get_file_as_string(path)
	check(runtime.save_game() != OK and runtime.persistence.last_save_code == "SAVE_WRITE_FAILED", "partial write cannot report success")
	check(FileAccess.get_file_as_string(path) == previous_bytes and runtime.world_scene.active_region != null, "failed write retains old slot and live game")
	DirAccess.remove_absolute(path + ".tmp")
	check(runtime.save_game() == OK, "save recovers after write failure")
	DirAccess.remove_absolute(path)
	before = runtime.core.saves.capture(runtime.registry, runtime.world.state.world_id, runtime.world.state.world_seed)
	check(runtime.resume_game() == ERR_FILE_NOT_FOUND and runtime.persistence.last_resume_code == "NO_SAVE", "missing slot during active play is NO_SAVE")
	check(runtime.core.saves.capture(runtime.registry, runtime.world.state.world_id, runtime.world.state.world_seed) == before, "missing slot does not mutate live state")
	check(runtime.save_game() == OK, "explicit save can recreate absent slot")
	var diagnostics: Dictionary = runtime.development_state()
	check(diagnostics.slot_id == "test.persistence" and diagnostics.slot_path == path and diagnostics.save_code == "SAVE_OK", "structured persistence diagnostics")
	runtime.free()
	DirAccess.remove_absolute(path)
	check(not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".tmp"), "test file cleanup")
	print("Save/resume tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
