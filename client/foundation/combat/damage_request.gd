class_name DamageRequest
extends CombatRequest

var damage_type_id := "combat.damage.physical"
var blockable := true
var dodgeable := true
var parryable := false
var interrupt_relevant := false
var friendly_fire := false
var allow_self := false
var has_impact := false
var impact_position := Vector3.ZERO
