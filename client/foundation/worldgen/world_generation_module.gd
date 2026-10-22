class_name WorldGenerationModule
extends CoreModule

# Genesis is a capability of the existing World/Region, not a second world/save.
var ledger := ChunkLedger.new()
var world: WorldState
var definition: WorldDefinition
var directory: RegionDirectory
var durable_commit: Callable

func _init() -> void:
	id = "foundation.world_genesis"
	requires.assign(["foundation.world", "foundation.regions"])
	provides.assign(["foundation.world_genesis"])
	persistent = true

func register(services: CoreServices) -> Error:
	return services.provide(id, ledger)

func initialize(services: CoreServices) -> Error:
	world = services.resolve("foundation.world") as WorldState
	definition = services.resolve("foundation.world_definition") as WorldDefinition
	directory = services.resolve("foundation.regions") as RegionDirectory
	if world == null or directory == null: return ERR_UNCONFIGURED
	var authored: Array = []
	var content: ResourceCatalog = ResourceCatalog.defaults()
	for node in content.nodes:
		authored.append({"node_id": node.node_id, "profile_id": node.profile_id, "region_id": node.region_id, "position_mm": [roundi(node.position.x * 1000), roundi(node.position.y * 1000), roundi(node.position.z * 1000)]})
	var region := definition.region(world.current_region_id)
	return ledger.configure(WorldBlueprint.create(world.world_id, world.world_seed, int(region.chunk_size), 4, authored), _commit)

func _commit(candidate: Dictionary) -> Error:
	return durable_commit.call(candidate) if durable_commit.is_valid() else ERR_UNCONFIGURED

func capture_state() -> Dictionary:
	return ledger.capture()

func validate_state(value: Dictionary) -> Error:
	return OK if ledger.validate_state(value) else ERR_INVALID_DATA

func restore_state(value: Dictionary) -> void:
	ledger.restore(value)

func dispose() -> void:
	durable_commit = Callable()
	ledger.commit = Callable()

static func placements(value: Dictionary) -> Dictionary:
	var result := {}
	for node: Dictionary in value.blueprint.authored_resources: result[node.node_id] = node
	for record: Dictionary in value.chunks.values():
		for node: Dictionary in record.base.resources: result[node.node_id] = node
	return result

static func node_definition(node: Dictionary) -> ResourceNodeDefinition:
	var result := ResourceNodeDefinition.new()
	result.node_id = node.node_id
	result.profile_id = node.profile_id
	result.region_id = node.region_id
	result.position = Vector3(node.position_mm[0], node.position_mm[1], node.position_mm[2]) / 1000.0
	return result
