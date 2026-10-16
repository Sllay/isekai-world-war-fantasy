class_name RegionScene
extends Node3D

var record: RegionState
var directory: RegionDirectory
var avatar: PlayerAvatar
var residency_lost: Callable

func _ready() -> void:
	# Terrain is region-local; physics actors retain the Player world-space contract.
	$Terrain.position = record.definition.origin
	var query := HomeValleySurfaceQuery.new()
	query.definition = record.definition
	query.clearance_at = _clearance_at
	record.recovery.surface_query = query

func spawn_player(state: PlayerState, entry_id: String) -> Error:
	if avatar != null:
		return ERR_ALREADY_IN_USE
	var error := directory.enter(record.definition.region_id, entry_id, state)
	if error != OK:
		return error
	if not record.definition.safe_position(state.position):
		record.recovery.recover()
	_attach(state)
	return OK

func resume_player(state: PlayerState) -> Error:
	if avatar != null:
		return ERR_ALREADY_IN_USE
	var error := directory.resume_player(record.definition.region_id)
	if error != OK:
		return error
	if not record.definition.safe_position(state.position):
		record.recovery.recover()
	_attach(state)
	return OK

func _attach(state: PlayerState) -> void:
	avatar = PlayerAvatar.new()
	avatar.name = "Player"
	avatar.state = state
	$Actors.add_child(avatar)
	record.recovery.clear_unsafe_motion = avatar.motor.clear_unsafe_motion

func detach_player() -> void:
	if residency_lost.is_valid():
		residency_lost.call()
	for actor in record.actors.values():
		actor.residency_lost()
	if avatar != null:
		# Release the physical body synchronously before another region can attach it.
		$Actors.remove_child(avatar)
		avatar.free()
		avatar = null
	record.recovery.surface_query = null
	record.recovery.clear_unsafe_motion = Callable()
	directory.leave(record.definition.region_id)

func _physics_process(_delta: float) -> void:
	if avatar != null:
		record.recovery.observe()

func _clearance_at(feet: Vector3) -> bool:
	if not is_inside_tree():
		return false
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * 0.9)
	query.collision_mask = 0xFFFFFFFF # Include actor bodies as well as terrain.
	if avatar != null:
		query.exclude = [avatar.motor.get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

# Debug input changes only the live transform; normal Region observation recovers.
func test_underfloor() -> bool:
	if not OS.is_debug_build() or avatar == null or record.recovery.surface_query == null:
		return false
	var height: Variant = record.recovery.surface_query.expected_height(avatar.state.position, record.definition.region_id)
	if height == null:
		return false
	avatar.state.position.y = float(height) - record.definition.penetration_depth - 2.0
	avatar.state.velocity = Vector3(0, -20, 0)
	avatar.state.grounded = false
	return true
