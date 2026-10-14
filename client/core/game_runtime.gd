class_name GameRuntime
extends Node

var registry := CoreModuleRegistry.new()
var core := CoreRuntimeServicesModule.new()

func _ready() -> void:
	core.flags = registry.flags
	core.diagnostics = registry.diagnostics
	var error := registry.add(core)
	if error == OK:
		error = registry.boot()
	if error != OK:
		push_error("Core bootstrap failed: %s" % error)
		get_tree().quit(1)
		return
	if "--core-smoke" in OS.get_cmdline_user_args():
		assert(registry.services.inspect().size() == core.provides.size())
		get_tree().quit(0)

func _process(delta: float) -> void:
	if registry.state == CoreModuleRegistry.State.RUNNING:
		core.clock.advance(delta)
		if not core.clock.paused:
			core.scheduler.run_due(core.clock.tick)

func _exit_tree() -> void:
	registry.shutdown()
