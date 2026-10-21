extends SceneTree

class Relations extends CombatTargetPolicy:
	func relationship(_a: String, _b: String) -> Relationship:
		return Relationship.ENEMY

var checks := 0
var failures := 0
var core := CoreRuntimeServicesModule.new()
var combat := CombatModule.new()
var registry := CoreModuleRegistry.new()
var host := LocalAuthorityHost.new()
var gateway: LoopbackAuthorityGateway
var player := PlayerState.new()
var enemy: Combatant
var executor: ActionExecutor
var enemy_actions: ActionExecutor
var defense_facts := 0
var positions: Dictionary = {}

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func step(count: int) -> void:
	for i in range(count):
		core.clock.tick += 1
		host.advance()

func envelope(sequence: int, kind: String, payload: Dictionary, tick := -1) -> Dictionary:
	return {"version": 1, "sequence": sequence, "tick": core.clock.tick if tick < 0 else tick, "kind": kind, "payload": payload}

func run() -> void:
	registry.add(core)
	registry.add(combat)
	check(registry.boot() == OK, "authority domain harness boots without scene/UI")
	combat.service.target_policy = Relations.new()
	player.entity_id = core.entities.create()
	player.position = Vector3.ZERO
	player.facing = Vector3.BACK
	combat.service.register(player.entity_id, "combat.profile.standard")
	enemy = combat.service.register(core.entities.create(), "combat.profile.standard")
	positions[enemy.entity_id] = Vector3(0, 0, 2)
	executor = ActionExecutor.new(combat.service, combat.actions, player.entity_id)
	executor.position_of = func(id: String) -> Variant: return player.position if id == player.entity_id else positions.get(id)
	enemy_actions = ActionExecutor.new(combat.service, combat.actions, enemy.entity_id)
	enemy_actions.position_of = executor.position_of
	host.configure(combat.service, executor, player, "authenticated-session")
	host.actor_executors[enemy.entity_id] = enemy_actions
	host.defense.position_of = executor.position_of
	host.defense.facing_of = func(_id: String) -> Vector3: return player.facing
	host.safe_spawn = func() -> void: player.position = Vector3(0, 0, 8)
	gateway = LoopbackAuthorityGateway.new(host, "authenticated-session")
	var state := combat.service.combatant(player.entity_id)
	check(not host.submit("forged-session", envelope(1, "action", {"slot": "primary", "target": enemy.entity_id})).accepted, "session owns actor; forged peer rejected")
	check(not gateway.request("damage", {"amount": 9999}).accepted, "client damage outcome rejected")
	check(not gateway.request("action", {"slot": "primary", "target": enemy.entity_id, "health": 100}).accepted, "forged action fields rejected")
	check(not gateway.request("move", {"position": Vector3(999, 0, 0)}).accepted, "client final position rejected")
	check(not gateway.request("resource", {"value": 999}).accepted, "resource/cooldown outcome unavailable")
	check(not gateway.request("move", {"axis": Vector2(NAN, 0), "facing": Vector3.FORWARD, "jump": false}).accepted, "NaN movement rejected")
	check(not host.submit("authenticated-session", envelope(100, "cancel", {}, core.clock.tick + 3)).accepted, "future command rejected")
	core.clock.tick = 50
	check(not host.submit("authenticated-session", envelope(100, "cancel", {}, 1)).accepted, "stale command rejected")
	var command := envelope(100, "action", {"slot": "primary", "target": enemy.entity_id})
	check(host.submit("authenticated-session", command).accepted, "semantic attack accepted into bounded inbox")
	command.payload["damage"] = 999
	check(not host.submit("authenticated-session", envelope(100, "cancel", {})).accepted, "duplicate sequence rejected")
	check(not host.submit("authenticated-session", envelope(99, "cancel", {})).accepted, "older sequence rejected")
	step(5)
	check(enemy.health == 88, "queued deep copy derives 12 damage from authoritative catalog")
	step(16)
	check(enemy.health == 88, "duplicate cannot repeat commit")
	# Direct deterministic domain and loopback have equivalent canonical effects.
	var direct_owner := combat.service.register(core.entities.create(), "combat.profile.standard")
	var direct_target := combat.service.register(core.entities.create(), "combat.profile.standard")
	var direct := ActionExecutor.new(combat.service, combat.actions, direct_owner.entity_id)
	direct.position_of = func(_id: String) -> Vector3: return Vector3.ZERO
	check(direct.activate("combat.action.basic_strike", ActionTarget.new(direct_target.entity_id)) == "STARTED", "domain counterpart starts")
	for i in range(4):
		core.clock.tick += 1
		direct.advance()
	check(direct_target.health == enemy.health and direct_owner.resource == state.resource, "loopback/domain result equivalence")
	# Ingress boundedness, including blocked actions, is independent of content.
	for i in range(8):
		check(host.submit("authenticated-session", envelope(101 + i, "cancel", {})).accepted, "bounded inbox accepts capacity")
	check(not host.submit("authenticated-session", envelope(109, "cancel", {})).accepted, "inbox backpressure")
	step(2)
	gateway = LoopbackAuthorityGateway.new(host, "authenticated-session")
	# Reconnect sequences are session-scoped; testing a new transport cannot reset them.
	check(not gateway.request("cancel").accepted, "same-session sequence reset cannot replay")
	host.submit("authenticated-session", envelope(110, "guard", {"enabled": true}))
	host.submit("authenticated-session", envelope(111, "move", {"axis": Vector2.ZERO, "facing": Vector3.BACK, "jump": false}))
	step(1)
	var health := state.health
	var energy := state.resource
	var result := combat.service.damage(DamageRequest.new(enemy.entity_id, player.entity_id, 8))
	check(result.actual == 2 and result.prevented == 6 and state.resource == energy - 4, "frontal guard derives reduction and transactional energy cost")
	check(state.health == health - 2, "guard success still reports chip damage")
	player.facing = Vector3.FORWARD
	result = combat.service.damage(DamageRequest.new(enemy.entity_id, player.entity_id, 8))
	check(result.actual == 8 and result.defense == "GUARD_FAILED", "rear attack defeats guard")
	host.defense.set_guard(player.entity_id, false)
	check(host.defense.dodge(player.entity_id) == "DODGE", "resource-backed dodge starts")
	health = state.health
	result = combat.service.damage(DamageRequest.new(enemy.entity_id, player.entity_id, 8))
	check(result.actual == 0 and result.defense == "DODGED" and state.health == health, "dodgeable hit evaded in canonical window")
	check(host.defense.dodge(player.entity_id) == "DEFENSE_UNAVAILABLE", "dodge cannot refresh its window for free")
	step(4)
	result = combat.service.damage(DamageRequest.new(enemy.entity_id, player.entity_id, 8))
	check(result.actual == 8, "dodge window expires on authority ticks")
	var light := DamageRequest.new(player.entity_id, enemy.entity_id, 1)
	combat.service.damage(light)
	check(not host.defense.staggered(enemy.entity_id), "light hit never gameplay-stuns")
	var strong := DamageRequest.new(player.entity_id, enemy.entity_id, 1)
	strong.tags.assign(["combat.tag.strong"])
	combat.service.damage(strong)
	check(host.defense.staggered(enemy.entity_id), "valid strong hit produces bounded stagger")
	step(6)
	check(not host.defense.staggered(enemy.entity_id), "stagger releases movement/action gate")
	strong = DamageRequest.new(player.entity_id, enemy.entity_id, 1)
	strong.tags.assign(["combat.tag.strong"])
	combat.service.damage(strong)
	check(not host.defense.staggered(enemy.entity_id), "stagger immunity prevents repeated lock")
	step(20)
	var enemy_before := enemy.health
	var cost_before := state.resource
	check(enemy_actions.activate("combat.action.enemy.basic_strike", ActionTarget.new(player.entity_id)) == "STARTED", "opponent uses shared executor wind-up")
	check(host.submit("authenticated-session", envelope(112, "action", {"slot": "strong", "target": enemy.entity_id})).accepted, "strong skill enters the same semantic boundary")
	step(11)
	check(enemy.health == enemy_before - 26 and state.resource == cost_before - 10, "strong content derives exact damage and resource cost")
	check(enemy_actions.phase == ActionExecutor.Phase.CANCELLED and host.defense.staggered(enemy.entity_id), "strong stagger interrupts an interruptible enemy cast")
	step(20)
	combat.service.spend_resource(player.entity_id, state.resource)
	player.facing = Vector3.BACK
	host.defense.set_guard(player.entity_id, true)
	result = combat.service.damage(DamageRequest.new(enemy.entity_id, player.entity_id, 8))
	check(result.actual == 8 and result.defense == "GUARD_FAILED" and state.resource == 0, "exhausted guard cannot invent energy or block")
	host.defense.set_guard(player.entity_id, false)
	# A mirror can be corrected but can never move the host by editing a snapshot.
	var mirror := PlayerState.new()
	mirror.entity_id = player.entity_id
	mirror.position = Vector3(999, 0, 0)
	var reconcile := PlayerReconciler.new()
	var snapshot := host.snapshot()
	check(reconcile.apply(mirror, snapshot) and mirror.position == player.position, "real snapshot correction adapter")
	snapshot.player.position[0] = 9999
	check(player.position.x != 9999, "client snapshot is detached from canonical transform")
	snapshot.tick = 0
	check(not reconcile.apply(mirror, snapshot), "old correction rejected")
	var disconnected := AuthorityGateway.new()
	check(not disconnected.request("action", {}).accepted and disconnected.snapshot().is_empty(), "disconnected gateway never grants local authority")
	combat.service.damage(DamageRequest.new(enemy.entity_id, player.entity_id, 999))
	step(1)
	check(host.snapshot().lifecycle == "DEFEATED", "death remains defeated during wait")
	step(29)
	check(state.health == 0, "death wait cannot be bypassed")
	step(1)
	check(state.lifecycle == Combatant.Lifecycle.ALIVE and state.health == state.max_health() and state.resource == state.max_resource(), "authority restores coherent HP/energy/lifecycle")
	check(player.position == Vector3(0, 0, 8) and player.velocity == Vector3.ZERO, "respawn chooses trusted safe point")
	check(executor.phase == ActionExecutor.Phase.IDLE and not host.defense.state(player.entity_id).guard and host.movement.movement == Vector2.ZERO, "respawn clears transient gates/input")
	check(host.respawns == 1, "death produces one respawn")
	host.dispose()
	executor.position_of = Callable()
	enemy_actions.position_of = Callable()
	direct.position_of = Callable()
	registry.shutdown()
	print("Authority tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
