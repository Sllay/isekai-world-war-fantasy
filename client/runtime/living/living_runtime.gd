class_name LivingRuntime
extends Node3D

const MAX_MATERIALIZED := 4
const ENTER_DISTANCE := 24.0
const LEAVE_DISTANCE := 28.0
var module: LivingModule
var root_host: LocalAuthorityHost
var targeting: TargetingService
var region: RegionDefinition
var active_chunks: Callable
var spatial_gate: Callable
var route_port: Callable
@export var resource_sense_range := 20.0
var bodies: Dictionary[String, LivingBody] = {}
var hosts: Dictionary[String, LocalAuthorityHost] = {}
var queries := LivingWorldQueries.new()
var _routes: Dictionary = {}
var _destinations: Dictionary = {}
var _path_retry_tick: Dictionary = {}
var _waiting_chunks: Dictionary = {}
var _last_cell := Vector2i(1000000, 1000000)
var _last_count := -1
var _force_relevance := true
var _disposed := false
var materializations := 0
var dematerializations := 0
var peak_bodies := 0
var executed_intents := 0
var successful_bot_harvests := 0
var _last_wood: Dictionary = {}

func _ready() -> void:
	queries.module = module
	queries.targeting = targeting
	queries.region = region
	queries.active_chunks = active_chunks
	queries.spatial_gate = spatial_gate
	queries.resource_sense_range = resource_sense_range
	module.scheduler.decision_port = _choose
	_configure_factions()
	sync_relevance(root_host.player.position)

func invalidate_relevance() -> void:
	_force_relevance = true

func sync_relevance(center: Vector3) -> void:
	if _disposed or module == null or not center.is_finite(): return
	var cell := Vector2i(floori(center.x / 8.0), floori(center.z / 8.0))
	if not _force_relevance and cell == _last_cell and _last_count == module.actors.size():
		var changed := false
		for id: String in _waiting_chunks:
			if bool(active_chunks.call(id)) != bool(_waiting_chunks[id]): changed = true; break
		for id: String in bodies:
			if not bool(active_chunks.call(module.actors[id].state.chunk_id)): changed = true; break
		if not changed: return
	_force_relevance = false
	_last_cell = cell
	_last_count = module.actors.size()
	_waiting_chunks.clear()
	var candidates: Array[String] = []
	for id: String in module.actors:
		var actor := module.actors[id].state
		_refresh_location(actor)
		var squared := center.distance_squared_to(actor.position)
		var active := active_chunks.is_valid() and bool(active_chunks.call(actor.chunk_id))
		var boundary := LEAVE_DISTANCE if bodies.has(id) else ENTER_DISTANCE
		if squared <= boundary * boundary:
			if active: candidates.append(id)
			elif _waiting_chunks.size() < 16: _waiting_chunks[actor.chunk_id] = false
	candidates.sort_custom(func(a: String, b: String) -> bool:
		var first := center.distance_squared_to(module.actors[a].state.position)
		var second := center.distance_squared_to(module.actors[b].state.position)
		return a < b if is_equal_approx(first, second) else first < second)
	if candidates.size() > MAX_MATERIALIZED: candidates.resize(MAX_MATERIALIZED)
	for id: String in bodies.keys():
		if id not in candidates: _dematerialize(id)
	for id: String in module.actors:
		var actor := module.actors[id].state
		var level := LivingActorState.Fidelity.L0 if id in candidates else LivingActorState.Fidelity.L1 if center.distance_to(actor.position) <= 64.0 else LivingActorState.Fidelity.L2 if center.distance_to(actor.position) <= 128.0 else LivingActorState.Fidelity.L3
		module.scheduler.set_fidelity(id, level, module.combat.clock.tick)
		_refresh_location(actor)
		if level <= LivingActorState.Fidelity.L1: module.perception.spatial.update(id, actor.position)
		else: module.perception.spatial.remove(id)
	for id: String in candidates:
		if not bodies.has(id): _materialize(id)

