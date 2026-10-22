class_name ResourceService
extends RefCounted

var inventory: InventoryService
var catalog: ResourceCatalog
var world_seed := 77231
var _nodes: Dictionary[String, ResourceNodeState] = {}

func definition(node_id: String) -> ResourceNodeDefinition:
	return _nodes[node_id].definition.duplicate(true) as ResourceNodeDefinition if _nodes.has(node_id) else null

func node_ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_nodes.keys())
	result.sort()
	return result

func node_count() -> int:
	return _nodes.size()

# Trusted world placement adapter. Existing reserves are never reset on residency.
func register_node(authored: ResourceNodeDefinition) -> Error:
	if authored == null or not authored.valid() or catalog.profile(authored.profile_id) == null: return ERR_INVALID_DATA
	if _nodes.has(authored.node_id):
		var previous := definition(authored.node_id)
		return OK if previous.profile_id == authored.profile_id and previous.region_id == authored.region_id and previous.position == authored.position else ERR_INVALID_DATA
	if _nodes.size() >= 256: return ERR_OUT_OF_MEMORY
	_nodes[authored.node_id] = ResourceNodeState.new(authored.duplicate(true) as ResourceNodeDefinition, catalog.profile(authored.profile_id))
	return OK

func configure(items: InventoryService, content: ResourceCatalog, trusted_seed: int = 77231) -> Error:
	if items == null or content == null or not content.valid(items.catalog):
		return ERR_INVALID_DATA
	inventory = items
	catalog = content.duplicate(true) as ResourceCatalog
	world_seed = trusted_seed
	_nodes.clear()
	for authored in catalog.nodes:
		_nodes[authored.node_id] = ResourceNodeState.new(authored, catalog.profile(authored.profile_id))
	return OK

# Commit-time domain validation. Caller supplies authority-owned actor/tool facts.
# Preview uses a detached node so merely checking cannot refill canonical state.
func gather_check(actor_id: String, container_id: String, node_id: String, tick: int, position: Vector3, tool_definition: ItemDefinition, actor_inventory: InventoryService = null) -> Dictionary:
	if inventory == null or catalog == null or not _nodes.has(node_id):
		return _failure("NODE_UNKNOWN")
	if actor_id.is_empty() or container_id.is_empty() or tick < 0 or tick > 9007199254740991 or not position.is_finite():
		return _failure("INVALID_GATHER")
	var ledger := actor_inventory if actor_inventory != null else inventory
	var container := ledger.snapshot(container_id)
	if container.is_empty() or container.get("owner_id") != actor_id:
		return _failure("NOT_OWNER")
	var node_value := _staged(node_id, tick)
	var profile_value := node_value.profile
	if position.distance_squared_to(node_value.definition.position) > profile_value.interaction_range * profile_value.interaction_range:
		return _failure("OUT_OF_RANGE")
	if node_value.remaining == 0:
		return _failure("DEPLETED")
	if tool_definition == null or not tool_definition.tool_tags.has(profile_value.tool_tag):
		return _failure("WRONG_TOOL")
	if tool_definition.tool_power < profile_value.minimum_tool_power:
		return _failure("TOOL_TOO_WEAK")
	var resolved := _resolve_yield(node_value)
	if not resolved.ok:
		return resolved
	# Capacity is preflighted against a detached canonical ledger. No output,
	# reserve, revision, identity allocation or RNG counter escapes this trial.
	var trial := InventoryService.new(ledger.catalog)
	if trial.restore(ledger.capture()) != OK:
		return _failure("INVALID_INVENTORY")
	var planned := trial.transact(actor_id, _yield_operations(container_id, node_id, resolved.outputs))
	if not planned.ok:
		return _failure(planned.code)
	return {"ok": true, "code": "GATHER_READY", "node": _view(node_value), "work_ticks": profile_value.work_ticks}

func gather(actor_id: String, container_id: String, node_id: String, tick: int, position: Vector3, tool_definition: ItemDefinition, actor_inventory: InventoryService = null) -> Dictionary:
	var checked := gather_check(actor_id, container_id, node_id, tick, position, tool_definition, actor_inventory)
	if not checked.ok:
		return checked
	var staged := _staged(node_id, tick)
	var resolved := _resolve_yield(staged)
	if not resolved.ok:
		return resolved
	var ledger := actor_inventory if actor_inventory != null else inventory
	var transaction := ledger.transact(actor_id, _yield_operations(container_id, node_id, resolved.outputs))
	if not transaction.ok:
		return _failure(transaction.code)
	staged.remaining -= 1
	staged.extractions += 1
	if staged.remaining == 0 and staged.profile.regeneration_ticks > 0:
		staged.regeneration_tick = tick + staged.profile.regeneration_ticks
	_nodes[node_id] = staged
	return {"ok": true, "code": "GATHERED", "outputs": resolved.outputs, "node": _view(staged), "revision": transaction.get("revision", 0)}

