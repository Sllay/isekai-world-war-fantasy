extends "res://runtime/game_runtime.gd"

@export var slot_path := "user://tests/p3-runtime-delivery.json"
var scenario: Node
var scenario_result: Dictionary = {}

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--p3-slot="): slot_path = argument.trim_prefix("--p3-slot=")
	save_slot = LocalSaveSlot.new("test.p3_runtime", slot_path)
	super._ready()
	if persistence != null: persistence.suppress_autosave = true
	if startup_error != OK or authority_host == null:
		scenario_result = {"passed": false, "reason": "STARTUP_FAILED", "error": startup_error}
		freeze_scenario()
		return
	var avatar := world_scene.active_region.avatar
	avatar.input.set_physics_process(false)
	avatar.input.set_process_input(false)
	if FileAccess.file_exists(slot_path + ".expected.json"):
		freeze_scenario()
		_validate_checkpoint()
		return
	if persistence.startup_mode != "new_game":
		scenario_result = {"passed": false, "reason": "EXPECTED_CHECKPOINT_MISSING"}
		freeze_scenario()
		return
	scenario = preload("res://tests/p3_scenario_driver.gd").new()
	scenario.runtime = self
	add_child(scenario)

func freeze_scenario() -> void:
	set_process(false)
	if world_scene == null or world_scene.active_region == null: return
	var avatar := world_scene.active_region.avatar
	avatar.intent.clear_transient()
	avatar.motor.set_physics_process(false)
	if is_instance_valid(enemy_body): enemy_body.set_physics_process(false)
	for body in companion_bodies: body.set_physics_process(false)
	if is_instance_valid(living_runtime):
		for body in living_runtime.bodies.values(): body.set_physics_process(false)

func checkpoint_scenario(proofs: Dictionary) -> Dictionary:
	freeze_scenario()
	var error := save_game()
	if error != OK:
		scenario_result = {"passed": false, "reason": "SAVE_FAILED", "error": error}
		return scenario_result
	var before: Dictionary = core.saves.pages.metrics.duplicate()
	var second := save_game()
	proofs["unchanged_record_writes"] = core.saves.pages.metrics.pages_written - before.pages_written
	proofs["unchanged_records_reused"] = core.saves.pages.metrics.pages_reused - before.pages_reused
	var snapshot := persistence.capture_snapshot()
	var file := FileAccess.open(slot_path + ".expected.json", FileAccess.WRITE)
	if file == null:
		scenario_result = {"passed": false, "reason": "EXPECTED_WRITE_FAILED"}
		return scenario_result
	file.store_string(JSON.stringify({"version": 1, "snapshot": snapshot, "proofs": proofs}))
	file.close()
	scenario_result = {"passed": second == OK and proofs.unchanged_record_writes == 0, "checkpoint_saved": true, "resumed": false, "proofs": proofs, "slot_path": slot_path}
	return scenario_result

func _validate_checkpoint() -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot_path + ".expected.json"))
	if not expected is Dictionary or expected.get("version") != 1 or not expected.get("snapshot") is Dictionary:
		scenario_result = {"passed": false, "reason": "EXPECTED_INVALID"}
		return
	var actual: Dictionary = JSON.parse_string(JSON.stringify(persistence.capture_snapshot()))
	var sections := {}
	for id in actual.sections: sections[id] = actual.sections[id] == expected.snapshot.sections.get(id)
	var before: int = genesis.ledger.generator.generation_invocation_count
	var restored := genesis.ledger.request(Vector2i.ZERO, core.clock.tick)
	var matches: bool = actual == expected.snapshot
	scenario_result = {"passed": matches and persistence.startup_mode == "resume" and before == 0 and genesis.ledger.generator.generation_invocation_count == 0 and restored.ok, "checkpoint_saved": false, "resumed": true, "exact_snapshot": matches, "sections": sections, "generator_before": before, "generator_after": genesis.ledger.generator.generation_invocation_count, "proofs": expected.proofs, "slot_path": slot_path}
	if not matches: scenario_result.reason = "FRESH_PROCESS_STATE_MISMATCH"

func _mcp_state() -> Dictionary:
	return {"result": scenario_result, "scenario": scenario._mcp_state() if scenario != null else {}, "development": development_state()}
