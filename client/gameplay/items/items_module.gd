class_name ItemsModule
extends CoreModule

const BAG := "inventory.player.bag"
const STASH := "inventory.player.stash"
const EQUIPMENT_SOURCE := "items.equipment.weapon"
const FORGE := "station.home_forge"
const FORGE_POSITION := Vector3(-8, 0, 9)
var catalog := ItemCatalog.defaults()
var content := ResourceCatalog.defaults()
var inventory: InventoryService
var equipment: EquipmentState
var skills: LearnedSkillSet
var resources := ResourceService.new()
var crafting := CraftingService.new()
var loadout: ActionLoadout
var known_recipes: Array[String] = []
var drops: Dictionary = {}
var looted: Dictionary = {}
var revision := 0
var last_result := "READY"
var player: PlayerState
var combat: CombatService
var actions: ActionCatalog
var enemies: EnemyModule
var world: WorldDefinition
var capabilities: EntityComponents
var _defeat_token := -1

func _init() -> void:
	id = "gameplay.items_resources"
	requires.assign(["foundation.player", "foundation.combat", "foundation.player_combat", "gameplay.enemies"])
	persistent = true
	consumed_events.assign(["combat.combatant_defeated"])
	published_events.assign(["items.operation_resolved", "items.work_committed"])

func initialize(services: CoreServices) -> Error:
	player = services.resolve("foundation.player") as PlayerState
	combat = services.resolve("foundation.combat") as CombatService
	actions = services.resolve("foundation.actions") as ActionCatalog
	capabilities = services.resolve("foundation.player_capabilities") as EntityComponents
	# Actor stock is composed explicitly by the application after boot.
	if player == null or combat == null or actions == null or not content.valid(catalog): return ERR_INVALID_DATA
	for profile in content.node_profiles:
		if _register_work(harvest_action(profile.profile_id), profile.work_ticks, "items.effect.harvest") != OK: return ERR_INVALID_DATA
	for recipe in content.recipes:
		if _register_work(craft_action(recipe.recipe_id), recipe.work_ticks, "items.effect.craft") != OK: return ERR_INVALID_DATA
	if _register_work("combat.action.consume", 4, "items.effect.consume") != OK: return ERR_INVALID_DATA
	inventory = InventoryService.new(catalog)
	resources.configure(inventory, content)
	crafting.configure(inventory, content)
	var error := combat.events.define(ItemOperationResolved)
	return combat.events.define(ItemWorkCommitted) if error == OK else error

func bind(actors: EnemyModule, definition: WorldDefinition) -> void:
	enemies = actors
	world = definition
	resources.world_seed = world.world_seed
	_defeat_token = combat.events.subscribe(CombatantDefeated, _defeated)

func _register_work(action_id: String, ticks: int, capability: String) -> Error:
	var definition := ActionDefinition.new()
	definition.action_id = action_id
	definition.cast_ticks = ticks
	definition.recovery_ticks = 3
	definition.cooldown_ticks = 5
	definition.cast_while_moving = false
	var effect := ActionEffect.new()
	effect.kind = ActionEffect.Kind.CAPABILITY
	effect.capability_id = capability
	definition.effects.assign([effect])
	return actions.register(definition)

static func harvest_action(profile: String) -> String:
	return "combat.action.harvest_" + profile.replace(".", "_")

static func craft_action(recipe: String) -> String:
	return "combat.action.craft_" + recipe.replace(".", "_")

static func npc_container(spawn: String) -> String:
	return "inventory." + spawn

func actor_map() -> Dictionary:
	var result := {}
	for key: String in enemies.record.actors:
		var actor: RegionActorState = enemies.record.actors[key]
		if actor is EnemyActor: result[key] = actor.capture()
	return result

