class_name LivingPerception
extends RefCounted

var spatial := ActorSpatialIndex.new()
var actors: Dictionary[String, LivingActorState] = {}
var events := 0
var memories_created := 0
var known_actor: Callable

# Hearing is a spatial gameplay event, independent of audio and camera visibility.
# The caller must be a trusted authority fact producer, never a client packet.
func hear(source: String, event_id: String, point: Vector3, radius: float, tick: int, category: String = "perception.threat") -> Array[String]:
	var observed: Array[String] = []
	if not CombatNumbers.stable_entity(source) or event_id.is_empty() or event_id.length() > 128 or not known_actor.is_valid() or not bool(known_actor.call(source)) or not CoreIds.valid(category) or tick < 0: return observed
	events += 1
	for id: String in spatial.nearby(point, radius, 16):
		if id == source or not actors.has(id): continue
		var actor := actors[id]
		if actor.fidelity > LivingActorState.Fidelity.L1: continue
		var record := {"id": "memory.e" + (event_id + ":" + id).sha256_text().substr(0, 24), "kind": category, "subject_id": source, "position": [point.x, point.y, point.z], "created_tick": tick, "importance": 90 if category == "perception.threat" else 40, "confidence": 90, "expires_tick": -1 if category == "perception.threat" else tick + 600, "source": "knowledge.source.hearing", "anchor": category == "perception.threat"}
		if actor.memory.remember(record, tick, known_actor) == "REMEMBERED":
			actor.plan_dirty = true
			actor.revision += 1
			memories_created += 1
			observed.append(id)
	return observed
