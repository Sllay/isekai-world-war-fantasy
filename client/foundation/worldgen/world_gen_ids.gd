class_name WorldGenIds
extends RefCounted

# Canonical bytes ignore JSON's integer -> float representation change on load.
static func normalize(value: Variant) -> Variant:
	if value is float and is_finite(value) and absf(value) <= 9007199254740991.0 and value == int(value):
		return int(value)
	if value is Array:
		var result: Array = []
		for element: Variant in value: result.append(normalize(element))
		return result
	if value is Dictionary:
		var result: Dictionary = {}
		var ordered_keys: Array = value.keys()
		ordered_keys.sort()
		for key: Variant in ordered_keys: result[key] = normalize(value[key])
		return result
	return value

static func digest(value: Variant) -> String:
	return JSON.stringify(normalize(value), "", true, true).sha256_text()

static func stream(blueprint: Dictionary, region_id: String, coord: Vector2i, domain: String, index: int = 0) -> String:
	return digest([blueprint.world_id, blueprint.world_seed, blueprint.generator_id, blueprint.generator_version, region_id, coord.x, coord.y, domain, index])

static func entity(blueprint: Dictionary, region_id: String, coord: Vector2i, domain: String, index: int = 0) -> String:
	return stream(blueprint, region_id, coord, domain, index).substr(0, 32)

static func feature(blueprint: Dictionary, region_id: String, coord: Vector2i, domain: String, index: int = 0) -> String:
	return domain + ".generated.h" + entity(blueprint, region_id, coord, domain, index)

static func chunk(region_id: String, coord: Vector2i) -> String:
	return "%s:%d:%d" % [region_id, coord.x, coord.y]

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and value == int(value)

static func keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size(): return false
	for key: Variant in expected:
		if not value.has(key): return false
	return true
