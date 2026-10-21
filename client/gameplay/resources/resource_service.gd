class_name ResourceService
extends RefCounted

var inventory: InventoryService
var catalog: ResourceCatalog
var world_seed := 77231
var _nodes: Dictionary[String, ResourceNodeState] = {}

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
func gather_check(actor_id: String, container_id: String, node_id: String, tick: int, position: Vector3, tool_definition: ItemDefinition) -> Dictionary:
	if inventory == null or catalog == null or not _nodes.has(node_id):
		return _failure("NODE_UNKNOWN")
	if actor_id.is_empty() or container_id.is_empty() or tick < 0 or tick > 9007199254740991 or not position.is_finite():
		return _failure("INVALID_GATHER")
	var container := inventory.snapshot(container_id)
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
	var trial := InventoryService.new(inventory.catalog)
	if trial.restore(inventory.capture()) != OK:
		return _failure("INVALID_INVENTORY")
	var planned := trial.transact(actor_id, _yield_operations(container_id, node_id, resolved.outputs))
	if not planned.ok:
		return _failure(planned.code)
	return {"ok": true, "code": "GATHER_READY", "node": _view(node_value), "work_ticks": profile_value.work_ticks}

func gather(actor_id: String, container_id: String, node_id: String, tick: int, position: Vector3, tool_definition: ItemDefinition) -> Dictionary:
	var checked := gather_check(actor_id, container_id, node_id, tick, position, tool_definition)
	if not checked.ok:
		return checked
	var staged := _staged(node_id, tick)
	var resolved := _resolve_yield(staged)
	if not resolved.ok:
		return resolved
	var transaction := inventory.transact(actor_id, _yield_operations(container_id, node_id, resolved.outputs))
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
	if value.size() != 1 or not value.get("nodes") is Dictionary or value.nodes.size() != _nodes.size():
		return false
	for id in _nodes:
		if not value.nodes.get(id) is Dictionary or not _nodes[id].valid(value.nodes[id]):
			return false
	return true

func restore(value: Dictionary) -> void:
	for id in _nodes:
		_nodes[id].restore(value.nodes[id])

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
