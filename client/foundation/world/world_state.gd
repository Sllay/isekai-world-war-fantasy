class_name WorldState
extends RefCounted

var world_id: String
var world_seed: int
var schema_version := 1
var current_region_id: String
# Borrowed Core clock, never serialized or advanced here.
var clock: CoreClock

func capture() -> Dictionary:
	return {"world_id": world_id, "world_seed": world_seed, "schema_version": schema_version, "current_region_id": current_region_id}
