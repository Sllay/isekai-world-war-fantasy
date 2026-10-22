class_name ItemsAuthorityPort
extends AuthorityCommandPort

const KINDS: Array[String] = ["item.pickup", "item.equip", "item.unequip", "item.split", "item.merge", "item.move", "item.harvest", "item.craft", "item.consume", "skill.equip"]
var host: LocalAuthorityHost
var items: ItemsModule
var spatial_gate: Callable
var region_id: Callable
var pending: Dictionary = {}
var effects := ItemsActionPort.new()
var _tokens: Array[int] = []

func bind(authority: LocalAuthorityHost, domain: ItemsModule) -> void:
	host = authority
	items = domain
	effects.preflight = check_work
	effects.apply_effect = commit_work
	host.actions.capability_port = effects
	host.register_command_port(KINDS, self)
	host.extension_snapshot = items.state_view
	host.install_loadout(items.loadout)
	_tokens.append(host.combat.events.subscribe(ActionCancelled, _ended))
	_tokens.append(host.combat.events.subscribe(ActionCompleted, _ended))

func validate(kind: String, p: Dictionary) -> String:
	var fields := {"item.pickup": ["drop"], "item.equip": ["slot", "entry"], "item.unequip": ["slot"], "item.split": ["entry", "quantity"], "item.merge": ["source", "target"], "item.move": ["entry", "destination", "quantity"], "item.harvest": ["node"], "item.craft": ["recipe", "station", "choices"], "item.consume": ["entry"], "skill.equip": ["slot", "action"]}
	if not fields.has(kind) or not InventoryService._keys(p, fields[kind]): return "FORGED_ITEM_FIELDS"
	for key: String in p:
		if key == "quantity":
			if not CombatNumbers.integer(p[key], 1, 10000): return "INVALID_QUANTITY"
		elif key == "choices":
			if not p[key] is Dictionary or p[key].size() > 8: return "INVALID_CHOICES"
			for slot: Variant in p[key]:
				if not slot is String or slot.length() > 96 or not p[key][slot] is String or p[key][slot].length() > 96: return "INVALID_CHOICES"
		elif not p[key] is String or p[key].length() > 96: return "INVALID_ITEM_COMMAND"
	return "OK"

func execute(actor: String, kind: String, p: Dictionary) -> String:
	if actor != items.player.entity_id: return "ACTOR_MISMATCH"
	if host.combat.combatant(actor).lifecycle != Combatant.Lifecycle.ALIVE: return "OWNER_DEFEATED"
	if not host.can_act(actor): return "DEFENSE_OR_STAGGER"
	var code := "INVALID_ITEM_COMMAND"
	match kind:
		"item.harvest", "item.craft", "item.consume":
			if host.actions.phase not in [ActionExecutor.Phase.IDLE, ActionExecutor.Phase.CANCELLED]: return "ACTION_ACTIVE"
			pending = {"kind": kind, "payload": p.duplicate(true)}
			var action := "combat.action.consume"
			if kind == "item.harvest":
				var node := items.content.node(p.node)
				if node == null: pending.clear(); return "NODE_UNKNOWN"
				action = ItemsModule.harvest_action(node.profile_id)
			elif kind == "item.craft":
				if items.content.recipe(p.recipe) == null: pending.clear(); return "RECIPE_UNKNOWN"
				action = ItemsModule.craft_action(p.recipe)
			code = host.actions.activate(action)
			if code != "STARTED": pending.clear()
		_:
			if host.actions.phase not in [ActionExecutor.Phase.IDLE, ActionExecutor.Phase.CANCELLED]: return "ACTION_ACTIVE"
			match kind:
				"item.pickup": code = _pickup(actor, p.drop)
				"item.equip": code = _equip(p.slot, p.entry)
				"item.unequip": code = _equip(p.slot, "")
				"skill.equip": code = _skill(p.slot, p.action)
				"item.split", "item.merge", "item.move":
					var entry: String = p.get("entry", p.get("source", ""))
					if items.equipment.is_equipped(ItemsModule.BAG, entry) or (kind == "item.merge" and items.equipment.is_equipped(ItemsModule.BAG, p.target)): return "ITEM_EQUIPPED"
					var result: Dictionary
					if kind == "item.split": result = items.inventory.split(actor, ItemsModule.BAG, entry, int(p.quantity))
					elif kind == "item.merge": result = items.inventory.merge(actor, ItemsModule.BAG, entry, p.target)
					else:
						if p.destination not in [ItemsModule.BAG, ItemsModule.STASH] or items.player.position.distance_to(Vector3(-1, 0, 10)) > 3: return "STORAGE_UNAVAILABLE"
						var source := ItemsModule.STASH if p.destination == ItemsModule.BAG else ItemsModule.BAG
						result = items.inventory.transfer(actor, source, p.destination, entry, int(p.quantity))
					code = "ITEM_MOVED" if result.ok else result.code
	items.touch(code)
	return code

