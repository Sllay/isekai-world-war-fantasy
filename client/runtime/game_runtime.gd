extends GameRuntime

const WORLD_CONTENT = preload("res://world/primary_world.tres")
const WORLD_SCENE = preload("res://world/world.tscn")
var player := PlayerModule.new()
var world := WorldModule.new(WORLD_CONTENT)
var regions := RegionModule.new()
var enemies := EnemyModule.new()
var targeting := TargetingModule.new()
var telegraphs := TelegraphTracker.new()
var enemy_body: EnemyBody
var companion_bodies: Array[EnemyBody] = []
var initial_snapshot: Dictionary = {}
var combat := CombatModule.new()
var player_combat := PlayerCombatModule.new()
var world_scene: WorldScene
var save_slot := LocalSaveSlot.new()
var persistence: SaveCoordinator
var startup_error: Error = OK
var startup_message: Label
var save_controls: CanvasLayer
var action_adapter := PlayerActionAdapter.new()
var action_harness: Node3D
var authority_host: LocalAuthorityHost
var authority_gateway: AuthorityGateway
var authority_input := PlayerAuthorityAdapter.new()
var combat_feedback: Node
var prediction_mirror := PlayerState.new()
var reconciler := PlayerReconciler.new()
var items := ItemsModule.new()
var items_panel: ItemsPanel
var genesis := WorldGenerationModule.new()
var living := LivingModule.new()
var streamer: ChunkStreamer
var living_runtime: LivingRuntime
var _world_label: Label
var _enemy_cell := Vector2i(1000000, 1000000)
var _defer_genesis_until_save := false

func _ready() -> void:
	var core_only := "--core-smoke" in OS.get_cmdline_user_args()
	if not core_only:
		for module in [player, world, regions, combat, player_combat, targeting, enemies, items, genesis, living]:
			var error := registry.add(module)
			if error != OK:
				push_error("Production module registration failed: %s" % error)
				get_tree().quit(1)
				return
	super._ready()
	if registry.state != CoreModuleRegistry.State.RUNNING or core_only:
		return
	items.bind(enemies, WORLD_CONTENT)
	items.restore_state(items.initial_state(player.state.entity_id, items.actor_map()))
	living.bind(items)
	core.saves.page_members = {genesis.id: "chunks", living.id: "actors"}
	world_scene = WORLD_SCENE.instantiate() as WorldScene
	world_scene.directory = regions.directory
	world_scene.player = player.state
	add_child(world_scene)
	initial_snapshot = core.saves.capture(registry, WORLD_CONTENT.world_id, WORLD_CONTENT.world_seed)
	persistence = SaveCoordinator.new(save_slot, registry, core.saves, world_scene, WORLD_CONTENT)
	initial_snapshot.game_version = SaveIntegrity.GAME_VERSION
	persistence.initial_snapshot = initial_snapshot
	genesis.durable_commit = func(candidate: Dictionary) -> Error: return persistence.commit_section(genesis.id, candidate)
	persistence.checkpoint_committed = genesis.ledger.acknowledge_persisted
	telegraphs.bind(core.events, combat.actions, core.clock)
	startup_error = persistence.startup()
	_defer_genesis_until_save = persistence.migration_pending
	_create_save_controls()
	if startup_error != OK:
		set_process(false)
		startup_message = Label.new()
		startup_message.text = "Saved game could not be loaded. Your save has been kept.\nRestore a valid local save before restarting."
		startup_message.position = Vector2(30, 100)
		add_child(startup_message)
		return
	_activate_session()

