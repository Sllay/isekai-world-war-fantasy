class_name RegionRecovery
extends RefCounted

var definition: RegionDefinition
var player: PlayerState
var last_safe: Dictionary = {}
var recovery_count := 0
var diagnostics: CoreDiagnostics
var surface_query: RegionSurfaceQuery
var clear_unsafe_motion: Callable
var last_method := "NONE"
var last_candidate: Dictionary = {}
var _awaiting_ground := false

func suspicious(position: Vector3) -> bool:
	if not definition.safe_position(position):
		return true
	var height: Variant = surface_query.expected_height(position, definition.region_id) if surface_query != null else definition.surface_height(position)
	return height != null and position.y < float(height) - definition.penetration_depth

func observe() -> void:
	if suspicious(player.position):
		recover()
	elif definition.approved_surface(player.position) and (not _awaiting_ground or player.grounded):
		_awaiting_ground = false
		last_safe = {"position": _array(player.position), "facing": _array(player.facing)}

func valid(value: Dictionary) -> bool:
	if value.is_empty():
		return true
	if value.size() != 2:
		return false
	for key in ["position", "facing"]:
		if not value.get(key) is Array or value[key].size() != 3:
			return false
		for n in value[key]:
			if not (n is float or n is int) or not is_finite(float(n)):
				return false
	var facing := _vector(value.facing)
	return definition.safe_position(_vector(value.position)) and not suspicious(_vector(value.position)) and definition.approved_surface(_vector(value.position)) and absf(facing.y) < 0.001 and is_equal_approx(facing.length(), 1.0)

func recovery_transform() -> Dictionary:
	last_candidate = {}
	if surface_query != null and suspicious(player.position) and player.position.is_finite():
		var candidate := surface_query.candidate_above(player.position, definition.region_id, definition.recovery_surface_offset)
		if valid_candidate(candidate):
			var destination := candidate.position + Vector3.UP * definition.recovery_surface_offset
			last_method = "VERTICAL_SURFACE_RECOVERED"
			last_candidate = {"position": _array(destination), "surface_id": candidate.surface_id}
			var facing := player.facing if player.facing.is_finite() and absf(player.facing.y) < 0.001 and is_equal_approx(player.facing.length(), 1.0) else Vector3.FORWARD
			return {"position": _array(destination), "facing": _array(facing)}
	if not last_safe.is_empty() and valid(last_safe):
		last_method = "LAST_SAFE_RECOVERED"
		return last_safe.duplicate(true)
	last_method = "REGION_ENTRY_RECOVERED"
	return {"position": _array(definition.to_world_position(definition.entries[definition.default_entry])), "facing": [0, 0, -1]}

func recover() -> void:
	var safe := recovery_transform()
	player.position = _vector(safe.position)
	player.facing = _vector(safe.facing)
	player.velocity = Vector3.ZERO
	player.grounded = false
	player.intent = Vector2.ZERO
	_awaiting_ground = true
	if clear_unsafe_motion.is_valid():
		clear_unsafe_motion.call()
	recovery_count += 1
	if diagnostics != null:
		diagnostics.record("info", "foundation.regions", last_method, {"region_id": definition.region_id, "entity_id": player.entity_id, "position": _array(player.position)})

# Save captures a validated recovery transform for airborne/unsafe state without
# mutating the live Player. Approved authored surface contact also supports entry
# and immediate resume before the first physics contact callback.
func safe_snapshot(value: Dictionary) -> Dictionary:
	if not suspicious(player.position) and (player.grounded or definition.approved_surface(player.position)):
		return value
	var result := value.duplicate(true)
	var safe := recovery_transform()
	result.position = safe.position
	result.facing = safe.facing
	result.velocity = [0, 0, 0]
	return result

func _array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
func _vector(v: Array) -> Vector3:
	return Vector3(v[0], v[1], v[2])

func valid_candidate(candidate: RegionSurfaceCandidate) -> bool:
	if candidate == null or candidate.region_id != definition.region_id or not candidate.position.is_finite() or not candidate.normal.is_finite() or not candidate.clearance:
		return false
	return is_equal_approx(candidate.normal.length(), 1.0) and candidate.normal.dot(Vector3.UP) >= definition.recovery_walkable_dot and candidate.position.y > player.position.y and definition.safe_position(candidate.position + Vector3.UP * definition.recovery_surface_offset)

func development_state() -> Dictionary:
	return {"method": last_method, "candidate": last_candidate.duplicate(true), "count": recovery_count}
