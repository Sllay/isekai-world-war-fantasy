class_name EntityComponents
extends RefCounted

var entity_id: String
var _components: Dictionary = {}

func _init(stable_id: String) -> void:
	entity_id = stable_id

func attach(capability_id: String, component: RefCounted) -> Error:
	if not CoreIds.valid(capability_id) or component == null or _components.has(capability_id):
		return ERR_INVALID_PARAMETER
	_components[capability_id] = component
	return OK

func capability(capability_id: String) -> RefCounted:
	return _components.get(capability_id)

func detach(capability_id: String) -> void:
	_components.erase(capability_id)
