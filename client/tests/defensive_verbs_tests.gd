extends SceneTree

var checks := 0
var failures := 0
var runtime: Node
var facts: Array[DefenseResolved] = []
var service: CombatService
var player: Combatant
var enemy: EnemyActor
var actions: ActionExecutor

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func reset() -> void:
	var state: Dictionary = runtime.player_combat.initial_state(player.entity_id)
	service.restore_owned(player, player.entity_id, state.combatant)
	actions.restore({"cooldowns": {}})
	enemy.actions.restore({"cooldowns": {}})
	runtime.player.state.position = enemy.position + Vector3(0, 0, 1)
	runtime.player.state.facing = Vector3.FORWARD
	facts.clear()

func hit(dodgeable := true, blockable := true, parryable := true, amount := 8) -> CombatResult:
	var request := DamageRequest.new(enemy.entity_id, player.entity_id, amount)
	request.dodgeable = dodgeable
	request.blockable = blockable
	request.parryable = parryable
	return service.damage(request)

func ticks(count: int) -> void:
	for i in count:
		service.clock.tick += 1
		actions.advance()
		enemy.actions.advance()

func sampled_window(delta: float, frames: int) -> Dictionary:
	reset()
	actions.activate("combat.action.basic_dodge")
	var clock := CoreClock.new()
	var initial_tick := service.clock.tick
	for frame in frames:
		var steps := clock.advance(delta)
		for i in steps:
			service.clock.tick += 1
			actions.advance()
	return {"ticks": service.clock.tick - initial_tick, "resource": player.resource, "outcome": hit().outcome}