func _activate_session() -> void:
	startup_error = OK
	enemies.relevant = Callable()
	action_adapter.executor = player_combat.actions
	# Application activation rebuilds transient target ports for the restored
	# Region. Actor modules register only their own capabilities/identities.
	targeting.service.clear()
	targeting.service.disposition.groups.clear()
	targeting.service.disposition.hostile_groups = {"disposition.traveler": ["disposition.hostile"], "disposition.hostile": ["disposition.traveler"]}
	targeting.service.disposition.groups[player.state.entity_id] = "disposition.traveler"
	targeting.service.register(player.state.entity_id, _player_target_position)
	enemies.bind_residency()
	telegraphs.clear()
	player_combat.actions.position_of = enemies.targeting.position_of
	action_adapter.default_target = current_player_target
	if "--combat-actions-acceptance" not in OS.get_cmdline_user_args():
		enemy_body = EnemyBody.new()
		enemy_body.actor = enemies.actor
		world_scene.active_region.get_node("Actors").add_child(enemy_body)
		enemies.controller.move_toward = enemy_body.approach
		for body in companion_bodies:
			if is_instance_valid(body): body.free()
		companion_bodies.clear()
		for ai in enemies.companion_controllers:
			var body := EnemyBody.new()
			body.actor = ai.actor
			world_scene.active_region.get_node("Actors").add_child(body)
			ai.move_toward = body.approach
			companion_bodies.append(body)
		var renderer := TelegraphRenderer.new()
		renderer.tracker = telegraphs
		renderer.targeting = enemies.targeting
		world_scene.active_region.add_child(renderer)
	var avatar := world_scene.active_region.avatar
	avatar.intent.select_target = false
	avatar.motor.movement_gate = player_combat.actions.movement_allowed
	avatar.motor.turning_gate = player_combat.actions.turning_allowed
	if OS.is_debug_build() and "--combat-actions-acceptance" in OS.get_cmdline_user_args():
		targeting.service.unregister(enemies.actor.entity_id)
		if is_instance_valid(action_harness):
			action_harness.free()
		action_harness = preload("res://runtime/combat_action_harness.gd").new()
		action_harness.combat = combat.service
		action_harness.player = player.state
		add_child(action_harness)
		persistence.transient_entity_ids.assign([action_harness.target.entity_id])
		player_combat.actions.position_of = action_harness.position_of
		action_adapter.default_target = action_harness.target_id
	_setup_authority(avatar)
	_setup_world()
	if startup_error != OK: return
	set_process(true)
	get_tree().auto_accept_quit = false
	if is_instance_valid(startup_message):
		startup_message.queue_free()

func _create_save_controls() -> void:
	if OS.is_debug_build() and not is_instance_valid(save_controls):
		save_controls = preload("res://runtime/persistence/save_controls.gd").new()
		save_controls.save_action = save_game
		save_controls.delete_action = delete_save
		add_child(save_controls)
		if "--combat-debug" in OS.get_cmdline_user_args():
			var controls := preload("res://runtime/combat_debug_controls.gd").new()
			controls.combat = combat.service
			controls.state = player_combat.state
			controls.actions = player_combat.actions
			controls.enemy_summary = func() -> String:
				var selected := combat.service.combatant(current_player_target())
				return "Target HP %d/%d · %s" % [selected.health, selected.max_health(), "Skirmisher" if selected.entity_id == enemies.actor.entity_id else "Second skirmisher"] if selected != null else "Target: none (Target/T)"
			add_child(controls)

func _player_target_position() -> Variant:
	return player.state.position if world_scene.active_region != null else null

func current_player_target() -> String:
	return enemies.targeting.current(player.state.entity_id, 20.0)

func select_player_target() -> String:
	return enemies.targeting.cycle(player.state.entity_id, 20.0)

func delete_save() -> Error:
	var error := persistence.delete_and_reset()
	if error == OK:
		# Delete retains the existing unsaved P1/P2 reset preview. A new durable
		# world starts at explicit Save, never by silently recreating the slot.
		_defer_genesis_until_save = true
		_activate_session()
	return error

# Public application API for later UI/gameplay/lifecycle adapters.
func save_game() -> Error:
	if _defer_genesis_until_save:
		var initial_error := authority_host.save_game() if authority_host != null else ERR_UNCONFIGURED
		if initial_error != OK: return initial_error
		_defer_genesis_until_save = false
		_setup_world()
		return startup_error
	# Cached relevance is amortized during movement. Checkpoint at the exact
	# current position so a fresh runtime applies the same deterministic policy.
	if is_instance_valid(living_runtime):
		living_runtime.invalidate_relevance()
		living_runtime.sync_relevance(player.state.position)
	return authority_host.save_game() if authority_host != null else ERR_UNCONFIGURED

func resume_game() -> Error:
	if persistence == null:
		return ERR_UNCONFIGURED
	var previous_region := world_scene.active_region
	var error := persistence.resume_game()
	if error == OK or (persistence.ready and world_scene.active_region != previous_region):
		_defer_genesis_until_save = persistence.migration_pending
		_activate_session()
	return error

func request_exit() -> Error:
	if persistence != null and persistence.ready and not persistence.suppress_autosave:
		var error := save_game()
		if error != OK:
			return error
	get_tree().quit()
	return OK

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		request_exit()
	elif what == NOTIFICATION_APPLICATION_PAUSED and persistence != null and persistence.ready and not persistence.suppress_autosave:
		save_game()

