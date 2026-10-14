class_name CoreFeatureFlags
extends RefCounted

var _values: Dictionary = {}

func define(id: String, enabled: bool = false) -> Error:
	if not CoreIds.valid(id) or _values.has(id):
		return ERR_INVALID_PARAMETER
	_values[id] = enabled
	return OK

func enabled(id: String) -> bool:
	return _values.get(id, false)

func set_enabled(id: String, value: bool) -> Error:
	if not _values.has(id):
		return ERR_DOES_NOT_EXIST
	_values[id] = value
	return OK
