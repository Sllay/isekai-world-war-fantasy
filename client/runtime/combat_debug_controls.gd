extends CanvasLayer

# Small read-only development status. Gameplay comes from production actions.
var combat: CombatService
var state: Combatant
var actions: ActionExecutor
var enemy_summary: Callable
var recovery_summary: Callable
var status := Label.new()

func _ready() -> void:
	status.position = Vector2(20, 85)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(status)

func _process(_delta: float) -> void:
	status.text = "HP %d/%d  Resource %d/%d  %s" % [state.health, state.max_health(), state.resource, state.max_resource(), Combatant.Lifecycle.keys()[state.lifecycle]]
	if actions != null:
		var info := actions.development_state()
		status.text += "\n%s %s (%d ticks)  %s" % [info.action_id, info.phase, info.remaining_ticks, info.last_result]
	var defense := state.defense.development_state(combat.clock.tick)
	status.text += "\nGuard %s  Dodge %dt  Parry %dt  %s prevented %d / applied %d" % [defense.guard, defense.dodge_ticks, defense.parry_ticks, defense.last_result, defense.prevented, defense.applied]
	if recovery_summary.is_valid():
		status.text += "\n" + str(recovery_summary.call())
	if enemy_summary.is_valid():
		status.text += "\n" + str(enemy_summary.call())
