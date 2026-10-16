class_name HomeValleySurfaceQuery
extends RegionSurfaceQuery

# Only the current open, single-sheet authored terrain. No cave/bridge inference.
var definition: RegionDefinition
var clearance_at: Callable
var query_count := 0

func expected_height(position: Vector3, context: String) -> Variant:
	if context != definition.region_id or not position.is_finite():
		return null
	var local := definition.to_local_position(position)
	if not definition.safety_bounds.has_point(Vector2(local.x, local.z)):
		return null
	return definition.surface_height(position)

func candidate_above(position: Vector3, context: String, offset: float) -> RegionSurfaceCandidate:
	query_count += 1
	var height: Variant = expected_height(position, context)
	if height == null or float(height) <= position.y or not clearance_at.is_valid():
		return null
	var candidate := RegionSurfaceCandidate.new()
	candidate.position = Vector3(position.x, float(height), position.z)
	candidate.region_id = definition.region_id
	candidate.surface_id = "surface.home_valley.terrain"
	candidate.normal = definition.surface_normal(position)
	candidate.clearance = bool(clearance_at.call(candidate.position + Vector3.UP * offset))
	return candidate
