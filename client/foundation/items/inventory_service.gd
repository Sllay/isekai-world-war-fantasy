class_name InventoryService
extends RefCounted

# Authority-owned bounded value state. Callers receive copies, never live entries.
const MAX_CONTAINERS := 64
const MAX_SLOTS := 256
const MAX_OPERATIONS := 64
const MAX_UNITS := 1000000000
const CONDITION_SCALE := 10000
var catalog: ItemCatalog
var _state := {"revision": 0, "next_entry": 1, "containers": {}}
var _transaction_active := false

func _init(definitions: ItemCatalog = null) -> void:
	catalog = ItemCatalog.defaults() if definitions == null else definitions

func register_container(id: String, owner_id: String, slots: int, max_mass_grams: int) -> Error:
	if _transaction_active:
		return ERR_BUSY
	if not _identity(id) or not _identity(owner_id) or (slots != -1 and (slots < 1 or slots > MAX_SLOTS)) or max_mass_grams < 0 or max_mass_grams > MAX_UNITS:
		return ERR_INVALID_PARAMETER
	if _state.containers.has(id):
		return ERR_ALREADY_EXISTS
	if _state.containers.size() >= MAX_CONTAINERS:
		return ERR_OUT_OF_MEMORY
	_state.containers[id] = {"id": id, "owner_id": owner_id, "capacity_mode": "DYNAMIC_SLOTS" if slots == -1 else "FIXED_SLOTS", "slots": slots, "max_mass_grams": max_mass_grams, "revision": 0, "entries": []}
	return OK

func snapshot(id: String) -> Dictionary:
	if not _state.containers.has(id):
		return {}
	var result: Dictionary = _state.containers[id].duplicate(true)
	result.entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	result["mass_grams"] = _mass(result)
	return result

func entries(container_id: String) -> Array:
	return snapshot(container_id).get("entries", [])

func entry(container_id: String, entry_id: String) -> Dictionary:
	for value: Dictionary in entries(container_id):
		if value.id == entry_id:
			return value
	return {}

func quantity(container_id: String, definition_id: String) -> int:
	var result := 0
	for value: Dictionary in entries(container_id):
		if value.definition_id == definition_id:
			result += int(value.quantity)
	return result

func count(container_id: String, definition_id: String) -> int:
	return quantity(container_id, definition_id)

func capture() -> Dictionary:
	return _capture(_state)

func validate_state(value: Dictionary) -> Error:
	if not _keys(value, ["version", "revision", "next_entry", "containers"]) or not _integer(value.version, 1, 1) or not _integer(value.revision, 0, MAX_UNITS) or not _integer(value.next_entry, 1, MAX_UNITS):
		return ERR_INVALID_DATA
	if not value.containers is Array or value.containers.size() > MAX_CONTAINERS:
		return ERR_INVALID_DATA
	var containers := {}
	var entry_ids := {}
	var greatest_serial := 0
	for container: Variant in value.containers:
		if not container is Dictionary or not _keys(container, ["id", "owner_id", "capacity_mode", "slots", "max_mass_grams", "revision", "entries"]):
			return ERR_INVALID_DATA
		if not _identity(container.id) or not _identity(container.owner_id) or containers.has(container.id) or not _integer(container.revision, 0, int(value.revision)):
			return ERR_INVALID_DATA
		containers[container.id] = true
		if container.capacity_mode not in ["FIXED_SLOTS", "DYNAMIC_SLOTS"] or not _integer(container.slots, -1, MAX_SLOTS) or (container.capacity_mode == "DYNAMIC_SLOTS" and container.slots != -1) or (container.capacity_mode == "FIXED_SLOTS" and container.slots < 1):
			return ERR_INVALID_DATA
		if not _integer(container.max_mass_grams, 0, MAX_UNITS) or not container.entries is Array or container.entries.size() > _slot_limit(container):
			return ERR_INVALID_DATA
		for stack: Variant in container.entries:
			if not stack is Dictionary or not _keys(stack, ["id", "definition_id", "quantity", "owner_id", "container_id", "condition", "composition", "provenance"]):
				return ERR_INVALID_DATA
			if not stack.id is String or _serial(stack.id) < 1 or entry_ids.has(stack.id) or not stack.definition_id is String or stack.container_id != container.id or not _identity(stack.owner_id):
				return ERR_INVALID_DATA
			var definition := catalog.lookup(stack.definition_id)
			if definition == null or not _integer(stack.quantity, 1, definition.max_stack) or not _metadata({"condition": stack.condition, "composition": stack.composition, "provenance": stack.provenance, "owner_id": stack.owner_id}):
				return ERR_INVALID_DATA
			entry_ids[stack.id] = true
			greatest_serial = maxi(greatest_serial, _serial(stack.id))
		if _mass(container) > container.max_mass_grams:
			return ERR_INVALID_DATA
	return OK if greatest_serial < value.next_entry else ERR_INVALID_DATA

