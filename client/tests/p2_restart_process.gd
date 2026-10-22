extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var mode := ""
	var slot := ""
	for argument in OS.get_cmdline_user_args():
		if argument in ["save", "resume"]: mode = argument
		if argument.begins_with("--p2-slot="): slot = argument.trim_prefix("--p2-slot=")
	if mode.is_empty() or slot.is_empty():
		push_error("Use save|resume --p2-slot=/absolute/isolated-slot.json")
		quit(1)
		return
	if mode == "save" and (FileAccess.file_exists(slot) or FileAccess.file_exists(slot + ".expected.json")):
		push_error("Save phase requires a fresh isolated slot")
		quit(1)
		return
	Engine.time_scale = 2.0
	var world := preload("res://tests/p2_acceptance.tscn").instantiate()
	world.slot_path = slot
	root.add_child(world)
	var deadline := Time.get_ticks_msec() + 120000
	while world.scenario_result.is_empty() and (world.scenario == null or world.scenario.result.is_empty()) and Time.get_ticks_msec() < deadline:
		await physics_frame
	var result: Dictionary = world.scenario_result if not world.scenario_result.is_empty() else world.scenario.result if world.scenario != null else {}
	var passed: bool = result.get("passed", false) and result.get("checkpoint_saved" if mode == "save" else "resumed", false)
	if not passed:
		push_error("P2 restart %s failed: %s" % [mode, str(result)])
	world.free()
	Engine.time_scale = 1.0
	await process_frame
	print("P2 restart %s tests: 1 checks, %d failures" % [mode, 0 if passed else 1])
	quit(0 if passed else 1)
