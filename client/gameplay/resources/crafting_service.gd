class_name CraftingService
extends RefCounted

var inventory: InventoryService
var catalog: ResourceCatalog

func configure(items: InventoryService, content: ResourceCatalog) -> Error:
	if items == null or content == null or not content.valid(items.catalog):
		return ERR_INVALID_DATA
	inventory = items
	catalog = content.duplicate(true) as ResourceCatalog
	return OK

# Choices map recipe slot IDs to an available definition ID. Unspecified family
# slots choose a deterministic compatible definition; preview exposes the choice.
func preview(actor_id: String, container_id: String, recipe_id: String, choices: Dictionary = {}, station_tags: Array = [], known_recipes: Array = [], tool_definition: ItemDefinition = null) -> Dictionary:
	if inventory == null or catalog == null:
		return _failure("CRAFTING_UNCONFIGURED")
	var recipe_value := catalog.recipe(recipe_id)
	if recipe_value == null:
		return _failure("RECIPE_UNKNOWN")
	var container := inventory.snapshot(container_id)
	if container.is_empty() or container.get("owner_id") != actor_id:
		return _failure("NOT_OWNER")
	if recipe_value.requires_knowledge and not known_recipes.has(recipe_id):
		return _failure("RECIPE_NOT_KNOWN")
	if not recipe_value.station_tag.is_empty() and not station_tags.has(recipe_value.station_tag):
		return _failure("STATION_REQUIRED")
	if not recipe_value.tool_tag.is_empty():
		if tool_definition == null or not tool_definition.tool_tags.has(recipe_value.tool_tag):
			return _failure("WRONG_TOOL")
		if tool_definition.tool_power < recipe_value.minimum_tool_power:
			return _failure("TOOL_TOO_WEAK")
	var slots: Dictionary = {}
	for slot in recipe_value.inputs:
		slots[slot.slot_id] = slot
	for key in choices:
		if not key is String or not slots.has(key) or not choices[key] is String or not slots[key].accepts(inventory.catalog.lookup(choices[key])):
			return _failure("INVALID_MATERIAL_CHOICE")
	var remaining: Dictionary = {}
	var available: Array = inventory.entries(container_id)
	# Crafting prefers the lowest acceptable condition, then stable entry ID.
	available.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.condition < b.condition if a.condition != b.condition else a.id < b.id)
	for entry: Dictionary in available:
		remaining[entry.id] = entry.quantity
	var operations: Array = []
	var composition: Dictionary = {}
	var selected: Dictionary = {}
	for slot in recipe_value.inputs:
		var chosen: String = choices.get(slot.slot_id, "")
		if chosen.is_empty():
			var candidates: Array[String] = []
			for entry: Dictionary in available:
				if slot.accepts(inventory.catalog.lookup(entry.definition_id)) and entry.condition >= slot.minimum_condition and not candidates.has(entry.definition_id):
					candidates.append(entry.definition_id)
			candidates.sort()
			for candidate in candidates:
				var total := 0
				for entry: Dictionary in available:
					if entry.definition_id == candidate and entry.condition >= slot.minimum_condition:
						total += int(remaining[entry.id])
				if total >= slot.quantity:
					chosen = candidate
					break
		if chosen.is_empty():
			return _failure("MISSING_INGREDIENTS")
		var needed := slot.quantity
		for entry: Dictionary in available:
			if entry.definition_id != chosen or entry.condition < slot.minimum_condition:
				continue
			var take := mini(needed, int(remaining[entry.id]))
			if take > 0:
				operations.append({"kind": "remove", "container_id": container_id, "entry_id": entry.id, "quantity": take})
				remaining[entry.id] -= take
				needed -= take
			if needed == 0:
				break
		if needed > 0:
			return _failure("MISSING_INGREDIENTS")
		var material := inventory.catalog.lookup(chosen)
		composition[slot.slot_id] = material.material_id if not material.material_id.is_empty() else material.item_id
		selected[slot.slot_id] = chosen
	operations.append({"kind": "add", "container_id": container_id, "definition_id": recipe_value.output_definition_id, "quantity": recipe_value.output_quantity, "metadata": {"composition": composition, "provenance": {"source": "craft", "source_id": recipe_id}}})
	return {"ok": true, "code": "CRAFT_READY", "operations": operations, "composition": composition, "selected": selected, "output_definition_id": recipe_value.output_definition_id, "output_quantity": recipe_value.output_quantity, "work_ticks": recipe_value.work_ticks}

func craft(actor_id: String, container_id: String, recipe_id: String, tick: int, choices: Dictionary = {}, station_tags: Array = [], known_recipes: Array = [], tool_definition: ItemDefinition = null) -> Dictionary:
	if tick < 0:
		return _failure("INVALID_CRAFT")
	var planned := preview(actor_id, container_id, recipe_id, choices, station_tags, known_recipes, tool_definition)
	if not planned.ok:
		return planned
	var result := inventory.transact(actor_id, planned.operations)
	if not result.ok:
		return _failure(result.code)
	planned.erase("operations")
	planned.code = "CRAFTED"
	planned["revision"] = result.get("revision", 0)
	return planned

func _failure(code: String) -> Dictionary:
	return {"ok": false, "code": code}
