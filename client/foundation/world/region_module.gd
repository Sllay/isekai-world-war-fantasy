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
	state_version = 2

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
	for record in directory.records.values():
		record.recovery = RegionRecovery.new()
		record.recovery.definition = record.definition
		record.recovery.player = player
		record.recovery.diagnostics = services.resolve("core.diagnostics") as CoreDiagnostics
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
		var record := directory.record(region_id)
		var saved: Dictionary = value.regions[region_id]
		record.last_entry_id = saved.last_entry_id
		record.recovery.last_safe = saved.last_safe.duplicate(true)
		record.recovery.recovery_count = 0
		for key in record.actors:
			record.actors[key].restore(saved.actors[key])

func dispose() -> void:
	if capabilities != null:
		capabilities.detach("foundation.location")
	directory.location.region_id = ""

func migrate_state(from_version: int, value: Dictionary) -> Variant:
	if from_version != 1 or not value.get("regions") is Dictionary:
		return null
	var result := value.duplicate(true)
	for id in result.regions:
		if result.regions[id].has("last_safe") or result.regions[id].has("actors"):
			return null
		result.regions[id]["last_safe"] = {}
		# No actor defaults here: application release migration owns introducing
		# new content and its Core identities, never malformed current saves.
	return result
