class_name WorldModule
extends CoreModule

var definition: WorldDefinition
var state := WorldState.new()

func _init(content: WorldDefinition) -> void:
	definition = content
	id = "foundation.world"
	requires.assign(["core.runtime"])
	provides.assign(["foundation.world", "foundation.world_definition"])
	persistent = true

func register(services: CoreServices) -> Error:
	if definition == null or not definition.valid():
		return ERR_INVALID_DATA
	var error := services.provide("foundation.world", state)
	if error != OK:
		return error
	return services.provide("foundation.world_definition", definition)

func initialize(services: CoreServices) -> Error:
	state.clock = services.resolve("core.clock") as CoreClock
	if state.clock == null:
		return ERR_UNCONFIGURED
	state.world_id = definition.world_id
	state.world_seed = definition.world_seed
	state.current_region_id = definition.initial_region_id
	return OK

func capture_state() -> Dictionary:
	return state.capture()

func validate_state(value: Dictionary) -> Error:
	if value.get("world_id") != definition.world_id or value.get("schema_version") != 1:
		return ERR_INVALID_DATA
	var seed_value: Variant = value.get("world_seed")
	if not (seed_value is int or seed_value is float) or not is_finite(float(seed_value)) or absf(float(seed_value)) > 9007199254740991.0 or seed_value != int(seed_value):
		return ERR_INVALID_DATA
	var region_id: Variant = value.get("current_region_id")
	if not region_id is String or definition.region(region_id) == null:
		return ERR_INVALID_DATA
	return OK

func restore_state(value: Dictionary) -> void:
	state.world_seed = int(value.world_seed)
	state.current_region_id = value.current_region_id
