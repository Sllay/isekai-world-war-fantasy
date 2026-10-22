class_name LivingWorldQueries
extends RefCounted

# Bounded authority query adapter. No SceneTree scans or camera knowledge.
var module: LivingModule
var targeting: TargetingService
var region: RegionDefinition
var active_chunks: Callable
var spatial_gate: Callable
var resource_sense_range := 20.0
var _resource_cells: Dictionary = {}
var _resource_count := -1
var resource_queries := 0
var resource_candidates := 0
var target_queries := 0

func observed_resource(actor: LivingActorState) -> Dictionary:
	_reindex_resources()
	resource_queries += 1
	var tool := module.actors[actor.actor_id].items.tool()
	if tool == null: return {}
	var best := {}
	var distance := resource_sense_range * resource_sense_range
	var cell := ActorSpatialIndex._cell(actor.position)
	var examined := 0
	for x in range(cell.x - 2, cell.x + 3):
		for z in range(cell.y - 2, cell.y + 3):
			for id: String in _resource_cells.get(Vector2i(x, z), []):
				examined += 1
				resource_candidates += 1
				if examined > 64: return best
				var node := module.items.resources.definition(id)
				if node.region_id != actor.region_id or not _active(node.position): continue
				var squared := actor.position.distance_squared_to(node.position)
				if squared > distance or not visible(actor.position, node.position): continue
				var profile := module.items.content.profile(node.profile_id)
				if not tool.tool_tags.has(profile.tool_tag) or tool.tool_power < profile.minimum_tool_power: continue
				if module.items.resources.snapshot(id, module.combat.clock.tick).remaining <= 0: continue
				best = {"node": id, "position": node.position, "range": profile.interaction_range}
				distance = squared
	return best

func observed_target(actor: LivingActorState) -> Dictionary:
	target_queries += 1
	# Targeting contains only the bounded active actor set, not the logical world.
	# It already applies canonical range, lifecycle, relation and visibility.
	var targets := targeting.hostiles(actor.actor_id, 12.0)
	if targets.is_empty(): return {}
	var id := targets[0]
	var point: Variant = targeting.position_of(id)
	if not point is Vector3 or not visible(actor.position, point): return {}
	return {"target_id": id, "target_position": point, "target_perceived": true, "target_in_range": actor.position.distance_squared_to(point) <= 6.25}

func visible(origin: Vector3, destination: Vector3) -> bool:
	return not spatial_gate.is_valid() or bool(spatial_gate.call(origin, destination))

func _active(point: Vector3) -> bool:
	var key := region.chunk_id(region.to_local_position(point))
	return active_chunks.is_valid() and bool(active_chunks.call(key))

func _reindex_resources() -> void:
	var nodes: ResourceService = module.items.resources
	if nodes.node_count() == _resource_count: return
	var ids := nodes.node_ids()
	_resource_count = ids.size()
	_resource_cells.clear()
	for id: String in ids:
		var node := module.items.resources.definition(id)
		var cell := ActorSpatialIndex._cell(node.position)
		if not _resource_cells.has(cell): _resource_cells[cell] = []
		_resource_cells[cell].append(id)
