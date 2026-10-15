class_name PlayerState
extends RefCounted

var entity_id: String
var position := Vector3(0, 1, 0)
var velocity := Vector3.ZERO
var grounded := false
var facing := Vector3.FORWARD
var intent := Vector2.ZERO

func capture() -> Dictionary:
	return {"entity_id": entity_id, "position": _array(position), "velocity": _array(velocity), "facing": _array(facing)}

static func valid(value: Dictionary) -> bool:
	var id: Variant = value.get("entity_id")
	if not id is String or id.length() != 32 or id != id.to_lower() or not id.is_valid_hex_number(false):
		return false
	for key in ["position", "velocity", "facing"]:
		var vector: Variant = value.get(key)
		if not vector is Array or vector.size() != 3:
			return false
		for number in vector:
			if not (number is float or number is int) or not is_finite(float(number)):
				return false
	var direction := Vector3(value.facing[0], value.facing[1], value.facing[2])
	return absf(direction.y) < 0.001 and absf(direction.length() - 1.0) < 0.001

func restore(value: Dictionary) -> void:
	entity_id = value.entity_id
	position = Vector3(value.position[0], value.position[1], value.position[2])
	velocity = Vector3(value.velocity[0], value.velocity[1], value.velocity[2])
	facing = Vector3(value.facing[0], value.facing[1], value.facing[2])
	grounded = false
	intent = Vector2.ZERO

func _array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
