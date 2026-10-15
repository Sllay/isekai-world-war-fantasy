class_name RegionModule
extends CoreModule

var directory := RegionDirectory.new()
var player: PlayerState
var capabilities: EntityComponents

func _init() -> void:
	id = "foundation.regions"
	requires.assign(["core.runtime", "foundation.world", "foundation.player"])
	provides.assign(["foundation.regions", "foundation.player_location"])
	persistent = true

func register(services: CoreServices) -> Error:
	var error := services.provide("foundation.regions", directory)
	if error != OK:
		return error
	return services.provide("foundation.player_location", directory.location)

func initialize(services: CoreServices) -> Error:
	directory.world = services.resolve("foundation.world") as WorldState
	var definition := services.resolve("foundation.world_definition") as WorldDefinition
	player = services.resolve("foundation.player") as PlayerState
	capabilities = services.resolve("foundation.player_capabilities") as EntityComponents
	if directory.world == null or definition == null or player == null or capabilities == null:
		return ERR_UNCONFIGURED
	for region in definition.regions:
		if directory.add(region) != OK:
			return ERR_INVALID_DATA
	directory.location.world_id = directory.world.world_id
	return capabilities.attach("foundation.location", directory.location)

func capture_state() -> Dictionary:
	var regions: Dictionary = {}
	for region_id in directory.records:
		regions[region_id] = directory.records[region_id].capture()
	return {"regions": regions}

func validate_state(value: Dictionary) -> Error:
	if not value.get("regions") is Dictionary or value.regions.size() != directory.records.size():
		return ERR_INVALID_DATA
	for region_id in value.regions:
		if not region_id is String:
			return ERR_INVALID_DATA
		var record := directory.record(region_id)
		if record == null or not value.regions[region_id] is Dictionary or not record.valid(value.regions[region_id]):
			return ERR_INVALID_DATA
	return OK

func restore_state(value: Dictionary) -> void:
	for region_id in directory.records:
		directory.records[region_id].last_entry_id = value.regions[region_id].last_entry_id

func dispose() -> void:
	if capabilities != null:
		capabilities.detach("foundation.location")
	directory.location.region_id = ""