# Only fresh worlds or the explicit old-release migration call this. Never restore.
func initial_state(owner: String, actor_states: Dictionary) -> Dictionary:
	var ledger := InventoryService.new(catalog)
	ledger.register_container(BAG, owner, 24, 50000)
	ledger.register_container(STASH, owner, 48, 200000)
	for item in ["item.weapon.sword", "item.tool.axe", "item.tool.pickaxe", "item.armor.leather"]:
		ledger.add(owner, BAG, item, 1, {"provenance": {"source": "starting", "source_id": "items.starting.traveler"}})
	var gear := EquipmentState.new(owner)
	for entry: Dictionary in ledger.entries(BAG):
		var definition := catalog.lookup(entry.definition_id)
		if definition.equipment_slot in ["weapon", "armor"] or entry.definition_id == "item.tool.axe":
			gear.equip(definition.equipment_slot, BAG, entry.id, ledger)
	var known := LearnedSkillSet.new(owner)
	for action in ["combat.action.basic_strike", "combat.action.strong_strike", "combat.action.basic_heal"]:
		known.learn(action, "skill.source.starting", actions)
	var collected := {}
	var tombstones := {}
	for spawn: String in actor_states:
		var actor: Dictionary = actor_states[spawn]
		ledger.register_container(npc_container(spawn), actor.entity_id, 16, 50000)
		var dead: bool = actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED
		collected[spawn] = dead
		if dead:
			# Old-release deaths have no invented stock. An empty claimed tombstone
			# makes deletion/duplication checks unambiguous on all later saves.
			var key := "drop." + spawn
			ledger.register_container("inventory." + key, owner, 16, 50000)
			tombstones[key] = {"source": spawn, "container": "inventory." + key, "owner": owner, "position": actor.position.duplicate(), "region": actor.region_id, "claimed": true}
		else:
			var stock := LootResolver.resolve(content.loot("loot.actor.skirmisher_initial"), ("%d:%s" % [world.world_seed, spawn]).hash(), catalog)
			for output: Dictionary in stock.outputs:
				ledger.add(actor.entity_id, npc_container(spawn), output.definition_id, output.quantity, {"provenance": {"source": "initial_stock", "source_id": spawn}})
	var nodes := ResourceService.new()
	nodes.configure(ledger, content, world.world_seed)
	var base := preload("res://data/actions/player_loadout.tres") as ActionLoadout
	return {"owner_id": owner, "inventory": ledger.capture(), "equipment": gear.capture(), "skills": known.capture(), "loadout": {"id": base.loadout_id, "slots": base.slots.duplicate()}, "resources": nodes.capture(), "recipes": ["recipe.healing_balm", "recipe.iron_ingot", "recipe.camp_axe", "recipe.tempered_sword"], "drops": tombstones, "looted": collected, "revision": 0}

func capture_state() -> Dictionary:
	return {"owner_id": player.entity_id, "inventory": inventory.capture(), "equipment": equipment.capture(), "skills": skills.capture(), "loadout": {"id": loadout.loadout_id, "slots": loadout.slots.duplicate()}, "resources": resources.capture(), "recipes": known_recipes.duplicate(), "drops": drops.duplicate(true), "looted": looted.duplicate(), "revision": revision}