func tick() -> void:
	if _disposed: return
	var now := module.combat.clock.tick
	module.perception.spatial.update(root_host.player.entity_id, root_host.player.position)
	sync_relevance(root_host.player.position)
	for id: String in hosts:
		var bundle := module.actors[id]
		if bundle.combatant.lifecycle == Combatant.Lifecycle.ALIVE: hosts[id].advance()
		_refresh_location(bundle.state)
		if root_host.player.position.distance_squared_to(bundle.state.position) > LEAVE_DISTANCE * LEAVE_DISTANCE:
			_force_relevance = true
		module.perception.spatial.update(id, bundle.state.position)
		_follow_route(id)
		var wood := bundle.items.inventory.quantity(bundle.items.bag_id, "item.wood.common")
		if bundle.state.kind == "bot" and wood > int(_last_wood.get(id, 0)): successful_bot_harvests += 1
		_last_wood[id] = wood
	var settled_before: int = module.scheduler.metrics.completed_activities
	var jobs := module.scheduler.advance(now)
	# Deadline work may move an unmaterialized actor while the Player stands still.
	# Re-evaluate only when a scheduled consequence occurred, never scan every tick.
	if int(module.scheduler.metrics.completed_activities) != settled_before: _force_relevance = true
	for job: Dictionary in jobs:
		var actor := module.actors[job.actor_id].state
		_refresh_location(actor)
		if actor.fidelity == LivingActorState.Fidelity.L1:
			_apply_reduced(actor, job.intent)
			module.perception.spatial.update(actor.actor_id, actor.position)
		elif module.scheduler.valid_intent_epoch(job.actor_id, int(job.epoch)) and hosts.has(job.actor_id): _apply_intent(job.actor_id, job.intent)
	for path: Dictionary in module.paths.advance(route_port, module.scheduler.valid_intent_epoch):
		# An intent may have changed while its bounded request waited in the queue.
		if _destinations.has(path.actor_id) and (path.points[-1] as Vector3).distance_squared_to(_destinations[path.actor_id]) < 0.25:
			_routes[path.actor_id] = path.points.duplicate()
	for id: String in hosts: _follow_route(id)

func _choose(actor: LivingActorState, tick_value: int) -> Dictionary:
	if module.actors[actor.actor_id].combatant.lifecycle != Combatant.Lifecycle.ALIVE: return {"kind": "idle"}
	if not actor.plan_dirty and not actor.plan.is_empty() and tick_value < int(actor.plan.get("expires_tick", 0)):
		return module.decisions.choose(actor, tick_value)
	var context := {}
	if actor.kind == "bot" and actor.fidelity == LivingActorState.Fidelity.L0:
		context = queries.observed_target(actor)
		if context.is_empty():
			var observed := queries.observed_resource(actor)
			if not observed.is_empty(): context = {"known_resource": observed.node, "resource_position": observed.position, "resource_range": observed.range}
	return module.decisions.choose(actor, tick_value, context)

func _apply_intent(id: String, intent_value: Dictionary) -> void:
	var bundle := module.actors[id]
	var host := hosts[id]
	var actor := bundle.state
	if bundle.combatant.lifecycle != Combatant.Lifecycle.ALIVE: return
	var kind: String = intent_value.get("kind", "idle")
	if kind == "navigate" and intent_value.get("point") is Vector3:
		var destination: Vector3 = intent_value.point
		if not region.safe_position(destination): _clear_route(id); _stop_move(id); return
		if _navigation_distance_squared(actor.position, destination) < 0.25:
			_clear_route(id)
			_stop_move(id)
			_complete_activity(actor)
			return
		_begin_activity(actor, intent_value.get("goal", "work"), destination)
		if not _destinations.has(id) or (_destinations[id] as Vector3).distance_squared_to(destination) > 0.25:
			_clear_route(id)
			_destinations[id] = destination
		# Empty/temporarily unavailable local routes must recover when chunks
		# become available. Retry at 2 Hz for at most four active bodies.
		if not _routes.has(id) and module.combat.clock.tick >= int(_path_retry_tick.get(id, 0)):
			module.paths.request(id, actor.materialization_epoch, actor.position, destination, actor.region_id)
			_path_retry_tick[id] = module.combat.clock.tick + 10
	elif kind in ["action", "item.harvest"]:
		_clear_route(id)
		_stop_move(id)
		var payload := {"slot": intent_value.slot, "target": intent_value.target} if kind == "action" else {"node": intent_value.node}
		var result := host.submit_authority_intent(id, actor.materialization_epoch, kind, payload)
		executed_intents += 1
		if result.code in ["DEPLETED", "OUT_OF_RANGE", "NODE_UNKNOWN", "TARGET_UNAVAILABLE"]: actor.plan_dirty = true
	else: _clear_route(id); _stop_move(id)

