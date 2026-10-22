class_name LivingDecisionModel
extends RefCounted

var planner_calls := 0
var cached_hits := 0

# Pure intent producer over known context. The host still validates every action.
func choose(actor: LivingActorState, tick: int, context: Dictionary = {}) -> Dictionary:
	if actor == null: return {"kind": "idle"}
	if not actor.plan_dirty and not actor.plan.is_empty() and tick < int(actor.plan.get("expires_tick", 0)):
		cached_hits += 1
		return actor.plan.intent.duplicate(true)
	planner_calls += 1
	var threat := actor.memory.strongest("perception.threat", tick)
	var work := actor.memory.strongest("perception.resource", tick)
	var choice := {"kind": "idle"}
	var goal := "work"
	# Reactive safety outranks duty, with durable remembered danger after perception.
	if actor.kind == "npc" and (context.get("immediate_threat", false) or (not threat.is_empty() and tick - int(threat.created_tick) < 80)):
		goal = "shelter"
		choice = {"kind": "navigate", "point": actor.home, "goal": goal}
	elif actor.kind == "npc" and not work.is_empty() and tick - int(work.created_tick) < 80:
		goal = "inspect"
		choice = {"kind": "navigate", "point": Vector3(work.position[0], work.position[1], work.position[2]), "goal": goal}
	elif actor.kind == "bot" and context.get("target_perceived", false) and CombatNumbers.stable_entity(context.get("target_id")):
		goal = "combat"
		if context.get("target_in_range", false): choice = {"kind": "action", "slot": "primary", "target": context.target_id}
		elif context.get("target_position") is Vector3: choice = {"kind": "navigate", "point": context.target_position, "goal": goal}
	elif actor.kind == "bot" and context.get("known_resource") is String:
		goal = "gather"
		var point: Variant = context.get("resource_position")
		var interaction_range := float(context.get("resource_range", 2.75))
		if point is Vector3 and actor.position.distance_squared_to(point) > pow(interaction_range * 0.75, 2): choice = {"kind": "navigate", "point": point, "goal": goal}
		else: choice = {"kind": "item.harvest", "node": context.known_resource}
	else:
		# Bounded utility selection; no global GOAP or per-profession subclasses.
		var priorities := {"rest": int(actor.needs.rest), "work": int(actor.needs.duty), "guard": 75 if not threat.is_empty() else 0}
		goal = "work"
		for candidate: String in ["rest", "guard", "work"]:
			if int(priorities[candidate]) > int(priorities[goal]): goal = candidate
		choice = {"kind": "navigate", "point": actor.home if goal in ["rest", "guard"] else actor.work, "goal": goal}
	actor.plan = {"goal": goal, "intent": choice.duplicate(true), "expires_tick": tick + 20}
	actor.plan_dirty = false
	return choice
