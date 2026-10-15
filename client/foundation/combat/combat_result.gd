class_name CombatResult
extends RefCounted

var accepted := false
var code := ""
var transaction_id := ""
var source_entity := ""
var target_entity := ""
var relationship := CombatTargetPolicy.Relationship.INVALID
var requested := 0
var evaluated := 0
var actual := 0
var overage := 0
var health_before := 0
var health_after := 0
var defeated := false
