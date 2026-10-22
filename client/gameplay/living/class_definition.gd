class_name ClassDefinition
extends Resource

@export var class_id := ""
@export var base_attributes := {"strength": 10, "agility": 8, "intellect": 6, "vitality": 10}
@export var starting_actions: Array[String] = []
@export var equipment_tags: Array[String] = []
@export var role_tags: Array[String] = []
@export var progression_id := ""

func valid() -> bool:
	if not CoreIds.valid(class_id) or not CoreIds.valid(progression_id) or not RpgAttributes.valid_values(base_attributes, 1, 100): return false
	for values: Array[String] in [starting_actions, equipment_tags, role_tags]:
		if values.size() > 16: return false
		var seen := {}
		for value in values:
			if not CoreIds.valid(value) or seen.has(value): return false
			seen[value] = true
	return true

# Starting ownership is derived from class content; later learned/equipment
# skills retain their own sources and are not restricted to this starting list.
func seed_skills(skills: LearnedSkillSet, actions: ActionCatalog) -> Error:
	if not valid() or skills == null or actions == null: return ERR_INVALID_DATA
	var proposed := LearnedSkillSet.new(skills.owner_id)
	if proposed.restore(skills.capture(), actions) != OK: return ERR_INVALID_DATA
	for action_id: String in starting_actions:
		var error := proposed.learn(action_id, "skill.source.class", actions)
		if error not in [OK, ERR_ALREADY_EXISTS]: return error
	return skills.restore(proposed.capture(), actions)

func allows_equipment(definition: ItemDefinition) -> bool:
	if definition == null or definition.equipment_slot.is_empty(): return false
	for tag: String in equipment_tags:
		if definition.tags.has(tag) or definition.tool_tags.has(tag): return true
	return false
