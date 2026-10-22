extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)

func record(index: int, subject: String, tick: int = 0, anchor := false) -> Dictionary:
	return {"id": "memory.event.e%d" % index, "kind": "perception.threat" if anchor else "perception.notice", "subject_id": subject, "position": [2, 0, 2], "created_tick": tick, "importance": 90 if anchor else 40, "confidence": 90, "expires_tick": -1 if anchor else tick + 100, "source": "knowledge.source.hearing", "anchor": anchor}

func run() -> void:
	var catalog := LivingCatalog.defaults()
	var source := "a".repeat(32)
	var observer := "b".repeat(32)
	var far_id := "c".repeat(32)
	var ids := {source: true, observer: true, far_id: true}
	var known := func(subject_id: String) -> bool: return ids.has(subject_id)
	var memory := LivingMemory.new()
	check(memory.remember(record(1, source), 0, known) == "REMEMBERED", "bounded structured hearing record accepted")
	var before := memory.capture()
	check(memory.remember(record(1, source), 0, known) == "DUPLICATE_MEMORY" and memory.capture() == before, "duplicate perception fact does not duplicate memory")
	check(memory.remember(record(2, "d".repeat(32)), 0, known) == "INVALID_MEMORY" and memory.capture() == before, "memory cannot reference nonexistent entity")
	var invalid := record(2, source)
	invalid.created_tick = 5
	check(memory.remember(invalid, 0, known) == "INVALID_MEMORY", "future perception does not become knowledge")
	invalid = record(2, source)
	invalid.position[0] = NAN
	check(memory.remember(invalid, 0, known) == "INVALID_MEMORY", "nonfinite remembered location rejects")
	for index in range(2, 14): memory.remember(record(index, source, index), index, known)
	check(memory.capture().records.size() == LivingMemory.ORDINARY_CAP, "ordinary memories capped with deterministic replacement")
	check(not memory.capture().records.any(func(value: Dictionary) -> bool: return value.id == "memory.event.e1"), "old equally important ordinary event replaced first")
	for index in range(14, 18): memory.remember(record(index, source, index, true), index, known)
	check(memory.capture().records.size() == LivingMemory.ORDINARY_CAP + LivingMemory.ANCHOR_CAP, "important anchors have separate bounded reserve")
	memory.prune(1000)
	check(memory.capture().records.size() == LivingMemory.ANCHOR_CAP, "ordinary memories decay while durable causal anchors remain")
	var persisted := memory.capture()
	var resumed := LivingMemory.new()
	check(resumed.restore(JSON.parse_string(JSON.stringify(persisted)), known) == OK and resumed.capture() == persisted, "selected durable memory survives JSON save/resume")
	var corrupted := persisted.duplicate(true)
	corrupted.records[0].subject_id = "d".repeat(32)
	check(not LivingMemory.valid(corrupted, known), "persisted unknown subject fails cross-reference check")
	corrupted = persisted.duplicate(true)
	corrupted.records.append(corrupted.records[0].duplicate(true))
	check(not LivingMemory.valid(corrupted, known), "duplicate memory identity rejects")
	var npc := LivingActorState.new()
	npc.configure(observer, "npc", catalog)
	npc.chunk_id = "region.home_valley:1:0"
	npc.position = Vector3(3, 0, 0)
	npc.home = Vector3(8, 0, 0)
	npc.work = Vector3(1, 0, 0)
	npc.fidelity = LivingActorState.Fidelity.L0
	var far := LivingActorState.new()
	far.configure(far_id, "npc", catalog)
	far.chunk_id = npc.chunk_id
	far.position = Vector3(100, 0, 0)
	far.fidelity = LivingActorState.Fidelity.L0
	var sense := LivingPerception.new()
	sense.known_actor = known
	sense.actors[observer] = npc
	sense.actors[far_id] = far
	sense.spatial.update(source, Vector3.ZERO)
	sense.spatial.update(observer, npc.position)
	sense.spatial.update(far_id, far.position)
	var model := LivingDecisionModel.new()
	check(model.choose(npc, 0).goal == "work", "NPC begins from profession/context duty rather than static mannequin")
	check(sense.hear(source, "fact.combat.e1", Vector3.ZERO, 10, 1) == [observer], "nearby physical event reaches only bounded perceived observers")
	check(not npc.memory.strongest("perception.threat", 1).is_empty() and far.memory.capture().records.is_empty(), "existence alone grants no distant omniscient knowledge")
	check(model.choose(npc, 1).goal == "shelter", "perceived danger changes later NPC goal")
	var captured := npc.memory.capture()
	check(sense.hear(source, "fact.combat.e1", Vector3.ZERO, 10, 1).is_empty() and npc.memory.capture() == captured, "replayed hearing does not grow records")
	check(sense.hear("d".repeat(32), "fact.combat.e2", Vector3.ZERO, 10, 2).is_empty(), "forged unknown source cannot inject causal memory")
	npc.fidelity = LivingActorState.Fidelity.L2
	check(sense.hear(source, "fact.combat.e3", Vector3.ZERO, 10, 3).is_empty(), "aggregate actors do not run active local hearing")
	npc.fidelity = LivingActorState.Fidelity.L0
	npc.plan_dirty = true
	check(model.choose(npc, 100).goal == "guard", "durable remembered danger changes cautious behavior after immediate alarm expires")
	var actor_snapshot := npc.capture()
	var restored := LivingActorState.new()
	check(restored.restore(actor_snapshot, catalog, known) == OK, "actor memory participates in persistent logical schema")
	check(restored.memory.capture() == npc.memory.capture() and restored.plan.is_empty(), "durable knowledge persists, transient plan/LOS cache does not")
	var grid := ActorSpatialIndex.new()
	for index in 200:
		grid.update("%032x" % (index + 100), Vector3(index * 32, 0, 0))
	check(grid.size() == 200, "spatial index holds logical positions without nodes")
	var matches := grid.nearby(Vector3.ZERO, 8)
	check(matches.size() == 1 and grid.examined < 8, "local query scales with relevant cells rather than whole population")
	check(grid.nearby(Vector3.ZERO, INF).is_empty() and grid.nearby(Vector3.ZERO, 65).is_empty(), "unbounded/invalid perception queries reject")
	var id := "%032x" % 100
	grid.update(id, Vector3(500, 0, 500))
	check(grid.nearby(Vector3.ZERO, 8).is_empty(), "moving cell updates index without stale presence")
	grid.remove(id)
	check(grid.size() == 199 and grid.position_of(id) == null, "dematerialization may remove relevant index entry without actor destruction")
	var dense := ActorSpatialIndex.new()
	for index in 200: dense.update("%032x" % (index + 1000), Vector3.ZERO)
	check(dense.nearby(Vector3.ZERO, 8, 64).size() == 64 and dense.examined <= ActorSpatialIndex.MAX_QUERY_CANDIDATES, "dense population query/result budgets remain finite")
	print("P3 perception tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
