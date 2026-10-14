class_name CoreServices
extends RefCounted

var _entries: Dictionary = {}
var _owner: CoreModule
var _requires: Array[String] = []
var _optional: Array[String] = []

func enter(module: CoreModule) -> void:
	_owner = module
	_requires = module.requires.duplicate()
	_optional = module.optional.duplicate()

func leave() -> void:
	_owner = null
	_requires.clear()
	_optional.clear()

func provide(id: String, service: RefCounted) -> Error:
	if _owner == null or id not in _owner.provides or service == null or _entries.has(id):
		return ERR_INVALID_PARAMETER
	_entries[id] = {"owner": _owner.id, "service": service}
	return OK

func resolve(id: String) -> RefCounted:
	if _owner == null or not _entries.has(id):
		return null
	var entry: Dictionary = _entries[id]
	if entry.owner != _owner.id and entry.owner not in _requires and entry.owner not in _optional:
		return null
	return entry.service

func inspect() -> Array:
	return _entries.keys()

func clear() -> void:
	leave()
	_entries.clear()
