extends GameRuntime

var player := PlayerModule.new()

func _ready() -> void:
	if "--core-smoke" not in OS.get_cmdline_user_args():
		registry.add(player)
	super._ready()
	if registry.state == CoreModuleRegistry.State.RUNNING and "--core-smoke" not in OS.get_cmdline_user_args():
		var host := RuntimePlayerHost.new()
		host.name = "PlayerHost"
		host.state = player.state
		add_child(host)
