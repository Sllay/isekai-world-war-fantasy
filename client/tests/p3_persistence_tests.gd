extends SceneTree

const GENESIS := "foundation.world_genesis"
const LIVING := "gameplay.living"
const ITEMS := "gameplay.items_resources"
const CELL := Vector2i(3, 0)
var checks := 0
var failures := 0
var runtime: Node
var slot := ""

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
	if is_instance_valid(runtime.living_runtime):
		for body in runtime.living_runtime.bodies.values(): body.set_physics_process(false)
	if is_instance_valid(runtime.enemy_body): runtime.enemy_body.set_physics_process(false)
	for body in runtime.companion_bodies: body.set_physics_process(false)
	runtime.persistence.suppress_autosave = true

func write(value: Dictionary) -> void:
	var file := FileAccess.open(slot, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "", true, true))
	file.close()

func run() -> void:
	slot = "user://tests/p3-persistence-%s.json" % CoreIds.generate()
	runtime = preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.p3_persistence", slot)
	root.add_child(runtime)
	check(runtime.startup_error == OK, "production P3 runtime boots in isolated slot")
	if runtime.startup_error != OK:
		runtime.free()
		quit(1)
		return
	freeze()
	var starter: Dictionary = runtime.persistence.capture_snapshot()
	check(starter.game_version == "0.5.0" and starter.modules.size() == 11 and starter.sections.size() == 8, "P3 release registers eleven modules and eight owned sections")
	check(not runtime.persistence.integrity.prepare(starter).is_empty(), "complete production snapshot validates")
	test_migration(starter)
	check(runtime.save_game() == OK, "paged baseline checkpoint established before measuring storage growth")
	# This is an explicit trusted harness setup, not a client gameplay API. It
	# exercises the production genesis -> validation -> atomic commit -> spawn path.
	var storage_before := storage_bytes()
	var loaded: Dictionary = runtime.streamer._ensure(CELL)
	check(loaded.ok and loaded.record.base.spawns.size() == 2, "production world placement commits two logical actors")
	if not loaded.ok:
		runtime.free()
		quit(1)
		return
	print("P3 save size evidence: ", JSON.stringify({"before_bytes": storage_before, "after_bytes": storage_bytes(), "delta_bytes": storage_bytes() - storage_before}))
	check(runtime.living.actors.size() == 2 and runtime.living_runtime.bodies.is_empty(), "far generated actors exist without runtime bodies")
	var complete: Dictionary = runtime.persistence.capture_snapshot()
	check(not runtime.persistence.integrity.prepare(complete).is_empty(), "generated chunk, resource placements, claims and actor ownership agree")
	test_corruption(complete)
	test_rewards()
	test_dirty_pages()
	cleanup()
	await process_frame
	print("P3 persistence tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_migration(starter: Dictionary) -> void:
	var old := starter.duplicate(true)
	old.game_version = "0.4.0"
	for section in [GENESIS, LIVING]:
		old.modules.erase(section)
		old.sections.erase(section)
	old.sections["foundation.player_combat"].state.combatant.health = 73
	old.sections["foundation.player_combat"].state.combatant.resource = 29
	old.sections["foundation.player_combat"].state.actions.cooldowns["combat.action.strong_strike"] = 17
	var resource: Dictionary = old.sections[ITEMS].state.resources.nodes["resource.node.common_tree"]
	resource.remaining = 2
	resource.extractions = 1
	var before := old.duplicate(true)
	var invocations: int = runtime.genesis.ledger.generator.generation_invocation_count
	var upgraded: Dictionary = runtime.persistence.integrity.prepare(old)
	check(not upgraded.is_empty() and upgraded.game_version == "0.5.0", "exact completed P2 release migrates explicitly to P3")
	if upgraded.is_empty(): return
	for section: String in old.sections:
		check(upgraded.sections[section] == old.sections[section], "migration preserves P2 section exactly: " + section)
	check(upgraded.sections[GENESIS].state.chunks.is_empty() and upgraded.sections[LIVING].state.actors.is_empty(), "migration introduces schemas without inventing generated chunks or actors")
	check(old == before and runtime.persistence.capture_snapshot() == starter and runtime.genesis.ledger.generator.generation_invocation_count == invocations, "migration preparation never mutates input, gameplay or generation count")
	write(old)
	check(runtime.resume_game() == OK, "production coordinator resumes explicit old P2 slot")
	freeze()
	check(runtime.player_combat.state.health == 73 and runtime.player_combat.state.resource == 29 and runtime.player_combat.actions.remaining_cooldown("combat.action.strong_strike") == 17, "actual migration retains P2 health, resource and cooldown")
	check(runtime.items.capture_state() == old.sections[ITEMS].state, "actual migration preserves inventory, equipment, skills and depleted resource state")
	write(starter)
	check(runtime.resume_game() == OK, "restore isolated pristine checkpoint after migration fixture")
	freeze()

func test_corruption(complete: Dictionary) -> void:
	var cases: Array[Dictionary] = []
	var broken: Dictionary
	for section in [GENESIS, LIVING]:
		broken = complete.duplicate(true)
		broken.sections.erase(section)
		cases.append({"label": "missing current section " + section, "snapshot": broken})
		broken = complete.duplicate(true)
		broken.sections.erase(section)
		broken.modules.erase(section)
		cases.append({"label": "current release disguised as pre-P3 " + section, "snapshot": broken})
	var chunk_id := WorldGenIds.chunk(WorldBlueprint.REGION_ID, CELL)
	var actor_id: String = complete.sections[LIVING].state.actors.keys()[0]
	var node_id: String = complete.sections[GENESIS].state.chunks[chunk_id].base.resources[0].node_id
	broken = complete.duplicate(true)
	broken.sections[GENESIS].state.blueprint.generator_version = 2
	cases.append({"label": "incompatible generator version", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[GENESIS].state.chunks[chunk_id].base.terrain.heights_mm[0] += 1
	cases.append({"label": "corrupted canonical chunk hash", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[GENESIS].state.chunks[chunk_id].world_id = "world.foreign"
	cases.append({"label": "mismatched world ownership", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[GENESIS].state.chunks[chunk_id].region_id = "region.foreign"
	cases.append({"label": "mismatched region ownership", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[ITEMS].state.resources.nodes[node_id].position[0] += 1
	cases.append({"label": "P2 resource displaced from generated placement", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[ITEMS].state.resources.nodes[node_id].profile_id = "resource.profile.stone"
	cases.append({"label": "P2 resource profile differs from canonical generated definition", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[LIVING].state.actors[actor_id].state.memory.records.append(memory("ffffffffffffffffffffffffffffffff"))
	cases.append({"label": "durable memory references nonexistent entity", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[LIVING].state.actors[actor_id].state.allegiance = "faction.missing"
	cases.append({"label": "invalid faction reference", "snapshot": broken})
	for field in ["home", "work"]:
		broken = complete.duplicate(true)
		broken.sections[LIVING].state.actors[actor_id].state[field] = [1000, 0, 1000]
		cases.append({"label": "actor activity endpoint outside canonical region " + field, "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[LIVING].state.actors[actor_id].state.world_id = "world.foreign"
	cases.append({"label": "actor bound to foreign world", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[LIVING].state.actors[actor_id].state.chunk_id = "region.home_valley:0:0"
	cases.append({"label": "actor chunk disagrees with canonical location", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[LIVING].state.actors.erase(actor_id)
	cases.append({"label": "spawn claim missing its canonical actor", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections["core.runtime"].state.entities.ids.erase(actor_id)
	cases.append({"label": "actor absent from canonical identity registry", "snapshot": broken})
	broken = complete.duplicate(true)
	broken.sections[LIVING].state.player.progression.sources["world.discovery:landmark.missing"] = 1
	cases.append({"label": "progression source has no world gameplay referent", "snapshot": broken})
	var resident: RegionScene = runtime.world_scene.active_region
	for item: Dictionary in cases:
		check(runtime.persistence.integrity.prepare(item.snapshot).is_empty(), "reject " + item.label)
		write(item.snapshot)
		check(runtime.resume_game() != OK, "disk resume rejects " + item.label)
		check(runtime.persistence.capture_snapshot() == complete and runtime.world_scene.active_region == resident, "rejection preserves every live section and residency: " + item.label)
	write(complete)
	check(runtime.resume_game() == OK, "repaired generated checkpoint resumes")
	freeze()

func test_rewards() -> void:
	var before: Dictionary = runtime.persistence.capture_snapshot()
	for command in ["rpg.grant_xp", "world.mutate", "world.generate", "actor.spawn"]:
		var result: Dictionary = runtime.authority_gateway.request(command, {"amount": 500, "world_id": "world.foreign"})
		check(not result.get("accepted", false), "client cannot invoke authority result API: " + command)
	check(runtime.persistence.capture_snapshot() == before, "forged world and XP commands have no canonical effect")
	var enemy: EnemyActor = runtime.enemies.actor
	var xp_before: int = runtime.living.player_identity.progression.xp
	# Explicit domain fixture: CombatService is the authority-owned fact source;
	# client-supplied XP amounts never enter the gameplay API under test.
	var hit: CombatResult = runtime.combat.service.damage(DamageRequest.new(runtime.player.state.entity_id, enemy.entity_id, 1000))
	check(hit.accepted and runtime.living.player_identity.progression.xp == xp_before + 25, "canonical combat defeat fact grants definition-owned XP")
	var reward: Dictionary = runtime.living.award(runtime.player.state.entity_id, "combat.defeat", enemy.entity_id, 1)
	check(not reward.accepted and runtime.living.player_identity.progression.xp == xp_before + 25, "duplicate progression reward is idempotently rejected")
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "progression persists through production save/resume")
	freeze()
	check(runtime.living.player_identity.progression.xp == xp_before + 25, "restored progression preserves exact XP")
	reward = runtime.living.award(runtime.player.state.entity_id, "combat.defeat", enemy.entity_id, 1)
	check(not reward.accepted and runtime.living.player_identity.progression.xp == xp_before + 25, "persisted reward watermark still rejects replay after resume")

func test_dirty_pages() -> void:
	check(runtime.save_game() == OK, "initial paged production checkpoint succeeds")
	var metrics: Dictionary = runtime.core.saves.pages.metrics.duplicate()
	var chunks_before: Dictionary = runtime.genesis.capture_state()
	var actors_before: Dictionary = runtime.living.capture_state()
	check(runtime.save_game() == OK and runtime.core.saves.pages.metrics.pages_written == metrics.pages_written, "unchanged production save writes zero chunk or actor records")
	check(runtime.core.saves.pages.metrics.pages_reused - metrics.pages_reused == chunks_before.chunks.size() + actors_before.actors.size(), "unchanged world and actor records are reused by content identity")
	var id: String = runtime.living.actors.keys()[0]
	var actor: LivingActorState = runtime.living.actors[id].state
	check(actor.memory.remember(memory(runtime.player.state.entity_id), runtime.core.clock.tick, runtime.core.entities.contains) == "REMEMBERED", "trusted actor-memory fixture changes exactly one durable actor record")
	metrics = runtime.core.saves.pages.metrics.duplicate()
	check(runtime.save_game() == OK and runtime.core.saves.pages.metrics.pages_written - metrics.pages_written == 1, "one modified actor writes exactly one record page")
	check(runtime.genesis.capture_state() == chunks_before, "actor save leaves all canonical chunks unchanged")
	var logical_before: Dictionary = runtime.persistence.capture_snapshot()
	check(runtime.resume_game() == OK, "paged production checkpoint hydrates through coordinator")
	freeze()
	check(runtime.persistence.capture_snapshot() == logical_before, "paged reload preserves complete canonical snapshot")
	metrics = runtime.core.saves.pages.metrics.duplicate()
	check(runtime.save_game() == OK and runtime.core.saves.pages.metrics.pages_written == metrics.pages_written, "first save after hydration rewrites zero unchanged records")
	print("P3 production dirty-write metrics: ", JSON.stringify(runtime.core.saves.pages.metrics))

func memory(subject: String) -> Dictionary:
	return {"id": "memory.persistence_anchor", "kind": "memory.threat", "subject_id": subject, "position": [0, 0, 0], "created_tick": runtime.core.clock.tick, "importance": 90, "confidence": 100, "expires_tick": -1, "source": "perception.hearing", "anchor": true}

func cleanup() -> void:
	runtime.persistence.suppress_autosave = true
	runtime.free()
	DirAccess.remove_absolute(slot)
	var directory := slot + ".pages"
	for filename in DirAccess.get_files_at(directory): DirAccess.remove_absolute(directory.path_join(filename))
	DirAccess.remove_absolute(directory)

func storage_bytes() -> int:
	var result := FileAccess.get_file_as_bytes(slot).size()
	for filename in DirAccess.get_files_at(slot + ".pages"):
		result += FileAccess.get_file_as_bytes((slot + ".pages").path_join(filename)).size()
	return result
