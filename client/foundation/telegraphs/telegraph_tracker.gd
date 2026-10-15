class_name TelegraphTracker
extends RefCounted

# Read-only projection of typed action facts. It has no executor mutation API.
var catalog: ActionCatalog
var clock: CoreClock
var events: CoreEventBus
var definitions: Dictionary[String, TelegraphDefinition] = {}
var active: Dictionary[String, Dictionary] = {}
var _tokens: Array[int] = []

func bind(bus: CoreEventBus, actions: ActionCatalog, simulation: CoreClock) -> void:
	events = bus
	catalog = actions
	clock = simulation
	var definition := preload("res://foundation/telegraphs/melee_range.tres")
	definitions[definition.definition_id] = definition
	_tokens.append(events.subscribe(ActionStarted, _started))
	for type in [ActionCommitted, ActionCancelled, ActionCompleted]:
		_tokens.append(events.subscribe(type, _stopped))
	_tokens.append(events.subscribe(CombatantDefeated, _defeated))

func _started(event: ActionStarted) -> void:
	var definition := catalog.lookup(event.action_id)
	if definition == null or not definitions.has(definition.telegraph_id):
		return
	active[event.execution_id] = {"telegraph_id": definition.telegraph_id, "execution_id": event.execution_id, "owner_id": event.owner_id, "target_id": event.target_id, "range": definition.max_range, "start_tick": event.tick, "commit_tick": event.tick + definition.cast_ticks}

func _stopped(event: ActionEvent) -> void:
	active.erase(event.execution_id)

func _defeated(event: CombatantDefeated) -> void:
	for key in active.keys():
		if active[key].owner_id == event.target_entity or active[key].target_id == event.target_entity:
			active.erase(key)

func progress(value: Dictionary) -> float:
	return clampf(float(clock.tick - value.start_tick) / maxf(1, value.commit_tick - value.start_tick), 0, 1)

func clear() -> void:
	active.clear()

func dispose() -> void:
	for token in _tokens:
		events.unsubscribe(token)
	_tokens.clear()
	active.clear()
