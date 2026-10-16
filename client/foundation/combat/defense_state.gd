class_name DefenseState
extends RefCounted

# All active state is transient. Cooldowns belong to the owner's ActionExecutor.
var guard := false
var dodge_until := 0
var parry_until := 0
var last_result := "HIT"
var last_prevented := 0
var last_applied := 0
var policy: DefensePolicy

func clear() -> void:
	guard = false
	dodge_until = 0
	parry_until = 0

func development_state(tick: int) -> Dictionary:
	return {"guard": guard, "dodge_ticks": maxi(0, dodge_until - tick), "parry_ticks": maxi(0, parry_until - tick), "last_result": last_result, "prevented": last_prevented, "applied": last_applied}
