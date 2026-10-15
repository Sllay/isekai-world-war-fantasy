class_name RegionState
extends RefCounted

enum Lifecycle { UNLOADED, LOADING, LOADED, UNLOADING }
# Ownership hook only: no fidelity scheduler or simulation is implemented.
enum SimulationLod { UNASSIGNED, ACTIVE, REDUCED, AGGREGATE, LATENT }
var requested_simulation_lod := SimulationLod.UNASSIGNED
var definition: RegionDefinition
var world: WorldState
var lifecycle := Lifecycle.UNLOADED
# Region-owned canonical data for this slice; scene instances are transient.
var last_entry_id: String = ""
var actors: Dictionary[String, RegionActorState] = {}
var recovery: RegionRecovery

func transition(next: Lifecycle) -> Error:
	var allowed := {Lifecycle.UNLOADED: Lifecycle.LOADING, Lifecycle.LOADING: Lifecycle.LOADED, Lifecycle.LOADED: Lifecycle.UNLOADING, Lifecycle.UNLOADING: Lifecycle.UNLOADED}
	if allowed[lifecycle] != next:
		return ERR_INVALID_PARAMETER
	lifecycle = next
	return OK

func cancel_load() -> void:
	if lifecycle == Lifecycle.LOADING:
		lifecycle = Lifecycle.UNLOADED

func simulation_tick() -> int:
	return world.clock.tick

func capture() -> Dictionary:
	var result := {"region_id": definition.region_id, "world_id": world.world_id, "schema_version": definition.schema_version, "last_entry_id": last_entry_id}
	if recovery != null:
		result["last_safe"] = recovery.last_safe.duplicate(true)
	if not actors.is_empty():
		result["actors"] = {}
		for key in actors:
			result.actors[key] = actors[key].capture()
	return result

func valid(value: Dictionary) -> bool:
	if recovery != null and (not value.get("last_safe") is Dictionary or not recovery.valid(value.last_safe)):
		return false
	if not actors.is_empty():
		if not value.get("actors") is Dictionary or value.actors.size() != actors.size():
			return false
		for key in actors:
			if not value.actors.get(key) is Dictionary or not actors[key].valid(value.actors[key]):
				return false
	return value.get("region_id") == definition.region_id and value.get("world_id") == world.world_id and value.get("schema_version") == definition.schema_version and value.get("last_entry_id") is String and (value.last_entry_id.is_empty() or definition.entries.has(value.last_entry_id))
