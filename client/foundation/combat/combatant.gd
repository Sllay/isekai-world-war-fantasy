class_name Combatant
extends RefCounted

enum Lifecycle { ALIVE, DEFEATED }
var entity_id: String
var profile_id: String
var profile_version: int
var resource_id: String
var attributes: CombatAttributes
var health: int
var resource: int
var lifecycle := Lifecycle.ALIVE

func _init(stable_id: String, profile: Dictionary) -> void:
	entity_id = stable_id
	profile_id = profile.id
	profile_version = int(profile.version)
	resource_id = profile.resource_id
	attributes = CombatAttributes.new(profile)
	health = max_health()
	resource = max_resource()

func max_health() -> int:
	return attributes.value(CombatModifier.Stat.MAX_HEALTH)

func max_resource() -> int:
	return attributes.value(CombatModifier.Stat.MAX_RESOURCE)

func capture() -> Dictionary:
	return {"profile_id": profile_id, "profile_version": profile_version, "health": health, "resource": resource, "lifecycle": lifecycle, "modifiers": attributes.capture_modifiers()}

static func valid(data: Dictionary, profile: Dictionary) -> bool:
	if profile.is_empty() or data.get("profile_id") != profile.id or data.get("profile_version") != profile.version or not data.get("modifiers") is Array or data.modifiers.size() > CombatNumbers.MAX_MODIFIERS:
		return false
	var derived := CombatAttributes.new(profile)
	for modifier in data.modifiers:
		if not modifier is Dictionary or not CombatModifier.valid(modifier) or derived.add(CombatModifier.from_state(modifier)) != OK:
			return false
	if not CombatNumbers.integer(data.get("health"), 0, derived.value(CombatModifier.Stat.MAX_HEALTH)) or not CombatNumbers.integer(data.get("resource"), 0, derived.value(CombatModifier.Stat.MAX_RESOURCE)):
		return false
	if not CombatNumbers.integer(data.get("lifecycle"), 0, Lifecycle.size() - 1):
		return false
	return (data.lifecycle == Lifecycle.DEFEATED) == (data.health == 0)

func restore(data: Dictionary, profile: Dictionary) -> void:
	attributes = CombatAttributes.new(profile)
	for modifier in data.modifiers:
		attributes.add(CombatModifier.from_state(modifier))
	health = int(data.health)
	resource = int(data.resource)
	lifecycle = int(data.lifecycle)
