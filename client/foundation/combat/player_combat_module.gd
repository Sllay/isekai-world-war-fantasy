class_name PlayerCombatModule
extends CoreModule

const PROFILE_ID := "combat.profile.standard"
var state: Combatant
var service: CombatService
var player: PlayerState
var capabilities: EntityComponents

func _init() -> void:
	id = "foundation.player_combat"
	requires.assign(["core.runtime", "foundation.player", "foundation.combat"])
	persistent = true

func initialize(services: CoreServices) -> Error:
	service = services.resolve("foundation.combat") as CombatService
	player = services.resolve("foundation.player") as PlayerState
	capabilities = services.resolve("foundation.player_capabilities") as EntityComponents
	if service == null or player == null or capabilities == null:
		return ERR_UNCONFIGURED
	state = service.register(player.entity_id, PROFILE_ID)
	if state == null:
		return ERR_INVALID_DATA
	return capabilities.attach("foundation.combatant", state)

func initial_state(entity_id: String) -> Dictionary:
	return {"entity_id": entity_id, "combatant": Combatant.new(entity_id, service.data.lookup(PROFILE_ID)).capture()}

func capture_state() -> Dictionary:
	return {"entity_id": state.entity_id, "combatant": state.capture()}

func validate_state(value: Dictionary) -> Error:
	if not CombatNumbers.stable_entity(value.get("entity_id")) or not value.get("combatant") is Dictionary or value.combatant.get("profile_id") != PROFILE_ID or not Combatant.valid(value.combatant, service.data.lookup(PROFILE_ID)):
		return ERR_INVALID_DATA
	return OK

func restore_state(value: Dictionary) -> void:
	service.restore_owned(state, value.entity_id, value.combatant)

func dispose() -> void:
	if capabilities != null:
		capabilities.detach("foundation.combatant")
	if state != null:
		service.unregister(state.entity_id)

func development_state() -> Dictionary:
	var modifiers := state.attributes.capture_modifiers()
	return {"health": state.health, "max_health": state.max_health(), "resource": state.resource, "max_resource": state.max_resource(), "resource_id": state.resource_id, "combat_state": Combatant.Lifecycle.keys()[state.lifecycle], "modifier_count": modifiers.size(), "modifier_ids": modifiers.map(func(value: Dictionary) -> String: return value.source_id)}
