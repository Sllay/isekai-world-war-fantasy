class_name CombatRequest
extends RefCounted

var transaction_id := CoreIds.generate()
var source_entity: String
var target_entity: String
var amount: float = 0
var action_id := ""
var tags: Array[String] = []
var allow_neutral := false
# Informational only. The provider determines the authoritative relationship.
var relationship_hint := CombatTargetPolicy.Relationship.INVALID
var _resolved := false

func _init(source := "", target := "", units := 0.0) -> void:
	source_entity = source
	target_entity = target
	amount = units

func valid_metadata() -> bool:
	if not CombatNumbers.stable_entity(transaction_id) or (not action_id.is_empty() and not CoreIds.valid(action_id)):
		return false
	var seen: Dictionary = {}
	for tag in tags:
		if not CoreIds.valid(tag) or seen.has(tag):
			return false
		seen[tag] = true
	return true
