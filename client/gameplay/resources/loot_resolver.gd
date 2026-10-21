class_name LootResolver
extends RefCounted

# This resolves initial stock/biological yields; carried death loot is transferred.
static func resolve(profile: LootProfile, trusted_seed: int, items: ItemCatalog) -> Dictionary:
	if profile == null or items == null or not profile.valid(items):
		return {"ok": false, "code": "INVALID_LOOT_PROFILE", "outputs": []}
	var rng := RandomNumberGenerator.new()
	rng.seed = trusted_seed
	var quantities: Dictionary = {}
	for entry in profile.guaranteed:
		_add(quantities, entry, rng)
	var weight_sum := 0
	for entry in profile.weighted:
		weight_sum += int(entry.weight)
	for _roll in range(profile.rolls):
		var choice := rng.randi_range(1, weight_sum)
		for entry in profile.weighted:
			choice -= int(entry.weight)
			if choice <= 0:
				_add(quantities, entry, rng)
				break
	var outputs: Array[Dictionary] = []
	var ids := quantities.keys()
	ids.sort()
	for id: String in ids:
		outputs.append({"definition_id": id, "quantity": quantities[id]})
	return {"ok": true, "code": "LOOT_RESOLVED", "outputs": outputs}

static func _add(quantities: Dictionary, entry: Dictionary, rng: RandomNumberGenerator) -> void:
	quantities[entry.definition_id] = int(quantities.get(entry.definition_id, 0)) + rng.randi_range(int(entry.minimum), int(entry.maximum))
