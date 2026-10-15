class_name ActionCatalog
extends RefCounted

var _definitions: Dictionary[String, ActionDefinition] = {}
var data: CoreDataRegistry

func register(definition: ActionDefinition) -> Error:
	if definition == null or not definition.valid(data):
		return ERR_INVALID_DATA
	if _definitions.has(definition.action_id):
		return ERR_ALREADY_EXISTS
	if data.register(definition.action_id, "combat.action", {"id": definition.action_id, "kind": "action"}) != OK:
		return ERR_INVALID_DATA
	_definitions[definition.action_id] = definition.duplicate(true) as ActionDefinition
	return OK

func lookup(action_id: String) -> ActionDefinition:
	var definition: ActionDefinition = _definitions.get(action_id)
	return definition.duplicate(true) as ActionDefinition if definition != null else null

func ids() -> Array[String]:
	var result := _definitions.keys()
	result.sort()
	return result

static func valid_metadata(value: Dictionary) -> Error:
	return OK if value.get("id") is String and CoreIds.valid(value.id) and value.id.begins_with("combat.action.") and value.get("kind") == "action" else ERR_INVALID_DATA
