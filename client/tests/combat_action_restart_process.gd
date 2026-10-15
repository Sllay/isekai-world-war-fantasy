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
	var path := args[1].path_join("action-restart.json")
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.action_restart", path)
	root.add_child(runtime)
	runtime.set_process(false)
	check(runtime.startup_error == OK, "action restart runtime boots")
	var executor: ActionExecutor = runtime.player_combat.actions
	if args[0] == "save":
		var hit := DamageRequest.new(executor.owner_id, executor.owner_id, 30)
		hit.allow_self = true
		runtime.combat.service.damage(hit)
		check(executor.activate("combat.action.basic_heal") == "STARTED", "real heal starts before process checkpoint")
		for index in range(10): runtime._process(0.05)
		check(runtime.player_combat.state.health == 85 and runtime.player_combat.state.resource == 45, "checkpoint after real commit")
		check(runtime.save_game() == OK, "disk checkpoint during recovery")
	else:
		check(runtime.persistence.startup_mode == "resume", "fresh process resume selected")
		check(executor.phase == ActionExecutor.Phase.IDLE and executor.current == null, "fresh process never resumes half action")
		check(runtime.player_combat.state.health == 85 and runtime.player_combat.state.resource == 45, "fresh process preserves canonical effects and costs")
		check(executor.remaining_cooldown("combat.action.basic_heal") == 60, "fresh process preserves exact remaining cooldown")
		check(executor.activate("combat.action.basic_heal") == "COOLDOWN", "fresh process prevents reload exploit")
		for index in range(60): runtime._process(0.05)
		check(executor.activate("combat.action.basic_heal") == "STARTED", "fresh process restored clock expires cooldown")
		check(runtime.save_game() == OK, "save uncommitted cast")
		check(runtime.resume_game() == OK and executor.phase == ActionExecutor.Phase.IDLE, "half cast discarded on next restore")
		check(runtime.player_combat.state.resource == 45 and executor.remaining_cooldown("combat.action.basic_heal") == 0, "discarded half cast spends no resource/cooldown")
	runtime.free()
	print("Combat Action restart %s tests: %d checks, %d failures" % [args[0], checks, failures])
	quit(0 if failures == 0 else 1)
