extends SceneTree

# Exercises the production composition, not a second materialization harness.
# Relocation below is trusted test setup; Bot gameplay still enters its real host.
var checks := 0
var failures := 0
var runtime: Node
var slot := ""

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)

func freeze() -> void:
	runtime.set_process(false)
	runtime.persistence.suppress_autosave = true
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	avatar.input.set_physics_process(false)
	avatar.input.set_process_input(false)
	avatar.motor.set_physics_process(false)
	for body: LivingBody in runtime.living_runtime.bodies.values(): body.set_physics_process(false)

func focus(point: Vector3) -> void:
	runtime.player.state.position = point
	runtime.living_runtime.invalidate_relevance()
	runtime.living_runtime.sync_relevance(point)
	for body: LivingBody in runtime.living_runtime.bodies.values(): body.set_physics_process(false)

func run() -> void:
	slot = "user://tests/p3-materialization-%s.json" % CoreIds.generate()
	runtime = preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.p3_materialization", slot)
	root.add_child(runtime)
	check(runtime.startup_error == OK and is_instance_valid(runtime.living_runtime), "production P3 runtime boots with living adapter")
	if runtime.startup_error != OK or not is_instance_valid(runtime.living_runtime):
		runtime.free()
		quit(1)
		return
	freeze()
	check(runtime.streamer.views.size() == 9, "canonical startup attaches bounded chunk collision")
	var initial_generations: int = runtime.genesis.ledger.generator.generation_invocation_count
	runtime.streamer.advance_frame()
	check(runtime.genesis.ledger.generator.generation_invocation_count == initial_generations, "cold world work yields to the existing P1 combat threat")
	# The accepted P1/P2 arena is deliberately free of procedural spawn additions.
	# Stream to its neighboring generated cells using the real bounded streamer.
	runtime.player.state.position = Vector3(80, 0.1, 8)
	for _index in 32:
		runtime.core.clock.tick += 1
		runtime.streamer.advance_frame()
	var logical_count: int = runtime.living.actors.size()
	var id := ""
	for candidate: String in runtime.living.actors:
		if runtime.living.actors[candidate].state.kind == "bot" and runtime.streamer.active_chunk(runtime.living.actors[candidate].state.chunk_id): id = candidate; break
	check(not id.is_empty(), "generated first-scope spawn includes a logical Player-like Bot")
	if id.is_empty():
		runtime.free()
		quit(1)
		return
	var bundle: LivingCapabilities = runtime.living.actors[id]
	var center := bundle.state.position
	focus(center)
	check(runtime.living_runtime.bodies.has(id) and runtime.living_runtime.hosts.has(id), "nearby logical Bot materializes through production adapter")
	var original_body: LivingBody = runtime.living_runtime.bodies[id]
	var original_host: LocalAuthorityHost = runtime.living_runtime.hosts[id]
	check(original_body.state == bundle.state.player_state and original_host.player == bundle.state.player_state and original_host.actions == bundle.actions, "runtime body and host reference the same canonical actor capabilities")
	check(original_host.defense == runtime.authority_host.defense, "materialized Bot shares the root P1 defense contract")
	check(runtime.living_runtime.bodies.size() <= LivingRuntime.MAX_MATERIALIZED, "runtime actor population is explicitly bounded")
	var original_epoch := bundle.state.materialization_epoch
	var inventory := bundle.items.inventory.capture()
	var health := bundle.combatant.health
	var location := bundle.state.position
	var activity := bundle.state.activity.duplicate(true)
	var allegiance := bundle.state.allegiance
	var shared_policy: Callable = runtime.combat.service.damage_policy
	runtime.authority_host.defense.set_guard(runtime.player.state.entity_id, true)
	focus(Vector3(120, center.y, 120))
	check(not runtime.living_runtime.bodies.has(id) and not is_instance_valid(original_body), "irrelevant actor body is freed synchronously")
	check(runtime.living.actors[id] == bundle and runtime.living.actors.size() == logical_count, "dematerialization keeps the same logical identity without duplicate actors")
	check(bundle.items.inventory.capture() == inventory and bundle.combatant.health == health and bundle.state.position == location and bundle.state.allegiance == allegiance and bundle.state.activity == activity, "demotion preserves custody health allegiance location and activity")
	check(original_host.submit_authority_intent(id, original_epoch, "cancel", {}).code == "STALE_ACTOR_EPOCH", "retained old producer cannot act after its body dematerializes")
	check(runtime.targeting.service.position_of(id) == null and not bundle.actions.position_of.is_valid() and not bundle.actions.activation_gate.is_valid(), "demotion removes transient target and action callbacks")
	check(runtime.authority_host.defense.state(runtime.player.state.entity_id).guard and runtime.combat.service.damage_policy == shared_policy and runtime.authority_host.defense.position_of.is_valid(), "demotion leaves root Player guard and global mitigation ports intact")
	focus(center)
	var promoted: LocalAuthorityHost = runtime.living_runtime.hosts[id]
	check(promoted != original_host and bundle.state.materialization_epoch > original_epoch, "promotion creates a fresh host and invalidates former materialization epoch")
	check(promoted.actions == bundle.actions and runtime.living_runtime.bodies[id].state == bundle.state.player_state and bundle.items.inventory.capture() == inventory, "promotion reuses canonical capabilities and stock")
	var item_port := promoted.command_ports["skill.equip"] as ItemsAuthorityPort
	check(item_port.items == bundle.items and promoted.actions.capability_port != null and promoted.extension_snapshot.is_valid(), "rematerialized Bot has a live shared Items context and effect/snapshot ports")
	var result := promoted.submit_authority_intent(id, bundle.state.materialization_epoch, "skill.equip", {"slot": "skill_3", "action": "combat.action.basic_heal"})
	check(result.code == "SKILL_EQUIPPED" and promoted.loadout_state().slots.skill_3 == "combat.action.basic_heal" and bundle.items.loadout.slots.skill_3 == "combat.action.basic_heal", "actual rematerialized Bot skill mutation updates canonical loadout and host together")
	var body_count: int = runtime.living_runtime.bodies.size()
	for _index in 8:
		focus(Vector3(120, center.y, 120))
		focus(center)
	check(runtime.living_runtime.bodies.size() == body_count and runtime.living.actors.size() == logical_count and runtime.living_runtime.peak_bodies <= LivingRuntime.MAX_MATERIALIZED, "repeated promotion/demotion preserves bounded runtime and logical populations")
	check(runtime.targeting.service._positions.size() <= logical_count + 3, "repeated actor cycles never duplicate spatial target registrations")
	# A deadline can move a reduced actor into view while the Player stays still.
	var npc_id := ""
	for candidate: String in runtime.living.actors:
		if runtime.living.actors[candidate].state.kind == "npc" and not runtime.living_runtime.bodies.has(candidate): npc_id = candidate; break
	if not npc_id.is_empty():
		var npc: LivingActorState = runtime.living.actors[npc_id].state
		npc.begin_activity("activity.test.arrive", "travel", center, runtime.core.clock.tick, runtime.core.clock.tick + 1)
		runtime.living.scheduler.set_fidelity(npc_id, LivingActorState.Fidelity.L2, runtime.core.clock.tick)
		runtime.living.scheduler.wake(npc_id, runtime.core.clock.tick + 1)
		runtime.core.clock.tick += 1
		# Earlier due actors share the scheduler's production eight-job budget.
		for _index in ceili(float(logical_count) / LivingScheduler.JOB_BUDGET) + 2: runtime.living_runtime.tick()
		check(npc.position == center and runtime.living_runtime.bodies.has(npc_id), "resolved deadline wakes relevance and promotes actor even while Player stands still")
	else: check(false, "test world includes a reduced NPC for deadline wakeup")
	# Failed route resolution must retry after its source/destination becomes ready;
	# it cannot permanently memoize an unavailable route as an accepted one.
	var living_view: LivingRuntime = runtime.living_runtime
	var route := living_view.route_port
	living_view.route_port = func(_from: Vector3, _to: Vector3, _region: String) -> Array: return []
	var actor: LivingActorState = bundle.state
	var destination := actor.position + Vector3(-2, 0, 0)
	living_view._apply_intent(id, {"kind": "navigate", "point": destination, "goal": "work"})
	runtime.living.paths.advance(living_view.route_port, runtime.living.scheduler.valid_intent_epoch)
	var requests_before: int = runtime.living.paths.requested
	runtime.core.clock.tick += 10
	living_view.route_port = route
	living_view._apply_intent(id, {"kind": "navigate", "point": destination, "goal": "work"})
	check(runtime.living.paths.requested > requests_before, "temporarily unavailable local route retries with a bounded deadline")
	var resolved: Array[Dictionary] = runtime.living.paths.advance(living_view.route_port, runtime.living.scheduler.valid_intent_epoch)
	check(not resolved.is_empty(), "retried route uses the real now-available chunk navigation port")
	living_view._apply_intent(id, {"kind": "navigate", "point": Vector3(100000, 0, 100000), "goal": "work"})
	check(not living_view._destinations.has(id), "authority navigation rejects destinations outside region ownership")
	living_view._apply_intent(id, {"kind": "navigate", "point": actor.position + Vector3(0, 2, 0), "goal": "work"})
	check(not living_view._destinations.has(id), "grounded local navigation settles horizontal arrival across changing terrain heights")
	# Generated spawn profiles are nonrenewable in this first scope. A defeated
	# Bot keeps its death canonically when reduced, resumed or materialized again.
	actor.begin_activity("activity.test.defeated", "travel", destination, runtime.core.clock.tick, runtime.core.clock.tick + 1)
	runtime.combat.service.damage(DamageRequest.new(runtime.enemies.actor.entity_id, id, 1000))
	check(bundle.combatant.lifecycle == Combatant.Lifecycle.DEFEATED and actor.activity.is_empty(), "defeat interrupts logical activity before dematerialization")
	var death_position := actor.position
	focus(Vector3(-120, center.y, -120))
	for _index in 64:
		runtime.core.clock.tick += 1
		living_view.tick()
	check(actor.fidelity == LivingActorState.Fidelity.L3 and actor.position == death_position and bundle.combatant.lifecycle == Combatant.Lifecycle.DEFEATED, "latent defeated actor never resolves an old route or respawns while unmaterialized")
	focus(death_position)
	for _index in 32:
		runtime.core.clock.tick += 1
		living_view.tick()
	check(bundle.combatant.lifecycle == Combatant.Lifecycle.DEFEATED and living_view.bodies.has(id), "rematerialized generated Bot preserves canonical death without Player respawn policy")
	runtime.authority_host.defense.set_guard(runtime.player.state.entity_id, false)
	check(runtime.save_game() == OK, "materialized and reduced actor capabilities form a valid canonical save")
	runtime.persistence.suppress_autosave = true
	runtime.free()
	DirAccess.remove_absolute(slot)
	await process_frame
	print("P3 actor materialization tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
