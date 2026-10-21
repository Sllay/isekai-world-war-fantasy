class_name RecipeInput
extends Resource

@export var slot_id := ""
@export var definition_id := ""
@export var family_tag := ""
@export_range(1, 10000) var quantity := 1
@export_range(0, 10000) var minimum_condition := 0

func valid(items: ItemCatalog) -> bool:
	return CoreIds.valid(slot_id) and quantity >= 1 and quantity <= 10000 and minimum_condition >= 0 and minimum_condition <= 10000 and ((not definition_id.is_empty() and items.lookup(definition_id) != null and family_tag.is_empty()) or (definition_id.is_empty() and CoreIds.valid(family_tag)))

func accepts(definition: ItemDefinition) -> bool:
	return definition != null and (definition.item_id == definition_id if not definition_id.is_empty() else definition.tags.has(family_tag))