func restore(value: Dictionary) -> Error:
	if _transaction_active:
		return ERR_BUSY
	if validate_state(value) != OK:
		return ERR_INVALID_DATA
	var staged := {"revision": int(value.revision), "next_entry": int(value.next_entry), "containers": {}}
	for container: Dictionary in value.containers:
		var copy: Dictionary = container.duplicate(true)
		for key: String in ["slots", "max_mass_grams", "revision"]:
			copy[key] = int(copy[key])
		for stack: Dictionary in copy.entries:
			stack.quantity = int(stack.quantity)
			stack.condition = int(stack.condition)
			stack.composition = _json_copy(stack.composition)
			stack.provenance = _json_copy(stack.provenance)
		staged.containers[copy.id] = copy
	_state = staged
	return OK

func add(actor_id: String, container_id: String, definition_id: String, amount: int, metadata: Dictionary = {}) -> Dictionary:
	return transact(actor_id, [{"kind": "add", "container_id": container_id, "definition_id": definition_id, "quantity": amount, "metadata": metadata}])

func remove(actor_id: String, container_id: String, entry_id: String, amount: int) -> Dictionary:
	return transact(actor_id, [{"kind": "remove", "container_id": container_id, "entry_id": entry_id, "quantity": amount}])

func transfer(actor_id: String, source_id: String, destination_id: String, entry_id: String, amount: int) -> Dictionary:
	return transact(actor_id, [{"kind": "transfer", "source_id": source_id, "destination_id": destination_id, "entry_id": entry_id, "quantity": amount}])

func split(actor_id: String, container_id: String, entry_id: String, amount: int) -> Dictionary:
	return transact(actor_id, [{"kind": "split", "container_id": container_id, "entry_id": entry_id, "quantity": amount}])

func merge(actor_id: String, container_id: String, source_entry_id: String, target_entry_id: String) -> Dictionary:
	return transact(actor_id, [{"kind": "merge", "container_id": container_id, "source_entry_id": source_entry_id, "target_entry_id": target_entry_id}])

func transact(actor_id: String, operations: Array, expected_revisions: Dictionary = {}) -> Dictionary:
	if _transaction_active:
		return _failure("BUSY")
	if not _identity(actor_id) or operations.is_empty() or operations.size() > MAX_OPERATIONS or expected_revisions.size() > MAX_CONTAINERS:
		return _failure("INVALID_TRANSACTION")
	for id: Variant in expected_revisions:
		if not id is String or not _state.containers.has(id) or not _integer(expected_revisions[id], 0, MAX_UNITS) or expected_revisions[id] != _state.containers[id].revision:
			return _failure("REVISION_CONFLICT")
	if _state.revision >= MAX_UNITS:
		return _failure("REVISION_EXHAUSTED")
	_transaction_active = true
	# Copy the complete bounded ledger: later operations see prior staged changes.
	var staged: Dictionary = _state.duplicate(true)
	var changed := {}
	var created: Array[String] = []
	for operation: Variant in operations:
		var code := _apply(staged, actor_id, operation, changed, created)
		if code != "OK":
			_transaction_active = false
			return _failure(code)
	staged.revision += 1
	for id: String in changed:
		staged.containers[id].revision += 1
	if validate_state(_capture(staged)) != OK:
		_transaction_active = false
		return _failure("INVALID_STATE")
	_state = staged
	_transaction_active = false
	var changed_ids := changed.keys()
	changed_ids.sort()
	return {"ok": true, "code": "OK", "revision": _state.revision, "created_ids": created.duplicate(), "changed_containers": changed_ids}

