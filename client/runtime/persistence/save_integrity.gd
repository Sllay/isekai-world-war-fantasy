class_name SaveIntegrity
extends RefCounted

const GAME_VERSION := "0.5.0"

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
	var upgraded := _upgrade_p3(_upgrade_p2(_upgrade_a1(_upgrade_enemy_release(_upgrade_legacy(snapshot)))))
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
	if registry.modules.has("gameplay.items_resources"):
		if not staged.sections.has("gameplay.items_resources"): return _reject("ITEMS_SECTION_MISSING")
		if not _items_consistent(staged, entity_id, regions): return _reject("ITEMS_CUSTODY_OR_EQUIPMENT_MISMATCH")
	if registry.modules.has("foundation.world_genesis") and not _world_consistent(staged, entity_id, regions): return _reject("GENERATED_WORLD_OR_ACTOR_MISMATCH")
	# Known finite void positions from old slots recover through the authored
	# Region contract. Gross/nonfinite corruption still fails Player validation.
	var player_state: Dictionary = staged.sections["foundation.player"].state
	var region := content.region(world.current_region_id)
	var position := Vector3(player_state.position[0], player_state.position[1], player_state.position[2])
	if not region.safe_position(position):
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
	upgraded.game_version = "0.2.0"
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
	if snapshot.get("game_version") != "0.2.0" or snapshot.modules.size() != previous.size() or not snapshot.get("sections") is Dictionary:
		return {}
	for id in previous:
		if snapshot.modules.get(id) != "1.0.0":
			return {}
	if snapshot.sections.get("foundation.regions", {}).get("version") != 1:
		return {}
	var result := snapshot.duplicate(true)
	result.game_version = "0.2.0"
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

