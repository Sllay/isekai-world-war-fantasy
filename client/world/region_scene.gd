class_name RegionScene
extends Node3D

var record: RegionState
var directory: RegionDirectory
var avatar: PlayerAvatar

func _ready() -> void:
	# Terrain is region-local; physics actors retain the Player world-space contract.
	$Terrain.position = record.definition.origin

func spawn_player(state: PlayerState, entry_id: String) -> Error:
	if avatar != null:
		return ERR_ALREADY_IN_USE
	var error := directory.enter(record.definition.region_id, entry_id, state)
	if error != OK:
		return error
	_attach(state)
	return OK

func resume_player(state: PlayerState) -> Error:
	if avatar != null:
		return ERR_ALREADY_IN_USE
	var error := directory.resume_player(record.definition.region_id)
	if error != OK:
		return error
	_attach(state)
	return OK

func _attach(state: PlayerState) -> void:
	avatar = PlayerAvatar.new()
	avatar.name = "Player"
	avatar.state = state
	$Actors.add_child(avatar)

func detach_player() -> void:
	if avatar != null:
		# Release the physical body synchronously before another region can attach it.
		$Actors.remove_child(avatar)
		avatar.free()
		avatar = null
	directory.leave(record.definition.region_id)
