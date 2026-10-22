class_name LivingModule
extends CoreModule

var catalog := LivingCatalog.defaults()
var actors: Dictionary[String, LivingCapabilities] = {}
var player_identity := LivingActorState.new()
var combat: CombatService
var action_catalog: ActionCatalog
var entities: CoreEntityIds
var items: ItemsModule
var world: WorldState
var regions: RegionDirectory
var scheduler := LivingScheduler.new()
var perception := LivingPerception.new()
var decisions := LivingDecisionModel.new()
var paths := LivingPathQueue.new()
var revision := 0
var rewards := 0
var _tokens: Array[int] = []
var _validated_actors: Dictionary = {}
var validation_cache_hits := 0
var validation_cache_misses := 0

func _init() -> void:
	id = "gameplay.living"
	requires.assign(["core.runtime", "foundation.combat", "foundation.player", "foundation.world", "foundation.regions", "gameplay.items_resources", "foundation.world_genesis"])
	persistent = true
	consumed_events.assign(["combat.combatant_defeated", "items.work_committed", "combat.action_started"])

func initialize(services: CoreServices) -> Error:
	combat = services.resolve("foundation.combat") as CombatService
	action_catalog = services.resolve("foundation.actions") as ActionCatalog
	entities = services.resolve("core.entities") as CoreEntityIds
	world = services.resolve("foundation.world") as WorldState
	regions = services.resolve("foundation.regions") as RegionDirectory
	var player := services.resolve("foundation.player") as PlayerState
	if combat == null or entities == null or not catalog.valid(): return ERR_INVALID_DATA
	player_identity.configure(player.entity_id, "player", catalog)
	player_identity.player_state = player
	_tokens.append(combat.events.subscribe(CombatantDefeated, _defeated))
	_tokens.append(combat.events.subscribe(ItemWorkCommitted, _work))
	_tokens.append(combat.events.subscribe(ActionStarted, _heard_action))
	perception.known_actor = entities.contains
	return OK

func bind(domain: ItemsModule) -> void:
	items = domain
	player_identity.inventory_id = ItemsModule.BAG
	player_identity.equipment_id = "equipment.player"

func seed_chunk(record: Dictionary) -> Array[String]:
	var created: Array[String] = []
	for spawn: Dictionary in record.base.spawns:
		if actors.has(spawn.actor_id): continue
		if record.delta.spawn_claims.has(spawn.spawn_id): continue # Integrity rejects missing claimed actors.
		if actors.size() >= LivingScheduler.MAX_ACTORS: break
		if entities.register(spawn.actor_id) != OK: continue
		var actor := LivingActorState.new()
		actor.configure(spawn.actor_id, "bot" if spawn.profile_id == "spawn.profile.traveler_bot" else "npc", catalog)
		actor.world_id = world.world_id
		actor.region_id = spawn.region_id
		actor.chunk_id = record.chunk_id
		actor.position = Vector3(spawn.position_mm[0], spawn.position_mm[1], spawn.position_mm[2]) / 1000.0 + Vector3(0, 0.1, 0)
		actor.home = actor.position
		actor.work = actor.position + Vector3(-3, 0, 0)
		actor.begin_activity("activity.initial_work", "work", actor.work, combat.clock.tick, combat.clock.tick + 100)
		var bundle := LivingCapabilities.new()
		bundle.configure(actor, combat, action_catalog, items.catalog, items.content, items.resources, catalog.character_class(actor.class_id))
		bundle.seed_stock()
		actors[actor.actor_id] = bundle
		scheduler.register(actor, combat.clock.tick)
		perception.actors[actor.actor_id] = actor
		created.append(spawn.spawn_id)
	if not created.is_empty(): revision += 1
	return created

func capture_state() -> Dictionary:
	var values := {}
	for key: String in actors:
		values[key] = actors[key].capture()
		var actor := actors[key].state
		var region := regions.record(actor.region_id).definition
		values[key].state.chunk_id = region.chunk_id(region.to_local_position(actor.position))
	return {"player": capture_player(), "actors": values, "revision": revision}

func capture_player() -> Dictionary:
	return _player_data(player_identity)

func initial_state(owner: String) -> Dictionary:
	var actor := LivingActorState.new()
	actor.configure(owner, "player", catalog)
	return {"player": _player_data(actor), "actors": {}, "revision": 0}

static func _player_data(p: LivingActorState) -> Dictionary:
	return {"id": p.actor_id, "race_id": p.race_id, "class_id": p.class_id, "culture_id": p.culture_id, "origin_id": p.origin_id, "historical_faction_id": p.historical_faction_id, "allegiance": p.allegiance, "attributes": p.attributes.capture(), "progression": p.progression.capture()}

