class_name A1ScenarioDriver
extends Node

# Integrated acceptance bot. Only semantic PlayerIntent enters gameplay; no HP,
# damage, resource, cooldown or transform writes. Usable in the live test world.
var runtime: Node
var phase := "approach"
var result: Dictionary = {}
var _start_tick := -1
var _health_before := 0
var _second_health := 0
var saw_stagger := false
var saw_dead := false
var saw_respawn := false
var _initial_respawns := 0

func _ready() -> void:
	name = "A1Scenario"
	_start_tick = runtime.core.clock.tick
	_initial_respawns = runtime.authority_host.respawns

func _physics_process(_delta: float) -> void:
	if not result.is_empty():
		return
	var host: LocalAuthorityHost = runtime.authority_host
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	var target: EnemyActor = runtime.enemies.actor if phase not in ["second", "die", "respawn", "return_combat"] else runtime.enemies.companions[0]
	var toward: Vector3 = target.position - runtime.player.state.position
	toward.y = 0
	avatar.intent.target_entity_id = target.entity_id
	if toward.length_squared() > 0.001:
		avatar.intent.aim_direction = toward.normalized()
	avatar.intent.movement = Vector2.ZERO
	avatar.intent.guard = phase == "guard"
	if host.combat.clock.tick - _start_tick > 2400:
		result = {"passed": false, "phase": phase, "reason": "SCENARIO_TIMEOUT"}
		return
	match phase:
		"approach", "second", "return_combat":
			if toward.length() > 2.0:
				var local := toward.normalized().rotated(Vector3.UP, -avatar.orbit.yaw)
				avatar.intent.movement = Vector2(local.x, local.z)
			else:
				if phase == "approach":
					phase = "guard"
				elif phase == "second":
					phase = "die"
				else:
					avatar.intent.primary_action = true
					if target.combatant.health < _second_health:
						finish()
		"guard":
			if runtime.combat_feedback.defense_outcomes.get("GUARDED", 0) > 0:
				_health_before = runtime.player_combat.state.health
				phase = "receive"
		"receive":
			if runtime.player_combat.state.health < _health_before:
				phase = "strong"
		"strong":
			avatar.intent.strong_action = true
			if host.defense.staggered(target.entity_id):
				saw_stagger = true
				phase = "basics"
		"basics":
			avatar.intent.primary_action = true
			if target.combatant.lifecycle == Combatant.Lifecycle.DEFEATED:
				phase = "second"
				avatar.intent.primary_action = false
		"die":
			if runtime.player_combat.state.lifecycle == Combatant.Lifecycle.DEFEATED:
				saw_dead = true
				phase = "respawn"
		"respawn":
			if host.respawns > _initial_respawns:
				saw_respawn = runtime.player_combat.state.health == runtime.player_combat.state.max_health() and host.movement.movement == Vector2.ZERO
				_second_health = runtime.enemies.companions[0].combatant.health
				phase = "return_combat"

func finish() -> void:
	var actor: Combatant = runtime.player_combat.state
	var state: Dictionary = runtime.authority_gateway.snapshot()
	result = {"passed": saw_stagger and saw_dead and saw_respawn and state.lifecycle == "ALIVE", "phase": "finished", "guarded": runtime.combat_feedback.defense_outcomes.get("GUARDED", 0), "stagger": saw_stagger, "death": saw_dead, "respawn": saw_respawn, "respawns": state.respawns, "reentered_combat": true, "confirmed_hits": runtime.combat_feedback.confirmed_hits, "health": actor.health, "energy": actor.resource, "ticks": runtime.core.clock.tick - _start_tick}
	phase = "finished"

func _mcp_state() -> Dictionary:
	return {"phase": phase, "result": result, "elapsed_ticks": runtime.core.clock.tick - _start_tick}