func _pickup(actor: String, id: String) -> String:
	if not items.drops.has(id): return "DROP_UNKNOWN"
	var drop: Dictionary = items.drops[id]
	if drop.owner != actor: return "PICKUP_NOT_OWNER"
	if drop.claimed: return "ALREADY_PICKED_UP"
	if not _near(drop.position, drop.region): return "OUT_OF_RANGE"
	var ops: Array = []
	for entry: Dictionary in items.inventory.entries(drop.container):
		ops.append({"kind": "transfer", "source_id": drop.container, "destination_id": ItemsModule.BAG, "entry_id": entry.id, "quantity": entry.quantity})
	if ops.is_empty(): return "ALREADY_PICKED_UP"
	var result := items.inventory.transact(actor, ops)
	if not result.ok: return result.code
	drop.claimed = true
	return "PICKED_UP"

func _near(position: Array, region: String) -> bool:
	var point := Vector3(position[0], position[1], position[2])
	return (not region_id.is_valid() or region_id.call() == region) and items.player.position.distance_squared_to(point) <= 7.5625 and (not spatial_gate.is_valid() or bool(spatial_gate.call(point)))

func check_work(capability: String, owner: String) -> String:
	if pending.is_empty() or owner != items.player.entity_id: return "NO_ITEM_INTENT"
	var expected := {"items.effect.harvest": "item.harvest", "items.effect.craft": "item.craft", "items.effect.consume": "item.consume"}
	if expected.get(capability) != pending.kind: return "WRONG_ITEM_INTENT"
	var p: Dictionary = pending.payload
	match pending.kind:
		"item.harvest":
			var node := items.content.node(p.node)
			if node == null: return "NODE_UNKNOWN"
			if region_id.is_valid() and region_id.call() != node.region_id: return "WRONG_REGION"
			if spatial_gate.is_valid() and not bool(spatial_gate.call(node.position)): return "TARGET_OCCLUDED"
			var result := items.resources.gather_check(owner, ItemsModule.BAG, p.node, host.combat.clock.tick, items.player.position, items.tool())
			return "OK" if result.ok else result.code
		"item.craft":
			var tags := _station_tags(p.station)
			if not p.station.is_empty() and tags.is_empty(): return "STATION_UNAVAILABLE"
			var result := items.crafting.preview(owner, ItemsModule.BAG, p.recipe, p.choices, tags, items.known_recipes, items.tool())
			if result.ok:
				for op: Dictionary in result.operations:
					if op.kind == "remove" and items.equipment.is_equipped(ItemsModule.BAG, op.entry_id): return "ITEM_EQUIPPED"
				var trial := InventoryService.new(items.catalog)
				trial.restore(items.inventory.capture())
				var capacity := trial.transact(owner, result.operations)
				if not capacity.ok: return capacity.code
			return "OK" if result.ok else result.code
		"item.consume":
			var entry := items.inventory.entry(ItemsModule.BAG, p.entry)
			if entry.is_empty(): return "ITEM_NOT_OWNED"
			var definition := items.catalog.lookup(entry.definition_id)
			if definition.consume_heal <= 0: return "NOT_CONSUMABLE"
			var state := host.combat.combatant(owner)
			if state.lifecycle != Combatant.Lifecycle.ALIVE: return "OWNER_DEFEATED"
			return "HEALTH_FULL" if state.health == state.max_health() else "OK"
	return "INVALID_ITEM_COMMAND"