func _apply(state: Dictionary, actor_id: String, raw: Variant, changed: Dictionary, created: Array[String]) -> String:
	if not raw is Dictionary or not raw.get("kind") is String:
		return "INVALID_OPERATION"
	var op: Dictionary = raw
	var fields := {"add": ["kind", "container_id", "definition_id", "quantity"], "remove": ["kind", "container_id", "entry_id", "quantity"], "split": ["kind", "container_id", "entry_id", "quantity"], "merge": ["kind", "container_id", "source_entry_id", "target_entry_id"], "transfer": ["kind", "source_id", "destination_id", "entry_id", "quantity"]}
	if not fields.has(op.kind) or not _keys(op, fields[op.kind], ["metadata"] if op.kind == "add" else []):
		return "INVALID_OPERATION"
	var source_id: Variant = op.get("source_id", op.get("container_id"))
	if not source_id is String or not state.containers.has(source_id):
		return "CONTAINER_UNAVAILABLE"
	var source: Dictionary = state.containers[source_id]
	if source.owner_id != actor_id:
		return "OWNERSHIP_REJECTED"
	if op.kind != "merge" and not _integer(op.quantity, 1, MAX_UNITS):
		return "INVALID_QUANTITY"
	if op.kind == "add":
		if not op.definition_id is String:
			return "UNKNOWN_ITEM"
		var definition := catalog.lookup(op.definition_id)
		var metadata: Variant = op.get("metadata", {})
		if definition == null:
			return "UNKNOWN_ITEM"
		if not metadata is Dictionary or not _metadata(metadata):
			return "INVALID_METADATA"
		var stack := {"id": "", "definition_id": op.definition_id, "quantity": int(op.quantity), "owner_id": metadata.get("owner_id", source.owner_id), "container_id": source_id, "condition": int(metadata.get("condition", CONDITION_SCALE)), "composition": _json_copy(metadata.get("composition", {})), "provenance": _json_copy(metadata.get("provenance", {}))}
		var added := _insert(state, source, stack, int(op.quantity), created)
		if added != "OK":
			return added
	elif op.kind == "merge":
		if not op.source_entry_id is String or not op.target_entry_id is String or op.source_entry_id == op.target_entry_id:
			return "INVALID_ENTRY"
		var from := _find(source, op.source_entry_id)
		var target := _find(source, op.target_entry_id)
		if from.is_empty() or target.is_empty():
			return "ENTRY_UNAVAILABLE"
		if not _compatible(from, target):
			return "INCOMPATIBLE_STACK"
		if from.quantity + target.quantity > catalog.lookup(from.definition_id).max_stack:
			return "STACK_FULL"
		target.quantity += from.quantity
		source.entries.erase(from)
	else:
		if not op.entry_id is String:
			return "INVALID_ENTRY"
		var stack := _find(source, op.entry_id)
		if stack.is_empty():
			return "ENTRY_UNAVAILABLE"
		if op.quantity > stack.quantity:
			return "INSUFFICIENT_QUANTITY"
		if op.kind == "remove":
			_take(source, stack, int(op.quantity))
		elif op.kind == "split":
			if op.quantity == stack.quantity:
				return "INVALID_SPLIT"
			if source.entries.size() >= _slot_limit(source):
				return "SLOTS_FULL"
			var copy: Dictionary = stack.duplicate(true)
			copy.id = _allocate(state)
			if copy.id.is_empty():
				return "IDENTITY_EXHAUSTED"
			copy.quantity = int(op.quantity)
			stack.quantity -= int(op.quantity)
			source.entries.append(copy)
			created.append(copy.id)
		elif op.kind == "transfer":
			if not op.destination_id is String or op.destination_id == source_id or not state.containers.has(op.destination_id):
				return "CONTAINER_UNAVAILABLE"
			var destination: Dictionary = state.containers[op.destination_id]
			var copy: Dictionary = stack.duplicate(true)
			copy.container_id = op.destination_id
			# A full individual transfer preserves identity; split lots allocate an ID.
			var preserve: String = stack.id if op.quantity == stack.quantity else ""
			_take(source, stack, int(op.quantity))
			var added := _insert(state, destination, copy, int(op.quantity), created, preserve)
			if added != "OK":
				return added
			changed[op.destination_id] = true
	changed[source_id] = true
	return "OK"

func _insert(state: Dictionary, container: Dictionary, template: Dictionary, amount: int, created: Array[String], preserve_id := "") -> String:
	var definition := catalog.lookup(template.definition_id)
	if _mass(container) + definition.unit_mass_grams * amount > container.max_mass_grams:
		return "MASS_CAPACITY"
	var remaining := amount
	container.entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
	for stack: Dictionary in container.entries:
		if _compatible(stack, template):
			var accepted := mini(remaining, definition.max_stack - int(stack.quantity))
			stack.quantity += accepted
			remaining -= accepted
			if remaining == 0:
				return "OK"
	while remaining > 0:
		if container.entries.size() >= _slot_limit(container):
			return "SLOTS_FULL"
		var stack: Dictionary = template.duplicate(true)
		stack.id = preserve_id if not preserve_id.is_empty() else _allocate(state)
		preserve_id = ""
		if stack.id.is_empty():
			return "IDENTITY_EXHAUSTED"
		stack.quantity = mini(remaining, definition.max_stack)
		stack.container_id = container.id
		container.entries.append(stack)
		created.append(stack.id)
		remaining -= int(stack.quantity)
	return "OK"

