class_name RaceDefinition
extends Resource

@export var race_id := ""
@export var visual_profile_id := ""
@export var attribute_modifiers := {"strength": 0, "agility": 0, "intellect": 0, "vitality": 0}
@export var culture_id := ""
@export var origin_id := ""
@export var historical_faction_id := ""
@export var gameplay_tags: Array[String] = []

func valid() -> bool:
	if not CoreIds.valid(race_id) or not CoreIds.valid(visual_profile_id) or not CoreIds.valid(culture_id) or not CoreIds.valid(origin_id) or not CoreIds.valid(historical_faction_id) or not RpgAttributes.valid_values(attribute_modifiers, -100, 100): return false
	if gameplay_tags.size() > 16: return false
	for tag in gameplay_tags:
		if not CoreIds.valid(tag): return false
	return true
