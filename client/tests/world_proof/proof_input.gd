class_name ProofInput
extends Node
## Proof-local intent adapter. Replace gestures with UI via these same setters.

var touch_move := Vector2.ZERO
var touch_orbit := 0.0
var jump_pending := false
var move_finger := -1
var orbit_finger := -1
var move_origin := Vector2.ZERO

func _enter_tree() -> void:
	_bind("proof_left", [KEY_A, KEY_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_bind("proof_right", [KEY_D, KEY_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_bind("proof_forward", [KEY_W, KEY_UP], JOY_AXIS_LEFT_Y, -1.0)
	_bind("proof_back", [KEY_S, KEY_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_bind("proof_orbit_left", [KEY_Q], JOY_AXIS_RIGHT_X, -1.0)
	_bind("proof_orbit_right", [KEY_E], JOY_AXIS_RIGHT_X, 1.0)
	_bind("proof_jump", [KEY_SPACE])
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	InputMap.action_add_event("proof_jump", button)

func _bind(action: StringName, keys: Array, axis: int = -1, value: float = 0.0) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, 0.2)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)
	if axis >= 0:
		var event := InputEventJoypadMotion.new()
		event.axis = axis
		event.axis_value = value
		InputMap.action_add_event(action, event)

func movement() -> Vector2:
	return (Input.get_vector("proof_left", "proof_right", "proof_forward", "proof_back") + touch_move).limit_length()

func orbit() -> float:
	return clampf(Input.get_axis("proof_orbit_left", "proof_orbit_right") + touch_orbit, -1.0, 1.0)

func consume_jump() -> bool:
	var requested := jump_pending or Input.is_action_just_pressed("proof_jump")
	jump_pending = false
	return requested

func set_touch_movement(value: Vector2) -> void:
	touch_move = value.limit_length()

func set_touch_orbit(value: float) -> void:
	touch_orbit = clampf(value, -1.0, 1.0)

func request_jump() -> void:
	jump_pending = true

func _input(event: InputEvent) -> void:
	var size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		if not event.pressed:
			if event.index == move_finger:
				move_finger = -1
				set_touch_movement(Vector2.ZERO)
			if event.index == orbit_finger:
				orbit_finger = -1
				set_touch_orbit(0.0)
		elif event.position.x < size.x * 0.5 and move_finger == -1:
			move_finger = event.index
			move_origin = event.position
		elif event.position.x >= size.x * 0.5:
			if event.position.y > size.y * 0.7:
				request_jump()
			elif orbit_finger == -1:
				orbit_finger = event.index
	elif event is InputEventScreenDrag:
		if event.index == move_finger:
			set_touch_movement((event.position - move_origin) / (size.y * 0.12))
		if event.index == orbit_finger:
			# Accumulate angular drag, then consume once per physics tick.
			set_touch_orbit(touch_orbit + event.relative.x / (size.x * 0.04))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		move_finger = -1
		orbit_finger = -1
		touch_move = Vector2.ZERO
		touch_orbit = 0.0
		jump_pending = false
