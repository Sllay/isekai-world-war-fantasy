class_name P2ScenarioDriver
extends Node

# Full-runtime bot: only semantic intent and bound-session gateway commands may
# change gameplay. No canonical transform, health, inventory or clock writes.
var runtime: Node
var phase := "starting"
var result: Dictionary = {}
var proofs: Dictionary = {}
var _start_tick := 0
var _start_msec := 0

func _ready() -> void:
	name = "P2Scenario"
	_start_tick = runtime.core.clock.tick
	_start_msec = Time.get_ticks_msec()
	call_deferred("run")

func run() -> void:
	if not await _defeat_enemy(): return
	var drop_id := "drop.spawn.melee_skirmisher"
	phase = "pickup"
	if not runtime.items.drops.has(drop_id):
		fail("DEFEAT_DID_NOT_CREATE_DROP")
		return
	var drop: Dictionary = runtime.items.drops[drop_id]
	var contents: Array = runtime.items.inventory.entries(drop.container)
	proofs["drop_entries_before_pickup"] = contents.size()
	proofs["actual_stock_before_defeat"] = proofs.get("initial_carried_entries", [])
	proofs["drop_custody_before_pickup"] = contents.duplicate(true)
	proofs["death_stock_conserved"] = _stock_signature(contents) == _stock_signature(proofs.get("initial_carried_entries", []))
	var location := Vector3(drop.position[0], drop.position[1], drop.position[2])
	if not await _move_to(location, 1.8): return
	if not await _command("item.pickup", {"drop": drop_id}, func() -> bool: return runtime.items.drops[drop_id].claimed): return
	proofs["drop_claimed"] = runtime.items.drops[drop_id].claimed and runtime.items.inventory.entries(drop.container).is_empty()
	proofs["npc_carried_empty"] = runtime.items.inventory.entries(ItemsModule.npc_container(EnemyModule.SPAWN)).is_empty()
	phase = "equip_axe"
	if not await _equip("tool", "item.tool.axe"): return
	var tree := "resource.node.common_tree"
	if not await _move_to(runtime.items.content.node(tree).position, 1.4): return
	for _gather in range(3):
		if not await _harvest(tree): return
	proofs["tree_depleted"] = runtime.items.resources.capture().nodes[tree].remaining == 0
	proofs["wood_gathered"] = runtime.items.inventory.quantity(ItemsModule.BAG, "item.wood.common")
	phase = "equip_pickaxe"
	if not await _equip("tool", "item.tool.pickaxe"): return
	for node_id in ["resource.node.stone", "resource.node.iron_ore"]:
		if not await _move_to(runtime.items.content.node(node_id).position, 1.4): return
		if not await _harvest(node_id): return
	phase = "craft_balm"
	if not await _craft("recipe.healing_balm", "item.consumable.healing_balm", ""): return
	if not await _move_to(ItemsModule.FORGE_POSITION, 1.4): return
	phase = "smelt_ore"
	if not await _craft("recipe.iron_ingot", "item.component.iron_ingot", ItemsModule.FORGE): return
	phase = "craft_sword"
	if not await _craft("recipe.tempered_sword", "item.weapon.tempered_sword", ItemsModule.FORGE, {"ingredient.wood": "item.wood.common"}): return
	var weapon := _entry("item.weapon.tempered_sword")
	proofs["crafted_composition"] = weapon.get("composition", {}).duplicate(true)
	proofs["material_preserved"] = weapon.get("composition", {}).get("ingredient.wood") == "material.wood.common"
	phase = "consume"
	var balm: Dictionary = {}
	for entry: Dictionary in runtime.items.inventory.entries(ItemsModule.BAG):
		if entry.definition_id == "item.consumable.healing_balm" and entry.provenance.get("source") == "craft":
			balm = entry
			break
	if balm.is_empty():
		fail("BALM_MISSING")
		return
	var health_before: int = runtime.player_combat.state.health
	var balm_before: int = runtime.items.inventory.quantity(ItemsModule.BAG, "item.consumable.healing_balm")
	if not await _command("item.consume", {"entry": balm.id}, func() -> bool: return runtime.items.inventory.quantity(ItemsModule.BAG, "item.consumable.healing_balm") == balm_before - 1, "combat.action.consume"): return
	proofs["health_before_consume"] = health_before
	proofs["health_after_consume"] = runtime.player_combat.state.health
	proofs["healing_applied"] = runtime.player_combat.state.health > health_before
	phase = "equip_crafted_weapon"
	if not await _equip("weapon", "item.weapon.tempered_sword"): return
	proofs["crafted_weapon_equipped"] = _equipped("weapon", weapon.id)
	if not await _wait_idle(): return
	# Let physical deceleration settle through normal host movement before save.
	for _frame in range(8):
		runtime.world_scene.active_region.avatar.intent.movement = Vector2.ZERO
		await get_tree().physics_frame
	proofs["enemy_defeated"] = runtime.enemies.actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED
	proofs["ticks"] = runtime.core.clock.tick - _start_tick
	var passed: bool = proofs.get("received_damage", false) and proofs.get("death_stock_conserved", false) and proofs.get("drop_claimed", false) and proofs.get("npc_carried_empty", false) and proofs.get("tree_depleted", false) and proofs.get("material_preserved", false) and proofs.get("healing_applied", false) and proofs.get("crafted_weapon_equipped", false)
	if not passed:
		fail("SCENARIO_INVARIANT_FAILED")
		return
	phase = "checkpoint"
	result = runtime.checkpoint_scenario(proofs)
	phase = "checkpoint_saved" if result.get("passed", false) else "failed"

