class_name CombatTargetPolicy
extends RefCounted

enum Relationship { INVALID, SELF, ALLY, ENEMY, NEUTRAL }

# Override in an injected provider; no faction or Player identity is assumed.
func relationship(source: String, target: String) -> Relationship:
	return Relationship.SELF if source == target else Relationship.NEUTRAL

func allows_damage(relation: Relationship, request: DamageRequest) -> bool:
	match relation:
		Relationship.SELF: return request.allow_self
		Relationship.ALLY: return request.friendly_fire
		Relationship.ENEMY: return true
		Relationship.NEUTRAL: return request.allow_neutral
	return false

func allows_healing(relation: Relationship, request: HealingRequest) -> bool:
	return relation in [Relationship.SELF, Relationship.ALLY] or (relation == Relationship.NEUTRAL and request.allow_neutral)