func _take(container: Dictionary, stack: Dictionary, amount: int) -> void:
	stack.quantity -= amount
	if stack.quantity == 0:
		container.entries.erase(stack)

func _find(container: Dictionary, id: String) -> Dictionary:
	for stack: Dictionary in container.entries:
		if stack.id == id:
			return stack
	return {}

func _compatible(a: Dictionary, b: Dictionary) -> bool:
	return a.definition_id == b.definition_id and a.owner_id == b.owner_id and a.condition == b.condition and a.composition == b.composition and a.provenance == b.provenance

func _mass(container: Dictionary) -> int:
	var result := 0
	for stack: Dictionary in container.entries:
		var definition := catalog.lookup(stack.definition_id)
		if definition == null:
			return MAX_UNITS + 1
		result += definition.unit_mass_grams * int(stack.quantity)
	return result

func _slot_limit(container: Dictionary) -> int:
	return MAX_SLOTS if container.capacity_mode == "DYNAMIC_SLOTS" else int(container.slots)

func _capture(state: Dictionary) -> Dictionary:
	var result := {"version": 1, "revision": state.revision, "next_entry": state.next_entry, "containers": []}
	var ids: Array = state.containers.keys()
	ids.sort()
	for id: String in ids:
		var container: Dictionary = state.containers[id].duplicate(true)
		container.entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.id < b.id)
		result.containers.append(container)
	return result

func _allocate(state: Dictionary) -> String:
	if state.next_entry >= MAX_UNITS:
		return ""
	var result := _entry_id(int(state.next_entry))
	state.next_entry += 1
	return result

static func _entry_id(serial: int) -> String:
	return "item.entry.e%010d" % serial

static func _serial(id: String) -> int:
	if not id.begins_with("item.entry.e"):
		return 0
	var suffix := id.trim_prefix("item.entry.e")
	if suffix.length() != 10 or not suffix.is_valid_int():
		return 0
	var value := int(suffix)
	return value if value > 0 and value < MAX_UNITS and _entry_id(value) == id else 0

static func _identity(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 128:
		return false
	for index: int in value.length():
		var code: int = value.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or code in [45, 46, 58, 95]):
			return false
	return true

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and value <= maximum and value == int(value)

static func _keys(value: Dictionary, required: Array, optional: Array = []) -> bool:
	for key: Variant in required:
		if not value.has(key):
			return false
	for key: Variant in value:
		if key not in required and key not in optional:
			return false
	return true

static func _metadata(value: Dictionary) -> bool:
	if not _keys(value, [], ["condition", "composition", "provenance", "owner_id"]):
		return false
	if value.has("condition") and not _integer(value.condition, 0, CONDITION_SCALE):
		return false
	if value.has("owner_id") and not _identity(value.owner_id):
		return false
	for field: String in ["composition", "provenance"]:
		if value.has(field) and (not value[field] is Dictionary or not _json_value(value[field], 0)):
			return false
	return true

static func _json_value(value: Variant, depth: int) -> bool:
	return _json_bounded(value, depth, [0])

static func _json_bounded(value: Variant, depth: int, budget: Array) -> bool:
	budget[0] += 1
	if depth > 4 or budget[0] > 128:
		return false
	if value is String:
		return value.length() <= 256
	if value is bool or value == null:
		return true
	if value is int or value is float:
		return _integer(value, -MAX_UNITS, MAX_UNITS)
	if value is Dictionary:
		if value.size() > 32:
			return false
		for key: Variant in value:
			if not key is String or key.is_empty() or key.length() > 128 or not _json_bounded(value[key], depth + 1, budget):
				return false
		return true
	if value is Array:
		if value.size() > 32:
			return false
		for member: Variant in value:
			if not _json_bounded(member, depth + 1, budget):
				return false
		return true
	return false

static func _json_copy(value: Variant) -> Variant:
	if value is int or value is float:
		return int(value)
	if value is Dictionary:
		var result := {}
		for key: String in value:
			result[key] = _json_copy(value[key])
		return result
	if value is Array:
		var result: Array = []
		for member: Variant in value:
			result.append(_json_copy(member))
		return result
	return value

func _failure(code: String) -> Dictionary:
	return {"ok": false, "code": code, "revision": _state.revision, "created_ids": [], "changed_containers": []}
