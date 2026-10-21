class_name EquipmentState
extends RefCounted

# Equipment references the same canonical inventory instance; it has no item copy.
const SLOTS := ["weapon", "tool", "armor"]
var owner_id: String
var _slots: Dictionary = {}

func _init(owner := "") -> void:
	owner_id = owner

func equip(slot: String, container_id: String, entry_id: String, inventory: InventoryService) -> Error:
	if slot not in SLOTS or inventory == null:
		return ERR_INVALID_PARAMETER
	var proposed := capture()
	proposed.slots[slot] = {"container_id": container_id, "entry_id": entry_id}
	if validate_state(proposed, inventory) != OK:
		return ERR_INVALID_DATA
	_slots = proposed.slots.duplicate(true)
	return OK

func unequip(slot: String) -> Error:
	return OK if _slots.erase(slot) else ERR_DOES_NOT_EXIST

func is_equipped(container_id: String, entry_id: String) -> bool:
	for reference: Dictionary in _slots.values():
		if reference.container_id == container_id and reference.entry_id == entry_id:
			return true
	return false

func references() -> Array:
	var result: Array = []
	for slot: String in SLOTS:
		if _slots.has(slot):
			result.append({"slot": slot, "container_id": _slots[slot].container_id, "entry_id": _slots[slot].entry_id})
	return result

func definitions(inventory: InventoryService) -> Dictionary:
	var result := {}
	if validate(inventory) != OK:
		return result
	for slot: String in SLOTS:
		if _slots.has(slot):
			var reference: Dictionary = _slots[slot]
			var stack := inventory.entry(reference.container_id, reference.entry_id)
			result[slot] = inventory.catalog.lookup(stack.definition_id)
	return result

func capture() -> Dictionary:
	return {"version": 1, "owner_id": owner_id, "slots": _slots.duplicate(true)}

func validate(inventory: InventoryService) -> Error:
	return validate_state(capture(), inventory)

func validate_state(value: Dictionary, inventory: InventoryService) -> Error:
	if inventory == null or not InventoryService._keys(value, ["version", "owner_id", "slots"]) or value.version != 1 or not InventoryService._identity(value.owner_id) or (not owner_id.is_empty() and value.owner_id != owner_id) or not value.slots is Dictionary or value.slots.size() > SLOTS.size():
		return ERR_INVALID_DATA
	var seen := {}
	for slot: Variant in value.slots:
		if slot not in SLOTS or not value.slots[slot] is Dictionary or not InventoryService._keys(value.slots[slot], ["container_id", "entry_id"]):
			return ERR_INVALID_DATA
		var reference: Dictionary = value.slots[slot]
		if not reference.container_id is String or not reference.entry_id is String or seen.has(reference.entry_id):
			return ERR_INVALID_DATA
		var container := inventory.snapshot(reference.container_id)
		var stack := inventory.entry(reference.container_id, reference.entry_id)
		# Possession controls equipment. Legal owner can differ after valid loot/theft.
		if container.is_empty() or container.owner_id != value.owner_id or stack.is_empty() or stack.quantity != 1:
			return ERR_INVALID_DATA
		var definition := inventory.catalog.lookup(stack.definition_id)
		if definition == null or definition.equipment_slot != slot:
			return ERR_INVALID_DATA
		seen[reference.entry_id] = true
	return OK

func restore(value: Dictionary, inventory: InventoryService) -> Error:
	if validate_state(value, inventory) != OK:
		return ERR_INVALID_DATA
	owner_id = value.owner_id
	_slots = value.slots.duplicate(true)
	return OK
