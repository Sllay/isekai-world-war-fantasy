class_name CoreSaveStore
extends RefCounted

const FORMAT_VERSION: int = 1
const GAME_VERSION: String = "0.1.0"
var diagnostics: CoreDiagnostics
var format_migrations: Dictionary = {}
var page_members: Dictionary = {}
var pages := CoreSavePages.new()

func capture(registry: CoreModuleRegistry, world_id: String, seed_value: int) -> Dictionary:
	if registry.state != CoreModuleRegistry.State.RUNNING or world_id.is_empty() or not _integer(seed_value):
		return {}
	var sections: Dictionary = {}
	var versions: Dictionary = {}
	for module in registry.order:
		versions[module.id] = module.version
		if module.persistent:
			sections[module.id] = {"version": module.state_version, "state": module.capture_state().duplicate(true)}
	return {"format_version": FORMAT_VERSION, "game_version": GAME_VERSION, "world_id": world_id, "world_seed": seed_value, "modules": versions, "sections": sections}

func _failure(reason: String) -> Error:
	if diagnostics != null:
		diagnostics.record("error", "core.save", "load_rejected", {"reason": reason})
	return ERR_INVALID_DATA

# Stage and validate every section before changing any live state.
# Unknown sections are rejected rather than silently losing disabled-module state.
func prepare_restore(registry: CoreModuleRegistry, snapshot: Dictionary) -> Dictionary:
	if registry.state != CoreModuleRegistry.State.RUNNING:
		return _rejected("runtime is not running")
	if not _json_safe(snapshot):
		return _rejected("snapshot contains unsupported JSON values")
	var staged := snapshot.duplicate(true)
	if not _integer(staged.get("format_version")):
		return _rejected("invalid format version")
	var format_version := int(staged.format_version)
	if format_version < 1 or format_version > FORMAT_VERSION:
		return _rejected("unsupported format version")
	while format_version < FORMAT_VERSION:
		if not format_migrations.has(format_version):
			return _rejected("missing format migration")
		var migrated: Variant = format_migrations[format_version].call(staged)
		if not migrated is Dictionary or migrated.get("format_version") != format_version + 1:
			return _rejected("invalid format migration")
		staged = migrated
		format_version += 1
	if not staged.get("world_id") is String or staged.world_id.is_empty() or not _integer(staged.get("world_seed")) or not staged.get("game_version") is String:
		return _rejected("invalid metadata")
	if not staged.get("sections") is Dictionary or not staged.get("modules") is Dictionary:
		return _rejected("missing module metadata")
	var expected: Dictionary = {}
	for module in registry.order:
		if not staged.modules.get(module.id) is String:
			return _rejected("missing module version: " + module.id)
		if module.persistent:
			expected[module.id] = module
	if staged.modules.size() != registry.order.size() or staged.sections.size() != expected.size():
		return _rejected("module set mismatch")
	var prepared: Dictionary = {}
	for id in staged.sections:
		if not expected.has(id):
			return _rejected("unknown section: " + id)
		var section: Variant = staged.sections[id]
		if not section is Dictionary or not section.get("state") is Dictionary or not _integer(section.get("version")):
			return _rejected("malformed section: " + id)
		var module: CoreModule = expected[id]
		var version := int(section.version)
		if version < 1 or version > module.state_version:
			return _rejected("unsupported section version: " + id)
		var value: Dictionary = section.state.duplicate(true)
		while version < module.state_version:
			var migrated: Variant = module.migrate_state(version, value)
			if not migrated is Dictionary:
				return _rejected("missing section migration: " + id)
			value = migrated
			version += 1
		if module.validate_state(value) != OK:
			return _rejected("invalid state: " + id)
		prepared[id] = value
	for id in prepared:
		staged.sections[id] = {"version": expected[id].state_version, "state": prepared[id]}
	return staged

func _rejected(reason: String) -> Dictionary:
	_failure(reason)
	return {}

func restore(registry: CoreModuleRegistry, snapshot: Dictionary) -> Error:
	if registry.state != CoreModuleRegistry.State.RUNNING:
		return ERR_UNCONFIGURED
	var staged := prepare_restore(registry, snapshot)
	if staged.is_empty():
		return ERR_INVALID_DATA
	for module in registry.order:
		if staged.sections.has(module.id):
			module.restore_state(staged.sections[module.id].state)
	return OK

func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and abs(float(value)) <= 9007199254740991.0 and value == int(value)

# Local snapshot adapter. Temp file is written/flushed before same-directory rename.
func write_snapshot(path: String, snapshot: Dictionary) -> Error:
	if not _json_safe(snapshot):
		return _failure("snapshot contains unsupported JSON values")
	if not page_members.is_empty():
		return pages.write(path, snapshot, page_members, _write_snapshot)
	return _write_snapshot(path, snapshot)

func _write_snapshot(path: String, snapshot: Dictionary) -> Error:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot, "", true, true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return error
	return DirAccess.rename_absolute(path + ".tmp", path)

func read_snapshot(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_failure("snapshot unavailable")
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		_failure("invalid JSON snapshot")
		return {}
	return pages.hydrate(path, parser.data) if parser.data.has("_core_pages") else parser.data

func _json_safe(value: Variant, depth: int = 0) -> bool:
	if depth > 64:
		return false
	if value == null or value is bool or value is String:
		return true
	if value is int:
		return _integer(value)
	if value is float:
		return is_finite(value)
	if value is Array:
		for element in value:
			if not _json_safe(element, depth + 1):
				return false
		return true
	if value is Dictionary:
		for key in value:
			if not key is String or not _json_safe(value[key], depth + 1):
				return false
		return true
	return false
