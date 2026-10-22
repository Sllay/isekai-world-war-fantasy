extends SceneTree

# Two independently launched OS processes exercise the production runtime/save
# coordinator. The save phase uses explicit trusted domain fixture setup; the
# separate Runtime MCP scenario drives actual semantic Player/Bot gameplay.
const CELL := Vector2i(3, 0)
var runtime: Node
var checks := 0
var failures := 0
var slot := ""
var mode := ""

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func freeze() -> void:
	runtime.set_process(false)
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	avatar.motor.set_physics_process(false)
	avatar.input.set_physics_process(false)
	avatar.input.set_process_input(false)
	avatar.intent.clear_transient()
	if is_instance_valid(runtime.enemy_body): runtime.enemy_body.set_physics_process(false)
	for body in runtime.companion_bodies: body.set_physics_process(false)
	for body in runtime.living_runtime.bodies.values(): body.set_physics_process(false)
	runtime.persistence.suppress_autosave = true

func run() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument in ["save", "resume"]: mode = argument
		if argument.begins_with("--p3-slot="): slot = argument.trim_prefix("--p3-slot=")
	if mode.is_empty() or slot.is_empty() or not slot.is_absolute_path():
		push_error("Use save|resume --p3-slot=/absolute/isolated-slot.json")
		quit(1)
		return
	if mode == "save" and (FileAccess.file_exists(slot) or FileAccess.file_exists(slot + ".expected.json")):
		push_error("Save phase requires a fresh isolated slot")
		quit(1)
		return
	runtime = preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.p3_process", slot)
	root.add_child(runtime)
	check(runtime.startup_error == OK, "isolated %s process boots production runtime" % mode)
	if runtime.startup_error != OK:
		runtime.free()
		quit(1)
		return
	freeze()
	if mode == "save": save_phase()
	else: resume_phase()
	var metrics: Dictionary = runtime.streamer.snapshot()
	metrics["page_io"] = runtime.core.saves.pages.metrics.duplicate()
	metrics["logical_actors"] = runtime.living.actors.size()
	metrics["materialized_actors"] = runtime.living_runtime.bodies.size()
	metrics["memory_bytes"] = OS.get_static_memory_usage()
	print("P3 fresh-process %s evidence: %s" % [mode, JSON.stringify(metrics)])
	runtime.persistence.suppress_autosave = true
	runtime.free()
	await process_frame
	print("P3 fresh-process %s tests: %d checks, %d failures" % [mode, checks, failures])
	quit(0 if failures == 0 else 1)

