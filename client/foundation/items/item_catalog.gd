class_name ItemCatalog
extends RefCounted

var _definitions: Dictionary[String, ItemDefinition] = {}

func register(definition: ItemDefinition) -> Error:
	if definition == null or not definition.valid():
		return ERR_INVALID_DATA
	if _definitions.has(definition.item_id):
		return ERR_ALREADY_EXISTS
	if _definitions.size() >= 256:
		return ERR_OUT_OF_MEMORY
	_definitions[definition.item_id] = definition.duplicate(true) as ItemDefinition
	return OK

func lookup(item_id: String) -> ItemDefinition:
	var value: ItemDefinition = _definitions.get(item_id)
	return value.duplicate(true) as ItemDefinition if value != null else null

func ids() -> Array[String]:
	var result := _definitions.keys()
	result.sort()
	return result

static func defaults() -> ItemCatalog:
	var result := ItemCatalog.new()
	var content := load("res://foundation/items/item_content.tres") as ItemContent
	if content == null:
		return result
	for definition: ItemDefinition in content.items:
		if result.register(definition) != OK:
			return ItemCatalog.new()
	return result
