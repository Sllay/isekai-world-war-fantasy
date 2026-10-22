class_name ChunkStreamer
extends Node3D

var generation: WorldGenerationModule
var living: LivingModule
var items: ItemsModule
var persistence: SaveCoordinator
var player: PlayerState
var region: RegionDefinition
var policy := StreamingRelevance.new()
var views: Dictionary = {}
var metrics := {"materializations": 0, "unloads": 0, "materialize_us": 0, "unload_us": 0, "peak_loaded": 0, "prefetches": 0, "last_error": "OK"}
var _discovered := {}
var _marker_tick := -1
var _token := -1
var background_work_allowed: Callable
var prefetch_interval_ticks := 4
var _next_prefetch_tick := 0

func initialize() -> Error:
	_token = items.combat.events.subscribe(ItemWorkCommitted, _work_committed)
	# Initial attachment is a loading phase: establish collision in the nine
	# adjacent cells before the first Player physics step. Runtime jobs stay bounded.
	var center := region.chunk_at(region.to_local_position(player.position))
	for z in range(center.y - policy.active_radius, center.y + policy.active_radius + 1):
		for x in range(center.x - policy.active_radius, center.x + policy.active_radius + 1):
			var coord := Vector2i(x, z)
			if not WorldBlueprint.contains(generation.ledger.blueprint, coord): continue
			var error := _materialize(coord)
			if error != OK: return error
	return OK

func advance_frame() -> void:
	var tick := items.combat.clock.tick
	var center := region.chunk_at(region.to_local_position(player.position))
	var plan := policy.plan(generation.ledger.blueprint, center, tick)
	if not plan.ok: metrics.last_error = plan.code; return
	# Durable cold-data work yields to active combat/actions. Nearby collision
	# was attached during loading; the active ring supplies movement lookahead.
	if background_work_allowed.is_valid() and not bool(background_work_allowed.call()): return
	# At most one old view is removed, and one view/data job executes per frame.
	if not plan.unload.is_empty():
		var key: String = plan.unload[0]
		if not generation.ledger.dirty_chunks.is_empty() and persistence.save_game() != OK:
			metrics.last_error = "DIRTY_SAVE_FAILED"; return
		var started := Time.get_ticks_usec()
		views[key].free()
		views.erase(key)
		policy.dematerialized(key)
		metrics.unloads += 1
		metrics.unload_us = Time.get_ticks_usec() - started
	if not plan.materialize.is_empty():
		_materialize(plan.materialize[0])
	elif tick >= _next_prefetch_tick:
		for cell: Vector2i in plan.prefetch:
			if generation.ledger.record(cell).is_empty():
				_ensure(cell, false)
				_next_prefetch_tick = tick + prefetch_interval_ticks
				metrics.prefetches += 1
				break
	if tick != _marker_tick and tick % 3 == 0:
		_marker_tick = tick
		for view in views.values(): view.update_markers()
	var current := generation.ledger.record(center)
	if not current.is_empty() and not _discovered.has(current.chunk_id):
		_discovered[current.chunk_id] = true
		living.award(player.entity_id, "world.discovery", current.base.landmarks[0].id, 1)

func _ensure(cell: Vector2i, activate_spawns: bool = true) -> Dictionary:
	var loaded := generation.ledger.request(cell, items.combat.clock.tick)
	if not loaded.ok: metrics.last_error = loaded.code; return loaded
	var record: Dictionary = loaded.record
	for placement: Dictionary in record.base.resources:
		if items.resources.register_node(WorldGenerationModule.node_definition(placement)) != OK:
			metrics.last_error = "RESOURCE_PLACEMENT_INVALID"
			return {"ok": false, "code": metrics.last_error}
	# Prefetch bakes canonical candidates only. Spawn activation is a distinct
	# authority transaction when a chunk first enters active relevance; actors
	# already born there continue logically after its view unloads.
	if not activate_spawns: return {"ok": true, "record": record}
	var before := generation.ledger.capture()
	var ids_before := items.combat.entities.capture()
	var revision_before := living.revision
	var created := living.seed_chunk(record)
	if not created.is_empty():
		var result := generation.ledger.mark_modified(cell, int(record.revision), {"spawn_claims": created})
		if not result.ok or persistence.save_game() != OK:
			# Only the newly reserved logical actors are rolled back; existing
			# gameplay, active actions and residency are never globally restored.
			for spawn: Dictionary in record.base.spawns:
				if spawn.spawn_id not in created: continue
				var bundle: LivingCapabilities = living.actors[spawn.actor_id]
				bundle.dispose()
				living.combat.unregister(spawn.actor_id)
				living.scheduler.unregister(spawn.actor_id)
				living.perception.actors.erase(spawn.actor_id)
				living.actors.erase(spawn.actor_id)
			living.revision = revision_before
			items.combat.entities.restore(ids_before)
			generation.ledger.restore(before)
			metrics.last_error = "SPAWN_COMMIT_FAILED"
			return {"ok": false, "code": metrics.last_error}
		generation.ledger.acknowledge_persisted()
	return {"ok": true, "record": generation.ledger.record(cell)}

