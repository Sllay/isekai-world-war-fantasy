class_name CombatDefinitions
extends RefCounted

const CONTENT: CombatContent = preload("res://data/combat/definitions.tres")

static func defaults() -> Dictionary:
	return {"tokens": CONTENT.tokens.duplicate(true), "profiles": CONTENT.profiles.duplicate(true)}

static func valid_token(value: Dictionary) -> Error:
	if not value.get("id") is String or not CoreIds.valid(value.id):
		return ERR_INVALID_DATA
	match value.get("kind"):
		"damage", "resource": return OK
		"attribute": return OK if CombatNumbers.integer(value.get("value"), 0, CombatModifier.Stat.size() - 1) else ERR_INVALID_DATA
		"operator": return OK if CombatNumbers.integer(value.get("value"), 0, CombatModifier.Operator.size() - 1) else ERR_INVALID_DATA
	return ERR_INVALID_DATA

static func valid_profile(value: Dictionary) -> Error:
	if not value.get("id") is String or not CoreIds.valid(value.id) or not CombatNumbers.integer(value.get("version"), 1, 1) or not value.get("resource_id") is String or not CoreIds.valid(value.resource_id):
		return ERR_INVALID_DATA
	for key in ["max_health", "max_resource"]:
		if not CombatNumbers.integer(value.get(key), 1 if key == "max_health" else 0, CombatNumbers.MAX_UNITS):
			return ERR_INVALID_DATA
	for key in ["damage_scale", "heal_scale"]:
		if not CombatNumbers.integer(value.get(key), 0, CombatNumbers.MAX_SCALE):
			return ERR_INVALID_DATA
	return OK
