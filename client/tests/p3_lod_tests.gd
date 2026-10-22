extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)

func actor(index: int, catalog: LivingCatalog) -> LivingActorState:
	var value := LivingActorState.new()
	value.configure("%032x" % (index + 1), "bot" if index % 2 else "npc", catalog)
	value.chunk_id = "region.home_valley:1:0"
	value.position = Vector3(index, 0, 0)
	return value

func run() -> void:
	var catalog := LivingCatalog.defaults()
	var scheduler := LivingScheduler.new()
	var value := actor(0, catalog)
	value.allegiance = "faction.free"
	value.begin_activity("activity.proof.travel", "travel", Vector3(12, 0, 0), 0, 1000)
	value.progression.award("world.discovery", "world.source.landmark", 1, catalog.progression("progression.chapter1_foundation"))
	check(scheduler.register(value, 0) == OK, "logical actor scheduler registers without runtime Node")
	check(scheduler.register(value, 0) != OK and scheduler.actors.size() == 1, "duplicate actor registration cannot create another identity")
	var base := value.capture()
	check(scheduler.set_fidelity(value.actor_id, LivingActorState.Fidelity.L1, 0) == OK and value.fidelity == LivingActorState.Fidelity.L1, "L2 promotes to reduced individual")
	check(scheduler.set_fidelity(value.actor_id, LivingActorState.Fidelity.L0, 0) == OK and value.fidelity == LivingActorState.Fidelity.L0, "L1 promotes to active")
	var epoch := value.materialization_epoch
	check(scheduler.valid_intent_epoch(value.actor_id, epoch), "active command epoch is valid")
	check(value.actor_id == base.id and value.position == Vector3(base.movement.position[0], base.movement.position[1], base.movement.position[2]) and value.allegiance == base.allegiance and value.progression.capture() == base.progression and value.inventory_id == base.inventory_id, "promotion preserves identity/movement/faction/progression/inventory references")
	check(scheduler.set_fidelity(value.actor_id, LivingActorState.Fidelity.L2, 1) == OK and not scheduler.valid_intent_epoch(value.actor_id, epoch), "dematerialization invalidates old active commands")
	check(value.activity == base.activity, "demotion preserves pending logical activity")
	check(scheduler.set_fidelity(value.actor_id, LivingActorState.Fidelity.L3, 2) == OK, "latent fidelity is explicit")
	var initial_jobs := int(scheduler.metrics.jobs)
	scheduler.advance(100000000)
	check(value.activity.completed and value.position == Vector3(12, 0, 0), "long-time advance resolves due arrival analytically")
	check(int(scheduler.metrics.jobs) - initial_jobs == 1 and scheduler.pending_count() == 0, "latent catch-up does not replay historical frames or poll forever")
	check(not value.resolve_due(100000001), "completed deadline cannot apply twice")
	check(scheduler.set_fidelity(value.actor_id, LivingActorState.Fidelity.L0, 100000002) == OK and value.position == Vector3(12, 0, 0), "rematerialization uses coherent arrived state")
	var model := LivingDecisionModel.new()
	var before := value.capture()
	var context := {"target_perceived": true, "target_in_range": true, "target_id": "b".repeat(32)}
	value.kind = "bot"
	var intent := model.choose(value, 100000002, context)
	check(intent.kind == "action" and intent.slot == "primary" and not intent.has("damage"), "Bot selects semantic canonical action without cheat outcome")
	check(value.progression.capture() == before.progression and value.inventory_id == before.inventory_id, "Bot decision does not grant XP or mutate item custody")
	model.choose(value, 100000003, context)
	check(model.planner_calls == 1 and model.cached_hits == 1, "plan stays cached until invalidation/expiry")
	value.plan_dirty = true
	model.choose(value, 100000004, {})
	check(model.planner_calls == 2, "event invalidation triggers bounded replanning")
	var pool := LivingScheduler.new()
	for index in 128:
		var entry := actor(index, catalog)
		entry.fidelity = LivingActorState.Fidelity.L0 if index < 2 else LivingActorState.Fidelity.L1 if index < 6 else LivingActorState.Fidelity.L2
		entry.begin_activity("activity.benchmark.travel", "travel", Vector3(index, 0, 4), 0, 500)
		pool.register(entry, index % 20)
	var started := Time.get_ticks_usec()
	var max_jobs := 0
	for tick in 100:
		var previous := int(pool.metrics.jobs)
		pool.advance(tick)
		max_jobs = maxi(max_jobs, int(pool.metrics.jobs) - previous)
	var elapsed := Time.get_ticks_usec() - started
	check(pool.actors.size() == 128 and pool.fidelity_counts().L0 == 2 and pool.fidelity_counts().L1 == 4, "population logical count differs from bounded active set")
	check(max_jobs <= LivingScheduler.JOB_BUDGET, "AI job work obeys per-tick budget")
	check(pool.metrics.jobs < 128 * 100 and pool.pending_count() <= 128, "reduced population avoids logical_population times every_frame cost")
	for id: String in pool.actors: pool.set_fidelity(id, LivingActorState.Fidelity.L3, 100)
	var before_long := int(pool.metrics.jobs)
	for _batch in 16: pool.advance(1000000)
	check(int(pool.metrics.jobs) - before_long == 128 and pool.pending_count() == 0, "hundreds of latent activities settle once in bounded batches")
	check(pool.actors.values().all(func(entry: LivingActorState) -> bool: return entry.activity.completed), "every deadline consequence settles without identity loss")
	var queue := LivingPathQueue.new()
	var first := scheduler.actors[value.actor_id]
	check(queue.request(first.actor_id, first.materialization_epoch, Vector3.ZERO, Vector3.RIGHT, first.region_id) == "PATH_QUEUED", "active local path queued through world adapter")
	check(queue.request(first.actor_id, first.materialization_epoch, Vector3.ZERO, Vector3.RIGHT, first.region_id) == "PATH_PENDING", "duplicate actor path coalesces")
	var resolver := func(origin: Vector3, destination: Vector3, region: String) -> Array: return [origin, destination] if region == "region.home_valley" else []
	var paths := queue.advance(resolver, scheduler.valid_intent_epoch)
	check(paths.size() == 1 and paths[0].points.size() == 2 and queue.resolved == 1, "bounded navigation resolves trusted local route")
	queue.request(first.actor_id, first.materialization_epoch, Vector3.ZERO, Vector3.RIGHT, first.region_id)
	scheduler.set_fidelity(first.actor_id, LivingActorState.Fidelity.L2, 100000003)
	check(queue.advance(resolver, scheduler.valid_intent_epoch).is_empty() and queue.stale == 1, "stale path completion cannot drive dematerialized actor")
	for index in 40: queue.request("%032x" % (index + 1000), 0, Vector3.ZERO, Vector3.RIGHT, "region.home_valley")
	check(queue.pending_count() == LivingPathQueue.CAPACITY, "path backlog bounded independently of population")
	var any_epoch := func(_id: String, _epoch: int) -> bool: return true
	check(queue.advance(resolver, any_epoch).size() == LivingPathQueue.PER_TICK, "path requests stagger through per-tick budget")
	print("P3 living benchmark: ", JSON.stringify({"logical_actors":128,"l0":2,"l1":4,"ticks":100,"scheduled_jobs":before_long,"long_advance_jobs":int(pool.metrics.jobs) - before_long,"max_jobs_per_tick":max_jobs,"decision_work_us":elapsed,"queue_peak":pool.metrics.peak_backlog}))
	print("P3 LOD tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
