class_name LootProfile
extends Resource

# Guaranteed entries and weighted choices share definition_id/minimum/maximum.
@export var profile_id := ""
@export var guaranteed: Array[Dictionary] = []
@export var weighted: Array[Dictionary] = []
@export_range(0, 16) var rolls := 0

func valid(items: ItemCatalog) -> bool:
	if not CoreIds.valid(profile_id) or guaranteed.size() > 16 or weighted.size() > 32 or rolls < 0 or rolls > 16 or (rolls > 0 and weighted.is_empty()):
		return false
	var weight_sum := 0
	for index in range(2):
		var entries: Array[Dictionary] = guaranteed if index == 0 else weighted
		for entry: Dictionary in entries:
			if not entry.get("definition_id") is String or items.lookup(entry.definition_id) == null or not CombatNumbers.integer(entry.get("minimum"), 1, 10000) or not CombatNumbers.integer(entry.get("maximum"), entry.minimum, 10000):
				return false
			if index == 1:
				if not CombatNumbers.integer(entry.get("weight"), 1, 1000000):
					return false
				weight_sum += int(entry.weight)
	return weight_sum <= CombatNumbers.MAX_UNITS