func validate_state(value: Dictionary) -> Error:
	if not InventoryService._keys(value, ["owner_id", "inventory", "equipment", "skills", "loadout", "resources", "recipes", "drops", "looted", "revision"]) or not CombatNumbers.stable_entity(value.owner_id) or not CombatNumbers.integer(value.revision, 0, CombatNumbers.MAX_UNITS): return ERR_INVALID_DATA
	for key in ["inventory", "equipment", "skills", "loadout", "resources", "drops", "looted"]:
		if not value[key] is Dictionary: return ERR_INVALID_DATA
	var ledger := InventoryService.new(catalog)
	if ledger.restore(value.inventory) != OK or EquipmentState.new(value.owner_id).validate_state(value.equipment, ledger) != OK or LearnedSkillSet.new(value.owner_id).validate_state(value.skills, actions) != OK or not resources.validate_state(value.resources): return ERR_INVALID_DATA
	for container in [BAG, STASH]:
		if ledger.snapshot(container).get("owner_id") != value.owner_id: return ERR_INVALID_DATA
	if not InventoryService._keys(value.loadout, ["id", "slots"]) or not value.loadout.id is String or not value.loadout.slots is Dictionary: return ERR_INVALID_DATA
	var equipped := ActionLoadout.new()
	equipped.loadout_id = value.loadout.id
	for slot: Variant in value.loadout.slots:
		if not slot is String or not value.loadout.slots[slot] is String: return ERR_INVALID_DATA
		equipped.slots[slot] = value.loadout.slots[slot]
	var known := LearnedSkillSet.new(value.owner_id)
	known.restore(value.skills, actions)
	if known.validate_loadout(equipped, actions) != OK or not value.recipes is Array or value.recipes.size() > content.recipes.size(): return ERR_INVALID_DATA
	var seen := {}
	for recipe: Variant in value.recipes:
		if not recipe is String or content.recipe(recipe) == null or seen.has(recipe): return ERR_INVALID_DATA
		seen[recipe] = true
	if value.looted.size() != 2 or value.drops.size() > 2: return ERR_INVALID_DATA
	for spawn: Variant in value.looted:
		if spawn not in [EnemyModule.SPAWN, "spawn.melee_skirmisher_second"] or not value.looted[spawn] is bool: return ERR_INVALID_DATA
		if value.looted[spawn] != value.drops.has("drop." + str(spawn)): return ERR_INVALID_DATA
	var expected: Array = [BAG, STASH]
	for spawn: String in value.looted: expected.append(npc_container(spawn))
	for key: String in value.drops: expected.append("inventory." + key)
	if value.inventory.containers.size() != expected.size(): return ERR_INVALID_DATA
	for container: Dictionary in value.inventory.containers:
		if container.id not in expected or container.capacity_mode != "FIXED_SLOTS": return ERR_INVALID_DATA
		var slots := 24 if container.id == BAG else (48 if container.id == STASH else 16)
		var mass := 200000 if container.id == STASH else 50000
		if container.slots != slots or container.max_mass_grams != mass: return ERR_INVALID_DATA
	var expected_skills := LearnedSkillSet.new(value.owner_id)
	for slot: String in EquipmentState.SLOTS:
		if not value.equipment.slots.has(slot): continue
		var item_ref: Dictionary = value.equipment.slots[slot]
		var definition := catalog.lookup(ledger.entry(item_ref.container_id, item_ref.entry_id).definition_id)
		for action: String in definition.granted_skills: expected_skills.grant(action, "skill.source.equipment_" + slot, actions)
	if expected_skills.capture().grants != value.skills.grants: return ERR_INVALID_DATA
	for key: Variant in value.drops:
		var drop: Variant = value.drops[key]
		if not drop is Dictionary or not InventoryService._keys(drop, ["source", "container", "owner", "position", "region", "claimed"]) or key != "drop." + str(drop.source) or drop.source not in value.looted or not value.looted[drop.source] or drop.owner != value.owner_id or drop.container != "inventory." + str(key) or drop.region != "region.home_valley" or not drop.claimed is bool or not drop.position is Array or drop.position.size() != 3: return ERR_INVALID_DATA
		for number: Variant in drop.position:
			if not (number is int or number is float) or not is_finite(number) or absf(number) > 10000: return ERR_INVALID_DATA
		var held := ledger.snapshot(drop.container)
		if held.get("owner_id") != value.owner_id or (drop.claimed and not held.entries.is_empty()): return ERR_INVALID_DATA
	return OK