# Only the named old release may introduce the new authored opponent. Missing
# current-release actor state is corruption, never a reason to refill defaults.
func _upgrade_a1(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty() or snapshot.get("game_version") != "0.2.0":
		return snapshot
	var owner := registry.modules.get("gameplay.enemies") as EnemyModule
	if owner == null:
		return {}
	var saved: Variant = snapshot.get("sections", {}).get("foundation.regions", {}).get("state", {}).get("regions", {}).get(owner.actor.region_id)
	var ids: Variant = snapshot.get("sections", {}).get("core.runtime", {}).get("state", {}).get("entities", {}).get("ids")
	if not saved is Dictionary or not saved.get("actors") is Dictionary or saved.actors.size() != 1 or not ids is Array or not saved.actors.has(EnemyModule.SPAWN) or not owner.actor.valid(saved.actors[EnemyModule.SPAWN]):
		return {}
	var result := snapshot.duplicate(true)
	result.game_version = "0.3.0"
	for key in owner.companion_initial:
		var added: Dictionary = owner.companion_initial[key].duplicate(true)
		if ids.has(added.entity_id):
			# Old Core may already own the new session's provisional spawn ID.
			# Allocate a fresh identity; never alias an existing canonical actor.
			added.entity_id = CoreIds.generate()
			if ids.has(added.entity_id): return {}
		result.sections["foundation.regions"].state.regions[owner.actor.region_id].actors[key] = added
		result.sections["core.runtime"].state.entities.ids.append(added.entity_id)
	return result

func _upgrade_p2(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty() or snapshot.get("game_version") != "0.3.0" or not registry.modules.has("gameplay.items_resources"): return snapshot
	if not snapshot.get("modules") is Dictionary or not snapshot.get("sections") is Dictionary or snapshot.modules.has("gameplay.items_resources") or snapshot.sections.has("gameplay.items_resources") or snapshot.modules.size() != 8: return {}
	for id in registry.modules:
		if id not in ["gameplay.items_resources", "foundation.world_genesis", "gameplay.living"] and snapshot.modules.get(id) != registry.modules[id].version: return {}
	var player: Variant = snapshot.sections.get("foundation.player", {}).get("state")
	var actors: Variant = snapshot.sections.get("foundation.regions", {}).get("state", {}).get("regions", {}).get("region.home_valley", {}).get("actors")
	if not player is Dictionary or not PlayerState.valid(player) or not actors is Dictionary or actors.size() != 2: return {}
	var enemies := registry.modules["gameplay.enemies"] as EnemyModule
	if not actors.get(EnemyModule.SPAWN) is Dictionary or not enemies.actor.valid(actors[EnemyModule.SPAWN]): return {}
	if not actors.get("spawn.melee_skirmisher_second") is Dictionary or not enemies.companions[0].valid(actors["spawn.melee_skirmisher_second"]): return {}
	var owner := registry.modules["gameplay.items_resources"] as ItemsModule
	var result := snapshot.duplicate(true)
	result.game_version = "0.4.0"
	result.modules[owner.id] = owner.version
	result.sections[owner.id] = {"version": owner.state_version, "state": owner.initial_state(player.entity_id, actors)}
	return result

func _items_consistent(staged: Dictionary, owner_id: String, regions: Dictionary) -> bool:
	var state: Dictionary = staged.sections["gameplay.items_resources"].state
	if state.owner_id != owner_id or state.equipment.owner_id != owner_id or state.skills.owner_id != owner_id: return false
	var ids: Array = staged.sections["core.runtime"].state.entities.ids
	var holders := {}
	for container: Dictionary in state.inventory.containers:
		if not ids.has(container.owner_id): return false
		holders[container.id] = container
		for entry: Dictionary in container.entries:
			if not ids.has(entry.owner_id): return false
	var actors: Dictionary = regions["region.home_valley"].actors
	for spawn: String in state.looted:
		if not actors.has(spawn) or not holders.has(ItemsModule.npc_container(spawn)): return false
		var held: Dictionary = holders[ItemsModule.npc_container(spawn)]
		if held.owner_id != actors[spawn].entity_id or state.looted[spawn] != (actors[spawn].combatant.lifecycle == Combatant.Lifecycle.DEFEATED): return false
		if state.looted[spawn] and not held.entries.is_empty(): return false
	for drop: Dictionary in state.drops.values():
		var source_position: Array = actors[drop.source].position
		# JSON numbers are doubles; actor transforms are canonical float32 Vector3.
		# Compare at that same precision after repeated disk round-trips.
		if Vector3(drop.position[0], drop.position[1], drop.position[2]) != Vector3(source_position[0], source_position[1], source_position[2]): return false
	var module := registry.modules["gameplay.items_resources"] as ItemsModule
	var ledger := InventoryService.new(module.catalog)
	ledger.restore(state.inventory)
	var gear := EquipmentState.new(owner_id)
	gear.restore(state.equipment, ledger)
	var definitions := gear.definitions(ledger)
	var bonus: int = definitions.weapon.damage_bonus if definitions.has("weapon") else 0
	var modifiers: Array = staged.sections["foundation.player_combat"].state.combatant.modifiers
	var contribution: Array = modifiers.filter(func(value: Dictionary) -> bool: return value.source_id == ItemsModule.EQUIPMENT_SOURCE)
	if bonus == 0 and not contribution.is_empty(): return false
	if bonus > 0 and (contribution.size() != 1 or contribution[0].stat != CombatModifier.Stat.DAMAGE_SCALE or contribution[0].operator != CombatModifier.Operator.ADD or contribution[0].value != bonus): return false
	for node_id: String in state.resources.nodes:
		var node: Dictionary = state.resources.nodes[node_id]
		var resource_catalog: ResourceCatalog = module.content
		var profile := resource_catalog.profile(node.profile_id)
		if node.regeneration_tick > staged.sections["core.runtime"].state.clock.tick + profile.regeneration_ticks: return false
	return true

func _upgrade_p3(snapshot: Dictionary) -> Dictionary:
	if snapshot.is_empty() or snapshot.get("game_version") != "0.4.0" or not registry.modules.has("foundation.world_genesis"): return snapshot
	if not snapshot.get("modules") is Dictionary or not snapshot.get("sections") is Dictionary or snapshot.modules.size() != 9 or snapshot.sections.size() != 6: return {}
	for id in registry.modules:
		if id in ["foundation.world_genesis", "gameplay.living"]:
			if snapshot.modules.has(id) or snapshot.sections.has(id): return {}
		elif snapshot.modules.get(id) != registry.modules[id].version: return {}
	var player: Variant = snapshot.sections.get("foundation.player", {}).get("state")
	if not player is Dictionary or not PlayerState.valid(player): return {}
	var result := snapshot.duplicate(true)
	result.game_version = GAME_VERSION
	var generation := registry.modules["foundation.world_genesis"] as WorldGenerationModule
	var living := registry.modules["gameplay.living"] as LivingModule
	for module: CoreModule in [generation, living]: result.modules[module.id] = module.version
	result.sections[generation.id] = {"version": generation.state_version, "state": {"blueprint": generation.ledger.blueprint.duplicate(true), "chunks": {}}}
	result.sections[living.id] = {"version": living.state_version, "state": living.initial_state(player.entity_id)}
	return result

func _world_consistent(snapshot: Dictionary, player_id: String, regions: Dictionary) -> bool:
	if not snapshot.sections.has("foundation.world_genesis") or not snapshot.sections.has("gameplay.living"): return false
	var generated: Dictionary = snapshot.sections["foundation.world_genesis"].state
	if generated.blueprint.world_id != snapshot.world_id or generated.blueprint.world_seed != snapshot.world_seed: return false
	for region_id: String in generated.blueprint.regions:
		if not regions.has(region_id): return false
	var placement := WorldGenerationModule.placements(generated)
	var resources: Dictionary = snapshot.sections["gameplay.items_resources"].state.resources.nodes
	for node_id: String in resources:
		if not placement.has(node_id): return false
		var node: Dictionary = resources[node_id]
		var authored: Dictionary = placement[node_id]
		if node.profile_id != authored.profile_id or node.region_id != authored.region_id or Vector3(node.position[0], node.position[1], node.position[2]) != Vector3(authored.position_mm[0], authored.position_mm[1], authored.position_mm[2]) / 1000.0: return false
	var ids: Array = snapshot.sections["core.runtime"].state.entities.ids
	var valid_actor := func(id_value: String) -> bool: return ids.has(id_value)
	var known_sources := placement.duplicate()
	var spawns := {}
	var claims := {}
	for record: Dictionary in generated.chunks.values():
		for landmark: Dictionary in record.base.landmarks: known_sources[landmark.id] = true
		for spawn: Dictionary in record.base.spawns:
			if spawns.has(spawn.actor_id): return false
			spawns[spawn.actor_id] = spawn
			if record.delta.spawn_claims.has(spawn.spawn_id): claims[spawn.actor_id] = true
		for removed: String in record.delta.removed_resources:
			if not resources.has(removed) or resources[removed].remaining != 0: return false
	var item_content := ResourceCatalog.defaults()
	for recipe in item_content.recipes: known_sources[recipe.recipe_id] = true
	var valid_source := func(id_value: String) -> bool: return ids.has(id_value) or known_sources.has(id_value)
	var state: Dictionary = snapshot.sections["gameplay.living"].state
	var living := registry.modules["gameplay.living"] as LivingModule
	var rpg_catalog: LivingCatalog = living.catalog
	var identity_class: ClassDefinition = rpg_catalog.character_class(state.player.class_id)
	var progression: ProgressionDefinition = rpg_catalog.progression(identity_class.progression_id)
	if state.player.id != player_id or not LivingProgression.valid(state.player.progression, progression, valid_source): return false
	if state.actors.size() != claims.size(): return false
	var occupied := {player_id: true}
	for region: Dictionary in regions.values():
		for actor: Dictionary in region.get("actors", {}).values(): occupied[actor.entity_id] = true
	for key: String in state.actors:
		var actor: Dictionary = state.actors[key].state
		if occupied.has(key) or not ids.has(key) or not claims.has(key) or not spawns.has(key) or not LivingActorState.valid(actor, living.catalog, valid_actor, valid_source): return false
		occupied[key] = true
		if actor.world_id != snapshot.world_id or actor.region_id != spawns[key].region_id or actor.region_id not in regions: return false
		if actor.kind != ("bot" if spawns[key].profile_id == "spawn.profile.traveler_bot" else "npc"): return false
		if actor.inventory_id != "inventory.actor.a" + key or actor.equipment_id != "equipment.actor.a" + key: return false
		var position: Array = actor.movement.position
		var definition := content.region(actor.region_id)
		var point := Vector3(position[0], position[1], position[2])
		var cell := definition.chunk_at(definition.to_local_position(point))
		if actor.chunk_id != WorldGenIds.chunk(actor.region_id, cell) or not WorldBlueprint.contains(generated.blueprint, cell, actor.region_id) or not definition.safe_position(point): return false
		var activity_points: Array = [actor.home, actor.work]
		if not actor.activity.is_empty(): activity_points.append_array([actor.activity.origin, actor.activity.destination])
		for saved_point: Array in activity_points:
			var location := Vector3(saved_point[0], saved_point[1], saved_point[2])
			if not definition.safe_position(location) or not WorldBlueprint.contains(generated.blueprint, definition.chunk_at(definition.to_local_position(location)), actor.region_id): return false
		for container: Dictionary in state.actors[key].inventory.containers:
			for entry: Dictionary in container.entries:
				if not ids.has(entry.owner_id): return false
	return true
