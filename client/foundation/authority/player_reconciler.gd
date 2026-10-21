class_name PlayerReconciler
extends RefCounted

# Snapshot correction applies only to a presentation/prediction mirror, never
# canonical host state. No pending-input replay is claimed in A1.
var last_tick := -1
var acknowledged_sequence := 0

func apply(mirror: PlayerState, snapshot: Dictionary) -> bool:
	if not CombatNumbers.integer(snapshot.get("tick"), 0, 9007199254740991) or not CombatNumbers.integer(snapshot.get("ack"), 0, 9007199254740991) or snapshot.tick < last_tick or snapshot.ack < acknowledged_sequence or not snapshot.get("player") is Dictionary or not PlayerState.valid(snapshot.player) or snapshot.player.entity_id != mirror.entity_id:
		return false
	mirror.restore(snapshot.player)
	last_tick = int(snapshot.tick)
	acknowledged_sequence = int(snapshot.ack)
	return true
