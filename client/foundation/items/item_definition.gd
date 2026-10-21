class_name ItemDefinition
extends Resource

# Reusable content only. Custody, condition and provenance belong to entries.
@export var item_id := ""
@export var display_name := ""
@export var category := "item.category.material"
@export var material_id := ""
@export var tags: Array[String] = []
@export var max_stack := 1
@export var unit_mass_grams := 0
@export var equipment_slot := ""
@export var tool_tags: Array[String] = []
@export var tool_capability := ""
@export var tool_power := 0
# Basis points added to the existing CombatModifier DAMAGE_SCALE channel.
@export var damage_bonus := 0
@export var consume_heal := 0
@export var granted_skills: Array[String] = []

func valid() -> bool:
	if item_id.length() > 128 or not CoreIds.valid(item_id) or not item_id.begins_with("item.") or display_name.is_empty() or display_name.length() > 128:
		return false
	if category.length() > 128 or material_id.length() > 128 or not CoreIds.valid(category) or (not material_id.is_empty() and not CoreIds.valid(material_id)):
		return false
	if max_stack < 1 or max_stack > 10000 or unit_mass_grams < 0 or unit_mass_grams > 1000000000:
		return false
	if equipment_slot not in ["", "weapon", "tool", "armor"] or (not equipment_slot.is_empty() and max_stack != 1):
		return false
	if tool_power < 0 or tool_power > 1000 or damage_bonus < 0 or damage_bonus > 1000000 or consume_heal < 0 or consume_heal > 1000000000:
		return false
	if not tool_capability.is_empty() and (not CoreIds.valid(tool_capability) or not tool_tags.has(tool_capability)):
		return false
	if tags.size() > 32 or tool_tags.size() > 16 or granted_skills.size() > 16:
		return false
	for list: Array[String] in [tags, tool_tags, granted_skills]:
		var seen := {}
		for tag: String in list:
			if tag.length() > 128 or not CoreIds.valid(tag) or seen.has(tag):
				return false
			seen[tag] = true
	return true
