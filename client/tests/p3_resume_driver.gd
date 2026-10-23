extends "res://tests/p2_scenario_driver.gd"

# Continue the saved outing through ordinary semantic movement, proving that
# fresh-process logical actors can become physical again without new identities.
func run() -> void:
	phase = "resume_walk"
	var npc_id: String = runtime.scenario_result.proofs.npc_id
	var bundle: LivingCapabilities = runtime.living.actors[npc_id]
	var ids: Array = runtime.living.actors.keys()
	ids.sort()
	var health := bundle.combatant.health
	var inventory := bundle.items.inventory.capture()
	var faction := bundle.state.allegiance
	for x in [40.0, 72.0, 104.0]:
		if not await _move_to(Vector3(x, 0, 4), 0.8): return
	if not await _move_to(bundle.state.position, 3.0): return
	for frame in range(25): await get_tree().physics_frame
	var after: Array = runtime.living.actors.keys()
	after.sort()
	result = {"passed": runtime.living_runtime.bodies.has(npc_id) and ids == after and bundle.combatant.health == health and bundle.items.inventory.capture() == inventory and bundle.state.allegiance == faction and runtime.genesis.ledger.generator.generation_invocation_count == 0, "npc_materialized": runtime.living_runtime.bodies.has(npc_id), "same_actor_ids": ids == after, "npc_health_preserved": bundle.combatant.health == health, "npc_inventory_preserved": bundle.items.inventory.capture() == inventory, "faction_preserved": bundle.state.allegiance == faction, "generator_calls": runtime.genesis.ledger.generator.generation_invocation_count, "living": runtime.living_runtime.snapshot(), "streaming": runtime.streamer.snapshot()}
	phase = "resume_rematerialized" if result.passed else "failed"
	runtime.scenario_result["post_resume"] = result
	runtime.freeze_scenario()
