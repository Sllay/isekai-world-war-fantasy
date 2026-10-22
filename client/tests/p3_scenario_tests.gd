extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	Engine.time_scale = 3.0
	var slot := "user://tests/p3-semantic-%s.json" % CoreIds.generate()
	var world := preload("res://tests/p3_acceptance.tscn").instantiate()
	world.slot_path = slot
	root.add_child(world)
	var deadline := Time.get_ticks_msec() + 140000
	while world.scenario_result.is_empty() and (world.scenario == null or world.scenario.result.is_empty()) and Time.get_ticks_msec() < deadline:
		await physics_frame
	var result: Dictionary = world.scenario_result if not world.scenario_result.is_empty() else world.scenario.result if world.scenario != null else {}
	var passed: bool = result.get("passed", false)
	print("P3 semantic scenario evidence: ", JSON.stringify(result))
	world.free()
	await process_frame
	if passed:
		world = preload("res://tests/p3_acceptance.tscn").instantiate()
		world.slot_path = slot
		root.add_child(world)
		passed = world.scenario_result.get("passed", false)
		print("P3 semantic resume evidence: ", JSON.stringify(world.scenario_result))
		world.free()
	Engine.time_scale = 1.0
	for path in [slot, slot + ".expected.json"]: DirAccess.remove_absolute(path)
	var directory := slot + ".pages"
	for filename in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(filename))
	DirAccess.remove_absolute(directory)
	await process_frame
	print("P3 semantic scenario tests: 1 checks, %d failures" % (0 if passed else 1))
	quit(0 if passed else 1)
