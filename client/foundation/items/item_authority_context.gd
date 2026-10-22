class_name ItemAuthorityContext
extends RefCounted

# Actor-owned capability composition shared by humans and authority-controlled
# Bots. It references the same domains; it is not another inventory or executor.
var catalog: ItemCatalog
var bag_id := "inventory.player.bag"
var stash_id := "inventory.player.stash"
var content: ResourceCatalog
var inventory: InventoryService
var equipment: EquipmentState
var skills: LearnedSkillSet
var resources: ResourceService
var crafting: CraftingService
var loadout: ActionLoadout
var known_recipes: Array[String] = []
var drops: Dictionary = {}
var player: PlayerState
var combat: CombatService
var actions: ActionCatalog
var changed: Callable
var snapshot: Callable
var loadout_changed: Callable
# Optional authority-owned eligibility policy. Foundation remains independent of
# RPG classes; composition supplies a validated definition/capability predicate.
var equipment_eligibility: Callable

func touch(code: String) -> void:
	if changed.is_valid(): changed.call(code)

func state_view() -> Dictionary:
	return snapshot.call() if snapshot.is_valid() else {"inventory": inventory.capture(), "equipment": equipment.capture(), "skills": skills.capture()}

func set_loadout(value: ActionLoadout) -> void:
	loadout = value
	if loadout_changed.is_valid(): loadout_changed.call(value)

func tool() -> ItemDefinition:
	var slots: Dictionary = equipment.capture().slots
	if not slots.has("tool"): return null
	var entry := inventory.entry(slots.tool.container_id, slots.tool.entry_id)
	return null if entry.is_empty() or entry.condition <= 0 else catalog.lookup(entry.definition_id)

func dispose() -> void:
	changed = Callable()
	snapshot = Callable()
	loadout_changed = Callable()
	equipment_eligibility = Callable()
