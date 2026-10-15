class_name PlayerModule
extends CoreModule

var state := PlayerState.new()
var capabilities := EntityComponents.new("")
var entities: CoreEntityIds

func _init() -> void:
	id = "foundation.player"
	requires.assign(["core.runtime"])
	provides.assign(["foundation.player", "foundation.player_capabilities"])
	persistent = true

func register(services: CoreServices) -> Error:
	var error := services.provide("foundation.player", state)
	if error != OK:
		return error
	return services.provide("foundation.player_capabilities", capabilities)

func initialize(services: CoreServices) -> Error:
	entities = services.resolve("core.entities") as CoreEntityIds
	if entities == null:
		return ERR_UNCONFIGURED
	state.entity_id = entities.create()
	_rebuild_capabilities()
	return OK

func _rebuild_capabilities() -> void:
	capabilities.entity_id = state.entity_id
	if capabilities.capability("foundation.movement") == null:
		capabilities.attach("foundation.movement", state)

func capture_state() -> Dictionary:
	return state.capture()

func validate_state(value: Dictionary) -> Error:
	return OK if PlayerState.valid(value) else ERR_INVALID_DATA

func restore_state(value: Dictionary) -> void:
	state.restore(value)
	_rebuild_capabilities()
