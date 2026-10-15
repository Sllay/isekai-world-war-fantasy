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
	var registry := CoreModuleRegistry.new()
	var core := CoreRuntimeServicesModule.new()
	var player := PlayerModule.new()
	registry.add(core)
	registry.add(player)
	check(registry.boot() == OK, "isolated player boot")
	check(core.entities.contains(player.state.entity_id), "Core entity identity")
	check(player.capabilities.capability("foundation.movement") == player.state, "movement capability")
	var stable_id := player.state.entity_id
	player.state.position = Vector3(3, 4, 5)
	player.state.velocity = Vector3(1, 2, 3)
	var snapshot := core.saves.capture(registry, "test", 1)
	var json: Dictionary = JSON.parse_string(JSON.stringify(snapshot))
	player.state.position = Vector3.ZERO
	check(core.saves.restore(registry, json) == OK, "JSON snapshot restore")
	check(player.state.entity_id == stable_id and player.state.position == Vector3(3, 4, 5), "persistent identity and movement")
	var bad := player.capture_state()
	bad.position = [0, INF, 0]
	check(player.validate_state(bad) != OK, "reject nonfinite position")
	bad = player.capture_state()
	bad.facing = [0, 0, 0]
	check(player.validate_state(bad) != OK, "reject invalid direction")
	var velocity := PlayerMotor.horizontal_velocity(Vector3.ZERO, Vector3(6, 0, 0), 24, 0.1)
	check(is_equal_approx(velocity.x, 2.4), "acceleration bounded")
	check(PlayerMotor.horizontal_velocity(velocity, Vector3.ZERO, 30, 0.1).is_zero_approx(), "deceleration stops without overshoot")
	check(PlayerPresentation.resolve_view(Vector3.FORWARD, 0).direction == "back", "back view")
	check(PlayerPresentation.resolve_view(Vector3.FORWARD, PI).direction == "front", "camera relative front")
	check(PlayerPresentation.resolve_view(Vector3.LEFT, 0).mirrored, "opposite side mirror")
	var host := preload("res://tests/player_physics_fixture.gd").new()
	host.state = player.state
	player.state.position = Vector3(0, 1, 0)
	player.state.velocity = Vector3.ZERO
	root.add_child(host)
	for i in 90:
		await physics_frame
	check(player.state.grounded, "physical ground detection")
	var adapter := host.get_child(0) as PlayerInput
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.position = Vector2(100, 300)
	touch.pressed = true
	adapter._input(touch)
	touch.index = 3
	touch.position = Vector2(adapter.size.x - 200, 300)
	adapter._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = Vector2(170, 300)
	adapter._input(drag)
	drag.index = 3
	drag.relative = Vector2(50, 0)
	adapter._input(drag)
	check(adapter.touch_axis.x > 0.9 and host.intent.camera_delta < -0.5, "independent simultaneous touch channels")
	touch.index = 3
	touch.pressed = false
	adapter._input(touch)
	check(adapter.move_touch == 2 and adapter.camera_touch == -1, "camera release preserves movement finger")
	touch.index = 2
	adapter._input(touch)
	check(adapter.touch_axis == Vector2.ZERO, "movement touch release clears intent")
	host.intent.camera_delta = 0
	var key := InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	Input.parse_input_event(key)
	var keyboard_start := player.state.position
	for i in 20:
		await physics_frame
	check(player.state.position.distance_to(keyboard_start) > 0.2, "keyboard adapter changes physical state")
	key.pressed = false
	Input.parse_input_event(key)
	var start := player.state.position
	# Disable hardware polling for deterministic semantic-intent tests.
	host.get_child(0).set_physics_process(false)
	host.intent.movement = Vector2(1, 0)
	host.intent.camera_delta = 0.8
	for i in 30:
		await physics_frame
	check(player.state.position.distance_to(start) > 1, "physical movement")
	check(absf(host.orbit.yaw) > 0.5 and player.state.velocity.is_finite(), "simultaneous camera and movement")
	host.intent.movement = Vector2.ZERO
	host.intent.jump = true
	for i in 8:
		await physics_frame
	check(not player.state.grounded and player.state.position.y > 0.2, "jump leaves floor")
	for i in 100:
		await physics_frame
	check(player.state.grounded, "jump lands")
	player.state.position = Vector3(-4, 4, -4)
	player.state.velocity = Vector3.ZERO
	player.state.grounded = false
	for i in 100:
		await physics_frame
	check(player.state.grounded and player.state.position.y > 0.05, "elevated slope landing")
	player.state.position = Vector3(25, 2, 0)
	player.state.velocity = Vector3.ZERO
	player.state.grounded = false
	for i in 50:
		await physics_frame
	check(not player.state.grounded and player.state.velocity.y < 0, "falling beyond ground")
	host.queue_free()
	await process_frame
	registry.shutdown()
	print("Player tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
