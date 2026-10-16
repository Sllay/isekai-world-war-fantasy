extends SceneTree

var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0]
	var path := args[1].path_join("enemy-restart.json")
	var proof := args[1].path_join("enemy-proof.json")
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.enemy_restart", path)
	root.add_child(runtime)
	runtime.set_process(false)
	var actor: EnemyActor = runtime.enemies.actor
	var player: PlayerState = runtime.player.state
	var service: CombatService = runtime.combat.service
	var recovery: RegionRecovery = runtime.enemies.record.recovery
	check(runtime.startup_error == OK, "fresh process production boot")
	if mode == "save":
		player.position = actor.position + Vector3(0, 0, 1)
		player.grounded = true
		recovery.observe()
		var action: ActionExecutor = runtime.player_combat.actions
		check(action.activate("combat.action.basic_strike", ActionTarget.new(actor.entity_id)) == "STARTED", "Player action damages real enemy before process exit")
		for i in 4:
			service.clock.tick += 1
			action.advance()
		check(actor.combatant.health == 88, "damaged enemy checkpoint")
		actor.actions.restore({"cooldowns": {actor.archetype.action_id: 17}})
		# This accepted process case exercises the optional-port fallback path.
		recovery.surface_query = null
		player.position.y = -100
		player.velocity.y = -40
		recovery.observe()
		check(player.position.y > -1 and player.velocity == Vector3.ZERO, "void recovery before process save")
		check(runtime.save_game() == OK, "process writes Region actor and recovery state")
		var file := FileAccess.open(proof, FileAccess.WRITE)
		file.store_string(JSON.stringify({"entity_id": actor.entity_id, "player_id": player.entity_id, "safe": recovery.last_safe}))
		file.close()
	else:
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(proof))
		check(runtime.persistence.startup_mode == "resume", "separate OS process resumed slot")
		check(actor.entity_id == expected.entity_id and player.entity_id == expected.player_id, "same actor and Player identity across OS processes")
		check(runtime.core.entities.capture().ids.size() == 2, "exactly one Player and one Region actor")
		check(player.position == Vector3(expected.safe.position[0], expected.safe.position[1], expected.safe.position[2]) and player.velocity == Vector3.ZERO, "fresh process uses validated recovery transform")
		check(runtime.current_player_target().is_empty() and runtime.telegraphs.active.is_empty(), "no transient selection or telegraphs after restart")
		if mode == "resume":
			check(actor.combatant.health == 88 and actor.actions.remaining_cooldown(actor.archetype.action_id) == 17, "fresh process preserves enemy HP and cooldown")
			check(actor.actions.phase == ActionExecutor.Phase.IDLE, "fresh process drops active action phases")
			player.position = actor.position + Vector3(0, 0, 1)
			actor.actions.restore({"cooldowns": {}})
			check(actor.actions.activate(actor.archetype.action_id, ActionTarget.new(player.entity_id)) == "STARTED", "enemy starts uncommitted cast before next process")
			check(runtime.save_game() == OK, "disk save during windup")
		elif mode == "cast":
			check(actor.actions.phase == ActionExecutor.Phase.IDLE and actor.combatant.health == 88, "uncommitted cast not resumed across restart")
			for hit in 8:
				var action: ActionExecutor = runtime.player_combat.actions
				action.restore({"cooldowns": {}})
				action.activate("combat.action.basic_strike", ActionTarget.new(actor.entity_id))
				for i in 4:
					service.clock.tick += 1
					action.advance()
			check(actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED, "Player actions defeat persisted actor")
			check(runtime.save_game() == OK, "save defeated actor to same slot")
		else:
			check(actor.combatant.health == 0 and actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED, "fresh process preserves defeat without silent respawn")
			for i in 30: runtime._process(0.05)
			check(runtime.enemies.controller.state == EnemyController.State.DEFEATED, "restored defeated actor cannot act")
	# Use actual physics after safe resume: the same motor/camera/input stay usable.
	if mode == "defeated":
		var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
		avatar.get_child(0).set_physics_process(false)
		for i in 4: await physics_frame
		player.position.y = -30
		player.velocity.y = -50
		for i in 3: await physics_frame
		check(player.position.y > -1 and player.velocity.y > -2, "real Region physics callback recovers void crossing")
		# Dynamic recovery deliberately places feet above the surface. Wait for
		# real contact before issuing the existing grounded-only jump command.
		for i in 20:
			if player.grounded:
				break
			await physics_frame
		var start := player.position
		avatar.intent.movement = Vector2.RIGHT
		avatar.intent.camera_delta = 0.5
		avatar.intent.jump = true
		for i in 10: await physics_frame
		check(player.position.x > start.x and avatar.orbit.yaw > 0.4, "movement/camera healthy after recovered process resume")
		check(player.position.y > start.y + 0.2 and not player.grounded, "jump healthy after recovery")
	runtime.free()
	print("Enemy restart %s tests: %d checks, %d failures" % [mode, checks, failures])
	quit(0 if failures == 0 else 1)