func _defeat_enemy() -> bool:
	phase = "combat"
	var target: EnemyActor = runtime.enemies.actor
	proofs["initial_carried_entries"] = runtime.items.inventory.entries(ItemsModule.npc_container(EnemyModule.SPAWN))
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	var deadline: int = runtime.core.clock.tick + 600
	while target.combatant.lifecycle == Combatant.Lifecycle.ALIVE:
		if not _healthy(deadline): return false
		var toward: Vector3 = target.position - runtime.player.state.position
		toward.y = 0
		avatar.intent.target_entity_id = target.entity_id
		avatar.intent.aim_direction = toward.normalized() if toward.length_squared() > 0.001 else Vector3.FORWARD
		avatar.intent.guard = false
		avatar.intent.movement = _movement(toward.normalized()) if toward.length() > 1.8 else Vector2.ZERO
		if runtime.player_combat.state.health < runtime.player_combat.state.max_health():
			proofs["received_damage"] = true
		if proofs.get("received_damage", false) and toward.length() <= 2.25:
			var executor: ActionExecutor = runtime.player_combat.actions
			if executor.remaining_cooldown("combat.action.strong_strike") == 0 and executor.phase in [ActionExecutor.Phase.IDLE, ActionExecutor.Phase.CANCELLED]:
				avatar.intent.request_skill(1)
			else:
				avatar.intent.primary_action = true
		await get_tree().physics_frame
	avatar.intent.clear_transient()
	proofs["health_after_combat"] = runtime.player_combat.state.health
	return await _wait_idle()

func _move_to(destination: Vector3, radius: float) -> bool:
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	var deadline: int = runtime.core.clock.tick + 240
	while true:
		if not _healthy(deadline): return false
		var delta: Vector3 = destination - runtime.player.state.position
		delta.y = 0
		if delta.length() <= radius:
			avatar.intent.movement = Vector2.ZERO
			# One extra physics frame lets the next semantic action see stop input.
			await get_tree().physics_frame
			return true
		avatar.intent.movement = _movement(delta.normalized())
		await get_tree().physics_frame
	return false

func _movement(direction: Vector3) -> Vector2:
	var yaw: float = runtime.world_scene.active_region.avatar.orbit.yaw
	var local := direction.rotated(Vector3.UP, -yaw)
	return Vector2(local.x, local.z)

