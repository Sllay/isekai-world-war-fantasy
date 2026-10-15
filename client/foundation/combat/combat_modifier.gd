class_name CombatModifier
extends RefCounted

enum Stat { MAX_HEALTH, MAX_RESOURCE, DAMAGE_SCALE, HEAL_SCALE }
enum Operator { ADD, SCALE }
var source_id: String
var stat: Stat
var operator: Operator
var value: int

func _init(source := "", attribute: Stat = Stat.MAX_HEALTH, operation: Operator = Operator.ADD, units := 0) -> void:
	source_id = source
	stat = attribute
	operator = operation
	value = units

func capture() -> Dictionary:
	return {"source_id": source_id, "stat": stat, "operator": operator, "value": value}

static func valid(data: Dictionary) -> bool:
	if not data.get("source_id") is String or not CoreIds.valid(data.source_id) or not CombatNumbers.integer(data.get("stat"), 0, Stat.size() - 1) or not CombatNumbers.integer(data.get("operator"), 0, Operator.size() - 1):
		return false
	return CombatNumbers.integer(data.get("value"), 0 if data.operator == Operator.SCALE else -CombatNumbers.MAX_UNITS, CombatNumbers.MAX_SCALE if data.operator == Operator.SCALE else CombatNumbers.MAX_UNITS)

static func from_state(data: Dictionary) -> CombatModifier:
	return CombatModifier.new(data.source_id, int(data.stat), int(data.operator), int(data.value))
