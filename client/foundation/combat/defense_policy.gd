class_name DefensePolicy
extends Resource

@export_range(0, 10000) var block_mitigation_bps := 7500
@export_range(0, 1000000000) var block_resource_cost := 2
@export var resource_id := "combat.resource.energy"
@export_range(0, 360) var block_arc_degrees := 120.0
@export_range(0, 360) var parry_arc_degrees := 120.0

func valid() -> bool:
	return block_mitigation_bps >= 0 and block_mitigation_bps <= CombatNumbers.SCALE and block_resource_cost >= 0 and block_resource_cost <= CombatNumbers.MAX_UNITS and CoreIds.valid(resource_id) and is_finite(block_arc_degrees) and block_arc_degrees >= 0 and block_arc_degrees <= 360 and is_finite(parry_arc_degrees) and parry_arc_degrees >= 0 and parry_arc_degrees <= 360
