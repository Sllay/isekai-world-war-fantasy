class_name CombatNumbers
extends RefCounted

const MAX_UNITS := 1000000000
const SCALE := 10000
const MAX_SCALE := 1000000
const MAX_MODIFIERS := 64

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and value == int(value)

static func stable_entity(value: Variant) -> bool:
	return value is String and value.length() == 32 and value == value.to_lower() and value.is_valid_hex_number(false)
