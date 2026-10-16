class_name TargetingService
extends RefCounted

var combat: CombatService
var disposition := DispositionPolicy.new()
# Runtime position ports are never captured. Canonical selections contain IDs only.
var _positions: Dictionary[String, Callable] = {}
var _facings: Dictionary[String, Callable] = {}
var _current: Dictionary[String, String] = {}

func register(id: String, provider: Callable, facing: Callable = Callable()) -> Error:
	if combat.combatant(id) == null or not provider.is_valid() or _positions.has(id):
		return ERR_INVALID_PARAMETER
	_positions[id] = provider
	if facing.is_valid():
		_facings[id] = facing
	return OK

func unregister(id: String) -> void:
	_positions.erase(id)
	_facings.erase(id)
	var state := combat.combatant(id)
	if state != null:
		state.defense.clear()
	_current.erase(id)
	for owner in _current.keys():
		if _current[owner] == id:
			_current.erase(owner)

func position_of(id: String) -> Variant:
	if not _positions.has(id):
		return null
	var value: Variant = _positions[id].call()
	return value if value is Vector3 and value.is_finite() else null

func facing_of(id: String) -> Variant:
	if position_of(id) == null or not _facings.has(id):
		return null
	var value: Variant = _facings[id].call()
	return value if value is Vector3 and value.is_finite() and absf(value.y) < 0.001 and value.length_squared() > 0.001 else null

func valid_hostile(owner: String, target: String, max_range: float) -> bool:
	var a := combat.combatant(owner)
	var b := combat.combatant(target)
	if a == null or b == null or a.lifecycle != Combatant.Lifecycle.ALIVE or b.lifecycle != Combatant.Lifecycle.ALIVE or combat.relationship(owner, target) != CombatTargetPolicy.Relationship.ENEMY:
		return false
	var origin: Variant = position_of(owner)
	var destination: Variant = position_of(target)
	return origin is Vector3 and destination is Vector3 and origin.distance_squared_to(destination) <= max_range * max_range

func hostiles(owner: String, max_range: float) -> Array[String]:
	var result: Array[String] = []
	for id in _positions:
		if valid_hostile(owner, id, max_range):
			result.append(id)
	# Stable distance/identity order supports nearest and deterministic cycling.
	result.sort_custom(func(a: String, b: String) -> bool:
		var origin: Vector3 = position_of(owner)
		var da := origin.distance_squared_to(position_of(a))
		var db := origin.distance_squared_to(position_of(b))
		return a < b if is_equal_approx(da, db) else da < db)
	return result

func select(owner: String, target: String, max_range: float) -> bool:
	if not valid_hostile(owner, target, max_range):
		return false
	_current[owner] = target
	return true

func current(owner: String, max_range: float) -> String:
	var target: String = _current.get(owner, "")
	if not valid_hostile(owner, target, max_range):
		_current.erase(owner)
		return ""
	return target

func cycle(owner: String, max_range: float) -> String:
	var candidates := hostiles(owner, max_range)
	if candidates.is_empty():
		_current.erase(owner)
		return ""
	var next := (candidates.find(current(owner, max_range)) + 1) % candidates.size()
	_current[owner] = candidates[next]
	return candidates[next]

func clear() -> void:
	for id in _positions:
		var state := combat.combatant(id)
		if state != null:
			state.defense.clear()
	_positions.clear()
	_facings.clear()
	_current.clear()
