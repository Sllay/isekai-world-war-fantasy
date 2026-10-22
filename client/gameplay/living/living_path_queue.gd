class_name LivingPathQueue
extends RefCounted

const CAPACITY := 32
const PER_TICK := 2
var _requests: Array[Dictionary] = []
var requested := 0
var resolved := 0
var stale := 0

func request(actor_id: String, epoch: int, origin: Vector3, destination: Vector3, region: String) -> String:
	if not CombatNumbers.stable_entity(actor_id) or epoch < 0 or not origin.is_finite() or not destination.is_finite() or not CoreIds.valid(region): return "INVALID_PATH"
	for pending: Dictionary in _requests:
		if pending.actor_id == actor_id: return "PATH_PENDING"
	if _requests.size() >= CAPACITY: return "PATH_CAPACITY"
	_requests.append({"actor_id": actor_id, "epoch": epoch, "origin": origin, "destination": destination, "region_id": region})
	requested += 1
	return "PATH_QUEUED"

# Authority World supplies local routing; distant routes remain abstract activity.
func advance(resolve_local: Callable, valid_epoch: Callable, budget: int = PER_TICK) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not resolve_local.is_valid() or not valid_epoch.is_valid() or budget < 1 or budget > PER_TICK: return results
	for _index in mini(budget, _requests.size()):
		var pending: Dictionary = _requests.pop_front()
		if not bool(valid_epoch.call(pending.actor_id, pending.epoch)):
			stale += 1
			continue
		var path: Variant = resolve_local.call(pending.origin, pending.destination, pending.region_id)
		if not path is Array or path.is_empty() or path.size() > 32: continue
		var valid_path := true
		for point: Variant in path:
			if not point is Vector3 or not point.is_finite(): valid_path = false; break
		if not valid_path: continue
		resolved += 1
		results.append({"actor_id": pending.actor_id, "epoch": pending.epoch, "points": path.duplicate()})
	return results

func pending_count() -> int:
	return _requests.size()
