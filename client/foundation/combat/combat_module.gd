class_name CombatModule
extends CoreModule

var service := CombatService.new()
var definitions: Dictionary

func _init(content: Dictionary = {}) -> void:
	id = "foundation.combat"
	requires.assign(["core.runtime"])
	provides.assign(["foundation.combat"])
	published_events.assign(["combat.damage_applied", "combat.healing_applied", "combat.health_changed", "combat.combatant_defeated"])
	definitions = CombatDefinitions.defaults() if content.is_empty() else content.duplicate(true)
	for group in ["tokens", "profiles"]:
		if definitions.get(group) is Array:
			for definition in definitions[group]:
				if definition is Dictionary and definition.get("id") is String:
					data_ids.append(definition.id)

func register(services: CoreServices) -> Error:
	return services.provide("foundation.combat", service)

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
	for event_type in [DamageApplied, HealingApplied, HealthChanged, CombatantDefeated]:
		if service.events.define(event_type) != OK:
			return ERR_INVALID_DATA
	return OK

func dispose() -> void:
	service._combatants.clear()
