extends GameRuntime

const WORLD_CONTENT = preload("res://world/primary_world.tres")
const WORLD_SCENE = preload("res://world/world.tscn")
var player := PlayerModule.new()
var world := WorldModule.new(WORLD_CONTENT)
var regions := RegionModule.new()
var combat := CombatModule.new()
var player_combat := PlayerCombatModule.new()
var world_scene: WorldScene
var save_slot := LocalSaveSlot.new()
var persistence: SaveCoordinator
var startup_error: Error = OK
var startup_message: Label
var save_controls: CanvasLayer

func _ready() -> void:
	var core_only := "--core-smoke" in OS.get_cmdline_user_args()
	if not core_only:
		for module in [player, world, regions, combat, player_combat]:
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
	persistence = SaveCoordinator.new(save_slot, registry, core.saves, world_scene, WORLD_CONTENT)
	startup_error = persistence.startup()
	if startup_error != OK:
		set_process(false)
		startup_message = Label.new()
		startup_message.text = "Saved game could not be loaded. Your save has been kept.\nRestore a valid local save before restarting."
		startup_message.position = Vector2(30, 100)
		add_child(startup_message)
		return
	_activate_session()

func _activate_session() -> void:
	startup_error = OK
	set_process(true)
	get_tree().auto_accept_quit = false
	if is_instance_valid(startup_message):
		startup_message.queue_free()
	if OS.is_debug_build() and not is_instance_valid(save_controls):
		save_controls = preload("res://runtime/persistence/save_controls.gd").new()
		save_controls.save_action = save_game
		add_child(save_controls)
		var combat_controls := preload("res://runtime/combat_debug_controls.gd").new()
		combat_controls.combat = combat.service
		combat_controls.state = player_combat.state
		add_child(combat_controls)

# Public application API for later UI/gameplay/lifecycle adapters.
func save_game() -> Error:
	return persistence.save_game() if persistence != null else ERR_UNCONFIGURED

func resume_game() -> Error:
	if persistence == null:
		return ERR_UNCONFIGURED
	var error := persistence.resume_game()
	if error == OK:
		_activate_session()
	return error

func request_exit() -> Error:
	if persistence != null and persistence.ready:
		var error := save_game()
		if error != OK:
			return error
	get_tree().quit()
	return OK

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		request_exit()
	elif what == NOTIFICATION_APPLICATION_PAUSED and persistence != null and persistence.ready:
		save_game()

func development_state() -> Dictionary:
	var result := world_scene.development_state() if is_instance_valid(world_scene) else {}
	if persistence != null:
		result.merge(persistence.development_state(), true)
	if player_combat.state != null:
		result["combat"] = player_combat.development_state()
	return result

func _exit_tree() -> void:
	if is_instance_valid(world_scene):
		world_scene.close_region()
	super._exit_tree()
