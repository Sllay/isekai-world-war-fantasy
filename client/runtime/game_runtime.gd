extends GameRuntime

const WORLD_CONTENT = preload("res://world/primary_world.tres")
const WORLD_SCENE = preload("res://world/world.tscn")
var player := PlayerModule.new()
var world := WorldModule.new(WORLD_CONTENT)
var regions := RegionModule.new()
var world_scene: WorldScene

func _ready() -> void:
	var core_only := "--core-smoke" in OS.get_cmdline_user_args()
	if not core_only:
		for module in [player, world, regions]:
			var error := registry.add(module)
			if error != OK:
				push_error("Production module registration failed: %s" % error)
				get_tree().quit(1)
				return
	super._ready()
	if registry.state != CoreModuleRegistry.State.RUNNING or core_only:
		return
	world_scene = WORLD_SCENE.instantiate() as WorldScene
	world_scene.directory = regions.directory
	world_scene.player = player.state
	add_child(world_scene)
	var error := world_scene.open_current()
	if error != OK:
		push_error("Production region load failed: %s" % error)
		get_tree().quit(1)

func _exit_tree() -> void:
	if is_instance_valid(world_scene):
		world_scene.close_region()
	super._exit_tree()
