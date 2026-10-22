extends "res://runtime/game_runtime.gd"

# Runtime MCP intentionally reopens this exact slot in a new game process.
@export var slot_path := "user://tests/p2-runtime-foundation.json"
var scenario: Node
var scenario_result: Dictionary = {}
var _tick_samples_us: Array[float] = []

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--p2-slot="):
			slot_path = argument.trim_prefix("--p2-slot=")
	save_slot = LocalSaveSlot.new("test.p2", slot_path)
	super._ready()
	if persistence != null:
		persistence.suppress_autosave = true
	if startup_error != OK or authority_host == null:
		scenario_result = {"passed": false, "reason": "RUNTIME_STARTUP_FAILED", "startup_error": startup_error}
		freeze_scenario()
		return
	var avatar := world_scene.active_region.avatar
	avatar.input.set_physics_process(false)
	avatar.input.set_process_input(false)
	if FileAccess.file_exists(slot_path + ".expected.json"):
		# Freeze inside _ready, before any physics/gameplay tick can run.
		freeze_scenario()
		_validate_checkpoint()
		return
	if persistence.startup_mode != "new_game":
		scenario_result = {"passed": false, "reason": "EXPECTED_CHECKPOINT_MISSING"}
		freeze_scenario()
		return
	scenario = preload("res://tests/p2_scenario_driver.gd").new()
	scenario.runtime = self
	add_child(scenario)

func _process(delta: float) -> void:
	var previous := core.clock.tick
	var started := Time.get_ticks_usec()
	super._process(delta)
	var steps := core.clock.tick - previous
	if steps > 0 and _tick_samples_us.size() < 2400:
		_tick_samples_us.append(float(Time.get_ticks_usec() - started) / steps)

func freeze_scenario() -> void:
	set_process(false)
	if world_scene != null and world_scene.active_region != null:
		var avatar := world_scene.active_region.avatar
		avatar.intent.clear_transient()
		avatar.motor.set_physics_process(false)

func checkpoint_scenario(proofs: Dictionary) -> Dictionary:
	freeze_scenario()
	var error := save_game()
	if error != OK:
		scenario_result = {"passed": false, "reason": "CHECKPOINT_SAVE_FAILED", "error": error}
		return scenario_result
	var expected := {"version": 1, "snapshot": persistence.capture_snapshot(), "proofs": proofs.duplicate(true)}
	var file := FileAccess.open(slot_path + ".expected.json", FileAccess.WRITE)
	if file == null:
		scenario_result = {"passed": false, "reason": "EXPECTED_CHECKPOINT_WRITE_FAILED", "error": FileAccess.get_open_error()}
		return scenario_result
	file.store_string(JSON.stringify(expected))
	file.close()
	persistence.suppress_autosave = true
	scenario_result = {"passed": true, "checkpoint_saved": true, "resumed": false, "proofs": proofs.duplicate(true), "timing": timing_summary(), "slot_path": slot_path}
	return scenario_result

func _validate_checkpoint() -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path + ".expected.json"))
	if not expected is Dictionary or expected.get("version") != 1 or not expected.get("snapshot") is Dictionary:
		scenario_result = {"passed": false, "reason": "EXPECTED_CHECKPOINT_INVALID"}
		return
	var actual: Dictionary = JSON.parse_string(JSON.stringify(persistence.capture_snapshot()))
	var matches: bool = actual == expected.snapshot
	var sections: Dictionary = {}
	for id in actual.sections:
		sections[id] = actual.sections[id] == expected.snapshot.sections.get(id)
	scenario_result = {"passed": matches and persistence.startup_mode == "resume", "checkpoint_saved": false, "resumed": true, "exact_snapshot": matches, "sections": sections, "proofs": expected.get("proofs", {}), "slot_path": slot_path}
	if not matches:
		scenario_result["reason"] = "FRESH_PROCESS_STATE_MISMATCH"

func timing_summary() -> Dictionary:
	var samples := _tick_samples_us.duplicate()
	samples.sort()
	return {"application_tick_samples": samples.size(), "application_tick_p95_us": samples[mini(samples.size() - 1, int(samples.size() * 0.95))] if not samples.is_empty() else 0.0, "application_tick_max_us": samples.back() if not samples.is_empty() else 0.0}

func _mcp_state() -> Dictionary:
	return {"result": scenario_result, "scenario": scenario._mcp_state() if scenario != null else {}, "timing": timing_summary(), "development": development_state()}
