class_name DefenseResolver
extends RefCounted

# Pure decision: CombatService alone commits resource/health mutations.
# Priority is dodge > parry > block, exactly one resolution per transaction.
static func resolve(state: DefenseState, hit: DamageRequest, amount: int, tick: int, resource: int, resource_id: String, position_of: Callable, facing_of: Callable) -> Dictionary:
	var result := {"outcome": "HIT", "amount": amount, "cost": 0, "break_guard": false}
	if amount == 0 or state == null or state.policy == null or not state.policy.valid():
		return result
	var policy := state.policy
	if hit.dodgeable and tick < state.dodge_until:
		result.outcome = "DODGED"
		result.amount = 0
	elif hit.parryable and tick < state.parry_until and frontal(hit, policy.parry_arc_degrees, position_of, facing_of):
		result.outcome = "PARRIED"
		result.amount = 0
	elif hit.blockable and state.guard and frontal(hit, policy.block_arc_degrees, position_of, facing_of):
		if policy.block_resource_cost > 0 and (resource_id != policy.resource_id or resource < policy.block_resource_cost):
			result.break_guard = true
		else:
			result.outcome = "BLOCKED"
			@warning_ignore("integer_division")
			result.amount = amount * (CombatNumbers.SCALE - policy.block_mitigation_bps) / CombatNumbers.SCALE
			result.cost = policy.block_resource_cost
	return result

static func frontal(hit: DamageRequest, arc: float, positions: Callable, facings: Callable) -> bool:
	if arc >= 360:
		return true
	if not positions.is_valid() or not facings.is_valid():
		return false
	var a: Variant = positions.call(hit.source_entity)
	var b: Variant = positions.call(hit.target_entity)
	var f: Variant = facings.call(hit.target_entity)
	if not a is Vector3 or not b is Vector3 or not f is Vector3 or not a.is_finite() or not b.is_finite() or not f.is_finite():
		return false
	var direction := Vector3(a.x - b.x, 0, a.z - b.z)
	var facing := Vector3(f.x, 0, f.z)
	return facing.length_squared() > 0.001 and (direction.length_squared() < 0.000001 or facing.normalized().dot(direction.normalized()) >= cos(deg_to_rad(arc * 0.5)))
