extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	check("--authority-remote" in OS.get_cmdline_user_args(), "explicit remote mode, no implicit fallback")
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	var path := "user://tests/c1-remote-%s.json" % CoreIds.generate()
	runtime.save_slot = LocalSaveSlot.new("test.remote", path)
	root.add_child(runtime)
	runtime.persistence.suppress_autosave = true
	check(runtime.startup_error == OK and runtime.authority_host == null, "runtime does not construct local host in remote mode")
	check(runtime.authority_gateway.snapshot().is_empty(), "missing transport has no authoritative snapshot")
	check(not runtime.authority_gateway.request("action", {"slot": "skill_1", "target": runtime.enemies.actor.entity_id}).accepted, "disconnected runtime rejects gameplay request")
	var region: RegionScene = runtime.world_scene.active_region
	var avatar := region.avatar
	check(not avatar.motor.is_physics_processing() and not region.is_physics_processing(), "disconnected runtime disables motor and autonomous recovery")
	avatar.input.set_physics_process(false)
	avatar.intent.movement = Vector2.ONE.normalized()
	avatar.intent.primary_action = true
	avatar.intent.request_skill(1)
	avatar.intent.guard = true
	avatar.intent.jump = true
	var combat_before: Dictionary = runtime.player_combat.state.capture()
	var enemy_before: Vector3 = runtime.enemies.actor.position
	# Even an invalid local mirror cannot authorize a canonical recovery/teleport.
	runtime.player.state.position = Vector3(0, -100, 0)
	var recoveries := region.record.recovery.recovery_count
	for i in range(20):
		runtime._process(0.05)
		await physics_frame
	check(runtime.player.state.position == Vector3(0, -100, 0) and region.record.recovery.recovery_count == recoveries, "missing server never activates local transform recovery")
	check(runtime.player_combat.state.capture() == combat_before and runtime.player_combat.actions.phase == ActionExecutor.Phase.IDLE, "raw input cannot authoritatively spend, damage or defend while disconnected")
	check(runtime.enemies.actor.position == enemy_before and runtime.authority_host == null, "simulation remains frozen without promoting client authority")
	check(runtime.save_game() == ERR_UNCONFIGURED and not FileAccess.file_exists(path), "untrusted client state cannot be saved as canonical gameplay")
	runtime.free()
	await process_frame
	print("Remote authority tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