func validate_state(value: Dictionary) -> Error:
	if not InventoryService._keys(value, ["player", "actors", "revision"]) or not value.player is Dictionary or not value.actors is Dictionary or value.actors.size() > LivingScheduler.MAX_ACTORS or not CombatNumbers.integer(value.revision, 0, CombatNumbers.MAX_UNITS): return ERR_INVALID_DATA
	if not valid_player(value.player): return ERR_INVALID_DATA
	# Foreign references are checked again against the detached full snapshot by
	# SaveIntegrity; this module validator never consults stale live identities.
	var known := func(id_value: String) -> bool: return CombatNumbers.stable_entity(id_value)
	var source := func(id_value: String) -> bool: return CombatNumbers.stable_entity(id_value) or CoreIds.valid(id_value)
	# Reuse the prepared immutable catalog across this bounded checkpoint. Loading
	# and duplicating every item definition once per actor adds no validation.
	var item_catalog: ItemCatalog = items.catalog if items != null else ItemCatalog.defaults()
	for key: Variant in value.actors:
		if not key is String or not value.actors[key] is Dictionary or not value.actors[key].get("state") is Dictionary or value.actors[key].state.get("id") != key: return ERR_INVALID_DATA
		if value.actors[key] == _validated_actors.get(key):
			validation_cache_hits += 1
			continue
		validation_cache_misses += 1
		if not LivingCapabilities.valid(value.actors[key], catalog, item_catalog, action_catalog, combat, known, source): return ERR_INVALID_DATA
		_validated_actors[key] = value.actors[key].duplicate(true)
	for key: String in _validated_actors.keys():
		if not value.actors.has(key): _validated_actors.erase(key)
	return OK

func valid_player(value: Dictionary) -> bool:
	if not InventoryService._keys(value, ["id", "race_id", "class_id", "culture_id", "origin_id", "historical_faction_id", "allegiance", "attributes", "progression"]) or not CombatNumbers.stable_entity(value.id): return false
	for key in ["culture_id", "origin_id"]:
		if not value[key] is String or not CoreIds.valid(value[key]): return false
	if not value.get("race_id") is String or not value.get("class_id") is String or catalog.race(value.race_id) == null or catalog.character_class(value.class_id) == null or not value.get("historical_faction_id") is String or not value.get("allegiance") is String or catalog.faction(value.historical_faction_id) == null or catalog.faction(value.allegiance) == null: return false
	return value.attributes is Dictionary and RpgAttributes.valid(value.attributes) and value.progression is Dictionary and LivingProgression.valid(value.progression, catalog.progression(catalog.character_class(value.class_id).progression_id))

func restore_state(value: Dictionary) -> void:
	_validated_actors.clear()
	for key: String in actors:
		actors[key].dispose()
		combat.unregister(key)
	actors.clear()
	scheduler = LivingScheduler.new()
	perception.actors.clear()
	perception.spatial = ActorSpatialIndex.new()
	var p: Dictionary = value.player
	for key in ["race_id", "class_id", "culture_id", "origin_id", "historical_faction_id", "allegiance"]: player_identity.set(key, p[key])
	player_identity.attributes.restore(p.attributes)
	player_identity.progression.restore(p.progression, catalog.progression(catalog.character_class(p.class_id).progression_id))
	var known := func(actor_id: String) -> bool: return entities.contains(actor_id)
	for key: String in value.actors:
		var actor := LivingActorState.new()
		actor.configure(key, value.actors[key].state.kind, catalog)
		var bundle := LivingCapabilities.new()
		bundle.configure(actor, combat, action_catalog, items.catalog, items.content, items.resources, catalog.character_class(actor.class_id))
		bundle.restore(value.actors[key], catalog, known, Callable())
		actors[key] = bundle
		scheduler.register(actor, combat.clock.tick)
		perception.actors[key] = actor
	revision = int(value.revision)

func award(actor_id: String, cause: String, source: String, sequence: int) -> Dictionary:
	var actor := player_identity if actor_id == player_identity.actor_id else (actors[actor_id].state if actors.has(actor_id) else null)
	if actor == null: return {"accepted": false, "code": "UNKNOWN_ACTOR"}
	var result := actor.progression.award(cause, source, sequence, catalog.progression(catalog.character_class(actor.class_id).progression_id))
	if result.accepted: revision += 1; rewards += 1
	return result

func _defeated(fact: CombatantDefeated) -> void:
	award(fact.source_entity, "combat.defeat", fact.target_entity, 1)
	if actors.has(fact.target_entity):
		var bundle := actors[fact.target_entity]
		bundle.actions.interrupt()
		bundle.state.player_state.velocity = Vector3.ZERO
		bundle.state.activity.clear()
		bundle.state.plan.clear()
		bundle.state.plan_dirty = true
		bundle.state.revision += 1
		revision += 1

func _work(fact: ItemWorkCommitted) -> void:
	award(fact.actor_id, fact.cause, fact.subject_id, fact.sequence)
	if fact.cause != "resource.harvest": return
	var resources: ResourceService = items.resources
	var node := resources.definition(fact.subject_id)
	if node == null: return
	# Valid harvesting is a local, non-threatening world event. Knowledge comes
	# from hearing the committed work, never from an existing visual Node.
	for observer in perception.hear(fact.actor_id, fact.event_id, node.position, 18.0, fact.tick, "perception.resource"):
		scheduler.wake(observer, fact.tick)

func _heard_action(fact: ActionStarted) -> void:
	var definition := action_catalog.lookup(fact.action_id)
	if definition == null or not definition.effects.any(func(effect: ActionEffect) -> bool: return effect.kind == ActionEffect.Kind.DAMAGE): return
	var point := Vector3.ZERO
	if fact.owner_id == player_identity.actor_id: point = player_identity.position
	elif actors.has(fact.owner_id): point = actors[fact.owner_id].state.position
	else: return
	for observer in perception.hear(fact.owner_id, fact.execution_id, point, 12.0, fact.tick): scheduler.wake(observer, fact.tick)

func dispose() -> void:
	_validated_actors.clear()
	for token in _tokens: combat.events.unsubscribe(token)
	_tokens.clear()
	perception.known_actor = Callable()
	scheduler.decision_port = Callable()
	for bundle in actors.values(): bundle.dispose()
	actors.clear()
