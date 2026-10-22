class_name LivingScheduler
extends RefCounted

const MAX_ACTORS := 256
const JOB_BUDGET := 8
var actors: Dictionary[String, LivingActorState] = {}
var _jobs: Array[Dictionary] = []
var decision_port: Callable
var metrics := {"jobs": 0, "decisions_l0": 0, "decisions_l1": 0, "aggregate_jobs": 0, "latent_jobs": 0, "completed_activities": 0, "promotions": 0, "demotions": 0, "peak_backlog": 0}

func register(actor: LivingActorState, tick: int) -> Error:
	if actor == null or not CombatNumbers.stable_entity(actor.actor_id) or actors.has(actor.actor_id) or tick < 0: return ERR_INVALID_DATA
	if actors.size() >= MAX_ACTORS: return ERR_OUT_OF_MEMORY
	actors[actor.actor_id] = actor
	_schedule(actor, tick)
	return OK

func unregister(id: String) -> void:
	_remove_job(id)
	actors.erase(id)

func set_fidelity(id: String, level: LivingActorState.Fidelity, tick: int) -> Error:
	if not actors.has(id) or level not in LivingActorState.Fidelity.values() or tick < 0: return ERR_INVALID_DATA
	var actor := actors[id]
	if actor.fidelity == level: return OK
	if actor.resolve_due(tick): metrics.completed_activities += 1
	if level < actor.fidelity: metrics.promotions += 1
	else: metrics.demotions += 1
	actor.fidelity = level
	actor.materialization_epoch += 1
	actor.revision += 1
	actor.plan_dirty = true
	_schedule(actor, tick)
	return OK

func wake(id: String, tick: int) -> void:
	if not actors.has(id): return
	actors[id].plan_dirty = true
	_schedule(actors[id], tick)

# Work scales with due jobs and this hard budget, never actors * elapsed frames.
func advance(tick: int, budget: int = JOB_BUDGET) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if tick < 0 or budget < 1 or budget > 32: return results
	var consumed := 0
	while not _jobs.is_empty() and _jobs[0].due <= tick and consumed < budget:
		var job: Dictionary = _jobs.pop_front()
		if not actors.has(job.id): continue
		var actor := actors[job.id]
		consumed += 1
		metrics.jobs += 1
		if actor.resolve_due(tick): metrics.completed_activities += 1
		actor.memory.prune(tick)
		match actor.fidelity:
			LivingActorState.Fidelity.L0: metrics.decisions_l0 += 1
			LivingActorState.Fidelity.L1: metrics.decisions_l1 += 1
			LivingActorState.Fidelity.L2: metrics.aggregate_jobs += 1
			LivingActorState.Fidelity.L3: metrics.latent_jobs += 1
		if decision_port.is_valid() and actor.fidelity <= LivingActorState.Fidelity.L1:
			var choice: Variant = decision_port.call(actor, tick)
			if choice is Dictionary: results.append({"actor_id": actor.actor_id, "epoch": actor.materialization_epoch, "intent": choice.duplicate(true)})
		var interval: int = [1, 5, 20, 0][actor.fidelity]
		if interval > 0: _schedule(actor, tick + interval)
		elif not actor.activity.is_empty() and not actor.activity.completed and actor.activity.finish_tick > tick: _schedule(actor, int(actor.activity.finish_tick))
	metrics.peak_backlog = maxi(int(metrics.peak_backlog), _jobs.size())
	return results

func valid_intent_epoch(id: String, epoch: int) -> bool:
	return actors.has(id) and actors[id].fidelity == LivingActorState.Fidelity.L0 and actors[id].materialization_epoch == epoch

func fidelity_counts() -> Dictionary:
	var result := {"L0": 0, "L1": 0, "L2": 0, "L3": 0}
	for actor: LivingActorState in actors.values(): result["L%d" % actor.fidelity] += 1
	return result

func pending_count() -> int:
	return _jobs.size()

func _schedule(actor: LivingActorState, tick: int) -> void:
	_remove_job(actor.actor_id)
	var job := {"id": actor.actor_id, "due": tick}
	var low := 0
	var high := _jobs.size()
	while low < high:
		@warning_ignore("integer_division")
		var middle := (low + high) / 2
		var previous: Dictionary = _jobs[middle]
		if previous.due < tick or (previous.due == tick and previous.id < actor.actor_id): low = middle + 1
		else: high = middle
	_jobs.insert(low, job)

func _remove_job(id: String) -> void:
	for index in range(_jobs.size()):
		if _jobs[index].id == id:
			_jobs.remove_at(index)
			return
