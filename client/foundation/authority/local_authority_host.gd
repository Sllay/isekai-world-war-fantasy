class_name LocalAuthorityHost
extends RefCounted

# Explicit development authority, composed by the application. Domain services
# remain reusable. Client ingress accepts bounded semantic values only.
var combat: CombatService
var actions: ActionExecutor
var player: PlayerState
var defense := CombatDefense.new()
var movement := PlayerIntent.new()
var move_port: Callable
var recovery_port: Callable
var physics_delta := 0.0
var safe_spawn: Callable
var checkpoint: Callable
var enemy_step: Callable
var actor_executors: Dictionary = {}
var loadout := {"primary": "combat.action.basic_strike", "strong": "combat.action.strong_strike", "heal": "combat.action.basic_heal"}
var _session := ""
var _queue: Array[Dictionary] = []
var _last_sequence := 0
var _ack := 0
var _processed_tick := -1
var _input_tick := -100
var _dead_until := -1
var respawns := 0
var last_result := "READY"

func configure(service: CombatService, executor: ActionExecutor, state: PlayerState, session: String) -> void:
	combat = service
	actions = executor
	player = state
	_session = session
	defense.bind(combat)
	actor_executors[player.entity_id] = actions
	actions.activation_gate = func() -> bool: return can_act(player.entity_id)
	actions.mobility_gate = func() -> bool: return not defense.staggered(player.entity_id)

func can_act(id: String) -> bool:
	return not defense.staggered(id) and not defense.dodging(id) and not defense.state(id).guard

func movement_allowed() -> bool:
	return combat.combatant(player.entity_id).lifecycle == Combatant.Lifecycle.ALIVE and not defense.staggered(player.entity_id) and actions.movement_allowed()

func _reject(code: String) -> Dictionary:
	return {"accepted": false, "code": code}

func submit(session: String, command: Dictionary) -> Dictionary:
	if session != _session or session.is_empty():
		return _reject("UNAUTHENTICATED")
	if command.size() != 5 or command.get("version") != 1 or not command.get("kind") is String or not command.get("payload") is Dictionary:
		return _reject("INVALID_ENVELOPE")
	if not CombatNumbers.integer(command.get("sequence"), 1, 9007199254740991) or not CombatNumbers.integer(command.get("tick"), 0, 9007199254740991):
		return _reject("INVALID_ENVELOPE")
	if command.sequence <= _last_sequence:
		return _reject("DUPLICATE_OR_REPLAY")
	if command.tick < combat.clock.tick - 20 or command.tick > combat.clock.tick + 2:
		return _reject("STALE_OR_FUTURE")
	var p: Dictionary = command.payload
	match command.kind:
		"move":
			if p.size() != 3 or not p.get("axis") is Vector2 or not p.axis.is_finite() or p.axis.length() > 1.001 or not p.get("facing") is Vector3 or not p.facing.is_finite() or absf(p.facing.y) > 0.001 or not is_equal_approx(p.facing.length(), 1.0) or not p.get("jump") is bool:
				return _reject("INVALID_MOVE")
		"action":
			if p.size() != 2 or p.get("slot") not in loadout or not p.get("target") is String or p.target.length() > 32:
				return _reject("INVALID_ACTION")
		"guard":
			if p.size() != 1 or not p.get("enabled") is bool:
				return _reject("INVALID_GUARD")
		"dodge", "cancel", "respawn":
			if not p.is_empty():
				return _reject("FORGED_STATE")
		_:
			return _reject("UNKNOWN_COMMAND")
	if _queue.size() >= 8:
		return _reject("QUEUE_FULL")
	_last_sequence = int(command.sequence)
	_queue.append(command.duplicate(true))
	return {"accepted": true, "code": "QUEUED", "sequence": _last_sequence}

