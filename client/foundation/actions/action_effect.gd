class_name ActionEffect
extends Resource

enum Kind { DAMAGE, HEALING, DODGE, GUARD, PARRY, INTERRUPT }
@export_range(0, 1200) var window_ticks := 0
@export_range(0, 20) var movement_distance := 0.0
@export var kind: Kind = Kind.DAMAGE
@export_range(0, 1000000000) var amount: int = 0
@export var damage_type_id := "combat.damage.physical"
@export var blockable := true
@export var dodgeable := true
@export var parryable := false
@export var allow_neutral := false
@export var friendly_fire := false
@export var allow_self := false

func valid(data: CoreDataRegistry) -> bool:
	return window_ticks >= 0 and window_ticks <= 1200 and is_finite(movement_distance) and movement_distance >= 0 and movement_distance <= 20 and (kind not in [Kind.DODGE, Kind.PARRY] or window_ticks > 0) and kind in Kind.values() and amount >= 0 and amount <= CombatNumbers.MAX_UNITS and (kind != Kind.DAMAGE or data.lookup(damage_type_id).get("kind") == "damage")

func request(source: String, target: String, action: ActionDefinition) -> CombatRequest:
	var result: CombatRequest
	if kind == Kind.DAMAGE:
		var hit := DamageRequest.new(source, target, amount)
		hit.damage_type_id = damage_type_id
		hit.blockable = blockable
		hit.dodgeable = dodgeable
		hit.parryable = parryable
		hit.friendly_fire = friendly_fire
		hit.allow_self = allow_self
		hit.interrupt_relevant = action.interruptible
		result = hit
	else:
		result = HealingRequest.new(source, target, amount)
	result.allow_neutral = allow_neutral
	result.action_id = action.action_id
	result.tags = action.tags.duplicate()
	return result
