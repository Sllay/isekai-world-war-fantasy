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
	var args := OS.get_cmdline_user_args()
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.defense_restart", args[1].path_join("defense-restart.json"))
	root.add_child(runtime)
	runtime.set_process(false)
	var player: Combatant = runtime.player_combat.state
	var action: ActionExecutor = runtime.player_combat.actions
	var state: PlayerState = runtime.player.state
	var proof := args[1].path_join("defense-proof.json")
	check(runtime.startup_error == OK, "independent process boot")
	if args[0] == "save":
		check(action.activate("combat.action.basic_dodge") == "STARTED", "save during active dodge")
		runtime.combat.service.begin_defense(player.entity_id, "GUARD", 0)
		runtime.combat.service.begin_defense(player.entity_id, "PARRY", 4)
		state.position = Vector3(2, 0.1, -24)
		check(runtime.world_scene.active_region.test_underfloor(), "process injects below raised terrain")
		check(runtime.save_game() == OK, "disk save during defense and underfloor")
		var file := FileAccess.open(proof, FileAccess.WRITE)
		file.store_string(JSON.stringify({"id": state.entity_id, "resource": player.resource, "health": player.health}))
		file.close()
	else:
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(proof))
		check(runtime.persistence.startup_mode == "resume" and state.entity_id == expected.id, "same Player in fresh OS process")
		check(player.resource == expected.resource and player.health == expected.health, "committed health and resource persist")
		check(not player.defense.guard and player.defense.dodge_until == 0 and player.defense.parry_until == 0, "all active defense windows reset on restart")
		check(action.phase == ActionExecutor.Phase.IDLE and action.remaining_cooldown("combat.action.basic_dodge") == 24, "transient phase resets and cooldown persists without offline expiry")
		check(state.position.is_equal_approx(Vector3(2, 3.12, -24)) and state.velocity == Vector3.ZERO, "fresh process resumes above local terrain instead of underfloor")
		check(runtime.combat.action_runtime.last_result == "NONE", "interrupt diagnostics are transient")
		var snapshot: Dictionary = runtime.persistence.capture_snapshot()
		check(not JSON.stringify(snapshot).contains("dodge_until") and not JSON.stringify(snapshot).contains("Callable") and not JSON.stringify(snapshot).contains("NodePath"), "canonical save contains no transient defense or scene ports")
	runtime.free()
	print("Defense restart %s tests: %d checks, %d failures" % [args[0], checks, failures])
	quit(0 if failures == 0 else 1)
