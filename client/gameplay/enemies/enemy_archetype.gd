class_name EnemyArchetype
extends Resource

@export var archetype_id := "enemy.archetype.melee_skirmisher"
@export var profile_id := "combat.profile.standard"
@export var action_id := "combat.action.enemy.basic_strike"
@export var awareness_range := 8.0
@export var leash_distance := 12.0
@export var speed := 2.5
@export var range_margin := 0.25

func valid(catalog: ActionCatalog) -> bool:
	if catalog == null or not CoreIds.valid(archetype_id) or not archetype_id.begins_with("enemy.archetype.") or not CoreIds.valid(profile_id):
		return false
	var action := catalog.lookup(action_id)
	for number in [awareness_range, leash_distance, speed, range_margin]:
		if not is_finite(number) or number <= 0:
			return false
	return action != null and action.target_mode == ActionDefinition.TargetMode.ENTITY and action.max_range > range_margin and awareness_range >= action.max_range and leash_distance > awareness_range