func _materialize(cell: Vector2i) -> Error:
	var key := WorldGenIds.chunk(region.region_id, cell)
	if views.has(key): return OK
	var result := _ensure(cell)
	if not result.ok: return ERR_INVALID_DATA
	var started := Time.get_ticks_usec()
	var view := ChunkView.new()
	view.record = result.record
	view.resources = items.resources
	view.clock = items.combat.clock
	add_child(view)
	views[key] = view
	policy.materialized(cell)
	metrics.materializations += 1
	metrics.materialize_us = Time.get_ticks_usec() - started
	metrics.peak_loaded = maxi(int(metrics.peak_loaded), views.size())
	return OK

func active_chunk(chunk_id: String) -> bool:
	if not views.has(chunk_id): return false
	var cell: Vector2i = region.chunk_at(region.to_local_position(player.position))
	var coord: Array = views[chunk_id].record.coord
	return maxi(absi(coord[0] - cell.x), absi(coord[1] - cell.y)) <= policy.active_radius

func resource_candidates() -> Array:
	var result: Array = []
	for key: String in views:
		if not active_chunk(key): continue
		for node: Dictionary in views[key].record.base.resources: result.append(node.node_id)
	return result

func route(origin: Vector3, destination: Vector3, region_id: String) -> Array:
	if region_id != region.region_id or not region.safe_position(origin) or not region.safe_position(destination): return []
	var from := region.chunk_at(region.to_local_position(origin))
	var target := region.chunk_at(region.to_local_position(destination))
	if not views.has(WorldGenIds.chunk(region_id, from)) or not views.has(WorldGenIds.chunk(region_id, target)): return []
	# Open first-scope terrain: one cached local corridor. Chunk base already
	# supplies the walkable/portal seam for a later obstacle-aware path adapter.
	return [destination]

func _work_committed(fact: ItemWorkCommitted) -> void:
	if fact.cause != "resource.harvest": return
	var authored := items.resources.definition(fact.subject_id)
	if authored == null: return
	var profile := items.content.profile(authored.profile_id)
	if profile.regeneration_ticks > 0 or items.resources.snapshot(fact.subject_id, fact.tick).remaining > 0: return
	var cell := region.chunk_at(region.to_local_position(authored.position))
	var record := generation.ledger.record(cell)
	if not record.is_empty(): generation.ledger.mark_modified(cell, int(record.revision), {"removed_resources": [fact.subject_id]})

func snapshot() -> Dictionary:
	return {"metrics": metrics.duplicate(), "loaded": views.keys(), "loaded_count": views.size(), "canonical_chunks": generation.ledger.capture().chunks.size(), "generation_invocation_count": generation.ledger.generator.generation_invocation_count, "persisted_load_count": generation.ledger.persisted_load_count, "generation_us": generation.ledger.generator.last_generation_us, "generation_pipeline_us": generation.ledger.first_generation_us, "max_generation_pipeline_us": generation.ledger.max_generation_pipeline_us, "persisted_load_us": generation.ledger.last_persisted_load_us}

func _exit_tree() -> void:
	background_work_allowed = Callable()
	if _token >= 0: items.combat.events.unsubscribe(_token)
	policy.clear()
	views.clear()
