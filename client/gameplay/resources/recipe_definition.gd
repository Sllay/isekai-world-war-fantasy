class_name RecipeDefinition
extends Resource

@export var recipe_id := ""
@export var display_name := ""
@export var inputs: Array[RecipeInput] = []
@export var output_definition_id := ""
@export_range(1, 10000) var output_quantity := 1
@export_range(1, 1200) var work_ticks := 16
@export var station_tag := ""
@export var tool_tag := ""
@export_range(1, 100) var minimum_tool_power := 1
@export var requires_knowledge := false

func valid(items: ItemCatalog) -> bool:
	if not CoreIds.valid(recipe_id) or display_name.is_empty() or inputs.is_empty() or inputs.size() > 8 or items.lookup(output_definition_id) == null or output_quantity < 1 or output_quantity > 10000 or work_ticks < 1 or work_ticks > 1200 or minimum_tool_power < 1 or minimum_tool_power > 100:
		return false
	if (not station_tag.is_empty() and not CoreIds.valid(station_tag)) or (not tool_tag.is_empty() and not CoreIds.valid(tool_tag)):
		return false
	var seen: Dictionary = {}
	for input in inputs:
		if input == null or not input.valid(items) or seen.has(input.slot_id):
			return false
		seen[input.slot_id] = true
	return true
