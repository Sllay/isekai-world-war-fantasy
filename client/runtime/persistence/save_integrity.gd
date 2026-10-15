class_name SaveIntegrity
extends RefCounted

var registry: CoreModuleRegistry
var store: CoreSaveStore
var content: WorldDefinition
var reason := ""

func _init(modules: CoreModuleRegistry, adapter: CoreSaveStore, definition: WorldDefinition) -> void:
	registry = modules
	store = adapter
	content = definition

# Pure with respect to canonical state. Core prepares/migrates every section first.
func prepare(snapshot: Dictionary) -> Dictionary:
	reason = "SCHEMA_INVALID"
	var staged := store.prepare_restore(registry, snapshot)
	if staged.is_empty():
		return {}
	if staged.game_version != CoreSaveStore.GAME_VERSION:
		return _reject("GAME_VERSION_UNSUPPORTED")
	for module in registry.order:
		if staged.modules[module.id] != module.version:
			return _reject("MODULE_VERSION_UNSUPPORTED")
	for id in ["core.runtime", "foundation.player", "foundation.world", "foundation.regions"]:
		if not staged.sections.has(id):
			return _reject("REQUIRED_SECTION_MISSING")
	var world: Dictionary = staged.sections["foundation.world"].state
	if staged.world_id != world.world_id or staged.world_seed != world.world_seed:
		return _reject("WORLD_METADATA_MISMATCH")
	if world.world_id != content.world_id or world.world_seed != content.world_seed:
		return _reject("WORLD_CONTENT_MISMATCH")
	var regions: Dictionary = staged.sections["foundation.regions"].state.regions
	if content.region(world.current_region_id) == null or not regions.has(world.current_region_id):
		return _reject("REGION_UNKNOWN")
	for id in regions:
		if regions[id].world_id != world.world_id or regions[id].region_id != id:
			return _reject("REGION_MEMBERSHIP_MISMATCH")
	var entity_id: String = staged.sections["foundation.player"].state.entity_id
	if not staged.sections["core.runtime"].state.entities.ids.has(entity_id):
		return _reject("PLAYER_ID_ORPHANED")
	reason = "VALID"
	return staged

func _reject(code: String) -> Dictionary:
	reason = code
	return {}
