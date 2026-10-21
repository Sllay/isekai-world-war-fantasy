class_name ActionDefinition
extends Resource

enum TargetMode { SELF, ENTITY, DIRECTION, POINT }
@export var action_id := ""
@export_range(0, 1200) var cast_ticks: int = 0
@export_range(0, 1200) var recovery_ticks: int = 0
@export_range(0, 72000) var cooldown_ticks: int = 0
@export_range(0, 1000000000) var resource_cost: int = 0
@export var resource_id := "combat.resource.energy"
@export var interruptible := true
@export var cancellable := true
@export var cast_while_moving := true
@export var turn_while_casting := true
@export var target_mode: TargetMode = TargetMode.SELF
@export var max_range: float = 0.0
@export_range(1, 8) var max_targets: int = 1
# Authority world-query identity, required only for spatial targeting families.
@export var target_query_id := ""
@export var effects: Array[ActionEffect] = []
@export var tags: Array[String] = []
@export var windup_cue_id := ""
@export var commit_cue_id := ""
@export var recovery_cue_id := ""
@export var telegraph_id := ""

func valid(data: CoreDataRegistry) -> bool:
	if not CoreIds.valid(action_id) or not action_id.begins_with("combat.action."):
		return false
	if cast_ticks < 0 or cast_ticks > 1200 or recovery_ticks < 0 or recovery_ticks > 1200 or cooldown_ticks < 0 or cooldown_ticks > 72000 or resource_cost < 0 or resource_cost > CombatNumbers.MAX_UNITS:
		return false
	if data.lookup(resource_id).get("kind") != "resource" or target_mode not in TargetMode.values() or not is_finite(max_range) or max_range < 0 or max_range > 10000:
		return false
	if max_targets < 1 or max_targets > 8 or (target_mode in [TargetMode.SELF, TargetMode.ENTITY] and max_targets != 1):
		return false
	if target_mode in [TargetMode.DIRECTION, TargetMode.POINT] and not CoreIds.valid(target_query_id):
		return false
	if not target_query_id.is_empty() and not CoreIds.valid(target_query_id):
		return false
	if effects.is_empty() or effects.size() > 16:
		return false
	for effect in effects:
		if effect == null or not effect.valid(data):
			return false
	var seen: Dictionary = {}
	for tag in tags:
		if not CoreIds.valid(tag) or seen.has(tag):
			return false
		seen[tag] = true
	for cue in [windup_cue_id, commit_cue_id, recovery_cue_id, telegraph_id]:
		if not cue.is_empty() and not CoreIds.valid(cue):
			return false
	return true
