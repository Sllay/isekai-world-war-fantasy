class_name RaceVisualProfile
extends Resource

# References to curated LPC families/palettes, not imported pixels or gameplay.
@export var profile_id := ""
@export var body_families: Array[String] = []
@export var palette_ids: Array[String] = []
@export var equipment_tags: Array[String] = []
@export var uniform_scale := 1.0

func valid() -> bool:
	if not CoreIds.valid(profile_id) or body_families.is_empty() or palette_ids.is_empty() or not is_finite(uniform_scale) or uniform_scale < 0.5 or uniform_scale > 2.0: return false
	for values: Array[String] in [body_families, palette_ids, equipment_tags]:
		if values.size() > 16: return false
		var seen := {}
		for value: String in values:
			if not CoreIds.valid(value) or seen.has(value): return false
			seen[value] = true
	return true
