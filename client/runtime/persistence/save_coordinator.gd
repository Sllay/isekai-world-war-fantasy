class_name SaveCoordinator
extends RefCounted

# Application-owned development fixtures are excluded without mutating live IDs.
var transient_entity_ids: Array[String] = []
var slot: LocalSaveSlot
var registry: CoreModuleRegistry
var store: CoreSaveStore
var scene: WorldScene
var integrity: SaveIntegrity
var startup_mode := ""
var ready := false
var initial_snapshot: Dictionary = {}
var suppress_autosave := false
var delete_code := "NOT_DELETED"
var writes_blocked := false
var last_save_code := "NOT_SAVED"
var last_resume_code := "NOT_RESUMED"
var checkpoint_committed: Callable
var migration_pending := false
var timing := {"capture_us": 0, "validate_us": 0, "write_us": 0, "total_us": 0}
var max_commit_timing: Dictionary = {}

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
		if scene.active_region != null:
			var recovery := scene.active_region.record.recovery
			snapshot.sections["foundation.player"].state = recovery.safe_snapshot(snapshot.sections["foundation.player"].state)
		for id in transient_entity_ids:
			snapshot.sections["core.runtime"].state.entities.ids.erase(id)
	return snapshot

func save_game() -> Error:
	if not ready or writes_blocked or scene.active_region == null:
		return _save_failure("SAVE_BLOCKED", ERR_UNCONFIGURED)
	# Main-thread synchronous capture has no await: physics, clock and modules
	# cannot advance between capture, validation and the atomic replacement.
	var started := Time.get_ticks_usec()
	var snapshot := capture_snapshot()
	timing.capture_us = Time.get_ticks_usec() - started
	var validated := Time.get_ticks_usec()
	var staged := integrity.prepare(snapshot)
	timing.validate_us = Time.get_ticks_usec() - validated
	if staged.is_empty():
		return _save_failure("SAVE_INVALID", ERR_INVALID_DATA, integrity.reason)
	var writing := Time.get_ticks_usec()
	var error := slot.write(store, staged)
	timing.write_us = Time.get_ticks_usec() - writing
	timing.total_us = Time.get_ticks_usec() - started
	if error != OK:
		return _save_failure("SAVE_WRITE_FAILED", error)
	suppress_autosave = false
	migration_pending = false
	last_save_code = "SAVE_OK"
	if checkpoint_committed.is_valid(): checkpoint_committed.call()
	_report(last_save_code)
	return OK

# Generation's staged section is validated and durably committed before the
# owning ledger installs it. No provisional record leaks into canonical state.
func commit_section(section_id: String, candidate: Dictionary) -> Error:
	if not ready or writes_blocked or scene.active_region == null or not registry.modules.has(section_id): return ERR_UNCONFIGURED
	var started := Time.get_ticks_usec()
	var snapshot := capture_snapshot()
	if not snapshot.sections.has(section_id): return ERR_INVALID_DATA
	snapshot.sections[section_id].state = candidate.duplicate(true)
	var captured := Time.get_ticks_usec()
	var staged := integrity.prepare(snapshot)
	if staged.is_empty(): return ERR_INVALID_DATA
	var validated := Time.get_ticks_usec()
	var error := slot.write(store, staged)
	var ended := Time.get_ticks_usec()
	var measured := {"capture_us": captured - started, "validate_us": validated - captured, "write_us": ended - validated, "total_us": ended - started}
	if measured.total_us > int(max_commit_timing.get("total_us", 0)): max_commit_timing = measured
	return error

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
	migration_pending = loaded.snapshot.game_version != SaveIntegrity.GAME_VERSION
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
	return {"startup_mode": startup_mode, "slot_id": slot.id, "slot_path": slot.path, "save_format_version": CoreSaveStore.FORMAT_VERSION, "world_id": scene.directory.world.world_id, "current_region_id": scene.directory.world.current_region_id, "player_entity_id": scene.player.entity_id, "player_position": [scene.player.position.x, scene.player.position.y, scene.player.position.z], "world_tick": scene.directory.world.clock.tick, "save_code": last_save_code, "resume_code": last_resume_code, "writes_blocked": writes_blocked, "delete_code": delete_code, "autosave_suppressed": suppress_autosave}

func _report(code: String, details: Dictionary = {}) -> void:
	var context := development_state()
	context.merge(details)
	registry.diagnostics.record("error" if code in ["SAVE_INVALID", "SAVE_BLOCKED", "SAVE_WRITE_FAILED", "RESUME_ATTACH_FAILED", "NEW_GAME_FAILED"] else "info", "runtime.persistence", code, context)

func delete_and_reset() -> Error:
	# Validate a concrete clean reset before touching disk. Autosave is latched
	# off through reset and afterward until the user's next explicit Save.
	var staged := integrity.prepare(initial_snapshot)
	if staged.is_empty():
		return ERR_INVALID_DATA
	suppress_autosave = true
	var error := slot.delete()
	if error != OK:
		delete_code = "SAVE_DELETE_FAILED"
		_report(delete_code, {"error": error})
		return error
	ready = false
	writes_blocked = true
	scene.close_region()
	error = store.restore(registry, staged)
	if error == OK:
		error = scene.open_current()
	ready = error == OK
	writes_blocked = not ready
	startup_mode = "new_game"
	delete_code = "SAVE_DELETED" if ready else "SAVE_RESET_FAILED"
	_report(delete_code, {"error": error})
	return error
