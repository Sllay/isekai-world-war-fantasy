class_name LearnedSkillSet
extends RefCounted

# Permanent learning and temporary equipment grants are separate source records.
const MAX_ACTIONS := 64
const MAX_SOURCES := 16
var owner_id: String
var _known := {}
var _grants := {}

func _init(owner := "") -> void:
	owner_id = owner

func learn(action_id: String, source_id: String, catalog: ActionCatalog) -> Error:
	return _add(_known, action_id, source_id, catalog)

func grant(action_id: String, source_id: String, catalog: ActionCatalog) -> Error:
	return _add(_grants, action_id, source_id, catalog)

func revoke_source(source_id: String) -> void:
	# Revoking an item never erases abilities independently learned from the world.
	for action_id: String in _grants.keys():
		_grants[action_id].erase(source_id)
		if _grants[action_id].is_empty():
			_grants.erase(action_id)

func known_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_known.keys())
	result.sort()
	return result

func available_ids() -> Array[String]:
	var result := known_ids()
	for action_id: String in _grants:
		if not result.has(action_id):
			result.append(action_id)
	result.sort()
	return result

func eligible(action_id: String, catalog: ActionCatalog) -> bool:
	return catalog != null and catalog.lookup(action_id) != null and (_known.has(action_id) or _grants.has(action_id))

func validate_loadout(value: ActionLoadout, catalog: ActionCatalog) -> Error:
	if value == null or catalog == null or not value.valid(catalog):
		return ERR_INVALID_DATA
	for slot: String in ActionLoadout.SLOTS:
		if not value.slots[slot].is_empty() and not eligible(value.slots[slot], catalog):
			return ERR_UNAUTHORIZED
	return OK

func capture() -> Dictionary:
	return {"version": 1, "owner_id": owner_id, "known": _sorted(_known), "grants": _sorted(_grants)}

func validate_state(value: Dictionary, catalog: ActionCatalog) -> Error:
	if catalog == null or not InventoryService._keys(value, ["version", "owner_id", "known", "grants"]) or value.version != 1 or not InventoryService._identity(value.owner_id) or (not owner_id.is_empty() and value.owner_id != owner_id):
		return ERR_INVALID_DATA
	var all := {}
	for name: String in ["known", "grants"]:
		if not value[name] is Dictionary or value[name].size() > MAX_ACTIONS:
			return ERR_INVALID_DATA
		for action_id: Variant in value[name]:
			if not action_id is String or catalog.lookup(action_id) == null or not value[name][action_id] is Array or value[name][action_id].is_empty() or value[name][action_id].size() > MAX_SOURCES:
				return ERR_INVALID_DATA
			all[action_id] = true
			var seen := {}
			for source: Variant in value[name][action_id]:
				if not source is String or source.length() > 128 or not CoreIds.valid(source) or seen.has(source):
					return ERR_INVALID_DATA
				seen[source] = true
	return OK if all.size() <= MAX_ACTIONS else ERR_INVALID_DATA

func restore(value: Dictionary, catalog: ActionCatalog) -> Error:
	if validate_state(value, catalog) != OK:
		return ERR_INVALID_DATA
	owner_id = value.owner_id
	_known = _sorted(value.known)
	_grants = _sorted(value.grants)
	return OK

func _add(target: Dictionary, action_id: String, source_id: String, catalog: ActionCatalog) -> Error:
	if catalog == null or catalog.lookup(action_id) == null or source_id.length() > 128 or not CoreIds.valid(source_id):
		return ERR_INVALID_PARAMETER
	if target.has(action_id) and target[action_id].has(source_id):
		return ERR_ALREADY_EXISTS
	if not available_ids().has(action_id) and available_ids().size() >= MAX_ACTIONS:
		return ERR_OUT_OF_MEMORY
	if target.has(action_id) and target[action_id].size() >= MAX_SOURCES:
		return ERR_OUT_OF_MEMORY
	if not target.has(action_id):
		target[action_id] = []
	target[action_id].append(source_id)
	target[action_id].sort()
	return OK

func _sorted(value: Dictionary) -> Dictionary:
	var result := {}
	var ids := value.keys()
	ids.sort()
	for id: String in ids:
		var sources: Array = value[id].duplicate()
		sources.sort()
		result[id] = sources
	return result
