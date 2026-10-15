class_name WorldScene
extends Node3D

var directory: RegionDirectory
var player: PlayerState
var active_region: RegionScene

func open_current(resuming := false) -> Error:
	var record := directory.record(directory.world.current_region_id)
	if record == null:
		return ERR_DOES_NOT_EXIST
	return open_region(record.definition.region_id, record.definition.default_entry, resuming)

func open_region(region_id: String, entry_id: String, resuming := false) -> Error:
	if active_region != null:
		return ERR_ALREADY_IN_USE
	var record := directory.record(region_id)
	if record == null or record.lifecycle != RegionState.Lifecycle.UNLOADED or not record.definition.entries.has(entry_id):
		return ERR_INVALID_PARAMETER
	if resuming and directory.world.current_region_id != region_id:
		return ERR_INVALID_PARAMETER
	record.transition(RegionState.Lifecycle.LOADING)
	var instance := record.definition.scene.instantiate()
	if not instance is RegionScene or not instance.get_node_or_null("Terrain") is Node3D or not instance.get_node_or_null("Actors") is Node3D:
		instance.free()
		record.cancel_load()
		return ERR_INVALID_DATA
	active_region = instance as RegionScene
	active_region.record = record
	active_region.directory = directory
	$Regions.add_child(active_region)
	record.transition(RegionState.Lifecycle.LOADED)
	var error := active_region.resume_player(player) if resuming else active_region.spawn_player(player, entry_id)
	if error != OK:
		close_region()
	return error

func close_region() -> void:
	if active_region == null:
		return
	var record := active_region.record
	record.transition(RegionState.Lifecycle.UNLOADING)
	active_region.detach_player()
	$Regions.remove_child(active_region)
	active_region.free()
	active_region = null
	record.transition(RegionState.Lifecycle.UNLOADED)

func _exit_tree() -> void:
	close_region()

func development_state() -> Dictionary:
	var result := directory.world.capture()
	result["world_tick"] = directory.world.clock.tick
	result["player_entity_id"] = player.entity_id
	result["player_position"] = player.position
	var record := directory.record(directory.world.current_region_id)
	result["region_lifecycle"] = RegionState.Lifecycle.keys()[record.lifecycle] if record != null else "UNKNOWN"
	if record != null:
		var local := record.definition.to_local_position(player.position)
		result["region_local_position"] = local
		result["chunk_id"] = record.definition.chunk_id(local)
		result["chunk_coordinates"] = record.definition.chunk_at(local)
		result["chunk_local_position"] = local - Vector3(record.definition.chunk_at(local).x * record.definition.chunk_size, 0, record.definition.chunk_at(local).y * record.definition.chunk_size)
	if active_region != null and active_region.avatar != null:
		result.merge(active_region.avatar.development_state())
	return result
