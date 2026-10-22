class_name LivingCapabilities
extends RefCounted

var state: LivingActorState
var combatant: Combatant
var actions: ActionExecutor
var items := ItemAuthorityContext.new()
var components: EntityComponents
var character_class: ClassDefinition

func configure(actor: LivingActorState, combat: CombatService, action_catalog: ActionCatalog, item_catalog: ItemCatalog, resource_catalog: ResourceCatalog, resources: ResourceService, class_definition: ClassDefinition = null) -> void:
	state = actor
	var selected_class: ClassDefinition = class_definition
	if selected_class == null:
		var living_catalog := LivingCatalog.defaults()
		selected_class = living_catalog.character_class(actor.class_id)
	assert(selected_class != null and selected_class.class_id == actor.class_id and selected_class.valid())
	character_class = selected_class.duplicate(true) as ClassDefinition
	combatant = combat.combatant(actor.actor_id)
	if combatant == null: combatant = combat.register(actor.actor_id, PlayerCombatModule.PROFILE_ID)
	actions = ActionExecutor.new(combat, action_catalog, actor.actor_id)
	items.player = actor.player_state
	items.combat = combat
	items.actions = action_catalog
	items.catalog = item_catalog
	items.content = resource_catalog
	items.resources = resources
	items.bag_id = actor.inventory_id
	items.stash_id = actor.inventory_id + ".storage"
	items.inventory = InventoryService.new(item_catalog)
	items.inventory.register_container(items.bag_id, actor.actor_id, 24, 50000)
	items.inventory.register_container(items.stash_id, actor.actor_id, 48, 200000)
	items.equipment = EquipmentState.new(actor.actor_id)
	items.skills = LearnedSkillSet.new(actor.actor_id)
	items.crafting = CraftingService.new()
	items.crafting.configure(items.inventory, resource_catalog)
	items.loadout = (load("res://data/actions/player_loadout.tres") as ActionLoadout).duplicate(true) as ActionLoadout
	items.known_recipes.assign(["recipe.healing_balm", "recipe.iron_ingot", "recipe.camp_axe", "recipe.tempered_sword"])
	var seeded := character_class.seed_skills(items.skills, action_catalog)
	assert(seeded == OK, "Validated class starting actions must resolve in the Action catalog")
	for slot: String in ["skill_1", "skill_2", "skill_3"]:
		if not items.loadout.slots[slot].is_empty() and not items.skills.eligible(items.loadout.slots[slot], action_catalog): items.loadout.slots[slot] = ""
	bind_item_eligibility()
	components = EntityComponents.new(actor.actor_id)
	components.attach("foundation.movement", actor.player_state)
	components.attach("foundation.combatant", combatant)
	components.attach("foundation.actions", actions)
	components.attach("foundation.inventory", items.inventory)
	components.attach("foundation.equipment", items.equipment)
	components.attach("foundation.skills", items.skills)
	components.attach("foundation.memory", actor.memory)

# A transient ItemsAuthorityPort clears callbacks when it dematerializes. The
# next host attachment reinstalls this predicate from persistent class identity.
func bind_item_eligibility() -> void:
	items.equipment_eligibility = character_class.allows_equipment

func seed_stock() -> void:
	for id in ["item.weapon.sword", "item.tool.axe", "item.tool.pickaxe", "item.consumable.healing_balm"]:
		items.inventory.add(state.actor_id, items.bag_id, id, 1, {"provenance": {"source": "initial_stock", "source_id": "spawn.profile.traveler_bot" if state.kind == "bot" else "spawn.profile.villager"}})
	for entry: Dictionary in items.inventory.entries(items.bag_id):
		var definition := items.catalog.lookup(entry.definition_id)
		if character_class.allows_equipment(definition) and (definition.equipment_slot == "weapon" or entry.definition_id == "item.tool.axe"): items.equipment.equip(definition.equipment_slot, items.bag_id, entry.id, items.inventory)

func capture() -> Dictionary:
	return {"state": state.capture(), "combatant": combatant.capture(), "actions": actions.capture(), "inventory": items.inventory.capture(), "equipment": items.equipment.capture(), "skills": items.skills.capture(), "loadout": {"id": items.loadout.loadout_id, "slots": items.loadout.slots.duplicate()}}

static func valid(value: Dictionary, catalog: LivingCatalog, item_catalog: ItemCatalog, action_catalog: ActionCatalog, combat: CombatService, known_actor: Callable, known_source: Callable) -> bool:
	if not InventoryService._keys(value, ["state", "combatant", "actions", "inventory", "equipment", "skills", "loadout"]): return false
	for key: String in value:
		if not value[key] is Dictionary: return false
	if not LivingActorState.valid(value.state, catalog, known_actor, known_source) or value.state.kind not in ["npc", "bot"]: return false
	var owner: String = value.state.id
	if value.combatant.get("profile_id") != PlayerCombatModule.PROFILE_ID or not Combatant.valid(value.combatant, combat.data.lookup(PlayerCombatModule.PROFILE_ID)): return false
	var trial_actions := ActionExecutor.new(combat, action_catalog, owner)
	if not trial_actions.valid_snapshot(value.actions): return false
	var ledger := InventoryService.new(item_catalog)
	if ledger.restore(value.inventory) != OK or value.inventory.containers.size() != 2: return false
	for container: Dictionary in value.inventory.containers:
		if container.id not in [value.state.inventory_id, value.state.inventory_id + ".storage"] or container.owner_id != owner: return false
		if container.slots != (24 if container.id == value.state.inventory_id else 48) or container.max_mass_grams != (50000 if container.id == value.state.inventory_id else 200000): return false
	if EquipmentState.new(owner).validate_state(value.equipment, ledger) != OK or LearnedSkillSet.new(owner).validate_state(value.skills, action_catalog) != OK: return false
	var equipment := EquipmentState.new(owner)
	equipment.restore(value.equipment, ledger)
	var class_data := catalog.character_class(value.state.class_id)
	for definition: ItemDefinition in equipment.definitions(ledger).values():
		if not class_data.allows_equipment(definition): return false
	if not InventoryService._keys(value.loadout, ["id", "slots"]) or not value.loadout.id is String or not value.loadout.slots is Dictionary: return false
	var loadout := ActionLoadout.new()
	loadout.loadout_id = value.loadout.id
	for key: Variant in value.loadout.slots:
		if not key is String or not value.loadout.slots[key] is String: return false
		loadout.slots[key] = value.loadout.slots[key]
	var skills := LearnedSkillSet.new(owner)
	skills.restore(value.skills, action_catalog)
	return skills.validate_loadout(loadout, action_catalog) == OK

func restore(value: Dictionary, catalog: LivingCatalog, known_actor: Callable, known_source: Callable) -> void:
	state.restore(value.state, catalog, known_actor, known_source)
	actions.combat.restore_owned(combatant, state.actor_id, value.combatant)
	actions.restore(value.actions)
	items.inventory.restore(value.inventory)
	items.equipment.restore(value.equipment, items.inventory)
	items.skills.restore(value.skills, items.actions)
	items.loadout.loadout_id = value.loadout.id
	items.loadout.slots.assign(value.loadout.slots)

func dispose() -> void:
	items.dispose()
	actions.capability_port = null
	actions.position_of = Callable()
	actions.target_gate = Callable()
	actions.activation_gate = Callable()
	actions.mobility_gate = Callable()
