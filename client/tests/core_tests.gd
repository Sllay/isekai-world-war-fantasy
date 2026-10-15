extends SceneTree

var checks: int = 0
var failures: int = 0

class Fact extends CoreEvent:
	var value: int = 0

class TestModule extends CoreModule:
	var value: int = 7
	var fail_start: bool = false
	var disposed: bool = false
	var stopped: bool = false
	func _init(module_id: String = "test.state") -> void:
		id = module_id
		persistent = true
		state_version = 2
	func start() -> Error:
		return FAILED if fail_start else OK
	func stop() -> void:
		stopped = true
	func dispose() -> void:
		disposed = true
	func capture_state() -> Dictionary:
		return {"value": value}
	func validate_state(snapshot: Dictionary) -> Error:
		return OK if snapshot.get("value") is int or snapshot.get("value") is float else ERR_INVALID_DATA
	func restore_state(snapshot: Dictionary) -> void:
		value = int(snapshot.value)
	func migrate_state(from: int, snapshot: Dictionary) -> Variant:
		return {"value": snapshot.get("old_value", 0)} if from == 1 else null

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_modules()
	test_events()
	test_data_components_flags()
	test_time()
	test_save()
	check(checks >= 50, "all test groups completed")
	print("Core tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_modules() -> void:
	var missing := CoreModuleRegistry.new()
	var module := TestModule.new()
	module.requires.assign(["test.absent"])
	check(missing.add(module) == OK, "module added")
	check(missing.add(module) != OK, "duplicate module rejected")
	check(missing.boot() != OK, "missing dependency rejected")
	var cycle := CoreModuleRegistry.new()
	var a := TestModule.new("test.a")
	var b := TestModule.new("test.b")
	a.requires.assign([b.id])
	b.requires.assign([a.id])
	cycle.add(a)
	cycle.add(b)
	check(cycle.boot() != OK, "dependency cycle rejected")
	var good := CoreModuleRegistry.new()
	a = TestModule.new("test.a")
	b = TestModule.new("test.b")
	b.requires.assign([a.id])
	a.optional.assign(["test.absent"])
	good.add(b)
	good.add(a)
	check(good.boot() == OK and good.order[0] == a, "ordered startup with absent optional dependency")
	good.shutdown()
	check(a.disposed and b.stopped, "reverse shutdown lifecycle")
	var failed := CoreModuleRegistry.new()
	a = TestModule.new()
	a.fail_start = true
	failed.add(a)
	check(failed.boot() != OK and a.disposed and a.stopped, "failed startup cleanup")
	var disabled := CoreModuleRegistry.new()
	a = TestModule.new("test.a")
	a.feature_flag = "test.feature"
	b = TestModule.new("test.b")
	b.optional.assign([a.id])
	disabled.add(a)
	disabled.add(b)
	check(disabled.boot() == OK and disabled.order.size() == 1, "disabled optional module omitted")
	disabled.shutdown()
	var layered := CoreModuleRegistry.new()
	a = TestModule.new("core.invalid")
	a.requires.assign(["foundation.example"])
	layered.add(a)
	check(layered.boot() != OK, "Core upward dependency rejected")
	var undeclared := CoreModuleRegistry.new()
	a = TestModule.new()
	a.provides.assign(["test.missing"])
	undeclared.add(a)
	check(undeclared.boot() != OK and a.disposed, "unprovided contract fails visibly")
	var services := CoreServices.new()
	a = TestModule.new("test.owner")
	a.provides.assign(["test.service"])
	services.enter(a)
	check(services.provide("test.service", RefCounted.new()) == OK, "declared service registered")
	check(services.provide("test.service", RefCounted.new()) != OK, "duplicate service rejected")
	b = TestModule.new("test.consumer")
	services.enter(b)
	check(services.resolve("test.service") == null, "undeclared service dependency blocked")
	b.requires.assign([a.id])
	services.enter(b)
	check(services.resolve("test.service") != null, "declared dependency resolves service")

func test_events() -> void:
	var bus := CoreEventBus.new()
	check(bus.define(Fact) == OK, "typed event defined")
	check(bus.define(CoreClock) != OK, "non-event type rejected")
	var observed: Array[int] = []
	var tokens: Array[int] = [0]
	bus.subscribe(Fact, func(event: Fact) -> void:
		observed.append(event.value)
		bus.unsubscribe(tokens[0])
		bus.subscribe(Fact, func(_event: Fact) -> void: observed.append(3)))
	tokens[0] = bus.subscribe(Fact, func(_event: Fact) -> void: observed.append(2))
	var fact := Fact.new()
	fact.source_module = "test.events"
	fact.value = 1
	check(bus.publish(fact) == OK and observed == [1], "safe unsubscribe and subscribe during dispatch")
	bus.publish(fact)
	check(observed == [1, 1, 3], "new subscription begins next publication")
	var recursive := CoreEventBus.new()
	recursive.max_dispatch_depth = 2
	recursive.define(Fact)
	var errors: Array[int] = []
	recursive.subscribe(Fact, func(event: Fact) -> void: errors.append(recursive.publish(event)))
	recursive.publish(fact)
	check(ERR_BUSY in errors, "recursive event storm bounded")
	bus.clear()
	recursive.clear()

func test_data_components_flags() -> void:
	var data := CoreDataRegistry.new()
	check(data.define_family("test.definition", func(d: Dictionary) -> Error: return OK if d.has("value") else ERR_INVALID_DATA) == OK, "data schema registered")
	check(data.register("test.one", "test.definition", {"value": 1}) == OK, "namespaced data registered")
	check(data.register("test.one", "test.definition", {"value": 2}) != OK, "duplicate data rejected")
	check(data.register("test.two", "test.definition", {}) != OK, "invalid data rejected")
	var copy := data.lookup("test.one")
	copy.value = 99
	check(data.lookup("test.one").value == 1, "data reads isolated")
	var entities := CoreEntityIds.new()
	check(not CoreIds.valid("invalid") and not CoreIds.valid("test.Bad"), "invalid namespaces rejected")
	var id := entities.create()
	check(entities.validate({"ids": [id, id]}) != OK, "duplicate saved identities rejected")
	var components := EntityComponents.new(id)
	var capability := RefCounted.new()
	check(components.attach("test.capability", capability) == OK, "capability attached")
	check(components.attach("test.capability", capability) != OK, "duplicate capability rejected")
	check(components.capability("test.capability") == capability, "capability resolved")
	components.detach("test.capability")
	check(components.capability("test.capability") == null, "capability detached")
	var flags := CoreFeatureFlags.new()
	check(not flags.enabled("test.unknown"), "unknown flags disabled")
	check(flags.define("test.flag") == OK and flags.set_enabled("test.flag", true) == OK and flags.enabled("test.flag"), "feature flag toggled")
	var diagnostics := CoreDiagnostics.new()
	diagnostics.capacity = 1
	diagnostics.record("info", "test.logs", "first")
	diagnostics.record("info", "test.logs", "second")
	check(diagnostics.records.size() == 1 and diagnostics.records[0].code == "second", "bounded structured diagnostics")

func test_time() -> void:
	var clock := CoreClock.new()
	clock.step_seconds = 1.0
	clock.max_steps_per_frame = 2
	check(clock.advance(5.0) == 2 and clock.tick == 2, "clock frame budget")
	check(clock.advance(0.0) == 2 and clock.tick == 4, "clock retains backlog")
	clock.paused = true
	check(clock.advance(10.0) == 0 and clock.tick == 4, "clock pause")
	clock.paused = false
	clock.step_seconds = 0.0
	check(clock.advance(1.0) == 0, "invalid clock configuration rejected")
	var backlog := CoreClock.new()
	var backlog_state := backlog.capture()
	backlog_state.remainder = 1e100
	backlog.restore(backlog_state)
	check(backlog.advance(0.01) == backlog.max_steps_per_frame and backlog.tick == 4, "large restored backlog clamps before integer conversion")
	var scheduler := CoreTickScheduler.new()
	scheduler.max_callbacks_per_frame = 2
	var seen: Array[int] = []
	scheduler.schedule(2, func(deadline: int) -> void: seen.append(deadline), 3)
	scheduler.schedule(1, func(deadline: int) -> void: seen.append(deadline))
	var cancelled := scheduler.schedule(0, func(_deadline: int) -> void: seen.append(99))
	scheduler.cancel(cancelled)
	check(scheduler.run_due(8) == 1 and seen == [1], "cancelled work bounded and deadline ordered")
	check(scheduler.run_due(8) == 2 and seen == [1, 2, 5], "recurring work retains deterministic deadlines")
	scheduler.run_due(8)
	check(seen == [1, 2, 5, 8], "staggered recurring catch-up")

func test_save() -> void:
	var registry := CoreModuleRegistry.new()
	var runtime := CoreRuntimeServicesModule.new()
	var module := TestModule.new()
	registry.add(runtime)
	registry.add(module)
	check(registry.boot() == OK, "production Core integration boot")
	var id := runtime.entities.create()
	runtime.clock.advance(0.1)
	var store := runtime.saves
	var snapshot := store.capture(registry, "test-world", 123)
	var path := "user://core-test-save.json"
	check(store.write_snapshot(path, snapshot) == OK, "snapshot written")
	var loaded := store.read_snapshot(path)
	registry.shutdown()
	registry = CoreModuleRegistry.new()
	runtime = CoreRuntimeServicesModule.new()
	module = TestModule.new()
	registry.add(runtime)
	registry.add(module)
	check(registry.boot() == OK, "fresh runtime boot")
	check(store.restore(registry, loaded) == OK and runtime.entities.contains(id) and runtime.clock.tick == 2, "stable identity and clock survive disk restart")
	loaded.sections["test.state"] = {"version": 1, "state": {"old_value": 42}}
	var prepared := store.prepare_restore(registry, loaded)
	check(not prepared.is_empty() and prepared.sections["test.state"].version == module.state_version and module.value != 42, "prepare migrates without mutating live module")
	check(loaded.sections["test.state"].version == 1 and loaded.sections["test.state"].state.has("old_value"), "prepare does not mutate source snapshot")
	check(store.restore(registry, loaded) == OK and module.value == 42, "module section migration")
	loaded.sections["core.runtime"].state.clock.tick = 88
	loaded.sections["test.state"].state = {"old_value": "bad"}
	check(store.restore(registry, loaded) != OK and runtime.clock.tick == 2 and module.value == 42, "invalid section causes no partial mutation")
	var unknown := snapshot.duplicate(true)
	unknown.sections["test.unknown"] = {"version": 1, "state": {}}
	check(store.restore(registry, unknown) != OK, "unknown module section rejected")
	check(store.write_snapshot(path, {"object": RefCounted.new()}) != OK, "runtime objects rejected from JSON persistence")
	check(store.write_snapshot(path, {"large_integer": 9223372036854775807}) != OK, "lossy JSON integers rejected")
	loaded.format_version = 999
	check(store.restore(registry, loaded) != OK, "future format rejected")
	var fraction := 0.12345678901234566
	check(store.write_snapshot(path, {"fraction": fraction}) == OK and store.read_snapshot(path).fraction == fraction, "disk JSON preserves fractional clock precision")
	registry.shutdown()
	DirAccess.remove_absolute(path)
