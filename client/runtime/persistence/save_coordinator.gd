class_name SaveCoordinator
extends RefCounted

var slot: LocalSaveSlot
var registry: CoreModuleRegistry
var store: CoreSaveStore
var scene: WorldScene
var integrity: SaveIntegrity
var startup_mode := ""
var ready := false
var writes_blocked := false
var last_save_code := "NOT_SAVED"
var last_resume_code := "NOT_RESUMED"

func _init(save_slot: LocalSaveSlot, modules: CoreModuleRegistry, adapter: CoreSaveStore, world_scene: WorldScene, content: WorldDefinition) -> void:
	slot = save_slot
	registry = modules
	store = adapter
	scene = world_scene
	integrity = SaveIntegrity.new(registry, store, content)

func startup() -> Error:
	var loaded := slot.read(store)
	if loaded.code == "NO_SAVE":
		startup_mode = "new_game"
		last_resume_code = "NO_SAVE"
		var error := scene.open_current()
		ready = error == OK
		_report("NEW_GAME_READY" if ready else "NEW_GAME_FAILED", {"error": error})
		return error
	startup_mode = "resume"
	return _resume_read(loaded)

func capture_snapshot() -> Dictionary:
	var snapshot := store.capture(registry, scene.directory.world.world_id, scene.directory.world.world_seed)
	if not snapshot.is_empty():
		snapshot.game_version = SaveIntegrity.GAME_VERSION
	return snapshot

func save_game() -> Error:
	if not ready or writes_blocked or scene.active_region == null:
		return _save_failure("SAVE_BLOCKED", ERR_UNCONFIGURED)
	# Main-thread synchronous capture has no await: physics, clock and modules
	# cannot advance between capture, validation and the atomic replacement.
	var snapshot := capture_snapshot()
	var staged := integrity.prepare(snapshot)
	if staged.is_empty():
		return _save_failure("SAVE_INVALID", ERR_INVALID_DATA, integrity.reason)
	var error := slot.write(store, staged)
	if error != OK:
		return _save_failure("SAVE_WRITE_FAILED", error)
	last_save_code = "SAVE_OK"
	_report(last_save_code)
	return OK

func resume_game() -> Error:
	return _resume_read(slot.read(store))

func _resume_read(loaded: Dictionary) -> Error:
	if loaded.code == "NO_SAVE":
		last_resume_code = "NO_SAVE"
		_report(last_resume_code)
		return ERR_FILE_NOT_FOUND
	if loaded.code != "SAVE_READ":
		return _resume_failure("SAVE_INVALID", loaded.get("reason", "READ_FAILED"))
	var staged := integrity.prepare(loaded.snapshot)
	if staged.is_empty():
		return _resume_failure("SAVE_INVALID", integrity.reason)
	# No residency changes until *all* schema and cross-section checks pass.
	var previous := capture_snapshot()
	var was_resident := scene.active_region != null
	scene.close_region()
	var error := store.restore(registry, staged)
	if error == OK:
		error = scene.open_current(true)
	if error != OK:
		# Content/attachment failure must preserve the previous canonical game too.
		scene.close_region()
		var rollback := store.restore(registry, previous)
		if rollback == OK and was_resident:
			rollback = scene.open_current(true)
		ready = was_resident and rollback == OK
		return _resume_failure("RESUME_ATTACH_FAILED", "error=%d rollback=%d" % [error, rollback])
	ready = true
	writes_blocked = false
	last_resume_code = "RESUME_OK"
	_report(last_resume_code)
	return OK

func _save_failure(code: String, error: Error, reason := "") -> Error:
	last_save_code = code
	_report(code, {"error": error, "reason": reason})
	return error

func _resume_failure(code: String, reason: String) -> Error:
	writes_blocked = true
	last_resume_code = code
	_report(code, {"reason": reason})
	return ERR_INVALID_DATA

func development_state() -> Dictionary:
	return {"startup_mode": startup_mode, "slot_id": slot.id, "slot_path": slot.path, "save_format_version": CoreSaveStore.FORMAT_VERSION, "world_id": scene.directory.world.world_id, "current_region_id": scene.directory.world.current_region_id, "player_entity_id": scene.player.entity_id, "player_position": [scene.player.position.x, scene.player.position.y, scene.player.position.z], "world_tick": scene.directory.world.clock.tick, "save_code": last_save_code, "resume_code": last_resume_code, "writes_blocked": writes_blocked}

func _report(code: String, details: Dictionary = {}) -> void:
	var context := development_state()
	context.merge(details)
	registry.diagnostics.record("error" if code in ["SAVE_INVALID", "SAVE_BLOCKED", "SAVE_WRITE_FAILED", "RESUME_ATTACH_FAILED", "NEW_GAME_FAILED"] else "info", "runtime.persistence", code, context)
