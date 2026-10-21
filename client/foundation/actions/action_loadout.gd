class_name ActionLoadout
extends Resource

# Trusted equipment/content boundary. Clients request a slot, never install IDs.
const SLOTS := ["primary", "skill_1", "skill_2", "skill_3"]
const ALIASES := {"strong": "skill_1", "heal": "skill_2"}
@export var loadout_id := ""
@export var slots: Dictionary[String, String] = {}

func valid(catalog: ActionCatalog) -> bool:
	if not CoreIds.valid(loadout_id) or slots.size() != SLOTS.size():
		return false
	for slot: String in SLOTS:
		if not slots.has(slot) or (slot == "primary" and slots[slot].is_empty()):
			return false
		if not slots[slot].is_empty() and catalog.lookup(slots[slot]) == null:
			return false
	return true

func action_for(slot: String) -> String:
	# Wire compatibility with the A1 command vocabulary; new input uses skill_N.
	return slots.get(ALIASES.get(slot, slot), "")