func _harvest(node_id: String) -> bool:
	phase = "harvest:" + node_id
	var before: int = runtime.items.resources.capture().nodes[node_id].remaining
	var profile: String = runtime.items.content.node(node_id).profile_id
	return await _command("item.harvest", {"node": node_id}, func() -> bool: return runtime.items.resources.capture().nodes[node_id].remaining == before - 1, ItemsModule.harvest_action(profile))

func _craft(recipe_id: String, definition_id: String, station_id: String, choices: Dictionary = {}) -> bool:
	var before: int = runtime.items.inventory.quantity(ItemsModule.BAG, definition_id)
	var payload := {"recipe": recipe_id, "station": station_id, "choices": choices}
	return await _command("item.craft", payload, func() -> bool: return runtime.items.inventory.quantity(ItemsModule.BAG, definition_id) == before + 1, ItemsModule.craft_action(recipe_id))

func _equip(slot: String, definition_id: String) -> bool:
	var entry := _entry(definition_id)
	if entry.is_empty():
		fail("EQUIPMENT_MISSING:" + definition_id)
		return false
	return await _command("item.equip", {"slot": slot, "entry": entry.id}, func() -> bool: return _equipped(slot, entry.id))

func _equipped(slot: String, entry_id: String) -> bool:
	return runtime.items.equipment.capture().slots.get(slot, {}).get("entry_id") == entry_id

func _entry(definition_id: String) -> Dictionary:
	for entry: Dictionary in runtime.items.inventory.entries(ItemsModule.BAG):
		if entry.definition_id == definition_id:
			return entry
	return {}

func _stock_signature(entries: Array) -> Dictionary:
	var result_value: Dictionary = {}
	for entry: Dictionary in entries:
		var copy := entry.duplicate(true)
		copy.erase("container_id")
		result_value[entry.id] = copy
	return result_value

func _command(kind: String, payload: Dictionary, committed: Callable, action_id: String = "") -> bool:
	if not await _wait_idle(action_id): return false
	var queued: Dictionary = runtime.authority_gateway.request(kind, payload)
	if not queued.get("accepted", false):
		fail("INGRESS_REJECTED:" + kind, queued)
		return false
	var deadline: int = runtime.core.clock.tick + 160
	while true:
		await get_tree().physics_frame
		if not _healthy(deadline): return false
		var snapshot: Dictionary = runtime.authority_gateway.snapshot()
		if snapshot.get("ack", 0) >= queued.sequence and committed.call():
			return await _wait_idle()
	return false

func _wait_idle(action_id: String = "") -> bool:
	var deadline: int = runtime.core.clock.tick + 160
	while true:
		if not _healthy(deadline): return false
		var executor: ActionExecutor = runtime.player_combat.actions
		if executor.phase in [ActionExecutor.Phase.IDLE, ActionExecutor.Phase.CANCELLED] and (action_id.is_empty() or executor.remaining_cooldown(action_id) == 0) and runtime.authority_host.can_act(runtime.player.state.entity_id):
			return true
		await get_tree().physics_frame
	return false

func _healthy(deadline: int) -> bool:
	if not result.is_empty(): return false
	if runtime.player_combat.state.lifecycle != Combatant.Lifecycle.ALIVE:
		fail("PLAYER_DEFEATED")
		return false
	if runtime.core.clock.tick > deadline or runtime.core.clock.tick - _start_tick > 2400 or Time.get_ticks_msec() - _start_msec > 120000:
		fail("SCENARIO_TIMEOUT", {"host_result": runtime.authority_host.last_result, "items_result": runtime.items.last_result, "action": runtime.player_combat.actions.development_state(), "position": runtime.player.state.capture().position})
		return false
	return true

func fail(reason: String, detail: Dictionary = {}) -> void:
	result = {"passed": false, "phase": phase, "reason": reason, "detail": detail, "proofs": proofs}
	runtime.freeze_scenario()

func _mcp_state() -> Dictionary:
	return {"phase": phase, "result": result, "elapsed_ticks": runtime.core.clock.tick - _start_tick, "proofs": proofs}
