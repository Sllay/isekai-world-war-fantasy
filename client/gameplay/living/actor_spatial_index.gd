class_name ActorSpatialIndex
extends RefCounted

const CELL_SIZE := 16.0
const MAX_ENTRIES := 512
const MAX_QUERY_CANDIDATES := 128
var _positions: Dictionary[String, Vector3] = {}
var _cells: Dictionary = {}
var query_count := 0
var examined := 0
var truncated := 0

func update(id: String, point: Vector3) -> Error:
	if not CombatNumbers.stable_entity(id) or not point.is_finite(): return ERR_INVALID_DATA
	if not _positions.has(id) and _positions.size() >= MAX_ENTRIES: return ERR_OUT_OF_MEMORY
	var cell := _cell(point)
	if _positions.has(id) and _cell(_positions[id]) == cell:
		_positions[id] = point
		return OK
	remove(id)
	_positions[id] = point
	if not _cells.has(cell): _cells[cell] = {}
	_cells[cell][id] = true
	return OK

func remove(id: String) -> void:
	if not _positions.has(id): return
	var cell := _cell(_positions[id])
	_cells[cell].erase(id)
	if _cells[cell].is_empty(): _cells.erase(cell)
	_positions.erase(id)

func position_of(id: String) -> Variant:
	return _positions.get(id)

func nearby(point: Vector3, radius: float, result_cap: int = 16) -> Array[String]:
	var result: Array[String] = []
	if not point.is_finite() or not is_finite(radius) or radius < 0 or radius > 64 or result_cap < 1 or result_cap > 64: return result
	query_count += 1
	var minimum := _cell(point - Vector3(radius, 0, radius))
	var maximum := _cell(point + Vector3(radius, 0, radius))
	var budget := MAX_QUERY_CANDIDATES
	for x in range(minimum.x, maximum.x + 1):
		for z in range(minimum.y, maximum.y + 1):
			var ids: Array = _cells.get(Vector2i(x, z), {}).keys()
			ids.sort()
			for id: String in ids:
				if budget == 0: truncated += 1; result.sort(); return result
				budget -= 1
				examined += 1
				if point.distance_squared_to(_positions[id]) <= radius * radius:
					result.append(id)
					if result.size() == result_cap: result.sort(); return result
	result.sort()
	return result

func size() -> int:
	return _positions.size()

static func _cell(point: Vector3) -> Vector2i:
	return Vector2i(floori(point.x / CELL_SIZE), floori(point.z / CELL_SIZE))
