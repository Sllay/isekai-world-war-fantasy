class_name EnemyActor
extends RegionActorState

var entity_id := ""
var archetype: EnemyArchetype
var region_id := ""
var position := Vector3.ZERO
var home := Vector3.ZERO
var facing := Vector3.FORWARD
var combatant: Combatant
var actions: ActionExecutor
var capabilities: EntityComponents

func capture() -> Dictionary:
	return {"entity_id": entity_id, "archetype_id": archetype.archetype_id, "region_id": region_id, "position": _array(position), "home": _array(home), "facing": _array(facing), "combatant": combatant.capture(), "actions": actions.capture()}

func valid(value: Dictionary) -> bool:
	if not CombatNumbers.stable_entity(value.get("entity_id")) or value.get("archetype_id") != archetype.archetype_id or value.get("region_id") != region_id:
		return false
	for key in ["position", "home", "facing"]:
		if not value.get(key) is Array or value[key].size() != 3:
			return false
		for number in value[key]:
			if not (number is float or number is int) or not is_finite(float(number)) or absf(number) > 1000000:
				return false
	if not Vector3(value.home[0], value.home[1], value.home[2]).is_equal_approx(home):
		return false
	var direction := Vector3(value.facing[0], value.facing[1], value.facing[2])
	return absf(direction.y) < 0.001 and is_equal_approx(direction.length(), 1.0) and value.get("combatant") is Dictionary and value.combatant.get("profile_id") == archetype.profile_id and Combatant.valid(value.combatant, actions.combat.data.lookup(archetype.profile_id)) and value.get("actions") is Dictionary and actions.valid_snapshot(value.actions)

func restore(value: Dictionary) -> void:
	entity_id = value.entity_id
	position = Vector3(value.position[0], value.position[1], value.position[2])
	facing = Vector3(value.facing[0], value.facing[1], value.facing[2])
	actions.combat.restore_owned(combatant, entity_id, value.combatant)
	actions.owner_id = entity_id
	actions.restore(value.actions)
	capabilities.entity_id = entity_id

func _array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

func residency_lost() -> void:
	actions.cancel()