func restore_state(value: Dictionary) -> void:
	inventory.restore(value.inventory)
	equipment = EquipmentState.new(value.owner_id)
	equipment.restore(value.equipment, inventory)
	skills = LearnedSkillSet.new(value.owner_id)
	skills.restore(value.skills, actions)
	loadout = ActionLoadout.new()
	loadout.loadout_id = value.loadout.id
	loadout.slots.assign(value.loadout.slots)
	resources.restore(value.resources)
	known_recipes.assign(value.recipes)
	drops = value.drops.duplicate(true)
	# Canonical positions have the same Vector3 precision/type as their actor.
	# JSON/page codecs may normalize integral floats to integers; raw arrays must
	# not make an otherwise unchanged drop differ after save/resume.
	for drop: Dictionary in drops.values():
		var point := Vector3(drop.position[0], drop.position[1], drop.position[2])
		drop.position = [point.x, point.y, point.z]
	looted = value.looted.duplicate()
	revision = int(value.revision)
	last_result = "RESTORED"
	if capabilities != null:
		for key in ["foundation.inventory", "foundation.equipment", "foundation.skills"]: capabilities.detach(key)
		capabilities.attach("foundation.inventory", inventory)
		capabilities.attach("foundation.equipment", equipment)
		capabilities.attach("foundation.skills", skills)

func _defeated(fact: CombatantDefeated) -> void:
	for spawn: String in actor_map():
		var actor: Dictionary = actor_map()[spawn]
		if actor.entity_id != fact.target_entity or looted.get(spawn, true): continue
		var key := "drop." + spawn
		var container := "inventory." + key
		var previous := inventory.capture()
		if inventory.register_container(container, player.entity_id, 16, 50000) != OK: return
		var operations: Array = []
		for entry: Dictionary in inventory.entries(npc_container(spawn)):
			operations.append({"kind": "transfer", "source_id": npc_container(spawn), "destination_id": container, "entry_id": entry.id, "quantity": entry.quantity})
		if not operations.is_empty() and not inventory.transact(fact.target_entity, operations).ok:
			inventory.restore(previous)
			return
		looted[spawn] = true
		drops[key] = {"source": spawn, "container": container, "owner": player.entity_id, "position": actor.position.duplicate(), "region": actor.region_id, "claimed": operations.is_empty()}
		touch("LOOT_AVAILABLE")

func touch(code: String) -> void:
	revision += 1
	last_result = code
	var fact := ItemOperationResolved.new()
	fact.tick = combat.clock.tick
	fact.owner_id = player.entity_id
	fact.code = code
	fact.revision = revision
	combat.events.publish(fact)

func tool() -> ItemDefinition:
	var references: Dictionary = equipment.capture().slots
	if not references.has("tool"): return null
	var entry := inventory.entry(references.tool.container_id, references.tool.entry_id)
	if entry.is_empty() or entry.condition <= 0: return null
	return catalog.lookup(entry.definition_id)

func authority_context() -> ItemAuthorityContext:
	var context := ItemAuthorityContext.new()
	context.catalog = catalog
	context.content = content
	context.inventory = inventory
	context.equipment = equipment
	context.skills = skills
	context.resources = resources
	context.crafting = crafting
	context.loadout = loadout
	context.known_recipes = known_recipes
	context.drops = drops
	context.player = player
	context.combat = combat
	context.actions = actions
	context.changed = touch
	context.snapshot = state_view
	context.loadout_changed = func(value: ActionLoadout) -> void: loadout = value
	return context

func state_view() -> Dictionary:
	var nodes := {}
	for node in content.nodes: nodes[node.node_id] = resources.snapshot(node.node_id, combat.clock.tick)
	return {"revision": revision, "inventory": inventory.snapshot(BAG), "stash": inventory.snapshot(STASH), "equipment": equipment.capture(), "skills": skills.capture(), "drops": drops.duplicate(true), "nodes": nodes, "result": last_result}

func dispose() -> void:
	if combat != null and _defeat_token >= 0: combat.events.unsubscribe(_defeat_token)
	if capabilities != null:
		for key in ["foundation.inventory", "foundation.equipment", "foundation.skills"]: capabilities.detach(key)
	enemies = null
