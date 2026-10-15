extends CanvasLayer

# Development acceptance only: transactions use the same production service.
var combat: CombatService
var state: Combatant
var actions: ActionExecutor
var status := Label.new()
const TEST_AMOUNT := 10

func _ready() -> void:
	status.position = Vector2(20, 85)
	add_child(status)
	for healing in [false]:
		var button := Button.new()
		button.text = "Heal 10" if healing else "Damage 10"
		button.position = Vector2(165 if healing else 20, 190)
		button.size = Vector2(135, 50)
		button.pressed.connect(_test_transaction.bind(healing))
		add_child(button)

func _test_transaction(healing: bool) -> void:
	if healing:
		combat.heal(HealingRequest.new(state.entity_id, state.entity_id, TEST_AMOUNT))
	else:
		var request := DamageRequest.new(state.entity_id, state.entity_id, TEST_AMOUNT)
		request.allow_self = true
		combat.damage(request)

func _process(_delta: float) -> void:
	status.text = "HP %d/%d  Resource %d/%d  %s" % [state.health, state.max_health(), state.resource, state.max_resource(), Combatant.Lifecycle.keys()[state.lifecycle]]
	if actions != null:
		var info := actions.development_state()
		status.text += "\n%s %s (%d ticks)  %s" % [info.action_id, info.phase, info.remaining_ticks, info.last_result]
