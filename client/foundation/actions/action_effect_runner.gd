class_name ActionEffectRunner
extends RefCounted

static func validate(combat: CombatService, definition: ActionDefinition, owner: String, target: String) -> String:
	var relation := combat.relationship(owner, target)
	if relation == CombatTargetPolicy.Relationship.INVALID:
		return "TARGET_UNAVAILABLE"
	for effect in definition.effects:
		if effect.kind in [ActionEffect.Kind.DODGE, ActionEffect.Kind.GUARD, ActionEffect.Kind.PARRY]:
			if owner != target or (combat.combatant(owner).defense.policy == null or not combat.combatant(owner).defense.policy.valid()):
				return "DEFENSE_UNAVAILABLE"
			continue
		if effect.kind == ActionEffect.Kind.INTERRUPT:
			if relation != CombatTargetPolicy.Relationship.ENEMY:
				return "RELATIONSHIP_REJECTED"
			continue
		var request := effect.request(owner, target, definition)
		var allowed := combat.target_policy.allows_damage(relation, request as DamageRequest) if effect.kind == ActionEffect.Kind.DAMAGE else combat.target_policy.allows_healing(relation, request as HealingRequest)
		if not allowed:
			return "RELATIONSHIP_REJECTED"
	return "OK"

static func execute(combat: CombatService, definition: ActionDefinition, owner: String, target: String, execution_id: String, runtime: ActionRuntime = null) -> Array[CombatResult]:
	var results: Array[CombatResult] = []
	for effect in definition.effects:
		if effect.kind in [ActionEffect.Kind.DAMAGE, ActionEffect.Kind.HEALING]:
			var request := effect.request(owner, target, definition)
			request.transaction_id = execution_id
			results.append(combat.damage(request as DamageRequest) if effect.kind == ActionEffect.Kind.DAMAGE else combat.heal(request as HealingRequest))
		elif effect.kind == ActionEffect.Kind.INTERRUPT:
			var result := runtime.interrupt(target) if runtime != null else CombatResult.new()
			if runtime == null:
				result.code = "EXECUTOR_UNAVAILABLE"
			result.transaction_id = execution_id
			result.action_id = definition.action_id
			result.source_entity = owner
			results.append(result)
		else:
			var result := CombatResult.new()
			result.transaction_id = execution_id
			result.action_id = definition.action_id
			result.source_entity = owner
			result.target_entity = owner
			result.accepted = combat.begin_defense(owner, ActionEffect.Kind.keys()[effect.kind], effect.window_ticks) == OK
			result.code = "DEFENSE_STARTED" if result.accepted else "DEFENSE_UNAVAILABLE"
			results.append(result)
	return results
