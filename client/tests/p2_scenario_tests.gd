extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func run() -> void:
	Engine.time_scale = 2.0
	var slot := "user://tests/p2-headless-%s.json" % CoreIds.generate()
	var world := preload("res://tests/p2_acceptance.tscn").instantiate()
	world.slot_path = slot
	root.add_child(world)
	var deadline := Time.get_ticks_msec() + 120000
	while world.scenario_result.is_empty() and (world.scenario == null or world.scenario.result.is_empty()) and Time.get_ticks_msec() < deadline:
		await physics_frame
	var result: Dictionary = world.scenario_result if not world.scenario_result.is_empty() else world.scenario.result
	check(result.get("passed", false), "semantic P2 runtime scenario: %s" % str(result))
	var proofs: Dictionary = result.get("proofs", {})
	check(proofs.get("enemy_defeated", false) and proofs.get("death_stock_conserved", false) and proofs.get("drop_claimed", false) and proofs.get("npc_carried_empty", false), "real actor stock transfers through defeat/drop/pickup")
	check(proofs.get("tree_depleted", false) and proofs.get("wood_gathered", 0) == 6, "equipped tools gather and deplete authored resources")
	check(proofs.get("material_preserved", false) and proofs.get("crafted_weapon_equipped", false), "atomic processing/material recipe equips persistent result")
	check(proofs.get("received_damage", false) and proofs.get("healing_applied", false), "consumable heals real received combat damage")
	check(result.get("checkpoint_saved", false), "authority saves integrated checkpoint")
	world.free()
	await process_frame
	var resumed := preload("res://tests/p2_acceptance.tscn").instantiate()
	resumed.slot_path = slot
	root.add_child(resumed)
	check(resumed.scenario_result.get("passed", false) and resumed.scenario_result.get("resumed", false), "new runtime instance resumes exact checkpoint: %s" % str(resumed.scenario_result))
	check(resumed.scenario_result.get("exact_snapshot", false), "all canonical save sections match before any startup physics")
	resumed.free()
	for path in [slot, slot + ".expected.json"]:
		DirAccess.remove_absolute(path)
	Engine.time_scale = 1.0
	await process_frame
	print("P2 scenario tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
