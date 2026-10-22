extends "res://tests/p2_scenario_driver.gd"

# Production PlayerIntent/AuthorityGateway only. This fixture never teleports,
# grants stock, edits health, injects memory or changes the simulation clock.
func run() -> void:
	proofs.initial_chunk_hash = runtime.genesis.ledger.record(Vector2i.ZERO).base_hash
	proofs.memory_before = OS.get_static_memory_usage()
	if not await _defeat_enemy(): return
	proofs.defeat_xp = runtime.living.player_identity.progression.xp
	var drop_id := "drop.spawn.melee_skirmisher"
	var drop: Dictionary = runtime.items.drops.get(drop_id, {})
	if drop.is_empty(): fail("LOOT_MISSING"); return
	if not await _move_to(Vector3(drop.position[0], drop.position[1], drop.position[2]), 1.8): return
	if not await _command("item.pickup", {"drop": drop_id}, func() -> bool: return runtime.items.drops[drop_id].claimed): return
	if not await _equip("tool", "item.tool.pickaxe"): return
	var mineral := "resource.node.stone"
	if not await _move_to(runtime.items.resources.definition(mineral).position, 1.4): return
	while runtime.items.resources.snapshot(mineral, runtime.core.clock.tick).remaining > 0:
		if not await _harvest(mineral): return
	proofs.depleted_node = mineral
	proofs.depleted_remaining = runtime.items.resources.snapshot(mineral, runtime.core.clock.tick).remaining
	proofs.outbound = []
	phase = "stream_outbound"
	for x in [16.0, 40.0, 72.0, 104.0]:
		if not await _move_to(Vector3(x, 0, 4), 0.8): return
		for frame in range(15): await get_tree().physics_frame
		proofs.outbound.append(_sample())
	# Pick a real NPC close enough to hear one generated resource being harvested.
	var npc_id := ""
	var resource_id := ""
	var best := INF
	for id: String in runtime.living.actors:
		var actor: LivingActorState = runtime.living.actors[id].state
		if actor.kind != "npc": continue
		for candidate: String in runtime.items.resources.node_ids():
			var candidate_node: ResourceNodeDefinition = runtime.items.resources.definition(candidate)
			var distance: float = actor.position.distance_to(candidate_node.position)
			var valid: bool = actor.position.x >= 64 and actor.position.x <= 125 and candidate_node.position.x <= 125 and distance < 14.0 and runtime.items.resources.snapshot(candidate, runtime.core.clock.tick).remaining > 0
			if valid and actor.position.distance_to(runtime.player.state.position) < best:
				npc_id = id
				resource_id = candidate
				best = actor.position.distance_to(runtime.player.state.position)
	if npc_id.is_empty(): fail("NPC_RESOURCE_PAIR_MISSING"); return
	phase = "npc_perception"
	var npc: LivingActorState = runtime.living.actors[npc_id].state
	var node: ResourceNodeDefinition = runtime.items.resources.definition(resource_id)
	var profile: ResourceDefinition = runtime.items.content.profile(node.profile_id)
	if not await _equip("tool", "item.tool.axe" if profile.tool_tag == "tool.axe" else "item.tool.pickaxe"): return
	if not await _move_to(node.position, 1.4): return
	var heard_before: int = runtime.living.perception.memories_created
	var remaining_before: int = runtime.items.resources.snapshot(resource_id, runtime.core.clock.tick).remaining
	if not await _command("item.harvest", {"node": resource_id}, func() -> bool: return runtime.items.resources.snapshot(resource_id, runtime.core.clock.tick).remaining < remaining_before, ItemsModule.harvest_action(node.profile_id)): return
	for frame in range(20): await get_tree().physics_frame
	proofs.npc_id = npc_id
	proofs.heard_event = runtime.living.perception.memories_created > heard_before
	proofs.npc_memory = npc.memory.capture()
	proofs.npc_goal = npc.plan.get("goal", "")
	proofs.npc_activity = npc.activity.duplicate(true)
	phase = "bot_canonical_gather"
	var bot_id := ""
	best = INF
	for id: String in runtime.living.actors:
		var actor: LivingActorState = runtime.living.actors[id].state
		var distance: float = actor.position.distance_to(runtime.player.state.position)
		if actor.kind == "bot" and distance < best: bot_id = id; best = distance
	if bot_id.is_empty(): fail("BOT_MISSING"); return
	var bot: LivingActorState = runtime.living.actors[bot_id].state
	if not await _move_to(bot.position, 3.0): return
	var deadline: int = runtime.core.clock.tick + 240
	while runtime.living.actors[bot_id].items.inventory.quantity(bot.inventory_id, "item.wood.common") == 0:
		if not _healthy(deadline): return
		await get_tree().physics_frame
	proofs.bot_id = bot_id
	proofs.bot_wood = runtime.living.actors[bot_id].items.inventory.quantity(bot.inventory_id, "item.wood.common")
	proofs.bot_xp = bot.progression.xp
	proofs.bot_host_shared_defense = runtime.living_runtime.hosts[bot_id].defense == runtime.authority_host.defense if runtime.living_runtime.hosts.has(bot_id) else false
	phase = "stream_return"
	proofs.inbound = []
	for x in [104.0, 72.0, 40.0, 4.0]:
		if not await _move_to(Vector3(x, 0, 4), 0.8): return
		for frame in range(15): await get_tree().physics_frame
		proofs.inbound.append(_sample())
	proofs.mutation_after_stream = runtime.items.resources.snapshot(mineral, runtime.core.clock.tick).remaining == 0
	proofs.npc_memory_after_stream = npc.memory.capture()
	proofs.final_chunk_hash = runtime.genesis.ledger.record(Vector2i.ZERO).base_hash
	proofs.memory_after = OS.get_static_memory_usage()
	proofs.streaming = runtime.streamer.snapshot()
	proofs.living = runtime.living_runtime.snapshot()
	proofs.player_xp = runtime.living.player_identity.progression.xp
	proofs.player_level = runtime.living.catalog.progression("progression.chapter1_foundation").level_for(proofs.player_xp)
	proofs.elapsed_ticks = runtime.core.clock.tick - _start_tick
	var passed: bool = proofs.defeat_xp >= 25 and proofs.depleted_remaining == 0 and proofs.mutation_after_stream and proofs.bot_wood > 0 and proofs.bot_xp > 0 and proofs.bot_host_shared_defense and not proofs.npc_memory.records.is_empty() and proofs.npc_goal == "inspect" and proofs.heard_event and proofs.streaming.metrics.unloads > 0 and proofs.streaming.metrics.peak_loaded <= 25 and proofs.living.peak_materialized <= 4 and proofs.initial_chunk_hash == proofs.final_chunk_hash
	if not passed: fail("P3_INVARIANT_FAILED"); return
	phase = "checkpoint"
	result = runtime.checkpoint_scenario(proofs)
	phase = "checkpoint_saved" if result.get("passed", false) else "failed"

func _sample() -> Dictionary:
	return {"position": runtime.player.state.capture().position, "chunks": runtime.streamer.views.size(), "actors": runtime.living.actors.size(), "bodies": runtime.living_runtime.bodies.size(), "memory_bytes": OS.get_static_memory_usage(), "generation_count": runtime.genesis.ledger.generator.generation_invocation_count}
