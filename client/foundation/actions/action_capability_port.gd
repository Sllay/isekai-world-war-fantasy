class_name ActionCapabilityPort
extends RefCounted

# Authority-owned non-health domain effects share the ActionExecutor lifecycle.
# Pure preflight is repeated at commit. A commit must be synchronous/transactional.
func validate(_effect: ActionEffect, _owner: String, _target: String) -> String:
	return "CAPABILITY_UNAVAILABLE"

func commit(_effect: ActionEffect, owner: String, target: String, execution: String) -> CombatResult:
	var result := CombatResult.new()
	result.code = "CAPABILITY_UNAVAILABLE"
	result.source_entity = owner
	result.target_entity = target
	result.transaction_id = execution
	return result
