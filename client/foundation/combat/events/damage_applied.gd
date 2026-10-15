class_name DamageApplied
extends CombatEvent

var damage_type_id := ""
var action_id := ""
var tags: Array[String] = []
var actual: int
var evaluated: int
var overkill: int
var relationship: CombatTargetPolicy.Relationship
var has_impact := false
var impact_position := Vector3.ZERO
