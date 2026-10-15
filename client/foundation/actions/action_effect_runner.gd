class_name ActionEffectRunner
extends RefCounted

static func validate(combat: CombatService, definition: ActionDefinition, owner: String, target: String) -> String:
	var relation := combat.relationship(owner, target)
	if relation == CombatTargetPolicy.Relationship.INVALID:
		return "TARGET_UNAVAILABLE"
	for effect in definition.effects:
		var request := effect.request(owner, target, definition)
		var allowed := combat.target_policy.allows_damage(relation, request as DamageRequest) if effect.kind == ActionEffect.Kind.DAMAGE else combat.target_policy.allows_healing(relation, request as HealingRequest)
		if not allowed:
			return "RELATIONSHIP_REJECTED"
	return "OK"

static func execute(combat: CombatService, definition: ActionDefinition, owner: String, target: String, execution_id: String) -> Array[CombatResult]:
	var results: Array[CombatResult] = []
	for effect in definition.effects:
		var request := effect.request(owner, target, definition)
		request.transaction_id = execution_id
		results.append(combat.damage(request as DamageRequest) if effect.kind == ActionEffect.Kind.DAMAGE else combat.heal(request as HealingRequest))
	return results