func _apply_reduced(actor: LivingActorState, intent_value: Dictionary) -> void:
	if module.actors[actor.actor_id].combatant.lifecycle != Combatant.Lifecycle.ALIVE: return
	if intent_value.get("kind") != "navigate" or not intent_value.get("point") is Vector3: return
	var destination: Vector3 = intent_value.point
	if not region.safe_position(destination): return
	if _navigation_distance_squared(actor.position, destination) < 0.25: _complete_activity(actor); return
	_begin_activity(actor, intent_value.get("goal", "work"), destination)

func _begin_activity(actor: LivingActorState, goal: String, destination: Vector3) -> void:
	var kind := "work" if goal in ["work", "guard", "gather", "combat"] else goal
	if kind not in ["work", "rest", "shelter", "travel"]: kind = "travel"
	var identifier := "activity.goal." + goal
	if not CoreIds.valid(identifier): identifier = "activity.goal.travel"
	if not actor.activity.is_empty() and actor.activity.id == identifier and Vector3(actor.activity.destination[0], actor.activity.destination[1], actor.activity.destination[2]).distance_squared_to(destination) < 0.25: return
	var duration := maxi(10, ceili(actor.position.distance_to(destination) / 4.0 / module.combat.clock.step_seconds))
	actor.begin_activity(identifier, kind, destination, module.combat.clock.tick, module.combat.clock.tick + duration)

func _complete_activity(actor: LivingActorState) -> void:
	if not actor.activity.is_empty() and not actor.activity.completed:
		actor.activity.completed = true
		actor.revision += 1
		module.revision += 1

func _follow_route(id: String) -> void:
	if not hosts.has(id) or not _routes.has(id): return
	var actor := module.actors[id].state
	var path: Array = _routes[id]
	while not path.is_empty() and _navigation_distance_squared(actor.position, path[0]) < 0.36: path.pop_front()
	if path.is_empty(): _clear_route(id); _stop_move(id); _complete_activity(actor); return
	var direction: Vector3 = path[0] - actor.position
	direction.y = 0
	if direction.length_squared() < 0.01: _stop_move(id); return
	direction = direction.normalized()
	hosts[id].submit_authority_intent(id, actor.materialization_epoch, "move", {"axis": Vector2(direction.x, direction.z), "facing": direction, "jump": false})

static func _navigation_distance_squared(first: Vector3, second: Vector3) -> float:
	return Vector2(first.x - second.x, first.z - second.z).length_squared()

func _clear_route(id: String) -> void:
	_routes.erase(id)
	_destinations.erase(id)
	_path_retry_tick.erase(id)

func _stop_move(id: String) -> void:
	if hosts.has(id):
		var actor := module.actors[id].state
		hosts[id].submit_authority_intent(id, actor.materialization_epoch, "move", {"axis": Vector2.ZERO, "facing": actor.facing, "jump": false})

func _materialize(id: String) -> void:
	if bodies.has(id) or bodies.size() >= MAX_MATERIALIZED: return
	var bundle := module.actors[id]
	var actor := bundle.state
	var host := LocalAuthorityHost.new()
	host.configure(module.combat, bundle.actions, actor.player_state, "", root_host.defense)
	host.server_intent_epoch = actor.materialization_epoch
	bundle.actions.position_of = targeting.position_of
	bundle.actions.target_gate = _visible_ids
	var port := ItemsAuthorityPort.new()
	port.region_id = func() -> String: return actor.region_id
	port.spatial_gate = func(point: Vector3) -> bool: return queries.visible(actor.position, point)
	bundle.bind_item_eligibility()
	port.bind_context(host, bundle.items)
	var body := LivingBody.new()
	body.bundle = bundle
	body.state = actor.player_state
	body.intent = host.movement
	body.tuning = (preload("res://foundation/player/default_tuning.tres") as PlayerTuning).duplicate(true) as PlayerTuning
	body.movement_gate = host.movement_allowed
	body.turning_gate = bundle.actions.turning_allowed
	body.authority_step = host.physics_step
	host.move_port = body.simulate
	host.safe_spawn = func() -> void:
		actor.position = actor.home
		actor.player_state.velocity = Vector3.ZERO
		body.position = actor.position
	bodies[id] = body
	hosts[id] = host
	add_child(body)
	targeting.register(id, func() -> Vector3: return actor.position)
	targeting.disposition.groups[id] = actor.allegiance
	module.perception.spatial.update(id, actor.position)
	_last_wood[id] = bundle.items.inventory.quantity(bundle.items.bag_id, "item.wood.common")
	materializations += 1
	peak_bodies = maxi(peak_bodies, bodies.size())

