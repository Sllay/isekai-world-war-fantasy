class_name ItemsActionPort
extends ActionCapabilityPort

var preflight: Callable
var apply_effect: Callable

func validate(effect: ActionEffect, owner: String, _target: String) -> String:
	return str(preflight.call(effect.capability_id, owner)) if preflight.is_valid() else "CAPABILITY_UNAVAILABLE"

func commit(effect: ActionEffect, owner: String, target: String, execution: String) -> CombatResult:
	var result := CombatResult.new()
	result.source_entity = owner
	result.target_entity = target
	result.transaction_id = execution
	if not apply_effect.is_valid():
		result.code = "CAPABILITY_UNAVAILABLE"
		return result
	var value: Dictionary = apply_effect.call(effect.capability_id, owner)
	result.accepted = value.get("ok", false)
	result.code = value.code
	return result
