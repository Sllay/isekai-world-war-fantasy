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

func _ready() -> void:
	var core_only := "--core-smoke" in OS.get_cmdline_user_args()
	if not core_only:
		for module in [player, world, regions, combat, player_combat, targeting, enemies]:
			var error := registry.add(module)
			if error != OK:
				push_error("Production module registration failed: %s" % error)
				get_tree().quit(1)
				return
	super._ready()
	if registry.state != CoreModuleRegistry.State.RUNNING or core_only:
		return
	world_scene = WORLD_SCENE.instantiate() as WorldScene
	world_scene.directory = regions.directory
	world_scene.player = player.state
	add_child(world_scene)
	initial_snapshot = core.saves.capture(registry, WORLD_CONTENT.world_id, WORLD_CONTENT.world_seed)
	persistence = SaveCoordinator.new(save_slot, registry, core.saves, world_scene, WORLD_CONTENT)
	initial_snapshot.game_version = SaveIntegrity.GAME_VERSION
	persistence.initial_snapshot = initial_snapshot
	telegraphs.bind(core.events, combat.actions, core.clock)
	startup_error = persistence.startup()
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
		var controls := preload("res://runtime/combat_debug_controls.gd").new()
		controls.combat = combat.service
		controls.state = player_combat.state
		controls.actions = player_combat.actions
		controls.enemy_summary = func() -> String: return "Skirmisher HP %d  %s  Target: %s" % [enemies.actor.combatant.health, EnemyController.State.keys()[enemies.controller.state], "Skirmisher" if not current_player_target().is_empty() else "none (Target/T)"]
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
		_activate_session()
	return error

# Public application API for later UI/gameplay/lifecycle adapters.
func save_game() -> Error:
	return persistence.save_game() if persistence != null else ERR_UNCONFIGURED

func resume_game() -> Error:
	if persistence == null:
		return ERR_UNCONFIGURED
	var previous_region := world_scene.active_region
	var error := persistence.resume_game()
	if error == OK or (persistence.ready and world_scene.active_region != previous_region):
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
	return result

func _process(delta: float) -> void:
	if registry.state != CoreModuleRegistry.State.RUNNING:
		return
	var previous := core.clock.tick
	var steps := core.clock.advance(delta)
	if steps == 0:
		return
	# Replay each newly advanced Core tick so effects and facts share exact ticks.
	core.clock.tick = previous
	for index in range(steps):
		core.clock.tick += 1
		core.scheduler.run_due(core.clock.tick)
		if player_combat.actions != null and persistence != null and persistence.ready:
			player_combat.actions.advance()
			if "--combat-actions-acceptance" not in OS.get_cmdline_user_args():
				enemies.tick()
			if world_scene.active_region != null and world_scene.active_region.avatar.intent.select_target:
				select_player_target()
				world_scene.active_region.avatar.intent.select_target = false
			if world_scene.active_region != null:
				action_adapter.consume(world_scene.active_region.avatar.intent)

func _exit_tree() -> void:
	telegraphs.dispose()
	if is_instance_valid(action_harness):
		action_harness.free()
	if is_instance_valid(world_scene):
		world_scene.close_region()
	super._exit_tree()
