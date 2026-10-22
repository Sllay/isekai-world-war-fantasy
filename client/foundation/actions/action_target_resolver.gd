class_name ActionTargetResolver
extends RefCounted

# Pure authority-side world query: (definition, owner ID, copied world hint) ->
# bounded Array of stable IDs. The world owns shapes/spatial indices, not Actions.
# No query means directional/point actions fail closed. Clients cannot set ports.
var world_query: Callable

func resolve(definition: ActionDefinition, owner: String, hint: ActionTarget, combat: CombatService, position_of: Callable, visible: Callable, capabilities: ActionCapabilityPort = null) -> Dictionary:
	if not hint.direction.is_finite() or not hint.point.is_finite():
		return _failure("INVALID_AIM")
	var chosen: Array[String] = []
	match definition.target_mode:
		ActionDefinition.TargetMode.SELF:
			chosen.append(owner)
		ActionDefinition.TargetMode.ENTITY:
			chosen.append(hint.entity_id)
		ActionDefinition.TargetMode.DIRECTION, ActionDefinition.TargetMode.POINT:
			if not world_query.is_valid():
				return _failure("TARGET_QUERY_UNAVAILABLE")
			if definition.target_mode == ActionDefinition.TargetMode.DIRECTION and not is_equal_approx(hint.direction.length(), 1.0):
				return _failure("INVALID_AIM")
			var origin: Variant = position_of.call(owner) if position_of.is_valid() else null
			if not origin is Vector3 or not origin.is_finite():
				return _failure("POSITION_UNAVAILABLE")
			if definition.target_mode == ActionDefinition.TargetMode.POINT and origin.distance_squared_to(hint.point) > definition.max_range * definition.max_range:
				return _failure("OUT_OF_RANGE")
			var candidates: Variant = world_query.call(definition.duplicate(true), owner, hint.copy())
			if not candidates is Array or candidates.is_empty() or candidates.size() > definition.max_targets:
				return _failure("INVALID_TARGET_QUERY")
			for id: Variant in candidates:
				if not id is String or chosen.has(id):
					return _failure("INVALID_TARGET_QUERY")
				chosen.append(id)
			# Query iteration order must never change transaction/event order.
			chosen.sort()
		_:
			return _failure("INVALID_TARGET_MODE")
	for id: String in chosen:
		var target := combat.combatant(id)
		if target == null:
			return _failure("TARGET_UNAVAILABLE")
		if target.lifecycle != Combatant.Lifecycle.ALIVE:
			return _failure("TARGET_DEFEATED")
		if definition.target_mode != ActionDefinition.TargetMode.SELF:
			if not position_of.is_valid():
				return _failure("POSITION_UNAVAILABLE")
			var origin: Variant = position_of.call(owner)
			var destination: Variant = position_of.call(id)
			if not origin is Vector3 or not destination is Vector3 or not origin.is_finite() or not destination.is_finite():
				return _failure("POSITION_UNAVAILABLE")
			if origin.distance_squared_to(destination) > definition.max_range * definition.max_range:
				return _failure("OUT_OF_RANGE")
			if visible.is_valid() and not bool(visible.call(owner, id)):
				return _failure("TARGET_OCCLUDED")
		var code := ActionEffectRunner.validate(combat, definition, owner, id, capabilities)
		if code != "OK":
			return _failure(code)
	return {"code": "OK", "targets": chosen}

func _failure(code: String) -> Dictionary:
	return {"code": code, "targets": []}