func development_state() -> Dictionary:
	var result := world_scene.development_state() if is_instance_valid(world_scene) else {}
	if persistence != null:
		result.merge(persistence.development_state(), true)
	if enemies.actor.combatant != null:
		result["enemy"] = enemies.controller.development_state()
		result["player_target"] = current_player_target()
		result["telegraphs"] = telegraphs.active.duplicate(true)
	if world_scene != null and world_scene.active_region != null:
		var recovery := world_scene.active_region.record.recovery
		result["last_safe"] = recovery.last_safe.duplicate(true)
		result["void_recoveries"] = recovery.recovery_count
	if player_combat.state != null:
		result["combat"] = player_combat.development_state()
		result["actions"] = player_combat.actions.development_state()
	if is_instance_valid(action_harness):
		result["action_target"] = action_harness.development_state()
	if authority_host != null:
		result["authority"] = authority_gateway.snapshot()
	if is_instance_valid(streamer): result["streaming"] = streamer.snapshot()
	if is_instance_valid(living_runtime): result["living"] = living_runtime.snapshot()
	result["rpg"] = living.capture_player() if living.items != null else {}
	result["storage"] = core.saves.pages.metrics.duplicate()
	return result

func _process(delta: float) -> void:
	if registry.state != CoreModuleRegistry.State.RUNNING:
		return
	if authority_host != null and is_instance_valid(streamer): streamer.advance_frame()
	var previous := core.clock.tick
	var steps := core.clock.advance(delta)
	if steps == 0:
		return
	# Replay each newly advanced Core tick so effects and facts share exact ticks.
	core.clock.tick = previous
	for index in range(steps):
		core.clock.tick += 1
		core.scheduler.run_due(core.clock.tick)
		if authority_host != null and persistence != null and persistence.ready and world_scene.active_region != null:
			var avatar := world_scene.active_region.avatar
			if avatar.intent.select_target:
				select_player_target()
				avatar.intent.select_target = false
			var chosen: String = avatar.intent.target_entity_id
			if chosen.is_empty():
				chosen = action_adapter.default_target.call() if action_adapter.default_target.is_valid() else current_player_target()
			if chosen.is_empty():
				chosen = select_player_target()
			authority_input.consume(avatar, chosen, player_combat.actions.position_of.call(chosen) if not chosen.is_empty() else null)
			authority_host.advance()
			if is_instance_valid(living_runtime): living_runtime.tick()
			_sync_enemy_bodies()
			if is_instance_valid(_world_label) and core.clock.tick % 10 == 0:
				_world_label.text = "Chunk %s · loaded %d/%d\nLogical %d · bodies %d\nL0/L1/L2/L3 %s\nGen %d · XP %d" % [world_scene.development_state().chunk_coordinates, streamer.views.size(), streamer.policy.max_resident_chunks, living.actors.size(), living_runtime.bodies.size(), str(living.scheduler.fidelity_counts()), genesis.ledger.generator.generation_invocation_count, living.player_identity.progression.xp]
			reconciler.apply(prediction_mirror, authority_gateway.snapshot())

func _exit_tree() -> void:
	targeting.service.visibility = Callable()
	if is_instance_valid(living_runtime): living_runtime.dispose()
	if persistence != null: persistence.checkpoint_committed = Callable()
	if authority_host != null:
		authority_host.dispose()
	telegraphs.dispose()
	if is_instance_valid(action_harness):
		action_harness.free()
	if is_instance_valid(world_scene):
		world_scene.close_region()
	super._exit_tree()

