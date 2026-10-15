class_name RegionActorState
extends RefCounted

# Region-owned persistence port. Feature owners implement value validation and
# capability rebinding; World knows no combat/AI schema or presentation Nodes.
func capture() -> Dictionary:
	return {}
func valid(_value: Dictionary) -> bool:
	return false
func restore(_value: Dictionary) -> void:
	pass

func residency_lost() -> void:
	pass
