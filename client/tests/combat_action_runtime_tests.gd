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
	var path := OS.get_cmdline_user_args()[0].path_join("action-runtime.json")
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.actions", path)
	root.add_child(runtime)
	runtime.set_process(false)
	check(runtime.startup_error == OK and runtime.action_harness != null, "runtime boots with bounded acceptance target")
	var executor: ActionExecutor = runtime.player_combat.actions
	check(runtime.player.capabilities.capability("foundation.actions") == executor, "Player action capability exposed")
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	var input := avatar.get_child(0) as PlayerInput
	input.set_physics_process(false)
	# Hardware adapters converge on semantic slots; no raw events in executor.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_F
	key.pressed = true
	input._input(key)
	check(avatar.intent.primary_action, "keyboard primary becomes semantic intent")
	runtime._process(0.05)
	check(executor.phase == ActionExecutor.Phase.CASTING, "semantic input starts runtime action")
	var strike_position: Vector3 = runtime.player.state.position
	avatar.intent.movement = Vector2.RIGHT
	avatar.intent.camera_delta = 0.4
	runtime._process(0.05) # Client intent must cross an authority tick before physics.
	for index in range(5): await physics_frame
	check(runtime.player.state.position.x > strike_position.x and avatar.orbit.yaw > 0, "strike permits physical movement and simultaneous camera input")
	avatar.intent.movement = Vector2.ZERO
	for index in range(3): runtime._process(0.05)
	check(runtime.action_harness.target.health == 88 and executor.effect_results.size() == 1, "runtime target takes one actual damage effect")
	for index in range(6): runtime._process(0.05)
	check(executor.phase == ActionExecutor.Phase.IDLE and runtime.action_harness.target.health == 88, "runtime recovery completes without duplicate damage")
	var hit := DamageRequest.new(runtime.player.state.entity_id, runtime.player.state.entity_id, 30)
	hit.allow_self = true
	runtime.combat.service.damage(hit)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_LEFT_SHOULDER
	pad.pressed = true
	input._input(pad)
	runtime._process(0.05)
	check(executor.current.action_id == "combat.action.basic_heal", "controller secondary uses same action pipeline")
	var start: Vector3 = runtime.player.state.position
	var facing: Vector3 = runtime.player.state.facing
	avatar.intent.movement = Vector2.RIGHT
	avatar.intent.camera_delta = 0.7
	runtime._process(0.05)
	for index in range(5):
		await physics_frame
	check(Vector2(runtime.player.state.position.x - start.x, runtime.player.state.position.z - start.z).length() < 0.001, "movement gate physically stops heal cast")
	check(runtime.player.state.facing == facing and absf(avatar.orbit.yaw) > 0.1, "turn gate preserves facing while camera works")
	avatar.intent.movement = Vector2.ZERO
	for index in range(9): runtime._process(0.05)
	check(runtime.player_combat.state.health == 85 and runtime.player_combat.state.resource == 45, "runtime heal uses canonical health/resource")
	var info: Dictionary = runtime.development_state().actions
	check(info.cooldowns["combat.action.basic_heal"] == 60 and info.last_result == "COMMITTED", "structured action resource/cooldown diagnostics")
	check(runtime.save_game() == OK, "save active recovery through production coordinator")
	var saved: Dictionary = runtime.persistence.capture_snapshot()
	check(not saved.sections["core.runtime"].state.entities.ids.has(runtime.action_harness.target.entity_id), "development target identity excluded from canonical save")
	check(not JSON.stringify(saved).contains("ActionTarget") and not JSON.stringify(saved).contains("PlayerIntent"), "no input or presentation objects saved")
	check(runtime.resume_game() == OK, "runtime resume succeeds")
	executor = runtime.player_combat.actions
	runtime.set_process(false)
	check(executor.phase == ActionExecutor.Phase.IDLE and executor.remaining_cooldown("combat.action.basic_heal") == 60, "resume drops action but retains cooldown")
	check(runtime.player_combat.state.health == 85 and runtime.player_combat.state.resource == 45, "resume keeps health/resource effects")
	var malformed: Dictionary = saved.duplicate(true)
	malformed.sections["foundation.player_combat"].state.erase("actions")
	check(runtime.persistence.integrity.prepare(malformed).is_empty(), "current section missing actions rejected")
	var old: Dictionary = saved.duplicate(true)
	old.sections["foundation.player_combat"].version = 1
	old.sections["foundation.player_combat"].state.erase("actions")
	old.sections["foundation.player_combat"].state.erase("defense")
	var migrated: Dictionary = runtime.persistence.integrity.prepare(old)
	check(not migrated.is_empty() and migrated.sections["foundation.player_combat"].state.actions.cooldowns.is_empty(), "explicit Slice 1 section migration")
	avatar = runtime.world_scene.active_region.avatar
	input = avatar.get_child(0) as PlayerInput
	input.set_physics_process(false)
	avatar.intent.movement = Vector2.RIGHT
	avatar.intent.camera_delta = 0.5
	start = runtime.player.state.position
	runtime._process(0.05)
	for index in range(30): await physics_frame
	check(runtime.player.state.position.distance_to(start) > 0.5 and avatar.orbit.yaw > 0.3, "movement and camera healthy after resume")
	avatar.intent.movement = Vector2.ZERO
	avatar.intent.jump = true
	runtime._process(0.05)
	for index in range(8): await physics_frame
	check(not runtime.player.state.grounded, "jump healthy after resume")
	# Touch action buttons reserve only their right-side region; movement/camera
	# fingers remain independent and jump stays in its original upper-right area.
	var touch := InputEventScreenTouch.new()
	touch.index = 10
	touch.position = Vector2(100, 300)
	touch.pressed = true
	input._input(touch)
	touch.index = 11
	touch.position = Vector2(input.size.x - 200, 300)
	input._input(touch)
	var button := input.get_child(2) as Button
	check(button.get_global_rect().position.is_equal_approx(Vector2(input.size.x - 150, input.size.y - 165)), "touch action button stays in reserved screen region")
	touch.index = 12
	touch.position = button.get_global_rect().get_center()
	input._input(touch)
	check(avatar.intent.secondary_action and input.move_touch == 10 and input.camera_touch == 11, "touch heal uses semantic slot and preserves touch owners")
	avatar.intent.consume_actions()
	var emulated := InputEventMouseButton.new()
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.pressed = true
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.position = button.get_global_rect().get_center()
	input._input(emulated)
	check(not avatar.intent.secondary_action, "touch mouse emulation cannot activate a second time")
	input.request_action(1)
	input._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not avatar.intent.secondary_action and input.move_touch == -1 and input.camera_touch == -1, "focus loss clears combat and touch input")
	runtime.free()
	print("Combat Action runtime tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
