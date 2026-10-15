class_name PlayerInput
extends Control

var intent: PlayerIntent
var tuning: PlayerTuning
var move_touch := -1
var camera_touch := -1
var move_origin := Vector2.ZERO
var touch_axis := Vector2.ZERO
var mouse_rotating := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var actions := {"player_left": [KEY_A, KEY_LEFT], "player_right": [KEY_D, KEY_RIGHT], "player_forward": [KEY_W, KEY_UP], "player_back": [KEY_S, KEY_DOWN], "player_jump": [KEY_SPACE], "camera_left": [KEY_Q], "camera_right": [KEY_E], "player_primary": [KEY_F], "player_secondary": [KEY_H], "player_cancel": [KEY_X]}
	for action in actions:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key in actions[action]:
				var event := InputEventKey.new()
				event.physical_keycode = key
				InputMap.action_add_event(action, event)
	var label := Label.new()
	label.text = "Strike: F / RB   Heal: H / LB   Cancel: X / B\nMove: WASD / left touch   Jump: Space / upper-right touch\nRotate: Q/E / right drag / right stick"
	label.position = Vector2(20, 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	for slot in [0, 1, 2, 3]:
		var button := Button.new()
		button.text = ["Strike (F)", "Heal (H)", "Cancel (X)", "Target (T)"][slot]
		button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		button.position = Vector2(-150, (-295 if slot == 3 else -230 + slot * 65))
		button.size = Vector2(135, 55)
		# Touch is read directly, so a second finger can act while moving.
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.focus_mode = Control.FOCUS_NONE
		add_child(button)
	queue_redraw()

func _draw() -> void:
	if DisplayServer.is_touchscreen_available():
		draw_arc(Vector2(110, size.y - 110), 70, 0, TAU, 48, Color(1, 1, 1, 0.4), 3)
		draw_circle(Vector2(size.x - 80, 90), 40, Color(1, 1, 1, 0.25))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index == move_touch:
				move_touch = -1
				touch_axis = Vector2.ZERO
			if event.index == camera_touch:
				camera_touch = -1
		elif OS.is_debug_build() and Rect2(Vector2(size.x - 435, 20), Vector2(285, 55)).has_point(event.position):
			return
		elif event.position.x < size.x * 0.45 and move_touch == -1:
			move_touch = event.index
			move_origin = event.position
		elif event.position.distance_to(Vector2(size.x - 80, 90)) < 60:
			intent.jump = true
		elif _action_slot(event.position) >= 0:
			request_action(_action_slot(event.position))
		elif camera_touch == -1:
			camera_touch = event.index
	elif event is InputEventScreenDrag:
		if event.index == move_touch:
			touch_axis = ((event.position - move_origin) / 70.0).limit_length()
		elif event.index == camera_touch:
			intent.camera_delta -= event.relative.x * tuning.touch_radians_per_pixel
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		var slot := _action_slot(event.position)
		if slot >= 0:
			request_action(slot)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		mouse_rotating = event.pressed
	elif event is InputEventMouseMotion and mouse_rotating:
		intent.camera_delta -= event.relative.x * tuning.mouse_radians_per_pixel
	elif event is InputEventKey and event.physical_keycode == KEY_T and event.pressed and not event.echo:
		intent.select_target = true
	elif event.is_action_pressed("player_primary") and not event.is_echo():
		request_action(0)
	elif event.is_action_pressed("player_secondary") and not event.is_echo():
		request_action(1)
	elif event.is_action_pressed("player_cancel") and not event.is_echo():
		request_action(2)
	elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_B]:
		request_action([JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_B].find(event.button_index))
	elif event.is_action_pressed("player_jump") and not event.is_echo():
		intent.jump = true
	elif event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A and event.pressed:
		intent.jump = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and intent != null:
		move_touch = -1
		camera_touch = -1
		touch_axis = Vector2.ZERO
		mouse_rotating = false
		intent.movement = Vector2.ZERO
		intent.jump = false
		intent.camera_delta = 0
		intent.consume_actions()
		intent.select_target = false

func _physics_process(delta: float) -> void:
	var axis := Input.get_vector("player_left", "player_right", "player_forward", "player_back")
	var rotation_axis := Input.get_axis("camera_left", "camera_right")
	var pads := Input.get_connected_joypads()
	if not pads.is_empty():
		var pad: int = pads[0]
		var stick := Vector2(Input.get_joy_axis(pad, JOY_AXIS_LEFT_X), Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
		if stick.length() > tuning.stick_deadzone:
			axis += stick
		var right := Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X)
		if absf(right) > tuning.stick_deadzone:
			rotation_axis += right
	intent.movement = (axis + touch_axis).limit_length()
	intent.camera_delta -= rotation_axis * tuning.controller_radians_per_second * delta

# UI and hardware converge here; no action IDs or gameplay execution in input.
func request_action(slot: int) -> void:
	match slot:
		0: intent.primary_action = true
		1: intent.secondary_action = true
		2: intent.cancel_action = true
		3: intent.select_target = true

func _action_slot(point: Vector2) -> int:
	for slot in range(4):
		if Rect2(Vector2(size.x - 150, size.y + (-295 if slot == 3 else -230 + slot * 65)), Vector2(135, 55)).has_point(point):
			return slot
	return -1