# Deadline evaluation is detached; only successful gathering commits the cycle.
func snapshot(node_id: String, tick: int) -> Dictionary:
	if not _nodes.has(node_id) or tick < 0 or tick > 9007199254740991:
		return {}
	return _view(_staged(node_id, tick))

func capture() -> Dictionary:
	var values: Dictionary = {}
	for id in _nodes:
		values[id] = _nodes[id].capture()
	return {"nodes": values}

func validate_state(value: Dictionary) -> bool:
	if value.size() != 1 or not value.get("nodes") is Dictionary or value.nodes.size() < catalog.nodes.size() or value.nodes.size() > 256:
		return false
	for authored in catalog.nodes:
		if not value.nodes.has(authored.node_id): return false
	for id: Variant in value.nodes:
		if not id is String or not value.nodes[id] is Dictionary or value.nodes[id].get("node_id") != id: return false
		var authored := catalog.node(id)
		if authored == null:
			if not id.begins_with("resource.generated.") or not _generated_definition(value.nodes[id]) is ResourceNodeDefinition: return false
			authored = _generated_definition(value.nodes[id])
		var state := ResourceNodeState.new(authored, catalog.profile(authored.profile_id))
		if not state.valid(value.nodes[id]):
			return false
	return true

func restore(value: Dictionary) -> void:
	_nodes.clear()
	for id: String in value.nodes:
		var authored := catalog.node(id)
		if authored == null: authored = _generated_definition(value.nodes[id])
		_nodes[id] = ResourceNodeState.new(authored, catalog.profile(authored.profile_id))
		_nodes[id].restore(value.nodes[id])

# Generic schema only. SaveIntegrity additionally requires exact ownership and
# placement in the same validated persisted WorldBlueprint/chunk base.
func _generated_definition(value: Dictionary) -> ResourceNodeDefinition:
	if not value.get("node_id") is String or not value.node_id.begins_with("resource.generated.") or not CoreIds.valid(value.node_id) or not value.get("profile_id") is String or catalog.profile(value.profile_id) == null or not value.get("region_id") is String or not CoreIds.valid(value.region_id) or not value.get("position") is Array or value.position.size() != 3: return null
	for number: Variant in value.position:
		if not (number is int or number is float) or not is_finite(number) or absf(number) > 10000: return null
	var authored := ResourceNodeDefinition.new()
	authored.node_id = value.node_id
	authored.profile_id = value.profile_id
	authored.region_id = value.region_id
	authored.position = Vector3(value.position[0], value.position[1], value.position[2])
	return authored

func _staged(id: String, tick: int) -> ResourceNodeState:
	var previous: ResourceNodeState = _nodes[id]
	var result := ResourceNodeState.new(previous.definition, previous.profile)
	result.restore(previous.capture())
	result.advance(tick)
	return result

func _resolve_yield(node: ResourceNodeState) -> Dictionary:
	var seed_value := ("%d:%s:%d:%d" % [world_seed, node.definition.node_id, node.cycle, node.extractions]).hash()
	return LootResolver.resolve(catalog.loot(node.profile.loot_profile_id), seed_value, inventory.catalog)

func _yield_operations(container_id: String, node_id: String, outputs: Array) -> Array:
	var operations: Array = []
	for output: Dictionary in outputs:
		operations.append({"kind": "add", "container_id": container_id, "definition_id": output.definition_id, "quantity": output.quantity, "metadata": {"provenance": {"source": "gather", "source_id": node_id}}})
	return operations

func _view(value: ResourceNodeState) -> Dictionary:
	var result := value.capture()
	result["display_name"] = value.profile.display_name
	result["kind"] = value.profile.kind
	result["tool_tag"] = value.profile.tool_tag
	result["minimum_tool_power"] = value.profile.minimum_tool_power
	result["work_ticks"] = value.profile.work_ticks
	result["interaction_range"] = value.profile.interaction_range
	result["max_reserves"] = value.profile.reserves
	return result

func _failure(code: String) -> Dictionary:
	return {"ok": false, "code": code, "outputs": []}
