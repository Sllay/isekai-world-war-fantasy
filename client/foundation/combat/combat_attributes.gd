class_name CombatAttributes
extends RefCounted

var base_health: int
var base_resource: int
var base_damage_scale: int
var base_heal_scale: int
var _modifiers: Dictionary[String, CombatModifier] = {}

func _init(profile: Dictionary) -> void:
	base_health = int(profile.max_health)
	base_resource = int(profile.max_resource)
	base_damage_scale = int(profile.damage_scale)
	base_heal_scale = int(profile.heal_scale)

func add(modifier: CombatModifier) -> Error:
	if modifier == null or not CombatModifier.valid(modifier.capture()):
		return ERR_INVALID_PARAMETER
	if _modifiers.has(modifier.source_id):
		return ERR_ALREADY_EXISTS
	if _modifiers.size() >= CombatNumbers.MAX_MODIFIERS:
		return ERR_OUT_OF_MEMORY
	_modifiers[modifier.source_id] = CombatModifier.from_state(modifier.capture())
	return OK

func remove(source_id: String) -> Error:
	return OK if _modifiers.erase(source_id) else ERR_DOES_NOT_EXIST

func value(stat: CombatModifier.Stat) -> int:
	var base: int = [base_health, base_resource, base_damage_scale, base_heal_scale][stat]
	var minimum := 1 if stat == CombatModifier.Stat.MAX_HEALTH else 0
	var maximum := CombatNumbers.MAX_UNITS if stat <= CombatModifier.Stat.MAX_RESOURCE else CombatNumbers.MAX_SCALE
	var ids := _modifiers.keys()
	ids.sort()
	for id in ids:
		var modifier := _modifiers[id]
		if modifier.stat == stat and modifier.operator == CombatModifier.Operator.ADD:
			base += modifier.value
	base = clampi(base, minimum, maximum)
	for id in ids:
		var modifier := _modifiers[id]
		if modifier.stat == stat and modifier.operator == CombatModifier.Operator.SCALE:
			@warning_ignore("integer_division")
			base = clampi(base * modifier.value / CombatNumbers.SCALE, minimum, maximum)
	return base

func capture_modifiers() -> Array:
	var result: Array = []
	var ids := _modifiers.keys()
	ids.sort()
	for id in ids:
		result.append(_modifiers[id].capture())
	return result
