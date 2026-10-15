class_name CombatModule
extends CoreModule

var service := CombatService.new()
var actions := ActionCatalog.new()
var definitions: Dictionary
var action_content: ActionContent

func _init(content: Dictionary = {}, action_data: ActionContent = null) -> void:
	action_content = preload("res://data/actions/definitions.tres") if action_data == null else action_data
	id = "foundation.combat"
	requires.assign(["core.runtime"])
	provides.assign(["foundation.combat", "foundation.actions"])
	published_events.assign(["combat.damage_applied", "combat.healing_applied", "combat.health_changed", "combat.combatant_defeated", "combat.action_started", "combat.action_committed", "combat.action_cancelled", "combat.action_completed"])
	definitions = CombatDefinitions.defaults() if content.is_empty() else content.duplicate(true)
	for group in ["tokens", "profiles"]:
		if definitions.get(group) is Array:
			for definition in definitions[group]:
				if definition is Dictionary and definition.get("id") is String:
					data_ids.append(definition.id)
	for definition in action_content.actions:
		if definition != null:
			data_ids.append(definition.action_id)

func register(services: CoreServices) -> Error:
	var error := services.provide("foundation.combat", service)
	return services.provide("foundation.actions", actions) if error == OK else error

func initialize(services: CoreServices) -> Error:
	service.entities = services.resolve("core.entities") as CoreEntityIds
	service.data = services.resolve("core.data") as CoreDataRegistry
	service.events = services.resolve("core.events") as CoreEventBus
	service.clock = services.resolve("core.clock") as CoreClock
	service.diagnostics = services.resolve("core.diagnostics") as CoreDiagnostics
	if service.entities == null or service.data == null or service.events == null or service.clock == null or service.diagnostics == null:
		return ERR_UNCONFIGURED
	var data := service.data
	if data.define_family("combat.token", CombatDefinitions.valid_token) != OK or data.define_family("combat.profile", CombatDefinitions.valid_profile) != OK:
		return ERR_INVALID_DATA
	for group in ["tokens", "profiles"]:
		if not definitions.get(group) is Array:
			return ERR_INVALID_DATA
		for definition in definitions[group]:
			if not definition is Dictionary or not definition.get("id") is String or data.register(definition.id, "combat.profile" if group == "profiles" else "combat.token", definition) != OK:
				return ERR_INVALID_DATA
	for profile in definitions.profiles:
		if data.lookup(profile.resource_id).get("kind") != "resource":
			return ERR_INVALID_DATA
	if data.define_family("combat.action", ActionCatalog.valid_metadata) != OK:
		return ERR_INVALID_DATA
	actions.data = data
	for definition in action_content.actions:
		if actions.register(definition) != OK:
			return ERR_INVALID_DATA
	for event_type in [DamageApplied, HealingApplied, HealthChanged, CombatantDefeated, ActionStarted, ActionCommitted, ActionCancelled, ActionCompleted]:
		if service.events.define(event_type) != OK:
			return ERR_INVALID_DATA
	return OK

func dispose() -> void:
	service._combatants.clear()
