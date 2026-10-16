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
	var upgraded := _upgrade_enemy_release(_upgrade_legacy(snapshot))
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
	var seen: Dictionary = {entity_id: true}
	for region_id in regions:
		for actor in regions[region_id].get("actors", {}).values():
			if seen.has(actor.entity_id) or not staged.sections["core.runtime"].state.entities.ids.has(actor.entity_id):
				return _reject("ACTOR_ID_ORPHANED_OR_DUPLICATE")
			seen[actor.entity_id] = true
	# Known finite void positions from old slots recover through the authored
	# Region contract. Gross/nonfinite corruption still fails Player validation.
	var player_state: Dictionary = staged.sections["foundation.player"].state
	var region := content.region(world.current_region_id)
	var position := Vector3(player_state.position[0], player_state.position[1], player_state.position[2])
	if not region.safe_position(position) or region.below_surface(position):
		var safe: Dictionary = regions[world.current_region_id].get("last_safe", {})
		player_state.position = safe.position.duplicate() if not safe.is_empty() else [region.to_world_position(region.entries[region.default_entry]).x, region.to_world_position(region.entries[region.default_entry]).y, region.to_world_position(region.entries[region.default_entry]).z]
		player_state.velocity = [0, 0, 0]
		if not safe.is_empty():
			player_state.facing = safe.facing.duplicate()
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

func _upgrade_enemy_release(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty() or not registry.modules.has("gameplay.enemies") or not snapshot.get("modules") is Dictionary or snapshot.modules.has("gameplay.enemies"):
		return snapshot
	var previous := ["core.runtime", "foundation.player", "foundation.world", "foundation.regions", "foundation.combat", "foundation.player_combat"]
	if snapshot.get("game_version") != GAME_VERSION or snapshot.modules.size() != previous.size() or not snapshot.get("sections") is Dictionary:
		return {}
	for id in previous:
		if snapshot.modules.get(id) != "1.0.0":
			return {}
	if snapshot.sections.get("foundation.regions", {}).get("version") != 1:
		return {}
	var result := snapshot.duplicate(true)
	result.modules["gameplay.enemies"] = registry.modules["gameplay.enemies"].version
	result.modules["foundation.targeting"] = registry.modules["foundation.targeting"].version
	var owner := registry.modules["gameplay.enemies"] as EnemyModule
	var section: Variant = result.sections.get("foundation.regions")
	if not section is Dictionary or not section.get("state") is Dictionary or not section.state.get("regions") is Dictionary or not section.state.regions.get(owner.actor.region_id) is Dictionary:
		return {}
	var core: Variant = result.sections.get("core.runtime")
	if not core is Dictionary or not core.get("state") is Dictionary or not core.state.get("entities") is Dictionary or not core.state.entities.get("ids") is Array:
		return {}
	var saved: Dictionary = section.state.regions[owner.actor.region_id]
	if saved.has("actors") or saved.has("last_safe"):
		return {}
	for region in result.sections["foundation.regions"].state.regions.values():
		if not region is Dictionary or region.has("actors") or region.has("last_safe"):
			return {}
		region["last_safe"] = {}
	saved["actors"] = {EnemyModule.SPAWN: owner.initial_state.duplicate(true)}
	result.sections["foundation.regions"].version = 2
	result.sections["core.runtime"].state.entities.ids.append(owner.initial_state.entity_id)
	return result
