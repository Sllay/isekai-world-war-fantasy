extends SceneTree

class Relations extends CombatTargetPolicy:
	var selected := Relationship.ENEMY
	func relationship(_source: String, _target: String) -> Relationship:
		return selected

var checks := 0
var failures := 0
var core := CoreRuntimeServicesModule.new()
var module := CombatModule.new()
var registry := CoreModuleRegistry.new()
var executor: ActionExecutor
var positions: Dictionary = {}
var damage_count := 0
var heal_count := 0
var phases: Array[String] = []
var ticks: Array[int] = []
const STRIKE := "combat.action.basic_strike"
const HEAL := "combat.action.basic_heal"

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func step(count: int) -> void:
	for index in range(count):
		core.clock.tick += 1
		executor.advance()

func reset() -> void:
	executor.restore({"cooldowns": {}})

func run() -> void:
	registry.add(core)
	registry.add(module)
	check(registry.boot() == OK, "action substrate boots without Player/World")
	var service := module.service
	var owner := service.register(core.entities.create(), "combat.profile.standard")
	var target := service.register(core.entities.create(), "combat.profile.standard")
	positions[owner.entity_id] = Vector3.ZERO
	positions[target.entity_id] = Vector3(0, 0, 2)
	var policy := Relations.new()
	service.target_policy = policy
	executor = ActionExecutor.new(service, module.actions, owner.entity_id)
	executor.position_of = func(id: String) -> Variant: return positions.get(id)
	check(module.actions.ids() == [HEAL, STRIKE, "combat.action.enemy.basic_strike"], "production action IDs")
	check(core.data.lookup(STRIKE).get("kind") == "action", "Core data discovery projection")
	check(module.actions.register(module.actions.lookup(STRIKE)) == ERR_ALREADY_EXISTS, "duplicate IDs reject")
	var definition := module.actions.lookup(STRIKE)
	definition.effects[0].amount = 999
	check(module.actions.lookup(STRIKE).effects[0].amount == 12, "catalog returns independent typed definitions")
	for field in ["cast_ticks", "recovery_ticks", "cooldown_ticks", "resource_cost"]:
		definition = module.actions.lookup(STRIKE)
		definition.set(field, -1)
		check(not definition.valid(core.data), "negative definition field: " + field)
	definition = module.actions.lookup(STRIKE)
	definition.max_range = NAN
	check(not definition.valid(core.data), "nonfinite range rejects")
	definition.max_range = 2.5
	definition.target_mode = ActionDefinition.TargetMode.POINT
	check(not definition.valid(core.data), "unimplemented targeting cannot silently execute")
	definition = module.actions.lookup(STRIKE)
	definition.effects[0].damage_type_id = "combat.damage.missing"
	check(not definition.valid(core.data), "unknown damage metadata rejects")
	definition = module.actions.lookup(STRIKE)
	definition.tags.assign(["combat.tag.hit", "combat.tag.hit"])
	check(not definition.valid(core.data), "duplicate tags reject")
	definition = module.actions.lookup(HEAL)
	definition.effects.clear()
	check(not definition.valid(core.data), "empty effects reject")
	check(executor.activate("combat.action.missing") == "UNKNOWN_ACTION", "unknown action reason")
	check(executor.activate(STRIKE) == "TARGET_UNAVAILABLE", "missing target rejects")
	positions[target.entity_id] = Vector3(0, 0, 3)
	check(executor.activate(STRIKE, ActionTarget.new(target.entity_id)) == "OUT_OF_RANGE", "world-space range validates")
	positions.erase(target.entity_id)
	check(executor.activate(STRIKE, ActionTarget.new(target.entity_id)) == "POSITION_UNAVAILABLE", "missing position rejects")
	positions[target.entity_id] = Vector3(0, 0, 2)
	policy.selected = CombatTargetPolicy.Relationship.ALLY
	check(executor.activate(STRIKE, ActionTarget.new(target.entity_id)) == "RELATIONSHIP_REJECTED", "relationship policy before activation")
	check(owner.resource == 50 and executor.capture().cooldowns.is_empty(), "rejections consume no resource/cooldown")
	policy.selected = CombatTargetPolicy.Relationship.ENEMY
	core.events.subscribe(DamageApplied, func(_event: DamageApplied) -> void: damage_count += 1)
	core.events.subscribe(HealingApplied, func(_event: HealingApplied) -> void: heal_count += 1)
	var start_token := core.events.subscribe(ActionStarted, func(event: ActionStarted) -> void:
		phases.append("started")
		ticks.append(event.tick)
		check(event.owner_id == owner.entity_id and event.action_id == STRIKE, "typed started stable IDs")
		check(executor.activate(HEAL) == "BUSY", "action event cannot reenter executor")
	)
	core.events.subscribe(ActionCommitted, func(event: ActionCommitted) -> void:
		phases.append("committed")
		ticks.append(event.tick)
		check(executor.phase == ActionExecutor.Phase.COMMIT, "explicit commit phase during fact")
	)
	core.events.subscribe(ActionCompleted, func(event: ActionCompleted) -> void:
		phases.append("completed")
		ticks.append(event.tick)
	)
	var start_tick := core.clock.tick
	check(executor.activate(STRIKE, ActionTarget.new(target.entity_id)) == "STARTED", "strike starts")
	core.events.unsubscribe(start_token)
	check(executor.movement_allowed() and executor.turning_allowed(), "strike allows moving/turning")
	check(executor.activate(HEAL) == "ACTION_ACTIVE", "active action excludes another")
	step(3)
	check(target.health == 100 and executor.phase == ActionExecutor.Phase.CASTING, "windup tick boundary")
	step(1)
	check(target.health == 88 and damage_count == 1, "damage reaches CombatService once")
	check(executor.remaining_cooldown(STRIKE) == 16, "cooldown starts on commit")
	for index in range(5): executor.advance()
	check(target.health == 88 and damage_count == 1, "same tick cannot double commit")
	step(6)
	check(executor.phase == ActionExecutor.Phase.IDLE and phases == ["started", "committed", "completed"], "deterministic phase sequence")
	check(ticks == [start_tick, start_tick + 4, start_tick + 10], "exact transition ticks")
	check(executor.activate(STRIKE, ActionTarget.new(target.entity_id)) == "COOLDOWN", "cooldown rejection after recovery")
	step(10)
	check(executor.remaining_cooldown(STRIKE) == 0 and executor.activate(STRIKE, ActionTarget.new(target.entity_id)) == "STARTED", "cooldown expires exactly")
	check(executor.cancel() == "CANCELLED" and executor.phase == ActionExecutor.Phase.CANCELLED, "voluntary cancel")
	check(executor.capture().cooldowns.is_empty() and executor.movement_allowed(), "cancel releases temporary state without cooldown")
	check(executor.activate(HEAL) == "STARTED" and not executor.movement_allowed() and not executor.turning_allowed(), "heal gates movement and turning")
	check(executor.interrupt() == "CANCELLED" and owner.resource == 50, "interrupt before commit spends nothing")
	check(executor.movement_allowed() and executor.turning_allowed(), "interrupt releases gates")
	var hit := DamageRequest.new(owner.entity_id, owner.entity_id, 30)
	hit.allow_self = true
	service.damage(hit)
	check(executor.activate(HEAL) == "STARTED", "self target resolved without caller target")
	step(10)
	check(owner.health == 85 and owner.resource == 45 and heal_count == 1, "healing and cost commit through production services once")
	executor.advance()
	check(owner.health == 85 and owner.resource == 45 and heal_count == 1, "heal cannot double spend/commit")
	check(executor.cancel() == "NOT_CANCELLABLE_PHASE", "recovery not refundable")
	var saved := executor.capture()
	check(saved.keys() == ["cooldowns"] and saved.cooldowns[HEAL] == 60, "save has only canonical remaining cooldowns")
	check(executor.valid_snapshot(saved) and not executor.valid_snapshot({}), "cooldown schema required")
	check(not executor.valid_snapshot({"cooldowns": {HEAL: -1}}), "negative cooldown rejected")
	check(not executor.valid_snapshot({"cooldowns": {HEAL: 0.5}}), "fractional cooldown rejected")
	check(not executor.valid_snapshot({"cooldowns": {HEAL: 61}}), "excessive cooldown rejected")
	check(not executor.valid_snapshot({"cooldowns": {"combat.action.missing": 1}}), "unknown saved cooldown rejected")
	executor.restore(saved)
	check(executor.phase == ActionExecutor.Phase.IDLE and executor.remaining_cooldown(HEAL) == 60 and executor.movement_allowed(), "restore drops active execution and retains cooldown")
	check(executor.activate(HEAL) == "COOLDOWN", "restore cannot bypass committed cooldown")
	step(60)
	check(executor.remaining_cooldown(HEAL) == 0, "restored cooldown expires by ticks")
	service.spend_resource(owner.entity_id, owner.resource)
	check(executor.activate(HEAL) == "INSUFFICIENT_RESOURCE" and executor.remaining_cooldown(HEAL) == 0, "insufficient resource no cooldown")
	service.restore_resource(owner.entity_id, 50)
	reset()
	executor.activate(HEAL)
	service.spend_resource(owner.entity_id, 50)
	step(10)
	check(executor.phase == ActionExecutor.Phase.CANCELLED and executor.last_result == "INSUFFICIENT_RESOURCE" and executor.remaining_cooldown(HEAL) == 0, "resource is revalidated before commit without spending twice")
	service.restore_resource(owner.entity_id, 50)
	reset()
	executor.activate(STRIKE, ActionTarget.new(target.entity_id))
	positions[target.entity_id] = Vector3(0, 0, 20)
	var health_before := target.health
	step(4)
	check(executor.phase == ActionExecutor.Phase.CANCELLED and target.health == health_before and executor.last_result == "OUT_OF_RANGE", "commit revalidates range")
	positions[target.entity_id] = Vector3(0, 0, 2)
	reset()
	executor.activate(STRIKE, ActionTarget.new(target.entity_id))
	policy.selected = CombatTargetPolicy.Relationship.ALLY
	step(4)
	check(target.health == health_before and executor.last_result == "RELATIONSHIP_REJECTED", "commit revalidates relationship")
	policy.selected = CombatTargetPolicy.Relationship.ENEMY
	definition = module.actions.lookup(HEAL)
	definition.action_id = "combat.action.uninterruptible_test"
	definition.interruptible = false
	definition.cancellable = false
	definition.cooldown_ticks = 0
	check(module.actions.register(definition) == OK, "new typed content without executor changes")
	reset()
	executor.activate(definition.action_id)
	check(executor.cancel() == "NOT_CANCELLABLE" and executor.interrupt() == "NOT_INTERRUPTIBLE", "definition cancellation flags respected")
	step(14)
	check(executor.remaining_cooldown(definition.action_id) == 0, "zero cooldown supported")
	reset()
	var input := PlayerInput.new()
	var intent := PlayerIntent.new()
	input.intent = intent
	input.request_action(1)
	intent.movement = Vector2.UP
	intent.camera_delta = 1.0
	intent.jump = true
	var adapter := PlayerActionAdapter.new()
	adapter.executor = executor
	adapter.consume(intent)
	check(executor.current.action_id == HEAL and not intent.secondary_action, "semantic input maps to action and consumes once")
	check(intent.movement == Vector2.UP and intent.jump and intent.camera_delta == 1, "combat intent preserves movement camera jump")
	input.request_action(2)
	adapter.consume(intent)
	check(executor.phase == ActionExecutor.Phase.CANCELLED, "semantic cancel boundary")
	input.free()
	reset()
	executor.activate(HEAL)
	executor.restore(executor.capture())
	check(executor.phase == ActionExecutor.Phase.IDLE and executor.remaining_cooldown(HEAL) == 0, "uncommitted half-cast never resumes")
	executor.activate(HEAL)
	hit = DamageRequest.new(owner.entity_id, owner.entity_id, 1000)
	hit.allow_self = true
	service.damage(hit)
	executor.advance()
	check(executor.phase == ActionExecutor.Phase.CANCELLED and executor.movement_allowed(), "defeat during casting releases action-owned gates")
	check(executor.activate(HEAL) == "OWNER_DEFEATED", "defeat prevents activation")
	executor.owner_id = CoreIds.generate()
	check(executor.activate(HEAL) == "OWNER_UNAVAILABLE", "owner must be registered combatant")
	registry.shutdown()
	print("Combat Action tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
