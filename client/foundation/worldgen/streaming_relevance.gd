class_name StreamingRelevance
extends RefCounted

# Pure bounded Region relevance policy; physical Nodes stay in its scene adapter.
var active_radius := 1
var prefetch_ring := 1
var unload_hysteresis := 12
var max_materializations_per_frame := 1
var max_resident_chunks := 25
var _resident: Dictionary = {}
var _outside_since: Dictionary = {}

func valid() -> bool:
	return active_radius >= 0 and active_radius <= 2 and prefetch_ring >= 0 and prefetch_ring <= 1 and unload_hysteresis >= 0 and unload_hysteresis <= 1200 and max_materializations_per_frame >= 1 and max_materializations_per_frame <= 4 and max_resident_chunks >= 9 and max_resident_chunks <= 81

func plan(blueprint: Dictionary, center: Vector2i, tick: int, region_id: String = WorldBlueprint.REGION_ID) -> Dictionary:
	if not valid() or not WorldBlueprint.valid(blueprint) or not WorldBlueprint.contains(blueprint, center, region_id) or tick < 0: return {"ok": false, "code": "INVALID_STREAM_RELEVANCE"}
	var desired: Array[Vector2i] = []
	var prefetch: Array[Vector2i] = []
	for z in range(center.y - active_radius - prefetch_ring, center.y + active_radius + prefetch_ring + 1):
		for x in range(center.x - active_radius - prefetch_ring, center.x + active_radius + prefetch_ring + 1):
			var cell := Vector2i(x, z)
			if not WorldBlueprint.contains(blueprint, cell, region_id): continue
			if maxi(absi(x - center.x), absi(z - center.y)) <= active_radius: desired.append(cell)
			else: prefetch.append(cell)
	var compare := func(a: Vector2i, b: Vector2i) -> bool:
		var a_distance := absi(a.x - center.x) + absi(a.y - center.y)
		var b_distance := absi(b.x - center.x) + absi(b.y - center.y)
		return a_distance < b_distance if a_distance != b_distance else (a.y < b.y if a.y != b.y else a.x < b.x)
	desired.sort_custom(compare)
	prefetch.sort_custom(compare)
	var to_materialize: Array[Vector2i] = []
	for cell: Vector2i in desired:
		var key := WorldGenIds.chunk(region_id, cell)
		_outside_since.erase(key)
		if not _resident.has(key) and to_materialize.size() < max_materializations_per_frame and _resident.size() + to_materialize.size() < max_resident_chunks: to_materialize.append(cell)
	var unload: Array[String] = []
	for key: String in _resident:
		var cell: Vector2i = _resident[key]
		# Prefetch radius provides spatial hysteresis as well as the tick deadline.
		if maxi(absi(cell.x - center.x), absi(cell.y - center.y)) <= active_radius + prefetch_ring:
			_outside_since.erase(key)
			continue
		if not _outside_since.has(key): _outside_since[key] = tick
		if tick - int(_outside_since[key]) >= unload_hysteresis: unload.append(key)
	unload.sort()
	return {"ok": true, "code": "STREAM_PLAN", "active": desired, "prefetch": prefetch, "materialize": to_materialize, "unload": unload}

func materialized(coord: Vector2i, region_id: String = WorldBlueprint.REGION_ID) -> Error:
	var key := WorldGenIds.chunk(region_id, coord)
	if _resident.has(key): return ERR_ALREADY_EXISTS
	if _resident.size() >= max_resident_chunks: return ERR_OUT_OF_MEMORY
	_resident[key] = coord
	return OK

func dematerialized(chunk_id: String) -> void:
	_resident.erase(chunk_id)
	_outside_since.erase(chunk_id)

func resident_count() -> int:
	return _resident.size()

func clear() -> void:
	_resident.clear()
	_outside_since.clear()
