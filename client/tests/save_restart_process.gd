extends SceneTree

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
	var args := OS.get_cmdline_user_args()
	var phase := args[0]
	var slot_path := args[1].path_join("restart-slot.json")
	var proof_path := args[1].path_join("restart-proof.json")
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.restart", slot_path)
	root.add_child(runtime)
	check(runtime.startup_error == OK, "production runtime boots")
	if phase == "exit":
		DirAccess.make_dir_absolute(slot_path + ".tmp")
		check(runtime.request_exit() != OK and runtime.world_scene.active_region != null, "normal exit refuses to discard progress after failed save")
		DirAccess.remove_absolute(slot_path + ".tmp")
		runtime.notification(NOTIFICATION_APPLICATION_PAUSED)
		check(runtime.persistence.last_save_code == "SAVE_OK", "application pause calls production save API")
		check(runtime.request_exit() == OK and runtime.persistence.last_save_code == "SAVE_OK", "normal exit saves before requesting shutdown")
	elif phase == "save":
		check(runtime.persistence.startup_mode == "new_game", "first process starts new game")
		for i in 60:
			await physics_frame
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
		check(runtime.player.state.position.z < -16 and runtime.player.state.position.y > 2.9, "real play reaches raised ridge before saving")
		check(runtime.save_game() == OK, "first process writes actual slot")
		var snapshot: Dictionary = runtime.core.saves.read_snapshot(slot_path)
		var file := FileAccess.open(proof_path, FileAccess.WRITE)
		file.store_string(FileAccess.get_file_as_string(slot_path))
		file.close()
		check(snapshot.sections["core.runtime"].state.clock.tick > 0, "time advanced before save")
	else:
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(proof_path))
		check(runtime.persistence.startup_mode == "resume", "separate process selects resume")
		var captured: Dictionary = runtime.persistence.capture_snapshot()
		# JSON has one numeric type; normalize integer/float representations on
		# both sides before comparing every canonical field.
		check(JSON.parse_string(JSON.stringify(captured, "", true, true)) == expected, "fresh process restores exact canonical snapshot before any frames")
		var expected_player: Dictionary = expected.sections["foundation.player"].state
		check(runtime.player.state.entity_id == expected_player.entity_id, "stable Player ID across OS processes")
		check(runtime.player.state.position == Vector3(expected_player.position[0], expected_player.position[1], expected_player.position[2]), "position restored on ridge rather than entry")
		check(runtime.world.state.current_region_id == expected.sections["foundation.world"].state.current_region_id and runtime.world.state.world_id == expected.world_id and runtime.world.state.world_seed == expected.world_seed, "World and Region restored")
		check(runtime.core.clock.tick == expected.sections["core.runtime"].state.clock.tick, "Core clock restored exactly")
		for i in 10:
			await physics_frame
		var start: Vector3 = runtime.player.state.position
		var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
		var adapter := avatar.get_child(0) as PlayerInput
		adapter.set_physics_process(false)
		avatar.intent.movement = Vector2.RIGHT
		avatar.intent.camera_delta = 0.8
		avatar.intent.jump = true
		runtime._process(0.05) # Forward semantic input before host-owned physics.
		for i in 10:
			await physics_frame
		check(not runtime.player.state.grounded and runtime.player.state.position.y > start.y + 0.3, "jump works after process resume")
		check(runtime.player.state.position.distance_to(start) > 0.4 and avatar.orbit.yaw > 0.5, "movement and camera work after process resume")
		avatar.intent.movement = Vector2.ZERO
		runtime._process(0.05)
		for i in 100:
			await physics_frame
		check(runtime.player.state.grounded and runtime.core.clock.tick > expected.sections["core.runtime"].state.clock.tick, "landing and shared time continue after resume")
		check(runtime.save_game() == OK, "second process can save again")
	runtime.free()
	print("Restart %s tests: %d checks, %d failures" % [phase, checks, failures])
	quit(0 if failures == 0 else 1)
