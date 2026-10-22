class_name LivingMemory
extends RefCounted

const ORDINARY_CAP := 8
const ANCHOR_CAP := 2
var _records: Dictionary = {}

func remember(record: Dictionary, tick: int, known_subject: Callable) -> String:
	if not _record_valid(record, known_subject) or record.created_tick > tick or tick < 0: return "INVALID_MEMORY"
	prune(tick)
	if _records.has(record.id): return "DUPLICATE_MEMORY"
	var anchors: bool = record.anchor
	var matching: Array = []
	for previous: Dictionary in _records.values():
		if previous.anchor == anchors: matching.append(previous)
	var cap := ANCHOR_CAP if anchors else ORDINARY_CAP
	if matching.size() >= cap:
		matching.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if a.importance != b.importance: return a.importance < b.importance
			return a.created_tick < b.created_tick if a.created_tick != b.created_tick else a.id < b.id)
		if record.importance < matching[0].importance: return "MEMORY_LOW_PRIORITY"
		_records.erase(matching[0].id)
	_records[record.id] = _canonical(record)
	return "REMEMBERED"

func prune(tick: int) -> void:
	for id: String in _records.keys():
		if _records[id].expires_tick >= 0 and _records[id].expires_tick <= tick: _records.erase(id)

func strongest(kind: String, tick: int) -> Dictionary:
	var result := {}
	for record: Dictionary in _records.values():
		if record.kind != kind or (record.expires_tick >= 0 and record.expires_tick <= tick): continue
		if result.is_empty() or record.importance > result.importance or (record.importance == result.importance and record.created_tick > result.created_tick): result = record
	return result.duplicate(true)

func capture() -> Dictionary:
	var records: Array = []
	var ids := _records.keys()
	ids.sort()
	for id: String in ids: records.append(_records[id].duplicate(true))
	return {"records": records}

static func valid(state: Dictionary, known_subject: Callable) -> bool:
	if not InventoryService._keys(state, ["records"]) or not state.records is Array or state.records.size() > ORDINARY_CAP + ANCHOR_CAP: return false
	var seen := {}
	var anchors := 0
	for record: Variant in state.records:
		if not record is Dictionary or not _record_valid(record, known_subject) or seen.has(record.id): return false
		seen[record.id] = true
		if record.anchor: anchors += 1
	return anchors <= ANCHOR_CAP and state.records.size() - anchors <= ORDINARY_CAP

func restore(state: Dictionary, known_subject: Callable) -> Error:
	if not valid(state, known_subject): return ERR_INVALID_DATA
	_records.clear()
	for record: Dictionary in state.records: _records[record.id] = _canonical(record)
	return OK

static func _canonical(record: Dictionary) -> Dictionary:
	var result := record.duplicate(true)
	for key: String in ["created_tick", "importance", "confidence", "expires_tick"]: result[key] = int(result[key])
	var point := Vector3(record.position[0], record.position[1], record.position[2])
	result.position = [point.x, point.y, point.z]
	return result

static func _record_valid(record: Dictionary, known_subject: Callable) -> bool:
	if not InventoryService._keys(record, ["id", "kind", "subject_id", "position", "created_tick", "importance", "confidence", "expires_tick", "source", "anchor"]): return false
	for field: String in ["id", "kind", "source"]:
		if not record[field] is String or record[field].length() > 96 or not CoreIds.valid(record[field]): return false
	if not record.subject_id is String or not CombatNumbers.stable_entity(record.subject_id) or not known_subject.is_valid() or not bool(known_subject.call(record.subject_id)): return false
	if not record.position is Array or record.position.size() != 3 or not record.anchor is bool: return false
	for number: Variant in record.position:
		if not (number is float or number is int) or not is_finite(number) or absf(number) > 1000000: return false
	if not CombatNumbers.integer(record.created_tick, 0, 9007199254740991) or not CombatNumbers.integer(record.importance, 0, 100) or not CombatNumbers.integer(record.confidence, 0, 100) or not CombatNumbers.integer(record.expires_tick, -1, 9007199254740991): return false
	return record.importance >= 80 and record.expires_tick == -1 if record.anchor else record.expires_tick > record.created_tick