func commit_work(capability: String, owner: String) -> Dictionary:
	var code := check_work(capability, owner)
	if code != "OK": return {"ok": false, "code": code}
	var p: Dictionary = pending.payload
	var result: Dictionary
	match pending.kind:
		"item.harvest": result = items.resources.gather(owner, ItemsModule.BAG, p.node, host.combat.clock.tick, items.player.position, items.tool())
		"item.craft": result = items.crafting.craft(owner, ItemsModule.BAG, p.recipe, host.combat.clock.tick, p.choices, _station_tags(p.station), items.known_recipes, items.tool())
		"item.consume":
			var entry := items.inventory.entry(ItemsModule.BAG, p.entry)
			var definition := items.catalog.lookup(entry.definition_id)
			var before := items.inventory.capture()
			result = items.inventory.remove(owner, ItemsModule.BAG, p.entry, 1)
			if result.ok:
				# Inventory commits before health facts, so observers see coherent state.
				# Rejected healing emits no facts; restore the exact staged ledger then.
				var healing := host.combat.heal(HealingRequest.new(owner, owner, definition.consume_heal))
				if not healing.accepted: items.inventory.restore(before)
				result = {"ok": healing.accepted, "code": "CONSUMED" if healing.accepted else healing.code, "healed": healing.actual}
	items.touch(result.code)
	return result

func _station_tags(id: String) -> Array:
	return ["station.forge"] if id == ItemsModule.FORGE and _near([ItemsModule.FORGE_POSITION.x, ItemsModule.FORGE_POSITION.y, ItemsModule.FORGE_POSITION.z], "region.home_valley") else []

func _equip(slot: String, entry: String) -> String:
	if slot not in EquipmentState.SLOTS: return "INVALID_EQUIPMENT_SLOT"
	var proposed := EquipmentState.new(items.player.entity_id)
	proposed.restore(items.equipment.capture(), items.inventory)
	var error := proposed.unequip(slot) if entry.is_empty() else proposed.equip(slot, ItemsModule.BAG, entry, items.inventory)
	if error != OK: return "EQUIP_REJECTED"
	var definitions := proposed.definitions(items.inventory)
	var bonus: int = definitions.weapon.damage_bonus if definitions.has("weapon") else 0
	var actor := host.combat.combatant(items.player.entity_id)
	var existing := actor.attributes.capture_modifiers()
	var had := existing.any(func(value: Dictionary) -> bool: return value.source_id == ItemsModule.EQUIPMENT_SOURCE)
	if bonus > 0 and existing.size() >= CombatNumbers.MAX_MODIFIERS and not had: return "MODIFIER_CAPACITY"
	if had and host.combat.remove_modifier(actor.entity_id, ItemsModule.EQUIPMENT_SOURCE) != OK: return "COMBAT_BUSY"
	if bonus > 0:
		error = host.combat.add_modifier(actor.entity_id, CombatModifier.new(ItemsModule.EQUIPMENT_SOURCE, CombatModifier.Stat.DAMAGE_SCALE, CombatModifier.Operator.ADD, bonus))
		assert(error == OK, "Prevalidated weapon modifier must commit in quiescent host")
	items.equipment.restore(proposed.capture(), items.inventory)
	for equipment_slot: String in EquipmentState.SLOTS:
		var source := "skill.source.equipment_" + equipment_slot
		items.skills.revoke_source(source)
		if definitions.has(equipment_slot):
			for skill: String in definitions[equipment_slot].granted_skills: items.skills.grant(skill, source, host.actions.catalog)
	for skill_slot: String in ["skill_1", "skill_2", "skill_3"]:
		if not items.loadout.slots[skill_slot].is_empty() and not items.skills.eligible(items.loadout.slots[skill_slot], host.actions.catalog): items.loadout.slots[skill_slot] = ""
	host.install_loadout(items.loadout)
	return "UNEQUIPPED" if entry.is_empty() else "EQUIPPED"

func _skill(slot: String, action: String) -> String:
	if slot not in ["skill_1", "skill_2", "skill_3"]: return "INVALID_SKILL_SLOT"
	if not action.is_empty() and not items.skills.eligible(action, host.actions.catalog): return "SKILL_NOT_OWNED"
	var proposed := items.loadout.duplicate(true) as ActionLoadout
	proposed.slots[slot] = action
	if host.install_loadout(proposed) != OK: return "LOADOUT_REJECTED"
	items.loadout = proposed
	return "SKILL_EQUIPPED"

func _ended(fact: ActionEvent) -> void:
	if host != null and fact.owner_id == items.player.entity_id: pending.clear()

func dispose() -> void:
	for token in _tokens: host.combat.events.unsubscribe(token)
	_tokens.clear()
	effects.preflight = Callable()
	effects.apply_effect = Callable()
	pending.clear()
	host = null
	items = null
	spatial_gate = Callable()
	region_id = Callable()
