class_name FactionDefinition
extends Resource

@export var faction_id := ""
@export var dispositions: Dictionary = {}

func valid() -> bool:
	if not CoreIds.valid(faction_id) or dispositions.size() > 16: return false
	for target: Variant in dispositions:
		if not target is String or not CoreIds.valid(target) or dispositions[target] not in ["friendly", "neutral", "hostile"]: return false
	return true
