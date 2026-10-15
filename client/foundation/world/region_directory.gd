class_name RegionDirectory
extends RefCounted

var world: WorldState
var records: Dictionary[String, RegionState] = {}
var location := PlayerLocation.new()

func add(definition: RegionDefinition) -> Error:
	if definition == null or not definition.valid() or records.has(definition.region_id):
		return ERR_INVALID_PARAMETER
	var record := RegionState.new()
	record.definition = definition
	record.world = world
	records[definition.region_id] = record
	return OK

func record(id: String) -> RegionState:
	return records.get(id)

func enter(id: String, entry_id: String, player: PlayerState) -> Error:
	var target := record(id)
	if target == null or target.lifecycle != RegionState.Lifecycle.LOADED or not target.definition.entries.has(entry_id) or not location.region_id.is_empty():
		return ERR_INVALID_PARAMETER
	world.current_region_id = id
	target.last_entry_id = entry_id
	location.world_id = world.world_id
	location.region_id = id
	player.position = target.definition.to_world_position(target.definition.entries[entry_id])
	player.velocity = Vector3.ZERO
	player.grounded = false
	player.intent = Vector2.ZERO
	return OK

# Bind restored state without applying an entry transform or resetting velocity.
func resume_player(id: String) -> Error:
	var target := record(id)
	if target == null or target.lifecycle != RegionState.Lifecycle.LOADED or not location.region_id.is_empty() or world.current_region_id != id:
		return ERR_INVALID_PARAMETER
	location.world_id = world.world_id
	location.region_id = id
	return OK

func leave(id: String) -> void:
	if location.region_id == id:
		location.region_id = ""
