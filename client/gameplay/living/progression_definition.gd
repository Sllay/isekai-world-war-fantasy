class_name ProgressionDefinition
extends Resource

@export var progression_id := ""
@export var thresholds: Array[int] = [0, 20, 60, 120]
@export var cause_awards := {"combat.defeat": 25, "resource.harvest": 3, "craft.complete": 5, "world.discovery": 8}

func valid() -> bool:
	if not CoreIds.valid(progression_id) or thresholds.is_empty() or thresholds.size() > 64 or thresholds[0] != 0 or cause_awards.is_empty() or cause_awards.size() > 16: return false
	var previous := -1
	for amount in thresholds:
		if amount <= previous or amount > CombatNumbers.MAX_UNITS: return false
		previous = amount
	for cause: Variant in cause_awards:
		if not cause is String or not CoreIds.valid(cause) or not CombatNumbers.integer(cause_awards[cause], 1, 100000): return false
	return true

func level_for(xp: int) -> int:
	var result := 1
	for index in range(1, thresholds.size()):
		if xp < thresholds[index]: break
		result = index + 1
	return result