func _dematerialize(id: String) -> void:
	if not bodies.has(id): return
	var bundle := module.actors[id]
	var host := hosts[id]
	host.server_intent_epoch = -1
	bundle.actions.interrupt()
	root_host.defense.state(id).guard = false
	host.dispose()
	bundle.actions.position_of = Callable()
	var body := bodies[id]
	body.authority_step = Callable()
	body.movement_gate = Callable()
	body.turning_gate = Callable()
	body.set_physics_process(false)
	remove_child(body)
	body.free()
	bodies.erase(id)
	hosts.erase(id)
	_clear_route(id)
	_last_wood.erase(id)
	targeting.unregister(id)
	targeting.disposition.groups.erase(id)
	module.perception.spatial.remove(id)
	dematerializations += 1

func _refresh_location(actor: LivingActorState) -> void:
	actor.chunk_id = region.chunk_id(region.to_local_position(actor.position))

func _visible_ids(source: String, target: String) -> bool:
	var first: Variant = targeting.position_of(source)
	var second: Variant = targeting.position_of(target)
	return first is Vector3 and second is Vector3 and queries.visible(first, second)

func _configure_factions() -> void:
	var policy := targeting.disposition
	for id: String in policy.groups:
		if policy.groups[id] == "disposition.traveler": policy.groups[id] = module.player_identity.allegiance
		elif policy.groups[id] == "disposition.hostile": policy.groups[id] = "faction.raiders"
	for definition: FactionDefinition in module.catalog.factions:
		var hostiles: Array = []
		for target: String in definition.dispositions:
			if definition.dispositions[target] == "hostile": hostiles.append(target)
		policy.hostile_groups[definition.faction_id] = hostiles

func snapshot() -> Dictionary:
	var actors := {}
	for id: String in module.actors:
		var bundle := module.actors[id]
		actors[id] = {"kind": bundle.state.kind, "position": LivingActorState._array(bundle.state.position), "chunk_id": bundle.state.chunk_id, "fidelity": bundle.state.fidelity, "epoch": bundle.state.materialization_epoch, "health": bundle.combatant.health, "goal": bundle.state.plan.get("goal", ""), "activity": bundle.state.activity.duplicate(true), "memories": bundle.state.memory.capture(), "xp": bundle.state.progression.xp, "wood": bundle.items.inventory.quantity(bundle.items.bag_id, "item.wood.common"), "materialized": bodies.has(id)}
	return {"logical_actors": module.actors.size(), "materialized_actors": bodies.size(), "peak_materialized": peak_bodies, "materializations": materializations, "dematerializations": dematerializations, "fidelity": module.scheduler.fidelity_counts(), "scheduler": module.scheduler.metrics.duplicate(), "path_requests": module.paths.requested, "paths_resolved": module.paths.resolved, "perception_queries": module.perception.spatial.query_count, "resource_queries": queries.resource_queries, "resource_candidates": queries.resource_candidates, "intents": executed_intents, "bot_harvests": successful_bot_harvests, "actors": actors}

func dispose() -> void:
	if _disposed: return
	_disposed = true
	for id: String in bodies.keys(): _dematerialize(id)
	module.scheduler.decision_port = Callable()
	_routes.clear()
	_destinations.clear()
	_path_retry_tick.clear()
	_waiting_chunks.clear()
	_last_wood.clear()
	active_chunks = Callable()
	spatial_gate = Callable()
	route_port = Callable()
	queries.active_chunks = Callable()
	queries.spatial_gate = Callable()
	queries.targeting = null
	queries.module = null

func _exit_tree() -> void:
	dispose()
