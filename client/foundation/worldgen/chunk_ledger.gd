class_name ChunkLedger
extends RefCounted

# Domain state, not a second save engine. The application supplies the existing
# CoreSaveStore/SaveCoordinator transaction as the durable generation commit port.
var blueprint: Dictionary = {}
var generator := WorldGenesis.new()
var commit: Callable
var generation_phases: Dictionary = {}
var dirty_chunks: Dictionary = {}
var persisted_load_count := 0
var first_generation_us := 0
var last_persisted_load_us := 0
var _records: Dictionary = {}

func configure(baked_blueprint: Dictionary, durable_commit: Callable = Callable()) -> Error:
	if not WorldBlueprint.valid(baked_blueprint): return ERR_INVALID_DATA
	blueprint = WorldGenIds.normalize(baked_blueprint)
	commit = durable_commit
	_records.clear()
	generation_phases.clear()
	dirty_chunks.clear()
	return OK

func capture() -> Dictionary:
	return {"blueprint": blueprint.duplicate(true), "chunks": _records.duplicate(true)}

func record(coord: Vector2i, region_id: String = WorldBlueprint.REGION_ID) -> Dictionary:
	return _records.get(WorldGenIds.chunk(region_id, coord), {}).duplicate(true)

func record_by_id(chunk_id: String) -> Dictionary:
	return _records.get(chunk_id, {}).duplicate(true)

func request(coord: Vector2i, tick: int, region_id: String = WorldBlueprint.REGION_ID) -> Dictionary:
	if not WorldBlueprint.valid(blueprint) or not WorldBlueprint.contains(blueprint, coord, region_id): return _failure("CHUNK_OUTSIDE_WORLD")
	var key := WorldGenIds.chunk(region_id, coord)
	if generation_phases.has(key): return _failure("GENERATION_BUSY")
	if _records.has(key):
		var load_started := Time.get_ticks_usec()
		var result := record(coord, region_id)
		if not ChunkRecord.valid(result, blueprint): return _failure("CHUNK_CORRUPT")
		persisted_load_count += 1
		last_persisted_load_us = Time.get_ticks_usec() - load_started
		return {"ok": true, "code": "PERSISTED_LOADED", "generated": false, "record": result}
	if not commit.is_valid(): return _failure("STORAGE_UNAVAILABLE")
	generation_phases[key] = "GENERATING"
	var started := Time.get_ticks_usec()
	var generated := generator.generate(blueprint, coord, tick, region_id)
	if not generated.ok:
		generation_phases.erase(key)
		return generated
	generation_phases[key] = "GENERATED"
	var staged := capture()
	staged.chunks[key] = generated.record.duplicate(true)
	var outcome: Variant = commit.call(staged.duplicate(true))
	var accepted: bool = outcome if outcome is bool else outcome is int and outcome == OK
	if not accepted:
		generation_phases.erase(key)
		return _failure("GENERATION_COMMIT_FAILED")
	_records[key] = generated.record.duplicate(true)
	generation_phases.erase(key)
	if first_generation_us == 0: first_generation_us = Time.get_ticks_usec() - started
	return {"ok": true, "code": "GENERATED_PERSISTED", "generated": true, "record": record(coord, region_id)}

# Typed monotonic world consequences only. Ordinary mutations remain dirty until
# the application's safe/batched checkpoint; no disk write on movement or frame.
func mark_modified(coord: Vector2i, expected_revision: int, patch: Dictionary, region_id: String = WorldBlueprint.REGION_ID) -> Dictionary:
	var key := WorldGenIds.chunk(region_id, coord)
	if not _records.has(key): return _failure("CHUNK_UNGENERATED")
	if generation_phases.has(key): return _failure("GENERATION_BUSY")
	var previous: Dictionary = _records[key]
	if previous.revision != expected_revision: return _failure("STALE_CHUNK_REVISION")
	if patch.is_empty() or patch.size() > 2: return _failure("INVALID_CHUNK_MUTATION")
	var next := previous.duplicate(true)
	var changed := false
	for field: Variant in patch:
		if field not in ["removed_resources", "spawn_claims"] or not patch[field] is Array: return _failure("FORGED_CHUNK_MUTATION")
		for id: Variant in patch[field]:
			if not id is String: return _failure("INVALID_CHUNK_MUTATION")
			if not next.delta[field].has(id):
				next.delta[field].append(id)
				changed = true
		next.delta[field].sort()
	if not ChunkRecord.valid_delta(next.delta, next.base): return _failure("INVALID_GENERATED_REFERENCE")
	if not changed: return {"ok": true, "code": "UNCHANGED", "revision": previous.revision}
	next.revision += 1
	next.lifecycle = "MODIFIED"
	if not ChunkRecord.valid(next, blueprint): return _failure("INVALID_CHUNK_MUTATION")
	_records[key] = next
	dirty_chunks[key] = true
	return {"ok": true, "code": "CHUNK_MODIFIED", "revision": next.revision}

func acknowledge_persisted(chunk_ids: Array = []) -> void:
	if chunk_ids.is_empty():
		dirty_chunks.clear()
	else:
		for key: Variant in chunk_ids: dirty_chunks.erase(key)

func validate_state(value: Dictionary) -> bool:
	value = WorldGenIds.normalize(value)
	if not WorldGenIds.keys(value, ["blueprint", "chunks"]) or not value.blueprint is Dictionary or not WorldBlueprint.valid(value.blueprint) or not value.chunks is Dictionary: return false
	# A configured world cannot silently load another world/version/profile.
	if not blueprint.is_empty() and WorldGenIds.digest(blueprint) != WorldGenIds.digest(value.blueprint): return false
	var side: int = value.blueprint.coord_limit * 2 + 1
	if value.chunks.size() > side * side: return false
	var features := {}
	for key: Variant in value.chunks:
		var baked: Variant = value.chunks[key]
		if not key is String or not baked is Dictionary or not ChunkRecord.valid(baked, value.blueprint) or key != baked.chunk_id: return false
		for entry: Dictionary in baked.base.resources:
			if features.has(entry.node_id): return false
			features[entry.node_id] = true
		for entry: Dictionary in baked.base.spawns:
			if features.has(entry.spawn_id) or features.has(entry.actor_id): return false
			features[entry.spawn_id] = true
			features[entry.actor_id] = true
	return true

func restore(value: Dictionary) -> Error:
	if not validate_state(value): return ERR_INVALID_DATA
	value = WorldGenIds.normalize(value)
	blueprint = value.blueprint.duplicate(true)
	_records = value.chunks.duplicate(true)
	generation_phases.clear()
	dirty_chunks.clear()
	return OK

func _failure(code: String) -> Dictionary:
	return {"ok": false, "code": code, "generated": false}