func save_phase() -> void:
	var before: int = runtime.genesis.ledger.generator.generation_invocation_count
	var generated: Dictionary = runtime.streamer._ensure(CELL)
	check(generated.ok and runtime.genesis.ledger.generator.generation_invocation_count == before + 1, "first missing chunk calls generator exactly once then durably commits")
	if not generated.ok: return
	var record: Dictionary = generated.record
	check(record.base.spawns.size() == 2 and record.delta.spawn_claims.size() == 2 and runtime.living.actors.size() == 2, "generated spawn identities are claimed once and logically resident")
	# The mineral placement always uses the P2 stone/ore definition. Gathering
	# uses the actual owned ledger, catalog tool and canonical ResourceService.
	var descriptor: Dictionary = record.base.resources[1]
	var node := runtime.items.resources.definition(descriptor.node_id) as ResourceNodeDefinition
	var profile := runtime.items.content.profile(node.profile_id) as ResourceDefinition
	var tool := runtime.items.catalog.lookup("item.tool.pickaxe") as ItemDefinition
	var before_inventory: Dictionary = runtime.items.inventory.capture()
	check(profile.regeneration_ticks == 0 and tool.tool_power >= profile.minimum_tool_power, "generated mineral reuses a permanent P2 node and valid catalog tool")
	for extraction in range(profile.reserves):
		var result: Dictionary = runtime.items.resources.gather(runtime.player.state.entity_id, ItemsModule.BAG, node.node_id, runtime.core.clock.tick, node.position, tool)
		check(result.ok, "canonical P2 gather commits extraction %d" % extraction)
		if not result.ok: return
		var fact := ItemWorkCommitted.new()
		fact.actor_id = runtime.player.state.entity_id
		fact.cause = "resource.harvest"
		fact.subject_id = node.node_id
		fact.sequence = extraction + 1
		fact.tick = runtime.core.clock.tick
		check(runtime.combat.service.events.publish(fact) == OK, "committed gather fact enters shared event contract")
	check(runtime.items.inventory.capture() != before_inventory and runtime.items.resources.snapshot(node.node_id, runtime.core.clock.tick).remaining == 0, "P2 inventory receives canonical yield and mineral becomes depleted")
	check(runtime.genesis.ledger.record(CELL).delta.removed_resources.has(node.node_id), "committed depletion produces the canonical chunk mutation")
	var actor_id: String = record.base.spawns[0].actor_id
	var bundle: LivingCapabilities = runtime.living.actors[actor_id]
	bundle.combatant.health = 66
	var memory := {"id": "memory.restart_anchor", "kind": "memory.threat", "subject_id": runtime.player.state.entity_id, "position": [0, 0, 0], "created_tick": runtime.core.clock.tick, "importance": 90, "confidence": 100, "expires_tick": -1, "source": "perception.hearing", "anchor": true}
	check(bundle.state.memory.remember(memory, runtime.core.clock.tick, runtime.core.entities.contains) == "REMEMBERED", "durable actor memory references a canonical entity")
	check(runtime.living.award(actor_id, "world.discovery", record.base.landmarks[0].id, 1).accepted, "trusted progression fixture uses an existing canonical world event source")
	check(runtime.save_game() == OK, "production coordinator commits modified chunk, P2 reserves and actor state")
	var expected := canonical_proof()
	expected["node_id"] = node.node_id
	expected["actor_id"] = actor_id
	expected["saved_generation_invocations"] = runtime.genesis.ledger.generator.generation_invocation_count
	var file := FileAccess.open(slot + ".expected.json", FileAccess.WRITE)
	check(file != null, "cross-process comparison evidence opens")
	if file != null:
		file.store_string(JSON.stringify(expected, "", true, true))
		file.close()

func resume_phase() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(slot + ".expected.json"))
	check(parsed is Dictionary, "fresh process reads comparison evidence")
	if not parsed is Dictionary: return
	var expected: Dictionary = parsed
	check(runtime.persistence.startup_mode == "resume", "fresh process uses persisted canonical slot")
	check(runtime.genesis.ledger.generator.generation_invocation_count == 0, "boot restores persisted chunks without any generator call")
	var loaded: Dictionary = runtime.streamer._ensure(CELL)
	check(loaded.ok and runtime.genesis.ledger.generator.generation_invocation_count == 0, "explicit persisted chunk request does not invoke generator")
	if not loaded.ok: return
	var actual := canonical_proof()
	for key: String in actual:
		check(actual[key] == expected.get(key), "fresh process retains canonical " + key)
	check(runtime.items.resources.snapshot(expected.node_id, runtime.core.clock.tick).remaining == 0 and loaded.record.delta.removed_resources.has(expected.node_id), "depleted world mineral stays removed across OS process restart")
	check(runtime.living.actors.size() == 2 and runtime.living.actors.has(expected.actor_id) and runtime.living.actors[expected.actor_id].combatant.health == 66, "logical actors restore without duplication or health loss")
	var actor := runtime.living.actors[expected.actor_id].state as LivingActorState
	check(actor.memory.capture().records.size() == 1 and actor.progression.xp == 8, "durable memory and progression restore independently of runtime Nodes")
	var metrics: Dictionary = runtime.core.saves.pages.metrics.duplicate()
	check(runtime.save_game() == OK and runtime.core.saves.pages.metrics.pages_written == metrics.pages_written, "fresh-process unchanged save reuses every persisted chunk and actor page")
	check(runtime.genesis.ledger.generator.generation_invocation_count == 0, "save after fresh load also performs no hidden generation")

func canonical_proof() -> Dictionary:
	return {"world_hash": WorldGenIds.digest(runtime.genesis.capture_state()), "chunk_hash": WorldGenIds.digest(runtime.genesis.ledger.record(CELL)), "resource_hash": WorldGenIds.digest(runtime.items.resources.capture()), "inventory_hash": WorldGenIds.digest(runtime.items.inventory.capture()), "equipment_hash": WorldGenIds.digest(runtime.items.equipment.capture()), "actor_hash": WorldGenIds.digest(runtime.living.capture_state()), "world_id": runtime.world.state.world_id, "world_seed": runtime.world.state.world_seed}
