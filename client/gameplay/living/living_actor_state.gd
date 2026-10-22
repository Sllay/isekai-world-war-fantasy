class_name LivingActorState
extends RefCounted

enum Fidelity { L0, L1, L2, L3 }
var player_state := PlayerState.new()
var actor_id: String:
	get: return player_state.entity_id
	set(value): player_state.entity_id = value
var position: Vector3:
	get: return player_state.position
	set(value): player_state.position = value
var facing: Vector3:
	get: return player_state.facing
	set(value): player_state.facing = value
var kind := "npc"
var world_id := "world.primary"
var region_id := "region.home_valley"
var chunk_id := ""
var race_id := "race.human"
var class_id := "class.warrior"
var culture_id := "culture.crossing"
var origin_id := "origin.world_a"
var historical_faction_id := "faction.home_valley"
var allegiance := "faction.home_valley"
var profession_id := "profession.guard"
var inventory_id := ""
var equipment_id := ""
var home := Vector3.ZERO
var work := Vector3.ZERO
var attributes := RpgAttributes.new()
var memory := LivingMemory.new()
var progression := LivingProgression.new()
var relationships: Dictionary = {}
var needs := {"safety": 100, "rest": 0, "duty": 70}
var activity: Dictionary = {}
var fidelity: Fidelity = Fidelity.L2
var materialization_epoch := 0
var revision := 0
# Cached plan is reconstructible and intentionally absent from saves.
var plan: Dictionary = {}
var plan_dirty := true

func configure(id: String, family: String, catalog: LivingCatalog) -> Error:
	if not CombatNumbers.stable_entity(id) or family not in ["npc", "bot", "player"] or catalog == null or not catalog.valid(): return ERR_INVALID_DATA
	actor_id = id
	kind = family
	inventory_id = "inventory.actor.a" + id
	equipment_id = "equipment.actor.a" + id
	var race := catalog.race(race_id)
	var character_class := catalog.character_class(class_id)
	attributes.base = character_class.base_attributes.duplicate()
	attributes.install("rpg.source.race", race.attribute_modifiers)
	return OK

func begin_activity(activity_id: String, activity_kind: String, destination: Vector3, started_tick: int, finish_tick: int) -> Error:
	if not CoreIds.valid(activity_id) or activity_kind not in ["work", "travel", "shelter", "rest"] or not destination.is_finite() or started_tick < 0 or finish_tick <= started_tick or finish_tick > 9007199254740991: return ERR_INVALID_DATA
	activity = {"id": activity_id, "kind": activity_kind, "origin": _array(position), "destination": _array(destination), "started_tick": started_tick, "finish_tick": finish_tick, "completed": false}
	revision += 1
	plan_dirty = true
	return OK

# Only unmaterialized simulation settles a route analytically. L0 uses host ports.
func resolve_due(tick: int) -> bool:
	if activity.is_empty() or activity.completed or activity.finish_tick > tick or fidelity == Fidelity.L0: return false
	var point: Array = activity.destination
	position = Vector3(point[0], point[1], point[2])
	activity.completed = true
	revision += 1
	plan_dirty = true
	return true

func capture() -> Dictionary:
	return {"id": actor_id, "kind": kind, "movement": player_state.capture(), "world_id": world_id, "region_id": region_id, "chunk_id": chunk_id, "race_id": race_id, "class_id": class_id, "culture_id": culture_id, "origin_id": origin_id, "historical_faction_id": historical_faction_id, "allegiance": allegiance, "profession_id": profession_id, "inventory_id": inventory_id, "equipment_id": equipment_id, "home": _array(home), "work": _array(work), "attributes": attributes.capture(), "memory": memory.capture(), "progression": progression.capture(), "relationships": relationships.duplicate(true), "needs": needs.duplicate(), "activity": activity.duplicate(true), "fidelity": fidelity, "materialization_epoch": materialization_epoch, "revision": revision}

