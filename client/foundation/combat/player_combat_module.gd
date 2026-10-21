class_name PlayerCombatModule
extends CoreModule

const PROFILE_ID := "combat.profile.standard"
var actions: ActionExecutor
var state: Combatant
var service: CombatService
var player: PlayerState
var capabilities: EntityComponents
var defense: CombatDefense
var restored_defense := {"dodge_ready": 0, "stagger_ready": 0}

func _init() -> void:
	id = "foundation.player_combat"
	requires.assign(["core.runtime", "foundation.player", "foundation.combat"])
	persistent = true
	state_version = 3

func initialize(services: CoreServices) -> Error:
	service = services.resolve("foundation.combat") as CombatService
	player = services.resolve("foundation.player") as PlayerState
	capabilities = services.resolve("foundation.player_capabilities") as EntityComponents
	if service == null or player == null or capabilities == null:
		return ERR_UNCONFIGURED
	state = service.register(player.entity_id, PROFILE_ID)
	if state == null:
		return ERR_INVALID_DATA
	actions = ActionExecutor.new(service, services.resolve("foundation.actions") as ActionCatalog, player.entity_id)
	var error := capabilities.attach("foundation.actions", actions)
	return capabilities.attach("foundation.combatant", state) if error == OK else error

func initial_state(entity_id: String) -> Dictionary:
	return {"entity_id": entity_id, "combatant": Combatant.new(entity_id, service.data.lookup(PROFILE_ID)).capture(), "actions": {"cooldowns": {}}, "defense": {"dodge_ready": 0, "stagger_ready": 0}}

func capture_state() -> Dictionary:
	return {"entity_id": state.entity_id, "combatant": state.capture(), "actions": actions.capture(), "defense": defense.capture(state.entity_id) if defense != null else restored_defense.duplicate()}

func validate_state(value: Dictionary) -> Error:
	if not CombatNumbers.stable_entity(value.get("entity_id")) or not value.get("combatant") is Dictionary or value.combatant.get("profile_id") != PROFILE_ID or not Combatant.valid(value.combatant, service.data.lookup(PROFILE_ID)):
		return ERR_INVALID_DATA
	if not value.get("actions") is Dictionary or not actions.valid_snapshot(value.actions):
		return ERR_INVALID_DATA
	if not CombatDefense.valid_snapshot(value.get("defense")):
		return ERR_INVALID_DATA
	return OK

func restore_state(value: Dictionary) -> void:
	service.restore_owned(state, value.entity_id, value.combatant)
	actions.owner_id = value.entity_id
	actions.restore(value.actions)
	restored_defense = value.defense.duplicate()
	if defense != null:
		defense.restore(state.entity_id, restored_defense)

func dispose() -> void:
	defense = null
	if capabilities != null:
		capabilities.detach("foundation.combatant")
		capabilities.detach("foundation.actions")
	if state != null:
		service.unregister(state.entity_id)

func development_state() -> Dictionary:
	var modifiers := state.attributes.capture_modifiers()
	return {"health": state.health, "max_health": state.max_health(), "resource": state.resource, "max_resource": state.max_resource(), "resource_id": state.resource_id, "combat_state": Combatant.Lifecycle.keys()[state.lifecycle], "modifier_count": modifiers.size(), "modifier_ids": modifiers.map(func(value: Dictionary) -> String: return value.source_id)}

# Slice 1 never had actions/cooldowns. Only its explicit section v1 migrates.
func migrate_state(from_version: int, value: Dictionary) -> Variant:
	if from_version == 2:
		if value.has("defense"): return null
		var upgraded := value.duplicate(true)
		upgraded["defense"] = {"dodge_ready": 0, "stagger_ready": 0}
		return upgraded
	if from_version != 1 or value.has("actions"):
		return null
	var result := value.duplicate(true)
	result["actions"] = {"cooldowns": {}}
	return result
