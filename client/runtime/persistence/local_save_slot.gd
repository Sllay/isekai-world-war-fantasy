class_name LocalSaveSlot
extends RefCounted

# Slot identity and storage location are injected, never embedded in gameplay.
var id: String
var path: String

func _init(slot_id := "local.current", file_path := "user://saves/current.json") -> void:
	id = slot_id
	path = file_path

func valid() -> bool:
	return CoreIds.valid(id) and not path.get_file().is_empty() and (path.begins_with("user://") or path.is_absolute_path()) and not path.begins_with("res://")

func read(store: CoreSaveStore) -> Dictionary:
	if not valid():
		return {"code": "SAVE_INVALID", "reason": "SLOT_INVALID"}
	if not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(path):
		return {"code": "NO_SAVE"}
	var snapshot := store.read_snapshot(path)
	if snapshot.is_empty():
		return {"code": "SAVE_INVALID", "reason": "READ_OR_JSON_INVALID"}
	return {"code": "SAVE_READ", "snapshot": snapshot}

func write(store: CoreSaveStore, snapshot: Dictionary) -> Error:
	if not valid():
		return ERR_INVALID_PARAMETER
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return error
	error = store.write_snapshot(path, snapshot)
	if error != OK and FileAccess.file_exists(path + ".tmp"):
		DirAccess.remove_absolute(path + ".tmp")
	return error
