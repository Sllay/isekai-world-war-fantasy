extends SceneTree

var checks := 0
var failures := 0
var runtime: Node
var damage_count := 0
var defeat_count := 0
var commits := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func step(count: int) -> void:
	for i in count:
		runtime._process(0.05)

func stop_physics() -> void:
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	avatar.motor.set_physics_process(false)
	avatar.get_child(0).set_physics_process(false)

func run() -> void:
	var isolated := CoreModuleRegistry.new()
	var isolated_core := CoreRuntimeServicesModule.new()
	isolated.add(isolated_core)
	isolated.add(CombatModule.new())
	isolated.add(TargetingModule.new())
	check(isolated.boot() == OK, "targeting/combat modules boot without Player, World or enemies")
	isolated.shutdown()
	var path := OS.get_cmdline_user_args()[0].path_join("enemy-unit.json")
	runtime = preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.enemy", path)
	root.add_child(runtime)
	runtime.set_process(false)
	await physics_frame
	await physics_frame
	stop_physics()
	var actor: EnemyActor = runtime.enemies.actor
	var ai: EnemyController = runtime.enemies.controller
	var targets: TargetingService = runtime.enemies.targeting
	var service: CombatService = runtime.combat.service
	var player: PlayerState = runtime.player.state
	var executor: ActionExecutor = actor.actions
	var record: RegionState = runtime.world_scene.active_region.record
	var original_id := actor.entity_id
	check(runtime.startup_error == OK, "production runtime boots")
	check(runtime.action_harness == null, "normal runtime has no cylinder fixture")
	check(runtime.registry.statuses["gameplay.enemies"] == "running", "production enemy module registered")
	check(service.data.lookup(actor.archetype.archetype_id).id == "enemy.archetype.melee_skirmisher", "archetype registered")
	check(CombatNumbers.stable_entity(original_id) and original_id != player.entity_id, "independent stable Core enemy identity")
	check(record.actors[EnemyModule.SPAWN] == actor and record.lifecycle == RegionState.Lifecycle.LOADED, "Region owns actor record/residency")
	check(actor.home == record.definition.to_world_position(record.definition.actor_spawns[EnemyModule.SPAWN]), "authored home")
	check(actor.capabilities.capability("foundation.combatant") == actor.combatant, "composed combatant capability")
	check(actor.capabilities.capability("foundation.actions") == executor, "composed action capability")
	check(executor.combat == runtime.player_combat.actions.combat and executor.catalog == runtime.player_combat.actions.catalog, "Player/enemy share service/catalog and generic executor")
	check(service.relationship(player.entity_id, original_id) == CombatTargetPolicy.Relationship.ENEMY and service.relationship(original_id, player.entity_id) == CombatTargetPolicy.Relationship.ENEMY, "bidirectional disposition policy")
	check(targets.register(original_id, func() -> Vector3: return actor.position) == ERR_INVALID_PARAMETER, "duplicate target registration rejected")
	check(not targets.valid_hostile(player.entity_id, CoreIds.generate(), 20), "unknown stable target unavailable")
	check(not targets.valid_hostile(player.entity_id, player.entity_id, 20), "self is not a hostile selection")
	check(runtime.current_player_target().is_empty(), "target initially transient and unselected")
	check(runtime.select_player_target() == original_id, "production target selection")
	check(runtime.player_combat.actions.phase == ActionExecutor.Phase.IDLE, "select does not execute")
	check(targets.hostiles(original_id, 8) == [player.entity_id], "autonomous hostile query")
	var old_position := player.position
	player.position = Vector3(40, 0, 40)
	check(runtime.current_player_target().is_empty(), "selection invalidates outside policy range")
	player.position = old_position
	service.events.subscribe(DamageApplied, func(event: DamageApplied) -> void:
		if event.source_entity == original_id: damage_count += 1)
	service.events.subscribe(CombatantDefeated, func(event: CombatantDefeated) -> void:
		if event.target_entity == original_id: defeat_count += 1)
	service.events.subscribe(ActionCommitted, func(event: ActionCommitted) -> void:
		if event.owner_id == original_id: commits += 1)
	var initial_position := actor.position
	step(1)
	check(ai.target_id == player.entity_id and ai.state == EnemyController.State.APPROACH, "acquire to approach")
	check(actor.position.distance_to(initial_position) > 0.01, "movement port approaches on Core tick")
	var same_tick := actor.position
	ai.tick()
	check(actor.position == same_tick, "repeated decision in same tick does not move")
	for i in 100:
		if executor.phase == ActionExecutor.Phase.CASTING: break
		step(1)
	check(executor.phase == ActionExecutor.Phase.CASTING and ai.state == EnemyController.State.ATTACK, "approach enters shared executor attack")
	check(runtime.telegraphs.active.size() == 1, "typed start fact creates telegraph")
	check(runtime.player_combat.state.health == 100 and damage_count == 0, "windup before damage")
	var renderer: TelegraphRenderer
	for node in runtime.world_scene.active_region.get_children():
		if node is TelegraphRenderer: renderer = node
	renderer._process(0)
	check(renderer.get_child_count() == 1, "reusable renderer creates one windup range band")
	var rendered := renderer.get_child(0) as MeshInstance3D
	check(rendered.mesh.get_surface_count() == 1 and rendered.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "lightweight single-surface telegraph mesh")
	check((rendered.material_override as StandardMaterial3D).transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "telegraph uses opaque geometry without transparent overdraw")
	var cast_position := actor.position
	step(23)
	check(runtime.player_combat.state.health == 100 and actor.position == cast_position, "windup timing and stationary attack")
	check(runtime.telegraphs.progress(runtime.telegraphs.active.values()[0]) > 0.9, "telegraph derives progress from Core timing")
	step(1)
	check(runtime.player_combat.state.health == 92 and damage_count == 1 and commits == 1, "exactly one shared service commit")
	check(runtime.telegraphs.active.is_empty(), "commit stops telegraph")
	renderer._process(0)
	check(renderer.get_child_count() == 0, "commit removes rendered geometry immediately on projection update")
	check(executor.remaining_cooldown(actor.archetype.action_id) == 40, "data cooldown starts at commit")
	step(14)
	check(damage_count == 1 and commits == 1, "recovery cannot repeat damage")
	check(executor.activate(actor.archetype.action_id, ActionTarget.new(player.entity_id)) == "COOLDOWN", "cooldown rejects premature attack")
	# Finish cooldown outside range, then start a controlled reaction scenario.
	player.position = actor.home + Vector3(0, 0, 5)
	step(26)
	executor.restore({"cooldowns": {}})
	runtime.telegraphs.clear()
	player.position = actor.position + Vector3(0, 0, 1)
	check(executor.activate(actor.archetype.action_id, ActionTarget.new(player.entity_id)) == "STARTED", "reaction scenario starts in range")
	check(runtime.telegraphs.active.size() == 1, "reaction windup visible")
	player.position = actor.position + Vector3(0, 0, 4)
	step(24)
	check(runtime.player_combat.state.health == 92 and damage_count == 1, "leaving range before commit avoids damage")
	check(executor.last_result == "OUT_OF_RANGE" and runtime.telegraphs.active.is_empty(), "commit revalidation cancels and clears telegraph")
	check(executor.remaining_cooldown(actor.archetype.action_id) == 0, "uncommitted cancellation spends no cooldown")
	player.position = actor.position + Vector3(0, 0, 1)
	executor.activate(actor.archetype.action_id, ActionTarget.new(player.entity_id))
	check(runtime.telegraphs.active.size() == 1 and executor.interrupt() == "CANCELLED", "shared interrupt cancels telegraphed action")
	check(runtime.telegraphs.active.is_empty() and damage_count == 1, "interruption removes presentation without damage")
	# Presentation may be absent entirely and cannot authorize a hit.
	player.position = actor.position + Vector3(0, 0, 1)
	executor.activate(actor.archetype.action_id, ActionTarget.new(player.entity_id))
	runtime.telegraphs.clear()
	step(24)
	check(damage_count == 2 and runtime.player_combat.state.health == 84, "telegraph has no authority over damage")
	player.position = actor.home + Vector3(30, 0, 0)
	step(1)
	check(ai.state == EnemyController.State.RETURN_HOME and ai.target_id.is_empty(), "leash disengages and clears intent")
	for i in 160:
		step(1)
		if ai.state == EnemyController.State.IDLE: break
	check(actor.position.distance_to(actor.home) < 0.1, "movement returns toward authored home")
	# Player action damage, checkpoint and restored half cast.
	player.position = actor.position + Vector3(0, 0, 1)
	var actions: ActionExecutor = runtime.player_combat.actions
	check(actions.activate("combat.action.basic_strike", ActionTarget.new(original_id)) == "STARTED", "Player targets production actor")
	for i in 4:
		service.clock.tick += 1
		actions.advance()
	check(actor.combatant.health == 88, "Player strike uses real enemy combatant")
	executor.restore({"cooldowns": {actor.archetype.action_id: 19}})
	check(runtime.save_game() == OK, "Region-owned enemy checkpoint")
	var snapshot: Dictionary = runtime.core.saves.read_snapshot(path)
	var saved_actor: Dictionary = snapshot.sections["foundation.regions"].state.regions[actor.region_id].actors[EnemyModule.SPAWN]
	check(saved_actor.entity_id == original_id and saved_actor.combatant.health == 88, "enemy ID/HP reside inside Region section")
	check(not JSON.stringify(snapshot).contains("target_entity_id") and not JSON.stringify(snapshot).contains("telegraph_id"), "transient targets/telegraphs not saved")
	check(runtime.resume_game() == OK, "enemy resume path")
	runtime.set_process(false)
	stop_physics()
	check(actor.entity_id == original_id and actor.combatant.health == 88, "resume preserves same actor identity and health")
	check(executor.phase == ActionExecutor.Phase.IDLE and executor.remaining_cooldown(actor.archetype.action_id) == 19, "enemy cooldown survives restore")
	check(runtime.current_player_target().is_empty() and ai.target_id.is_empty(), "resume clears transient target state")
	executor.restore({"cooldowns": {}})
	runtime.telegraphs.clear()
	player.position = actor.position + Vector3(0, 0, 1)
	executor.activate(actor.archetype.action_id, ActionTarget.new(player.entity_id))
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "save/resume during enemy cast")
	runtime.set_process(false)
	stop_physics()
	check(executor.phase == ActionExecutor.Phase.IDLE and runtime.telegraphs.active.is_empty(), "active cast never resumes halfway")
	# Defeat via the Player's normal action only. Enemy cast is active at defeat.
	player.position = actor.position + Vector3(0, 0, 1)
	executor.activate(actor.archetype.action_id, ActionTarget.new(player.entity_id))
	for strike in 8:
		actions.restore({"cooldowns": {}})
		actions.activate("combat.action.basic_strike", ActionTarget.new(original_id))
		for i in 4:
			service.clock.tick += 1
			actions.advance()
	runtime.enemies.tick()
	check(actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED and defeat_count == 1, "defeat fact exactly once")
	check(ai.state == EnemyController.State.DEFEATED and executor.current == null, "defeat stops AI and cancels cast safely")
	check(runtime.select_player_target().is_empty() and targets.hostiles(player.entity_id, 20).is_empty(), "defeated actor no longer targetable")
	var defeated_position := actor.position
	step(100)
	check(actor.position == defeated_position and defeat_count == 1, "defeated actor retained without movement/repeated defeat")
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "defeat save/resume")
	runtime.set_process(false)
	stop_physics()
	check(actor.entity_id == original_id and actor.combatant.health == 0, "defeat persists without respawn")
	var current_snapshot: Dictionary = runtime.persistence.capture_snapshot()
	var missing := current_snapshot.duplicate(true)
	missing.sections["foundation.regions"].state.regions[actor.region_id].erase("actors")
	check(runtime.persistence.integrity.prepare(missing).is_empty(), "missing current actor state cannot silently respawn")
	var previous := current_snapshot.duplicate(true)
	previous.modules.erase("gameplay.enemies")
	previous.modules.erase("foundation.targeting")
	previous.sections["foundation.regions"].version = 1
	previous.sections["core.runtime"].state.entities.ids.erase(original_id)
	for region in previous.sections["foundation.regions"].state.regions.values():
		region.erase("actors")
		region.erase("last_safe")
	var introduced: Dictionary = runtime.persistence.integrity.prepare(previous)
	check(not introduced.is_empty(), "exact accepted Slice 2 release upgrades with new actor identity")
	check(introduced.sections["foundation.regions"].state.regions[actor.region_id].actors[EnemyModule.SPAWN].combatant.health == 100, "release introduction uses pristine authored state, not current defeated actor")
	var malformed_previous := previous.duplicate(true)
	malformed_previous.sections["core.runtime"].state.entities = {}
	check(runtime.persistence.integrity.prepare(malformed_previous).is_empty(), "malformed previous release rejected without script failure")
	# Recovery contract is authored by Region, including approved spawn contacts.
	var recovery: RegionRecovery = record.recovery
	# Preserve the accepted last-safe/entry fallback assertions with the optional
	# surface port absent. Slice 4 separately tests dynamic local recovery.
	recovery.surface_query = null
	player.position = Vector3(2, 0, 8)
	player.grounded = true
	recovery.observe()
	var safe := recovery.last_safe.duplicate(true)
	player.position = Vector3(NAN, 0, 0)
	check(not record.definition.safe_position(player.position), "nonfinite position is unsafe")
	recovery.observe()
	check(player.position == Vector3(2, 0, 8), "nonfinite runtime position recovers safely")
	check(not record.definition.safe_position(Vector3(100, 0, 8)), "Region safety bounds own horizontal invalidity")
	check(safe.position == [2.0, 0.0, 8.0], "healthy grounded position updates recovery")
	recovery.last_safe = {}
	player.position = Vector3(0, -40, 0)
	recovery.observe()
	check(player.position == record.definition.to_world_position(record.definition.entries[record.definition.default_entry]), "missing last-safe falls back to Region entry contract")
	recovery.last_safe = safe.duplicate(true)
	player.position = Vector3(3, 5, 8)
	player.grounded = false
	recovery.observe()
	check(recovery.last_safe == safe, "airborne position never updates last safe")
	player.position = Vector3(3, -20, 8)
	player.velocity = Vector3(4, -30, 5)
	recovery.observe()
	check(player.position == Vector3(2, 0, 8) and player.velocity == Vector3.ZERO, "void crossing resets transform and falling velocity")
	check(recovery.recovery_count > 0 and player.entity_id == runtime.player_combat.state.entity_id, "recovery keeps same Player identity")
	player.position = Vector3(5, -100, 9)
	check(runtime.save_game() == OK, "unsafe current transform saves validated recovery point")
	var repaired: Dictionary = runtime.core.saves.read_snapshot(path)
	check(repaired.sections["foundation.player"].state.position == [2.0, 0.0, 8.0], "unsafe transform never enters canonical save")
	check(runtime.resume_game() == OK and player.position == Vector3(2, 0, 8), "safe resume after recovery")
	runtime.set_process(false)
	stop_physics()
	var bad := repaired.duplicate(true)
	bad.sections["foundation.player"].state.position = [1, -999, 1]
	var staged: Dictionary = runtime.persistence.integrity.prepare(bad)
	check(not staged.is_empty() and staged.sections["foundation.player"].state.position == [2.0, 0.0, 8.0], "old finite void save recovers during validation")
	bad = repaired.duplicate(true)
	bad.sections["foundation.regions"].state.regions[actor.region_id].actors[EnemyModule.SPAWN].entity_id = CoreIds.generate()
	check(runtime.persistence.integrity.prepare(bad).is_empty(), "orphaned enemy identity rejected")
	runtime.world_scene.close_region()
	check(targets.hostiles(player.entity_id, 20).is_empty(), "Region unload invalidates position/target query immediately")
	check(runtime.world_scene.open_current(true) == OK, "Region can reopen same canonical actor")
	# Confirm once then bounded second press; no UI-authorized direct file access.
	var confirmation := SaveDeleteConfirmation.new()
	check(not confirmation.request(0) and confirmation.pending(1), "first Delete requires confirmation")
	check(not confirmation.request(3001), "expired confirmation does not delete")
	check(confirmation.request(3002) and not confirmation.pending(3003), "second bounded press confirms once")
	var unrelated := path + ".unrelated"
	var unrelated_file := FileAccess.open(unrelated, FileAccess.WRITE)
	unrelated_file.store_string("keep")
	unrelated_file.close()
	runtime.save_controls._delete()
	check(FileAccess.file_exists(path) and runtime.save_controls.delete_button.text == "Confirm Delete", "actual development control first press preserves slot")
	runtime.save_controls._delete()
	check(not FileAccess.file_exists(path), "actual confirmed control calls slot deletion and reset")
	check(FileAccess.get_file_as_string(unrelated) == "keep", "Delete Save never deletes unrelated data")
	runtime.set_process(false)
	check(runtime.persistence.delete_code == "SAVE_DELETED" and runtime.persistence.ready, "structured deletion result/new game ready")
	check(actor.combatant.health == 100 and runtime.player_combat.state.health == 100, "reset clears defeated/damaged canonical state")
	runtime.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not FileAccess.file_exists(path) and runtime.persistence.suppress_autosave, "pause autosave cannot recreate deleted save")
	check(runtime.save_game() == OK and FileAccess.file_exists(path) and not runtime.persistence.suppress_autosave, "explicit Save re-enables lifecycle persistence")
	check(runtime.delete_save() == OK, "repeat clean deletion")
	check(runtime.request_exit() == OK and not FileAccess.file_exists(path), "exit cannot recreate deleted save")
	runtime.free()
	# A corrupt slot must still expose the development deletion recovery flow.
	var corrupt := FileAccess.open(path, FileAccess.WRITE)
	corrupt.store_string("broken json")
	corrupt.close()
	var blocked := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	blocked.save_slot = LocalSaveSlot.new("test.enemy", path)
	root.add_child(blocked)
	check(blocked.startup_error != OK and blocked.world_scene.active_region == null, "bad slot blocks runtime without replacing bytes")
	check(blocked.save_controls != null and blocked.delete_save() == OK, "Delete Save can recover a blocked startup")
	blocked.set_process(false)
	check(blocked.world_scene.active_region != null and not FileAccess.file_exists(path), "blocked-save deletion opens clean Region without writing")
	blocked.free()
	print("Enemy Telegraph tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