func _setup_authority(avatar: PlayerAvatar) -> void:
	if authority_host != null:
		authority_host.dispose()
		authority_host = null
	authority_gateway = AuthorityGateway.new()
	# Recovery is a gameplay transform mutation too. Only the host's physics port
	# may invoke it; a disconnected view must not run the Region's standalone path.
	world_scene.active_region.set_physics_process(false)
	# Explicit development mode, never a network-error fallback.
	if not OS.is_debug_build() or "--authority-remote" in OS.get_cmdline_user_args():
		avatar.motor.set_physics_process(false)
		return
	authority_host = LocalAuthorityHost.new()
	var session := CoreIds.generate()
	authority_host.configure(combat.service, player_combat.actions, player.state, session)
	player_combat.defense = authority_host.defense
	player_combat.defense.restore(player.state.entity_id, player_combat.restored_defense)
	authority_gateway = LoopbackAuthorityGateway.new(authority_host, session)
	authority_input.gateway = authority_gateway
	prediction_mirror.entity_id = player.state.entity_id
	reconciler = PlayerReconciler.new()
	authority_input.last_guard = false
	authority_host.defense.position_of = player_combat.actions.position_of
	authority_host.defense.facing_of = _authority_facing
	authority_host.actor_executors[enemies.actor.entity_id] = enemies.actor.actions
	enemies.actor.actions.activation_gate = func() -> bool: return authority_host.can_act(enemies.actor.entity_id)
	enemies.actor.actions.mobility_gate = func() -> bool: return not authority_host.defense.staggered(enemies.actor.entity_id)
	for extra in enemies.companions:
		authority_host.actor_executors[extra.entity_id] = extra.actions
		extra.actions.activation_gate = func() -> bool: return authority_host.can_act(extra.entity_id)
		extra.actions.mobility_gate = func() -> bool: return not authority_host.defense.staggered(extra.entity_id)
	authority_host.move_port = avatar.motor.simulate
	for executor: ActionExecutor in authority_host.actor_executors.values():
		executor.target_gate = _authority_line_of_sight
	targeting.service.visibility = _authority_line_of_sight
	authority_host.recovery_port = world_scene.active_region.record.recovery.observe
	avatar.motor.intent = authority_host.movement
	avatar.motor.movement_yaw = 0.0
	avatar.motor.authority_step = authority_host.physics_step
	avatar.motor.movement_gate = authority_host.movement_allowed
	avatar.motor.turning_gate = player_combat.actions.turning_allowed
	if is_instance_valid(combat_feedback):
		combat_feedback.free()
	combat_feedback = CombatFeedback.new()
	combat_feedback.host = authority_host
	combat_feedback.position_of = player_combat.actions.position_of
	world_scene.active_region.add_child(combat_feedback)
	combat_feedback.attach_actor(player.state.entity_id, avatar.presentation.marker)
	if is_instance_valid(enemy_body):
		combat_feedback.attach_actor(enemies.actor.entity_id, enemy_body.marker)
	for body in companion_bodies:
		combat_feedback.attach_actor(body.actor.entity_id, body.marker)
	authority_host.checkpoint = persistence.save_game
	var item_commands := ItemsAuthorityPort.new()
	item_commands.bind(authority_host, items)
	var character_class: ClassDefinition = living.catalog.character_class(living.player_identity.class_id)
	item_commands.items.equipment_eligibility = character_class.allows_equipment
	item_commands.region_id = func() -> String: return regions.directory.world.current_region_id
	item_commands.spatial_gate = _authority_world_visible
	items_panel = ItemsPanel.new()
	items_panel.items = items
	items_panel.gateway = authority_gateway
	items_panel.external_world_markers = not _defer_genesis_until_save
	world_scene.active_region.add_child(items_panel)
	avatar.input.ui_hit_test = items_panel.owns_point
	if "--combat-actions-acceptance" not in OS.get_cmdline_user_args():
		authority_host.enemy_step = enemies.tick
	authority_host.safe_spawn = func() -> void:
		var region := world_scene.active_region.record.definition
		player.state.position = region.to_world_position(region.entries.get("entry.respawn", region.entries[region.default_entry]))
		player.state.facing = Vector3.FORWARD
		avatar.intent.clear_transient()
		avatar.input.pointer_aim = false
		targeting.service.clear_selection(player.state.entity_id)
		authority_input.last_guard = false

func _authority_facing(id: String) -> Vector3:
	if id == player.state.entity_id:
		return player.state.facing
	if id == enemies.actor.entity_id:
		return enemies.actor.facing
	for extra in enemies.companions:
		if extra.entity_id == id: return extra.facing
	if living.actors.has(id): return living.actors[id].state.facing
	return Vector3.ZERO

