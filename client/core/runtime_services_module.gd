class_name CoreRuntimeServicesModule
extends CoreModule

var events := CoreEventBus.new()
var entities := CoreEntityIds.new()
var data := CoreDataRegistry.new()
var clock := CoreClock.new()
var scheduler := CoreTickScheduler.new()
var flags := CoreFeatureFlags.new()
var diagnostics := CoreDiagnostics.new()
var saves := CoreSaveStore.new()

func _init() -> void:
	id = "core.runtime"
	provides.assign(["core.events", "core.entities", "core.data", "core.clock", "core.scheduler", "core.flags", "core.diagnostics", "core.save"])
	persistent = true

func register(services: CoreServices) -> Error:
	var instances: Array[RefCounted] = [events, entities, data, clock, scheduler, flags, diagnostics, saves]
	for index in provides.size():
		var error := services.provide(provides[index], instances[index])
		if error != OK:
			return error
	events.diagnostics = diagnostics
	saves.diagnostics = diagnostics
	return OK

func capture_state() -> Dictionary:
	return {"entities": entities.capture(), "clock": clock.capture()}

func validate_state(value: Dictionary) -> Error:
	if not value.get("entities") is Dictionary or not value.get("clock") is Dictionary:
		return ERR_INVALID_DATA
	if entities.validate(value.entities) != OK or clock.validate(value.clock) != OK:
		return ERR_INVALID_DATA
	return OK

func restore_state(value: Dictionary) -> void:
	# Runtime callbacks are rebuilt by their owning modules after loading.
	scheduler.clear()
	entities.restore(value.entities)
	clock.restore(value.clock)

func dispose() -> void:
	events.clear()
	scheduler.clear()