func run() -> void:
	runtime = preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.defenses", OS.get_cmdline_user_args()[0].path_join("defenses.json"))
	root.add_child(runtime)
	runtime.set_process(false)
	service = runtime.combat.service
	player = runtime.player_combat.state
	enemy = runtime.enemies.actor
	actions = runtime.player_combat.actions
	var token := service.events.subscribe(DefenseResolved, func(fact: DefenseResolved) -> void: facts.append(fact))
	check(runtime.startup_error == OK, "production defense runtime boots")
	check(runtime.player.capabilities.capability("foundation.defense") == player.defense, "composed defense capability")
	reset()
	check(hit().actual == 8 and facts.size() == 1 and facts[0].outcome == "HIT", "baseline skirmisher damage unchanged")
	reset()
	check(actions.activate("combat.action.basic_dodge") == "STARTED", "dodge activates")
	check(player.resource == 44 and actions.remaining_cooldown("combat.action.basic_dodge") == 24, "authored dodge cost/cooldown")
	for i in 20: actions.advance()
	check(player.resource == 44 and player.defense.dodge_until - service.clock.tick == 6, "same tick frames cannot repeat cost or extend window")
	check(hit().outcome == "DODGED" and player.health == 100, "dodgeable damage prevented")
	check(hit(false).actual == 8, "non-dodgeable damage bypasses evade")
	ticks(6)
	check(hit().actual == 8, "exclusive dodge deadline expires")
	check(actions.activate("combat.action.basic_dodge") == "COOLDOWN" and player.resource == 44, "cooldown rejection costs nothing")
	check(sampled_window(0.03125, 16) == sampled_window(0.125, 4), "different render rates produce identical tick/window/resource outcomes")
	reset()
	service.spend_resource(player.entity_id, 50)
	check(actions.activate("combat.action.basic_dodge") == "INSUFFICIENT_RESOURCE" and player.resource == 0, "insufficient dodge resource rejects")
	reset()
	actions.activate("combat.action.basic_guard")
	check(player.defense.guard, "guard begin")
	var blocked := hit()
	check(blocked.outcome == "BLOCKED" and blocked.actual == 2 and blocked.prevented == 6 and player.resource == 48, "75 percent fixed-point block and per-hit cost")
	check(hit(true, false).actual == 8 and player.resource == 48, "unblockable hit spends no guard cost")
	runtime.player.state.facing = Vector3.BACK
	check(hit().outcome == "HIT" and player.resource == 48, "rear attack bypasses frontal guard")
	service.end_guard(player.entity_id)
	check(not player.defense.guard and hit().actual == 8, "guard end")
	reset()
	actions.activate("combat.action.basic_guard")
	check(hit(true, true, true, 7).actual == 1, "block integer flooring")
	service.spend_resource(player.entity_id, player.resource - 1)
	check(hit().actual == 8 and not player.defense.guard and player.resource == 1, "insufficient block energy breaks guard without spending")
	reset()
	check(hit().outcome == "HIT", "before parry activation hit is unprotected")
	check(actions.activate("combat.action.basic_parry") == "STARTED" and player.resource == 46, "parry authored cost")
	var parried := hit()
	check(parried.outcome == "PARRIED" and parried.actual == 0 and parried.prevented == 8, "parry prevents current hit")
	check(facts.size() == 2 and facts[1].applied == 0 and facts[1].raw == 8 and facts[1].target_entity == player.entity_id, "one typed correlated parry fact")
	check(hit(true, true, false).actual == 8, "non-parryable hit ignores parry")
	runtime.player.state.facing = Vector3.BACK
	check(hit().actual == 8, "rear parry fails")
	runtime.player.state.facing = Vector3.FORWARD
	ticks(4)
	check(hit().actual == 8, "late parry fails at exclusive deadline")
	check(actions.activate("combat.action.basic_parry") == "COOLDOWN" and player.resource == 46, "parry cooldown rejection costs nothing")
	reset()
	service.begin_defense(player.entity_id, "GUARD", 0)
	service.begin_defense(player.entity_id, "PARRY", 4)
	service.begin_defense(player.entity_id, "DODGE", 6)
	var request := DamageRequest.new(enemy.entity_id, player.entity_id, 8)
	var result := service.damage(request)
	check(result.outcome == "DODGED" and facts.size() == 1 and player.resource == 50, "dodge priority suppresses parry and block")
	check(service.damage(request).code == "REQUEST_CONSUMED" and facts.size() == 1, "same request cannot resolve twice")
	player.defense.dodge_until = 0
	check(hit().outcome == "PARRIED" and player.resource == 50, "parry priority suppresses block")
	reset()
	check(enemy.actions.activate(enemy.archetype.action_id, ActionTarget.new(player.entity_id)) == "STARTED", "real enemy windup starts")
	check(actions.activate("combat.action.basic_interrupt", ActionTarget.new(enemy.entity_id)) == "STARTED", "targeted interrupt starts")
	ticks(2)
	check(enemy.actions.phase == ActionExecutor.Phase.CANCELLED and actions.effect_results[0].accepted, "interrupt routes through target executor")
	check(runtime.telegraphs.active.is_empty(), "interrupted telegraph clears")
	ticks(20)
	check(player.health == 100 and enemy.combatant.health == 100, "interrupted attack never damages either actor")
	check(runtime.combat.action_runtime.interrupt(enemy.entity_id).code == "NOT_CANCELLABLE_PHASE", "duplicate interrupt rejects")
	reset()
	runtime.player.state.position += Vector3(20, 0, 0)
	check(actions.activate("combat.action.basic_interrupt", ActionTarget.new(enemy.entity_id)) == "OUT_OF_RANGE" and player.resource == 50, "interrupt range rejects without spending")
	check(actions.activate("combat.action.basic_interrupt", ActionTarget.new(CoreIds.generate())) == "TARGET_UNAVAILABLE", "invalid interrupt target")
	reset()
	enemy.actions.activate(enemy.archetype.action_id, ActionTarget.new(player.entity_id))
	enemy.actions.current.interruptible = false
	check(runtime.combat.action_runtime.interrupt(enemy.entity_id).code == "NOT_INTERRUPTIBLE", "noninterruptible cast rejects")
	reset()
	enemy.actions.activate(enemy.archetype.action_id, ActionTarget.new(player.entity_id))
	service.begin_defense(player.entity_id, "PARRY", 100)
	ticks(enemy.actions.current.cast_ticks)
	check(player.health == 100 and enemy.actions.phase == ActionExecutor.Phase.CANCELLED and enemy.actions.last_result == "PARRIED", "parry fact interrupts matching committed enemy recovery")
	check(facts.size() == 1 and facts[0].transaction_id == enemy.actions.execution_id, "parry reaction correlated exactly once")
	reset()
	enemy.actions.activate(enemy.archetype.action_id, ActionTarget.new(player.entity_id))
	runtime.player.state.position += Vector3(20, 0, 0)
	ticks(enemy.actions.current.cast_ticks)
	check(player.health == 100 and enemy.actions.last_result == "OUT_OF_RANGE", "windup range revalidation preserved")
	reset()
	service.begin_defense(player.entity_id, "GUARD", 0)
	service.begin_defense(player.entity_id, "PARRY", 4)
	service.begin_defense(player.entity_id, "DODGE", 6)
	hit(false, false, false, 100)
	check(not player.defense.guard and player.defense.dodge_until == 0 and player.defense.parry_until == 0, "defeat clears active defense")
	check(actions.activate("combat.action.basic_dodge") == "OWNER_DEFEATED", "defeated dodge rejects")
	reset()
	var intent := PlayerIntent.new()
	intent.guard_started = true
	intent.guard_ended = true
	runtime.action_adapter.consume(intent)
	check(not player.defense.guard, "touch press/release inside one tick cannot latch guard")
	service.begin_defense(player.entity_id, "GUARD", 0)
	runtime.enemies.targeting.unregister(player.entity_id)
	check(not player.defense.guard, "residency targeting loss clears defense")
	reset()
	actions.activate("combat.action.basic_parry")
	service.begin_defense(player.entity_id, "GUARD", 0)
	runtime.combat.action_runtime.last_result = "CANCELLED"
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "same-session defense save/resume succeeds")
	check(not player.defense.guard and player.defense.parry_until == 0 and runtime.combat.action_runtime.last_result == "NONE", "same-session resume clears all transient defense and interrupt state")
	check(actions.remaining_cooldown("combat.action.basic_parry") == 24 and player.resource == 46, "same-session resume retains committed resource and cooldown")
	service.events.unsubscribe(token)
	runtime.free()
	print("Defensive verbs tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