func advance() -> void:
	var tick := combat.clock.tick
	if tick <= _processed_tick:
		return
	_processed_tick = tick
	var actor := combat.combatant(player.entity_id)
	if actor.lifecycle == Combatant.Lifecycle.DEFEATED:
		if _dead_until < 0:
			_dead_until = tick + 30
			defense.states.clear()
			movement.movement = Vector2.ZERO
			player.velocity = Vector3.ZERO
		_queue.clear()
		for executor: ActionExecutor in actor_executors.values():
			executor.advance()
		if enemy_step.is_valid():
			enemy_step.call()
		if tick >= _dead_until:
			_respawn()
		return
	var count := 0
	while not _queue.is_empty() and count < 4:
		var command: Dictionary = _queue.pop_front()
		_ack = int(command.sequence)
		_execute(command)
		count += 1
	if tick - _input_tick > 2:
		movement.movement = Vector2.ZERO
		defense.set_guard(player.entity_id, false)
	for id: String in actor_executors:
		var executor: ActionExecutor = actor_executors[id]
		if defense.staggered(id):
			executor.interrupt()
		else:
			executor.advance()
	actions.advance()
	if enemy_step.is_valid():
		enemy_step.call()
	if tick % 10 == 0 and not defense.state(player.entity_id).guard and not defense.dodging(player.entity_id) and actions.phase in [ActionExecutor.Phase.IDLE, ActionExecutor.Phase.CANCELLED]:
		combat.restore_resource(player.entity_id, 1)

func physics_step(delta: float) -> void:
	# Physics collision runs at the host's physics cadence; client never supplies dt.
	if not is_finite(delta) or delta <= 0 or delta > 0.1:
		return
	if not movement_allowed():
		movement.movement = Vector2.ZERO
	if move_port.is_valid():
		move_port.call(delta)
	if recovery_port.is_valid():
		recovery_port.call()

func _execute(command: Dictionary) -> void:
	var p: Dictionary = command.payload
	match command.kind:
		"move":
			movement.movement = p.axis
			movement.jump = p.jump
			if not defense.staggered(player.entity_id) and actions.turning_allowed():
				player.facing = p.facing
			_input_tick = combat.clock.tick
			last_result = "MOVED"
		"action":
			last_result = actions.activate(loadout[p.slot], ActionTarget.new(p.target))
		"guard":
			if p.enabled and actions.phase == ActionExecutor.Phase.CASTING:
				actions.cancel()
			last_result = defense.set_guard(player.entity_id, p.enabled and actions.phase != ActionExecutor.Phase.RECOVERY)
		"dodge":
			if actions.phase == ActionExecutor.Phase.CASTING:
				actions.cancel()
			last_result = defense.dodge(player.entity_id) if actions.phase != ActionExecutor.Phase.RECOVERY else "ACTION_ACTIVE"
		"cancel": last_result = actions.cancel()
		"respawn": last_result = "NOT_DEFEATED"

func _respawn() -> void:
	if not safe_spawn.is_valid():
		last_result = "SAFE_SPAWN_UNAVAILABLE"
		return
	var actor := combat.combatant(player.entity_id)
	var restored := actor.capture()
	restored.health = actor.max_health()
	restored.resource = actor.max_resource()
	restored.lifecycle = Combatant.Lifecycle.ALIVE
	combat.restore_owned(actor, player.entity_id, restored)
	actions.restore(actions.capture())
	defense.states.clear()
	movement.movement = Vector2.ZERO
	movement.jump = false
	player.velocity = Vector3.ZERO
	player.intent = Vector2.ZERO
	safe_spawn.call()
	_dead_until = -1
	respawns += 1
	last_result = "RESPAWNED"

func snapshot() -> Dictionary:
	var actor := combat.combatant(player.entity_id)
	return {"tick": combat.clock.tick, "ack": _ack, "player": player.capture(), "health": actor.health, "resource": actor.resource, "lifecycle": Combatant.Lifecycle.keys()[actor.lifecycle], "defense": defense.state(player.entity_id).duplicate(true), "actions": actions.development_state(), "respawn_in": maxi(0, _dead_until - combat.clock.tick) if _dead_until >= 0 else 0, "respawns": respawns, "result": last_result}

func save_game() -> Error:
	return checkpoint.call() if checkpoint.is_valid() else ERR_UNCONFIGURED

func dispose() -> void:
	defense.dispose()
	for executor: ActionExecutor in actor_executors.values():
		executor.activation_gate = Callable()
		executor.mobility_gate = Callable()
		executor.target_gate = Callable()
	actor_executors.clear()
	move_port = Callable()
	recovery_port = Callable()
	safe_spawn = Callable()
	checkpoint = Callable()
	enemy_step = Callable()
	defense.position_of = Callable()
	defense.facing_of = Callable()
	_queue.clear()
