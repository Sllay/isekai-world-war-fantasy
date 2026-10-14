class_name CoreDataRegistry
extends RefCounted

var _families: Dictionary = {}
var _definitions: Dictionary = {}

func define_family(id: String, validator: Callable) -> Error:
	if not CoreIds.valid(id) or _families.has(id) or not validator.is_valid():
		return ERR_INVALID_PARAMETER
	_families[id] = validator
	return OK

func register(id: String, family: String, definition: Dictionary) -> Error:
	if not CoreIds.valid(id) or _definitions.has(id) or not _families.has(family):
		return ERR_INVALID_PARAMETER
	var copy := definition.duplicate(true)
	if _families[family].call(copy) != OK:
		return ERR_INVALID_DATA
	_definitions[id] = copy
	return OK

func lookup(id: String) -> Dictionary:
	return _definitions.get(id, {}).duplicate(true)
