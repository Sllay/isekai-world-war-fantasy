class_name LivingProgression
extends RefCounted

# Root consumes trusted gameplay facts. Amounts never enter this API.
# Monotonic per-source watermarks preserve replay protection without event logs.
const MAX_SOURCES := 64
var xp := 0
var _sequences: Dictionary = {}

func award(cause: String, source: String, sequence: int, definition: ProgressionDefinition) -> Dictionary:
	if definition == null or not definition.valid() or not definition.cause_awards.has(cause) or not _source(source) or sequence < 1 or sequence > 9007199254740991: return {"accepted": false, "code": "INVALID_REWARD_CAUSE"}
	var key := cause + ":" + source
	if sequence <= int(_sequences.get(key, 0)): return {"accepted": false, "code": "DUPLICATE_OR_STALE_REWARD"}
	if not _sequences.has(key) and _sequences.size() >= MAX_SOURCES: return {"accepted": false, "code": "REWARD_SOURCE_CAPACITY"}
	var amount := int(definition.cause_awards[cause])
	if xp > CombatNumbers.MAX_UNITS - amount: return {"accepted": false, "code": "XP_CAPACITY"}
	var previous := definition.level_for(xp)
	xp += amount
	_sequences[key] = sequence
	return {"accepted": true, "code": "XP_AWARDED", "amount": amount, "xp": xp, "previous_level": previous, "level": definition.level_for(xp)}

func capture() -> Dictionary:
	return {"xp": xp, "sources": _sequences.duplicate()}

static func _source(source: String) -> bool:
	return source.length() <= 128 and (CombatNumbers.stable_entity(source) or CoreIds.valid(source))

static func valid(state: Dictionary, definition: ProgressionDefinition, known_source: Callable = Callable()) -> bool:
	if definition == null or not InventoryService._keys(state, ["xp", "sources"]) or not CombatNumbers.integer(state.xp, 0, CombatNumbers.MAX_UNITS) or not state.sources is Dictionary or state.sources.size() > MAX_SOURCES: return false
	for key: Variant in state.sources:
		if not key is String: return false
		var parts: PackedStringArray = key.split(":")
		if parts.size() != 2 or not definition.cause_awards.has(parts[0]) or not _source(parts[1]) or not CombatNumbers.integer(state.sources[key], 1, 9007199254740991): return false
		if known_source.is_valid() and not bool(known_source.call(parts[1])): return false
	return true

func restore(state: Dictionary, definition: ProgressionDefinition, known_source: Callable = Callable()) -> Error:
	if not valid(state, definition, known_source): return ERR_INVALID_DATA
	xp = int(state.xp)
	_sequences.clear()
	for key: String in state.sources: _sequences[key] = int(state.sources[key])
	return OK