func _authority_line_of_sight(source: String, destination: String) -> bool:
	var from: Variant = player_combat.actions.position_of.call(source)
	var to: Variant = player_combat.actions.position_of.call(destination)
	if not from is Vector3 or not to is Vector3:
		return false
	var query := PhysicsRayQueryParameters3D.create(from + Vector3.UP, to + Vector3.UP, 1)
	var excluded: Array[RID] = [world_scene.active_region.avatar.motor.get_rid()]
	if is_instance_valid(enemy_body): excluded.append(enemy_body.get_rid())
	for body in companion_bodies:
		excluded.append(body.get_rid())
	query.exclude = excluded
	return world_scene.active_region.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _authority_world_visible(point: Vector3) -> bool:
	if not point.is_finite(): return false
	var query := PhysicsRayQueryParameters3D.create(player.state.position + Vector3.UP, point + Vector3.UP, 1)
	var excluded: Array[RID] = [world_scene.active_region.avatar.motor.get_rid()]
	if is_instance_valid(enemy_body): excluded.append(enemy_body.get_rid())
	for body in companion_bodies: excluded.append(body.get_rid())
	query.exclude = excluded
	return world_scene.active_region.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _world_visible(origin: Vector3, destination: Vector3) -> bool:
	if not origin.is_finite() or not destination.is_finite(): return false
	var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP, destination + Vector3.UP, 1)
	query.exclude = [world_scene.active_region.avatar.motor.get_rid()]
	return world_scene.active_region.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _setup_world() -> void:
	if authority_host == null or _defer_genesis_until_save: return
	var region := world_scene.active_region.record.definition
	var terrain := world_scene.active_region.get_node("Terrain")
	var authored := terrain.get_children()
	streamer = ChunkStreamer.new()
	streamer.generation = genesis
	streamer.living = living
	streamer.items = items
	streamer.persistence = persistence
	streamer.player = player.state
	streamer.region = region
	streamer.background_work_allowed = _world_stream_work_allowed
	terrain.add_child(streamer)
	var error := streamer.initialize()
	if error != OK:
		startup_error = error
		push_error("Canonical chunk attachment failed: " + str(streamer.metrics.last_error))
		_freeze_world_failure()
		return
	for child in authored: child.free()
	items_panel.attach_chunk_candidates(streamer.resource_candidates)
	living_runtime = LivingRuntime.new()
	living_runtime.module = living
	living_runtime.root_host = authority_host
	living_runtime.targeting = targeting.service
	living_runtime.region = region
	living_runtime.active_chunks = streamer.active_chunk
	living_runtime.spatial_gate = _world_visible
	living_runtime.route_port = streamer.route
	world_scene.active_region.add_child(living_runtime)
	enemies.relevant = func(actor: EnemyActor) -> bool: return streamer.active_chunk(region.chunk_id(region.to_local_position(actor.position)))
	_enemy_cell = Vector2i(1000000, 1000000)
	if OS.is_debug_build():
		var canvas := CanvasLayer.new()
		_world_label = Label.new()
		_world_label.position = Vector2(560, 255)
		_world_label.add_theme_font_size_override("font_size", 16)
		canvas.add_child(_world_label)
		world_scene.active_region.add_child(canvas)

func _sync_enemy_bodies() -> void:
	if not is_instance_valid(streamer) or "--combat-actions-acceptance" in OS.get_cmdline_user_args(): return
	var definition := world_scene.active_region.record.definition
	var cell := definition.chunk_at(definition.to_local_position(player.state.position))
	if cell == _enemy_cell and core.clock.tick % 5 != 0: return
	_enemy_cell = cell
	var actors: Array = [enemies.actor]
	actors.append_array(enemies.companions)
	for actor: EnemyActor in actors:
		var relevant := streamer.active_chunk(definition.chunk_id(definition.to_local_position(actor.position)))
		var body: EnemyBody = enemy_body if actor == enemies.actor else null
		if actor != enemies.actor:
			for candidate in companion_bodies:
				if candidate.actor == actor: body = candidate; break
		if relevant and not is_instance_valid(body):
			body = EnemyBody.new()
			body.actor = actor
			world_scene.active_region.get_node("Actors").add_child(body)
			if actor == enemies.actor: enemy_body = body; enemies.controller.move_toward = body.approach
			else:
				companion_bodies.append(body)
				for ai in enemies.companion_controllers:
					if ai.actor == actor: ai.move_toward = body.approach
			targeting.service.register(actor.entity_id, func() -> Vector3: return actor.position)
			combat_feedback.attach_actor(actor.entity_id, body.marker)
		elif not relevant and is_instance_valid(body):
			actor.actions.interrupt()
			targeting.service.unregister(actor.entity_id)
			if actor == enemies.actor: enemy_body = null; enemies.controller.move_toward = Callable()
			else:
				companion_bodies.erase(body)
				for ai in enemies.companion_controllers:
					if ai.actor == actor: ai.move_toward = Callable()
			body.free()

func _freeze_world_failure() -> void:
	set_process(false)
	var avatar := world_scene.active_region.avatar
	avatar.motor.set_physics_process(false)
	avatar.input.set_physics_process(false)
	persistence.writes_blocked = true
	persistence.suppress_autosave = true
	startup_message = Label.new()
	startup_message.text = "Canonical world attachment failed. Saved data has been preserved."
	add_child(startup_message)

func _world_stream_work_allowed() -> bool:
	if player_combat.actions.phase not in [ActionExecutor.Phase.IDLE, ActionExecutor.Phase.CANCELLED]: return false
	if enemies.actor.combatant.lifecycle == Combatant.Lifecycle.ALIVE and enemies.actor.position.distance_squared_to(player.state.position) < 196.0: return false
	for actor: EnemyActor in enemies.companions:
		if actor.combatant.lifecycle == Combatant.Lifecycle.ALIVE and actor.position.distance_squared_to(player.state.position) < 196.0: return false
	return true