static func valid(state: Dictionary, catalog: LivingCatalog, known_actor: Callable, known_reward_source: Callable = Callable()) -> bool:
	var keys := ["id", "kind", "movement", "world_id", "region_id", "chunk_id", "race_id", "class_id", "culture_id", "origin_id", "historical_faction_id", "allegiance", "profession_id", "inventory_id", "equipment_id", "home", "work", "attributes", "memory", "progression", "relationships", "needs", "activity", "fidelity", "materialization_epoch", "revision"]
	if not InventoryService._keys(state, keys) or not CombatNumbers.stable_entity(state.id) or state.kind not in ["npc", "bot", "player"] or not state.movement is Dictionary or not PlayerState.valid(state.movement) or state.id != state.movement.entity_id: return false
	for key: String in ["world_id", "region_id", "race_id", "class_id", "culture_id", "origin_id", "historical_faction_id", "allegiance", "profession_id", "inventory_id", "equipment_id"]:
		if not state[key] is String or state[key].length() > 128 or not CoreIds.valid(state[key]): return false
	if not _chunk_address(state.chunk_id, state.region_id): return false
	var character_class := catalog.character_class(state.class_id)
	if catalog.race(state.race_id) == null or character_class == null or catalog.faction(state.allegiance) == null or catalog.faction(state.historical_faction_id) == null: return false
	for point: String in ["home", "work"]:
		if not _point(state[point]): return false
	if not state.attributes is Dictionary or not RpgAttributes.valid(state.attributes) or not state.memory is Dictionary or not LivingMemory.valid(state.memory, known_actor) or not state.progression is Dictionary or not LivingProgression.valid(state.progression, catalog.progression(character_class.progression_id), known_reward_source): return false
	if not state.relationships is Dictionary or state.relationships.size() > 16: return false
	for target: Variant in state.relationships:
		if not target is String or not CombatNumbers.stable_entity(target) or target == state.id or not known_actor.is_valid() or not bool(known_actor.call(target)) or not CombatNumbers.integer(state.relationships[target], -100, 100): return false
	if not state.needs is Dictionary or not InventoryService._keys(state.needs, ["safety", "rest", "duty"]): return false
	for key: String in state.needs:
		if not CombatNumbers.integer(state.needs[key], 0, 100): return false
	return _activity_valid(state.activity) and CombatNumbers.integer(state.fidelity, Fidelity.L0, Fidelity.L3) and CombatNumbers.integer(state.materialization_epoch, 0, CombatNumbers.MAX_UNITS) and CombatNumbers.integer(state.revision, 0, CombatNumbers.MAX_UNITS)

func restore(state: Dictionary, catalog: LivingCatalog, known_actor: Callable, known_reward_source: Callable = Callable()) -> Error:
	if not valid(state, catalog, known_actor, known_reward_source): return ERR_INVALID_DATA
	player_state.restore(state.movement)
	for key: String in ["kind", "world_id", "region_id", "chunk_id", "race_id", "class_id", "culture_id", "origin_id", "historical_faction_id", "allegiance", "profession_id", "inventory_id", "equipment_id"]: set(key, state[key])
	home = Vector3(state.home[0], state.home[1], state.home[2])
	work = Vector3(state.work[0], state.work[1], state.work[2])
	attributes.restore(state.attributes)
	memory.restore(state.memory, known_actor)
	progression.restore(state.progression, catalog.progression(catalog.character_class(class_id).progression_id), known_reward_source)
	relationships = state.relationships.duplicate(true)
	for key: String in needs: needs[key] = int(state.needs[key])
	activity = state.activity.duplicate(true)
	if not activity.is_empty():
		activity.started_tick = int(activity.started_tick)
		activity.finish_tick = int(activity.finish_tick)
		for key: String in ["origin", "destination"]:
			var point := Vector3(activity[key][0], activity[key][1], activity[key][2])
			activity[key] = _array(point)
	fidelity = int(state.fidelity) as Fidelity
	materialization_epoch = int(state.materialization_epoch)
	revision = int(state.revision)
	plan.clear()
	plan_dirty = true
	return OK

static func _point(value: Variant) -> bool:
	if not value is Array or value.size() != 3: return false
	for number: Variant in value:
		if not (number is float or number is int) or not is_finite(number) or absf(number) > 1000000: return false
	return true

static func _chunk_address(value: Variant, region: String) -> bool:
	if not value is String or value.length() > 160: return false
	var parts: PackedStringArray = value.split(":")
	if parts.size() != 3 or parts[0] != region or not parts[1].is_valid_int() or not parts[2].is_valid_int(): return false
	if abs(int(parts[1])) > 1000000 or abs(int(parts[2])) > 1000000: return false
	return value == WorldGenIds.chunk(region, Vector2i(int(parts[1]), int(parts[2])))

static func _activity_valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	if value.is_empty(): return true
	return InventoryService._keys(value, ["id", "kind", "origin", "destination", "started_tick", "finish_tick", "completed"]) and value.id is String and CoreIds.valid(value.id) and value.kind in ["work", "travel", "shelter", "rest"] and _point(value.origin) and _point(value.destination) and CombatNumbers.integer(value.started_tick, 0, 9007199254740991) and CombatNumbers.integer(value.finish_tick, 1, 9007199254740991) and value.finish_tick > value.started_tick and value.completed is bool

static func _array(value: Vector3) -> Array:
	return [value.x, value.y, value.z]
