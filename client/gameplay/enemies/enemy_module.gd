class_name EnemyModule
extends CoreModule

var relevant: Callable

const ARCHETYPE = preload("res://gameplay/enemies/melee_skirmisher.tres")
const SPAWN := "spawn.melee_skirmisher"
var companions: Array[EnemyActor] = []
var companion_controllers: Array[EnemyController] = []
var companion_initial: Dictionary = {}
var _companion_registered: Array[String] = []
var actor := EnemyActor.new()
var controller := EnemyController.new()
var targeting: TargetingService
var disposition: DispositionPolicy
var initial_state: Dictionary
var _defeat_token := 0
var _registered_id := ""
var directory: RegionDirectory
var combat: CombatService
var record: RegionState

func _init() -> void:
	id = "gameplay.enemies"
	requires.assign(["foundation.regions", "foundation.combat", "foundation.targeting"])
	consumed_events.assign(["combat.combatant_defeated"])
	data_ids.assign([ARCHETYPE.archetype_id])

func initialize(services: CoreServices) -> Error:
	targeting = services.resolve("foundation.targeting") as TargetingService
	disposition = targeting.disposition
	combat = services.resolve("foundation.combat") as CombatService
	directory = services.resolve("foundation.regions") as RegionDirectory
	var catalog := services.resolve("foundation.actions") as ActionCatalog
	if not ARCHETYPE.valid(catalog):
		return ERR_INVALID_DATA
	if combat.data.define_family("enemy.archetype", _valid_metadata) != OK or combat.data.register(ARCHETYPE.archetype_id, "enemy.archetype", {"id": ARCHETYPE.archetype_id}) != OK:
		return ERR_INVALID_DATA
	record = directory.record("region.home_valley")
	if record == null or not record.definition.actor_spawns.has(SPAWN):
		return ERR_INVALID_DATA
	actor.entity_id = combat.entities.create()
	actor.archetype = ARCHETYPE
	actor.region_id = record.definition.region_id
	actor.home = record.definition.to_world_position(record.definition.actor_spawns[SPAWN])
	actor.position = actor.home
	actor.combatant = combat.register(actor.entity_id, ARCHETYPE.profile_id)
	actor.actions = ActionExecutor.new(combat, catalog, actor.entity_id)
	actor.capabilities = EntityComponents.new(actor.entity_id)
	actor.capabilities.attach("foundation.combatant", actor.combatant)
	actor.capabilities.attach("foundation.actions", actor.actions)
	var location := PlayerLocation.new()
	location.world_id = directory.world.world_id
	location.region_id = actor.region_id
	actor.capabilities.attach("foundation.location", location)
	record.actors[SPAWN] = actor
	targeting.combat = combat
	controller.actor = actor
	controller.targeting = targeting
	initial_state = actor.capture()
	_spawn_companion(catalog)
	_defeat_token = combat.events.subscribe(CombatantDefeated, _defeated)
	return OK

func bind_residency() -> void:
	if not _registered_id.is_empty():
		targeting.unregister(_registered_id)
		disposition.groups.erase(_registered_id)
	controller.reset()
	if record.lifecycle != RegionState.Lifecycle.LOADED:
		return
	disposition.groups[actor.entity_id] = "disposition.hostile"
	targeting.register(actor.entity_id, func() -> Variant:
		if record.lifecycle != RegionState.Lifecycle.LOADED: return null
		return actor.position)
	_registered_id = actor.entity_id
	actor.actions.position_of = targeting.position_of
	for old_id in _companion_registered:
		targeting.unregister(old_id)
		disposition.groups.erase(old_id)
	_companion_registered.clear()
	for extra in companions:
		disposition.groups[extra.entity_id] = "disposition.hostile"
		targeting.register(extra.entity_id, func() -> Variant:
			if record.lifecycle != RegionState.Lifecycle.LOADED: return null
			return extra.position)
		extra.actions.position_of = targeting.position_of
		_companion_registered.append(extra.entity_id)
	for ai in companion_controllers:
		ai.reset()

func tick() -> void:
	if record.lifecycle == RegionState.Lifecycle.LOADED:
		if not relevant.is_valid() or bool(relevant.call(actor)): controller.tick()
		for ai in companion_controllers:
			if not relevant.is_valid() or bool(relevant.call(ai.actor)): ai.tick()
	else:
		targeting.unregister(actor.entity_id)

func dispose() -> void:
	relevant = Callable()
	if combat == null:
		return
	combat.events.unsubscribe(_defeat_token)
	for extra in companions:
		targeting.unregister(extra.entity_id)
		disposition.groups.erase(extra.entity_id)
		combat.unregister(extra.entity_id)
		record.actors.erase("spawn.melee_skirmisher_second")
	companions.clear()
	companion_controllers.clear()
	targeting.unregister(actor.entity_id)
	disposition.groups.erase(actor.entity_id)
	controller.move_toward = Callable()
	if actor.actions != null:
		actor.actions.position_of = Callable()
	combat.unregister(actor.entity_id)
	if record != null:
		record.actors.erase(SPAWN)

static func _valid_metadata(value: Dictionary) -> Error:
	return OK if value.get("id") is String and value.id.begins_with("enemy.archetype.") and CoreIds.valid(value.id) else ERR_INVALID_DATA

func _defeated(event: CombatantDefeated) -> void:
	for ai in companion_controllers:
		if ai.actor.entity_id == event.target_entity:
			ai.state = EnemyController.State.DEFEATED
			ai.target_id = ""
			ai.actor.actions.advance()
	if event.target_entity == actor.entity_id:
		controller.state = EnemyController.State.DEFEATED
		controller.target_id = ""
		actor.actions.advance()

func _spawn_companion(catalog: ActionCatalog) -> void:
	const KEY := "spawn.melee_skirmisher_second"
	if not record.definition.actor_spawns.has(KEY):
		return
	var extra := EnemyActor.new()
	extra.entity_id = combat.entities.create()
	extra.archetype = ARCHETYPE
	extra.region_id = record.definition.region_id
	extra.home = record.definition.to_world_position(record.definition.actor_spawns[KEY])
	extra.position = extra.home
	extra.combatant = combat.register(extra.entity_id, ARCHETYPE.profile_id)
	extra.actions = ActionExecutor.new(combat, catalog, extra.entity_id)
	extra.capabilities = EntityComponents.new(extra.entity_id)
	extra.capabilities.attach("foundation.combatant", extra.combatant)
	extra.capabilities.attach("foundation.actions", extra.actions)
	var location := PlayerLocation.new()
	location.world_id = directory.world.world_id
	location.region_id = extra.region_id
	extra.capabilities.attach("foundation.location", location)
	var ai := EnemyController.new()
	ai.actor = extra
	ai.targeting = targeting
	companions.append(extra)
	companion_controllers.append(ai)
	record.actors[KEY] = extra
	companion_initial[KEY] = extra.capture()
