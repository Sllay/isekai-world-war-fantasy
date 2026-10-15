class_name SaveIntegrity
extends RefCounted

const GAME_VERSION := "0.2.0"

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
	var upgraded := _upgrade_legacy(snapshot)
	if upgraded.is_empty():
		return _reject("LEGACY_SAVE_INVALID")
	var staged := store.prepare_restore(registry, upgraded)
	if staged.is_empty():
		return {}
	if staged.game_version != GAME_VERSION:
		return _reject("GAME_VERSION_UNSUPPORTED")
	for module in registry.order:
		if staged.modules[module.id] != module.version:
			return _reject("MODULE_VERSION_UNSUPPORTED")
	for id in ["core.runtime", "foundation.player", "foundation.world", "foundation.regions", "foundation.player_combat"]:
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
	var player_combat: Dictionary = staged.sections["foundation.player_combat"].state
	if player_combat.entity_id != entity_id:
		return _reject("PLAYER_COMBAT_ID_MISMATCH")
	reason = "VALID"
	return staged

func _reject(code: String) -> Dictionary:
	reason = code
	return {}

# Explicit application upgrade: only the exact four-module M1.3 release can
# acquire initial combat state. New-format saves missing combat remain invalid.
func _upgrade_legacy(snapshot: Dictionary) -> Dictionary:
	if snapshot.get("game_version") != "0.1.0":
		return snapshot
	var ids := ["core.runtime", "foundation.player", "foundation.world", "foundation.regions"]
	if not snapshot.get("modules") is Dictionary or not snapshot.get("sections") is Dictionary or snapshot.modules.size() != ids.size() or snapshot.sections.size() != ids.size():
		return {}
	for id in ids:
		if snapshot.modules.get(id) != "1.0.0":
			return {}
		var section: Variant = snapshot.sections.get(id)
		if not section is Dictionary or not CombatNumbers.integer(section.get("version"), 1, 1) or not section.get("state") is Dictionary:
			return {}
	var entity_id: Variant = snapshot.sections["foundation.player"].state.get("entity_id")
	if not CombatNumbers.stable_entity(entity_id):
		return {}
	var upgraded := snapshot.duplicate(true)
	upgraded.game_version = GAME_VERSION
	for id in ["foundation.combat", "foundation.player_combat"]:
		if not registry.modules.has(id):
			return {}
		upgraded.modules[id] = registry.modules[id].version
	var owner := registry.modules["foundation.player_combat"] as PlayerCombatModule
	upgraded.sections[owner.id] = {"version": owner.state_version, "state": owner.initial_state(entity_id)}
	return upgraded
