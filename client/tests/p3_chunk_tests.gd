extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func run() -> void:
	var blueprint := WorldBlueprint.create("world.primary", 77231)
	var ledger := ChunkLedger.new()
	check(ledger.configure(blueprint) == OK, "ledger binds existing world blueprint")
	check(ledger.request(Vector2i(2, 0), 0).code == "STORAGE_UNAVAILABLE" and ledger.generator.generation_invocation_count == 0, "missing storage does not publish or generate half-ready chunk")
	var reentrant: Array = []
	var disk: Dictionary = {}
	ledger.commit = func(candidate: Dictionary) -> Error:
		reentrant.append(ledger.request(Vector2i(2, 0), 0))
		disk.assign(candidate)
		return OK
	var first := ledger.request(Vector2i(2, 0), 0)
	check(first.ok and first.generated and first.record.lifecycle == "PERSISTED", "generation validates and commits before canonical publication")
	check(reentrant.size() == 1 and reentrant[0].code == "GENERATION_BUSY" and ledger.generator.generation_invocation_count == 1, "simultaneous/reentrant requests cannot double-generate")
	check(disk == ledger.capture() and ledger.generation_phases.is_empty(), "durable candidate is same complete canonical chunk")
	check(not ledger.request(Vector2i(2, 0), 0).generated and ledger.generator.generation_invocation_count == 1, "second load never invokes generator")
	var failed := ChunkLedger.new()
	failed.configure(blueprint, func(_candidate: Dictionary) -> Error: return ERR_CANT_CREATE)
	check(failed.request(Vector2i(2, 0), 0).code == "GENERATION_COMMIT_FAILED" and failed.capture().chunks.is_empty() and failed.generation_phases.is_empty(), "failed commit leaves no canonical/half-generated state")
	var original := ledger.capture()
	var removal: String = first.record.base.resources[0].node_id
	check(ledger.mark_modified(Vector2i(2, 0), 0, {"damage": 100}).code == "FORGED_CHUNK_MUTATION", "arbitrary client-style world result not a valid mutation")
	check(ledger.mark_modified(Vector2i(2, 0), 0, {"removed_resources": ["resource.missing"]}).code == "INVALID_GENERATED_REFERENCE", "mutation must reference real chunk content")
	check(ledger.capture() == original, "rejected world mutation does not change canonical bytes")
	check(ledger.mark_modified(Vector2i(2, 0), 0, {"removed_resources": [removal]}).ok, "trusted valid world consequence changes delta")
	check(ledger.mark_modified(Vector2i(2, 0), 0, {"removed_resources": [removal]}).code == "STALE_CHUNK_REVISION", "duplicate/stale world mutation rejects")
	check(ledger.record(Vector2i(2, 0)).lifecycle == "MODIFIED" and ledger.dirty_chunks.size() == 1, "mutable deltas separated from immutable generated base and tracked dirty")
	check(ledger.record(Vector2i(2, 0)).base_hash == first.record.base_hash, "world mutation never regenerates base geography")
	var captured := ledger.capture()
	var fresh := ChunkLedger.new()
	check(fresh.restore(JSON.parse_string(JSON.stringify(captured))) == OK, "fresh domain restores persisted blueprint/records without creation")
	check(fresh.generator.generation_invocation_count == 0 and fresh.request(Vector2i(2, 0), 100).record.delta.removed_resources == [removal] and fresh.generator.generation_invocation_count == 0, "reload preserves mutation and makes zero generator calls")
	check(fresh.record(Vector2i(2, 0)).base_hash == first.record.base_hash, "loaded canonical hash equals first generation")
	var corrupt := captured.duplicate(true)
	corrupt.chunks[WorldGenIds.chunk(WorldBlueprint.REGION_ID, Vector2i(2, 0))].base.terrain.heights_mm[0] += 1
	check(fresh.restore(corrupt) == ERR_INVALID_DATA and fresh.capture() == captured, "corrupt chunk restore fails visibly without state replacement or fallback generation")
	var incompatible := captured.duplicate(true)
	incompatible.blueprint.generator_version = 2
	check(not fresh.validate_state(incompatible), "generator version mismatch rejected")
	ledger.acknowledge_persisted()
	check(ledger.dirty_chunks.is_empty(), "successful application checkpoint clears dirty work")
	test_streaming(blueprint)
	# Release explicit callback cycle in this isolated test harness.
	ledger.commit = Callable()
	print("P3 chunk lifecycle tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_streaming(blueprint: Dictionary) -> void:
	var policy := StreamingRelevance.new()
	var initial := policy.plan(blueprint, Vector2i.ZERO, 0)
	check(initial.ok and initial.active.size() == 9 and initial.prefetch.size() == 16 and initial.materialize.size() == 1, "active radius/prefetch ring and main-thread budget explicit")
	check(initial.materialize[0] == Vector2i.ZERO, "current player chunk has first materialization priority")
	check(policy.materialized(Vector2i.ZERO) == OK and policy.materialized(Vector2i.ZERO) == ERR_ALREADY_EXISTS, "duplicate materialization rejects")
	var near := policy.plan(blueprint, Vector2i(1, 0), 1)
	check(near.unload.is_empty(), "border crossing preserves spatial hysteresis")
	var far := policy.plan(blueprint, Vector2i(4, 0), 2)
	check(far.unload.is_empty(), "far old chunk waits unload deadline")
	check(policy.plan(blueprint, Vector2i(4, 0), 14).unload == [WorldGenIds.chunk(WorldBlueprint.REGION_ID, Vector2i.ZERO)], "unload occurs after controlled hysteresis")
	policy.clear()
	var tick := 0
	var peak := 0
	for _pass_index in range(4):
		var route: Array = [Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0), Vector2i(3, 0), Vector2i(2, 0), Vector2i(1, 0), Vector2i.ZERO]
		for center: Vector2i in route:
			for _frame in range(16):
				var plan := policy.plan(blueprint, center, tick)
				for key: String in plan.unload: policy.dematerialized(key)
				for coord: Vector2i in plan.materialize: check(policy.materialized(coord) == OK, "planned streaming materialization valid")
				peak = maxi(peak, policy.resident_count())
				tick += 1
	check(peak <= policy.max_resident_chunks and policy.resident_count() <= 15, "repeated A-B-C-D-return keeps resident chunks bounded")
	policy.clear()
	check(policy.resident_count() == 0, "dematerialization releases all residency without canonical data ownership")
