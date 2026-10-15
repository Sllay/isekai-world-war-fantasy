class_name CoreClock
extends RefCounted

var tick: int = 0
var step_seconds: float = 0.05
var max_steps_per_frame: int = 4
var paused: bool = false
var time_scale: float = 1.0
var _remainder: float = 0.0

func advance(delta: float) -> int:
	if paused or not is_finite(delta) or delta < 0.0 or not is_finite(time_scale) or time_scale < 0.0 or not is_finite(step_seconds) or step_seconds <= 0.0 or max_steps_per_frame < 1:
		return 0
	var accumulated := _remainder + delta * time_scale
	if not is_finite(accumulated):
		return 0
	_remainder = accumulated
	# Clamp before integer conversion, including very large restored backlogs.
	var steps := int(minf(_remainder / step_seconds, float(max_steps_per_frame)))
	_remainder -= steps * step_seconds
	tick += steps
	return steps

func capture() -> Dictionary:
	return {"tick": tick, "remainder": _remainder, "step_seconds": step_seconds, "time_scale": time_scale, "paused": paused}

func validate(value: Dictionary) -> Error:
	if not value.get("tick") is float and not value.get("tick") is int:
		return ERR_INVALID_DATA
	if not is_finite(float(value.tick)) or value.tick < 0 or value.tick > 9007199254740991.0 or value.tick != int(value.tick):
		return ERR_INVALID_DATA
	var remainder: Variant = value.get("remainder")
	if not (remainder is float or remainder is int) or not is_finite(float(remainder)) or remainder < 0:
		return ERR_INVALID_DATA
	for field in ["step_seconds", "time_scale"]:
		var number: Variant = value.get(field)
		if not (number is float or number is int) or not is_finite(float(number)):
			return ERR_INVALID_DATA
	if value.step_seconds <= 0 or value.time_scale < 0 or not value.get("paused") is bool:
		return ERR_INVALID_DATA
	return OK

func restore(value: Dictionary) -> void:
	tick = int(value.tick)
	_remainder = float(value.remainder)
	step_seconds = float(value.step_seconds)
	time_scale = float(value.time_scale)
	paused = value.paused
