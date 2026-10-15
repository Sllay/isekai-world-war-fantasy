class_name DispositionPolicy
extends CombatTargetPolicy

# Minimal authored disposition groups, independent of Player/faction classes.
var groups: Dictionary[String, String] = {}
var hostile_groups: Dictionary[String, Array] = {}

func relationship(source: String, target: String) -> Relationship:
	if source == target:
		return Relationship.SELF
	var a: String = groups.get(source, "")
	var b: String = groups.get(target, "")
	if a.is_empty() or b.is_empty():
		return Relationship.INVALID
	if a == b:
		return Relationship.ALLY
	return Relationship.ENEMY if b in hostile_groups.get(a, []) else Relationship.NEUTRAL
