class_name RpgAttributes
extends RefCounted

const KEYS := ["strength", "agility", "intellect", "vitality"]
var base := {"strength": 10, "agility": 8, "intellect": 6, "vitality": 10}
var _modifiers: Dictionary = {}

static func valid_values(values: Dictionary, minimum: int, maximum: int) -> bool:
	if not InventoryService._keys(values, KEYS): return false
	for key: String in KEYS:
		if not CombatNumbers.integer(values[key], minimum, maximum): return false
	return true

func install(source: String, modifiers: Dictionary) -> Error:
	if not CoreIds.valid(source) or source.length() > 96 or not valid_values(modifiers, -100, 100): return ERR_INVALID_DATA
	if not _modifiers.has(source) and _modifiers.size() >= 16: return ERR_OUT_OF_MEMORY
	_modifiers[source] = modifiers.duplicate()
	return OK

func remove(source: String) -> void:
	_modifiers.erase(source)

func value(key: String) -> int:
	if key not in KEYS: return 0
	var result := int(base[key])
	for source: String in _modifiers: result += int(_modifiers[source][key])
	return clampi(result, 1, 1000)

func capture() -> Dictionary:
	return {"base": base.duplicate(), "modifiers": _modifiers.duplicate(true)}

static func valid(state: Dictionary) -> bool:
	if not InventoryService._keys(state, ["base", "modifiers"]) or not state.base is Dictionary or not valid_values(state.base, 1, 100) or not state.modifiers is Dictionary or state.modifiers.size() > 16: return false
	for source: Variant in state.modifiers:
		if not source is String or source.length() > 96 or not CoreIds.valid(source) or not state.modifiers[source] is Dictionary or not valid_values(state.modifiers[source], -100, 100): return false
	return true

func restore(state: Dictionary) -> Error:
	if not valid(state): return ERR_INVALID_DATA
	for key: String in KEYS: base[key] = int(state.base[key])
	_modifiers.clear()
	for source: String in state.modifiers:
		var values := {}
		for key: String in KEYS: values[key] = int(state.modifiers[source][key])
		_modifiers[source] = values
	return OK
