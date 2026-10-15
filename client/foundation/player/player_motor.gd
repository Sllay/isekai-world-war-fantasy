class_name PlayerMotor
extends CharacterBody3D

var state: PlayerState
var intent: PlayerIntent
var tuning: PlayerTuning
# Providers return a nonnegative speed multiplier; no feature-specific rules here.
var movement_modifiers: Array[Callable] = []
var movement_yaw := 0.0
var movement_gate: Callable
var turning_gate: Callable

func _ready() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	floor_max_angle = deg_to_rad(tuning.floor_angle_degrees)
	floor_snap_length = tuning.floor_snap
	floor_constant_speed = true

static func horizontal_velocity(current: Vector3, target: Vector3, rate: float, delta: float) -> Vector3:
	var next := Vector2(current.x, current.z).move_toward(Vector2(target.x, target.z), rate * delta)
	return Vector3(next.x, current.y, next.y)

func _physics_process(delta: float) -> void:
	# State is authoritative, including after snapshot restore/teleport.
	position = state.position
	velocity = state.velocity
	var allowed := not movement_gate.is_valid() or bool(movement_gate.call())
	var axis := intent.movement.limit_length() if allowed else Vector2.ZERO
	if not allowed:
		velocity.x = 0
		velocity.z = 0
	state.intent = axis
	var direction := Vector3(axis.x, 0, axis.y).rotated(Vector3.UP, movement_yaw)
	var multiplier := 1.0
	for modifier in movement_modifiers:
		var factor: float = modifier.call(state)
		if is_finite(factor):
			multiplier *= maxf(0.0, factor)
	var rate := tuning.acceleration if direction.length_squared() > 0 else tuning.deceleration
	if not state.grounded:
		rate = tuning.air_acceleration
	velocity = horizontal_velocity(velocity, direction * tuning.speed * multiplier, rate, delta)
	var jump_requested := intent.consume_jump()
	if jump_requested and state.grounded and allowed:
		velocity.y = tuning.jump_speed
	else:
		velocity.y = maxf(velocity.y - tuning.gravity * delta, -tuning.terminal_speed)
	move_and_slide()
	state.position = position
	state.velocity = velocity
	state.grounded = is_on_floor()
	if direction.length_squared() > 0.001 and (not turning_gate.is_valid() or bool(turning_gate.call())):
		state.facing = direction.normalized()
