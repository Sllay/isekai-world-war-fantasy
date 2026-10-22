class_name CoreEntityIds
extends RefCounted

var _ids: Dictionary = {}

func create() -> String:
	var id := CoreIds.generate()
	while _ids.has(id):
		id = CoreIds.generate()
	_ids[id] = true
	return id

func contains(id: String) -> bool:
	return _ids.has(id)

func register(id: String) -> Error:
	if not id.length() == 32 or id != id.to_lower() or not id.is_valid_hex_number(false): return ERR_INVALID_DATA
	if _ids.has(id): return ERR_ALREADY_EXISTS
	_ids[id] = true
	return OK

func capture() -> Dictionary:
	return {"ids": _ids.keys()}

func validate(snapshot: Dictionary) -> Error:
	if not snapshot.get("ids") is Array:
		return ERR_INVALID_DATA
	var seen: Dictionary = {}
	for id in snapshot.ids:
		if not id is String or id.length() != 32 or id != id.to_lower() or not id.is_valid_hex_number(false) or seen.has(id):
			return ERR_INVALID_DATA
		seen[id] = true
	return OK

func restore(snapshot: Dictionary) -> void:
	_ids.clear()
	for id in snapshot.ids:
		_ids[id] = true
