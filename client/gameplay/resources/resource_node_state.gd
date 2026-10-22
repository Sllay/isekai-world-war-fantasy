class_name ResourceNodeState
extends RefCounted

var definition: ResourceNodeDefinition
var profile: ResourceDefinition
var remaining := 0
var regeneration_tick := -1
var cycle := 0
var extractions := 0

func _init(authored: ResourceNodeDefinition = null, rules: ResourceDefinition = null) -> void:
	definition = authored
	profile = rules
	if profile != null:
		remaining = profile.reserves

func advance(tick: int) -> void:
	if remaining == 0 and regeneration_tick >= 0 and tick >= regeneration_tick:
		remaining = profile.reserves
		regeneration_tick = -1
		cycle += 1
		extractions = 0

func capture() -> Dictionary:
	return {"node_id": definition.node_id, "profile_id": definition.profile_id, "region_id": definition.region_id, "position": [definition.position.x, definition.position.y, definition.position.z], "remaining": remaining, "regeneration_tick": regeneration_tick, "cycle": cycle, "extractions": extractions}

func valid(value: Dictionary) -> bool:
	if value.size() != 8 or value.get("node_id") != definition.node_id or value.get("profile_id") != definition.profile_id or value.get("region_id") != definition.region_id:
		return false
	var expected_position := [definition.position.x, definition.position.y, definition.position.z]
	if not value.get("position") is Array or value.position.size() != 3: return false
	for number: Variant in value.position:
		if not (number is int or number is float) or not is_finite(number): return false
	# Positions have Godot Vector3 precision on both sides of a JSON boundary.
	# Comparing the parsed doubles directly rejects valid generated placements.
	if Vector3(value.position[0], value.position[1], value.position[2]) != Vector3(expected_position[0], expected_position[1], expected_position[2]) or not CombatNumbers.integer(value.get("remaining"), 0, profile.reserves) or not CombatNumbers.integer(value.get("extractions"), 0, profile.reserves) or not CombatNumbers.integer(value.get("cycle"), 0, CombatNumbers.MAX_UNITS) or not CombatNumbers.integer(value.get("regeneration_tick"), -1, 9007199254740991):
		return false
	if value.remaining + value.extractions != profile.reserves:
		return false
	return value.regeneration_tick >= 0 if value.remaining == 0 and profile.regeneration_ticks > 0 else value.regeneration_tick == -1

func restore(value: Dictionary) -> void:
	remaining = int(value.remaining)
	regeneration_tick = int(value.regeneration_tick)
	cycle = int(value.cycle)
	extractions = int(value.extractions)
