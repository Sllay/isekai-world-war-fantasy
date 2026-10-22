extends SceneTree

# Explicit authority harness: real modules, command inbox, gateway and capability
# adapter. Direct setup below is trusted test state, never a client mutation path.
class Relations extends CombatTargetPolicy:
	func relationship(source: String, target: String) -> Relationship:
		return Relationship.SELF if source == target else Relationship.ENEMY

var checks := 0
var failures := 0
var core := CoreRuntimeServicesModule.new()
var combat := CombatModule.new()
var player := PlayerModule.new()
var player_combat := PlayerCombatModule.new()
var definition := preload("res://world/primary_world.tres") as WorldDefinition
var world := WorldModule.new(definition)
var regions := RegionModule.new()
var targets := TargetingModule.new()
var enemies := EnemyModule.new()
var items := ItemsModule.new()
var registry := CoreModuleRegistry.new()
var host := LocalAuthorityHost.new()
var port := ItemsAuthorityPort.new()
var gateway: LoopbackAuthorityGateway
var commits := 0
var active_region := "region.home_valley"
var visible := true

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func step(count := 1) -> void:
	for index: int in count:
		core.clock.tick += 1
		host.advance()

func envelope(sequence: int, kind: String, payload: Dictionary, tick: int) -> Dictionary:
	return {"version": 1, "sequence": sequence, "tick": tick, "kind": kind, "payload": payload}

func request(kind: String, payload: Dictionary) -> String:
	var result := gateway.request(kind, payload)
	if not result.accepted:
		return result.code
	step()
	return host.last_result

func settle() -> void:
	step(40)

func first_entry(definition_id: String, container := ItemsModule.BAG) -> String:
	for entry: Dictionary in items.inventory.entries(container):
		if entry.definition_id == definition_id:
			return entry.id
	return ""

func fixture_add(definition_id: String, quantity: int, container := ItemsModule.BAG, owner := "") -> String:
	var actor: String = player.state.entity_id if owner.is_empty() else owner
	var result := items.inventory.add(actor, container, definition_id, quantity)
	check(result.ok, "trusted setup adds %s" % definition_id)
	return first_entry(definition_id, container)

func work_payload(recipe := "recipe.healing_balm") -> Dictionary:
	return {"recipe": recipe, "station": "", "choices": {}}

func run() -> void:
	for module: CoreModule in [core, combat, player, player_combat, world, regions, targets, enemies, items]:
		registry.add(module)
	if registry.boot() != OK:
		check(false, "P2 production modules boot in isolated authority harness")
		registry.shutdown()
		quit(1)
		return
	check(true, "P2 production modules boot without SceneTree gameplay")
	items.bind(enemies, definition)
	var initial := items.initial_state(player.state.entity_id, items.actor_map())
	check(items.validate_state(initial) == OK, "new-world seeded stock and learned ownership validate")
	items.restore_state(initial)
	combat.service.target_policy = Relations.new()
	player_combat.actions.position_of = func(id: String) -> Variant:
		if id == player.state.entity_id: return player.state.position
		if id == enemies.actor.entity_id: return enemies.actor.position
		for actor: EnemyActor in enemies.companions:
			if id == actor.entity_id: return actor.position
		return null
	host.configure(combat.service, player_combat.actions, player.state, "p2-session")
	host.defense.position_of = player_combat.actions.position_of
	host.defense.facing_of = func(_id: String) -> Vector3: return player.state.facing
	port.region_id = func() -> String: return active_region
	port.spatial_gate = func(_point: Vector3) -> bool: return visible
	port.bind(host, items)
	gateway = LoopbackAuthorityGateway.new(host, "p2-session")
	var committed_token := combat.service.events.subscribe(ActionCommitted, func(fact: ActionCommitted) -> void:
		if fact.owner_id == player.state.entity_id: commits += 1)
	var owner := player.state.entity_id
	var original_inventory := items.inventory.capture()
	check(not gateway.request("item.grant", {"definition": "item.currency.coin", "quantity": 9999}).accepted, "client cannot grant finite stock")
	check(not gateway.request("item.harvest", {"node": "resource.node.common_tree", "yield": 9999}).accepted, "forged gather yield rejected at centralized ingress")
	check(not gateway.request("item.craft", {"recipe": "recipe.healing_balm", "station": "", "choices": {}, "output": "item.weapon.tempered_sword"}).accepted, "client cannot select arbitrary crafting output")
	check(not gateway.request("item.equip", {"slot": "weapon", "entry": first_entry("item.weapon.sword"), "damage_bonus": 999999}).accepted, "forged equipment stats rejected")
	check(not gateway.request("item.equip", {"slot": "weapon", "entry": first_entry("item.weapon.sword"), "actor": enemies.actor.entity_id}).accepted, "actor override cannot cross authenticated binding")
	check(port.execute(enemies.actor.entity_id, "item.unequip", {"slot": "weapon"}) == "ACTOR_MISMATCH", "command adapter independently enforces canonical actor")
	for quantity: Variant in [-1, 0, 0.5, INF, NAN, "2", true, 10001]:
		check(not gateway.request("item.split", {"entry": first_entry("item.weapon.sword"), "quantity": quantity}).accepted, "invalid item quantity rejected: %s" % str(quantity))
	check(not host.submit("forged-session", envelope(99999, "item.unequip", {"slot": "weapon"}, core.clock.tick)).accepted, "item commands require authenticated session")
	check(items.inventory.capture() == original_inventory, "forged outcomes leave canonical stock unchanged")
	check(request("item.equip", {"slot": "helmet", "entry": first_entry("item.weapon.sword")}) == "INVALID_EQUIPMENT_SLOT", "unknown equipment slot rejects")
	var foreign_bag := ItemsModule.npc_container(EnemyModule.SPAWN)
	var foreign_sword := first_entry("item.weapon.sword", foreign_bag)
	var foreign_balm := fixture_add("item.consumable.healing_balm", 1, foreign_bag, enemies.actor.entity_id)
	check(request("item.equip", {"slot": "weapon", "entry": foreign_sword}) == "EQUIP_REJECTED", "unowned NPC instance cannot be equipped")
	check(request("item.consume", {"entry": foreign_balm}) == "ITEM_NOT_OWNED", "foreign container consumable cannot be spent")
	check(request("skill.equip", {"slot": "primary", "action": "combat.action.basic_heal"}) == "INVALID_SKILL_SLOT", "skill commands cannot replace trusted primary slot")
	check(request("skill.equip", {"slot": "skill_4", "action": "combat.action.basic_heal"}) == "INVALID_SKILL_SLOT", "fourth skill slot rejects")
	check(request("skill.equip", {"slot": "skill_3", "action": "combat.action.consume"}) == "SKILL_NOT_OWNED", "internal work catalog existence does not grant skill ownership")
	check(request("skill.equip", {"slot": "skill_3", "action": "combat.action.strong_strike"}) == "SKILL_EQUIPPED", "explicit learned ownership permits skill assignment")
	check(request("skill.equip", {"slot": "skill_3", "action": ""}) == "SKILL_EQUIPPED", "empty skill slot remains supported")

	var sword := first_entry("item.weapon.sword")
	player.state.position = Vector3(-1, 0, 10)
	check(request("item.move", {"entry": sword, "destination": ItemsModule.STASH, "quantity": 1}) == "ITEM_EQUIPPED", "equipped instance cannot transfer to storage")
	check(request("item.split", {"entry": sword, "quantity": 1}) == "ITEM_EQUIPPED", "equipped reference cannot be split")
	check(request("item.merge", {"source": sword, "target": sword}) == "ITEM_EQUIPPED", "equipped reference cannot be merged or retired")
	var bag_view: Dictionary = gateway.snapshot().items.inventory
	bag_view.entries[0].quantity = 500
	check(items.inventory.entry(ItemsModule.BAG, bag_view.entries[0].id).quantity == 1, "replicated item state cannot mutate host ledger")
	var disconnected := AuthorityGateway.new()
	var before := items.inventory.capture()
	check(not disconnected.request("item.grant", {"quantity": 99}).accepted and not disconnected.request("item.harvest", {"node": "resource.node.common_tree"}).accepted and disconnected.snapshot().is_empty() and items.inventory.capture() == before, "disconnected gateway cannot promote local item mutations")

	# Weapon data feeds the existing combat attribute channel and effect runner.
	player.state.position = enemies.actor.position + Vector3(0, 0, 1)
	var enemy_health := enemies.actor.combatant.health
	check(request("action", {"slot": "primary", "target": enemies.actor.entity_id}) == "STARTED", "equipped starter uses existing action executor")
	step(4)
	check(enemies.actor.combatant.health == enemy_health - 12, "starter sword keeps P1 damage")
	settle()
	var upgrade := fixture_add("item.weapon.tempered_sword", 1)
	check(request("item.equip", {"slot": "weapon", "entry": upgrade}) == "EQUIPPED", "authority equips an owned upgrade instance")
	check(player_combat.state.attributes.value(CombatModifier.Stat.DAMAGE_SCALE) == 12000, "equipment contributes one existing DAMAGE_SCALE modifier")
	enemy_health = enemies.actor.combatant.health
	check(request("action", {"slot": "primary", "target": enemies.actor.entity_id}) == "STARTED", "upgrade reuses the same primary execution path")
	step(4)
	check(enemies.actor.combatant.health == enemy_health - 14, "existing CombatService applies bounded integer equipment damage")
	settle()
	check(request("item.unequip", {"slot": "weapon"}) == "UNEQUIPPED" and player_combat.state.attributes.value(CombatModifier.Stat.DAMAGE_SCALE) == 10000, "unequip removes only the source-owned modifier")
	check(request("item.equip", {"slot": "weapon", "entry": sword}) == "EQUIPPED", "original item remains canonical and reusable")

	# Test an extensible equipment grant without introducing final skill content.
	var granted_action := combat.actions.lookup("combat.action.basic_heal")
	granted_action.action_id = "combat.action.p2_granted_heal"
	check(combat.actions.register(granted_action) == OK, "trusted harness extends existing action catalog")
	var grant_armor := items.catalog.lookup("item.armor.leather")
	grant_armor.item_id = "item.armor.p2_grant"
	grant_armor.granted_skills.assign([granted_action.action_id])
	check(items.catalog.register(grant_armor) == OK, "trusted item content can declare eligible skill sources")
	var grant_entry := fixture_add(grant_armor.item_id, 1)
	check(request("skill.equip", {"slot": "skill_3", "action": granted_action.action_id}) == "SKILL_NOT_OWNED", "ungranted known definition is not eligible")
	check(request("item.equip", {"slot": "armor", "entry": grant_entry}) == "EQUIPPED", "owned equipment installs explicit grant source")
	check(request("skill.equip", {"slot": "skill_3", "action": granted_action.action_id}) == "SKILL_EQUIPPED", "live grant permits assigning the skill")
	check(request("item.unequip", {"slot": "armor"}) == "UNEQUIPPED" and not items.skills.eligible(granted_action.action_id, combat.actions) and host.loadout_state().slots.skill_3.is_empty(), "removing grant revokes eligibility and clears equipped slot")
	check(items.skills.learn(granted_action.action_id, "skill.source.trainer", combat.actions) == OK, "trusted independent learning is explicit")
	request("item.equip", {"slot": "armor", "entry": grant_entry})
	request("skill.equip", {"slot": "skill_3", "action": granted_action.action_id})
	check(request("item.unequip", {"slot": "armor"}) == "UNEQUIPPED" and items.skills.eligible(granted_action.action_id, combat.actions) and host.loadout_state().slots.skill_3 == granted_action.action_id, "grant revocation preserves independent learned ownership")

	# Pickup moves actual seeded stock once and rejects stale/replayed commands.
	player.state.position = enemies.actor.position
	combat.service.damage(DamageRequest.new(owner, enemies.actor.entity_id, 999))
	var drop_id := "drop." + EnemyModule.SPAWN
	check(items.drops.has(drop_id) and items.inventory.entries(foreign_bag).is_empty(), "death moves actual NPC stock into one canonical drop")
	var drop_stock := items.inventory.capture()
	items.drops[drop_id].owner = enemies.actor.entity_id
	check(request("item.pickup", {"drop": drop_id}) == "PICKUP_NOT_OWNER" and items.inventory.capture() == drop_stock, "pickup entitlement cannot be borrowed from another actor")
	items.drops[drop_id].owner = owner
	player.state.position += Vector3(30, 0, 0)
	check(request("item.pickup", {"drop": drop_id}) == "OUT_OF_RANGE" and items.inventory.capture() == drop_stock, "pickup validates canonical reach before custody commit")
	player.state.position = enemies.actor.position
	var coins_before := items.inventory.count(ItemsModule.BAG, "item.currency.coin")
	var accepted := gateway.request("item.pickup", {"drop": drop_id})
	check(accepted.accepted, "pickup semantic request enters centralized inbox")
	check(not host.submit("p2-session", envelope(accepted.sequence, "item.pickup", {"drop": drop_id}, core.clock.tick)).accepted, "duplicate pickup envelope rejects before commit")
	step()
	check(host.last_result == "PICKED_UP" and items.drops[drop_id].claimed and items.inventory.count(ItemsModule.BAG, "item.currency.coin") > coins_before, "pickup transfers finite existing coin stock")
	before = items.inventory.capture()
	check(request("item.pickup", {"drop": drop_id}) == "ALREADY_PICKED_UP" and items.inventory.capture() == before, "new-sequence duplicate pickup cannot mint stock")
	check(not host.submit("p2-session", envelope(99999, "item.pickup", {"drop": drop_id}, core.clock.tick - 21)).accepted and items.inventory.capture() == before, "stale pickup envelope cannot replay custody")
	check(request("item.pickup", {"drop": "drop.missing"}) == "DROP_UNKNOWN", "unknown drop fails closed")

	var tree := items.content.node("resource.node.common_tree")
	player.state.position = tree.position
	var nodes_before := items.resources.capture()
	before = items.inventory.capture()
	var action_id := ItemsModule.harvest_action(tree.profile_id)
	var no_port := ActionExecutor.new(combat.service, combat.actions, owner)
	check(no_port.activate(action_id) == "CAPABILITY_UNAVAILABLE" and items.inventory.capture() == before and items.resources.capture() == nodes_before, "work capability without authority port fails closed")
	var begin_commits := commits
	accepted = gateway.request("item.harvest", {"node": tree.node_id})
	check(accepted.accepted and not host.submit("p2-session", envelope(accepted.sequence, "item.harvest", {"node": tree.node_id}, core.clock.tick)).accepted, "duplicate harvest envelope rejected by same ingress")
	step()
	check(host.last_result == "STARTED" and player_combat.actions.phase == ActionExecutor.Phase.CASTING, "harvest reserves work through generic executor")
	check(request("item.harvest", {"node": tree.node_id}) == "ACTION_ACTIVE", "concurrent duplicate harvest cannot reserve another yield")
	step(12)
	check(commits == begin_commits + 1 and items.resources.snapshot(tree.node_id, core.clock.tick).remaining == 2 and items.inventory.count(ItemsModule.BAG, "item.wood.common") == 2, "harvest commits authored yield and one finite reserve exactly once")
	settle()
	before = items.inventory.capture()
	check(not host.submit("p2-session", envelope(99999, "item.harvest", {"node": tree.node_id}, core.clock.tick - 21)).accepted and items.inventory.capture() == before, "stale gather cannot mint another yield")
	visible = false
	check(request("item.harvest", {"node": tree.node_id}) == "TARGET_OCCLUDED", "trusted visibility blocks gathering")
	visible = true
	active_region = "region.other"
	check(request("item.harvest", {"node": tree.node_id}) == "WRONG_REGION", "resource intent cannot cross region custody")
	active_region = "region.home_valley"

	# Commit validation repeats position and tool checks after the windup.
	nodes_before = items.resources.capture()
	before = items.inventory.capture()
	check(request("item.harvest", {"node": tree.node_id}) == "STARTED", "movement revalidation fixture starts")
	player.state.position = tree.position + Vector3(30, 0, 0)
	step(12)
	check(player_combat.actions.phase == ActionExecutor.Phase.CANCELLED and player_combat.actions.last_result == "OUT_OF_RANGE" and items.resources.capture() == nodes_before and items.inventory.capture() == before and player_combat.actions.remaining_cooldown(action_id) == 0, "moving away cancels harvest before spend yield cooldown or reserve")
	player.state.position = tree.position
	check(request("item.harvest", {"node": tree.node_id}) == "STARTED", "tool removal revalidation fixture starts")
	var tool_id := first_entry("item.tool.axe")
	check(items.inventory.remove(owner, ItemsModule.BAG, tool_id, 1).ok, "trusted competing commit removes tool for adversarial fixture")
	step(12)
	check(player_combat.actions.phase == ActionExecutor.Phase.CANCELLED and player_combat.actions.last_result == "WRONG_TOOL" and items.resources.capture() == nodes_before, "missing canonical tool cancels work at commit")
	check(items.inventory.restore(before) == OK and items.equipment.validate(items.inventory) == OK, "trusted fixture restores matching instance references")
	check(port.pending.is_empty(), "cancelled work clears its transient command context")

	# Depletion is canonical and does not accept a new-sequence duplicate as refill.
	var pickaxe := first_entry("item.tool.pickaxe")
	check(request("item.equip", {"slot": "tool", "entry": pickaxe}) == "EQUIPPED", "mining requires an owned compatible tool")
	var stone := items.content.node("resource.node.stone")
	player.state.position = stone.position
	for extraction: int in 4:
		check(request("item.harvest", {"node": stone.node_id}) == "STARTED", "finite stone extraction %d starts" % extraction)
		settle()
	check(items.resources.snapshot(stone.node_id, core.clock.tick).remaining == 0, "nonrenewable stone node depletes")
	before = items.inventory.capture()
	nodes_before = items.resources.capture()
	check(request("item.harvest", {"node": stone.node_id}) == "DEPLETED" and items.inventory.capture() == before and items.resources.capture() == nodes_before, "depleted node cannot grant resources or reset")

	# Atomic recipe failures, duplicate commands and late ingredient invalidation.
	var missing_recipe := "recipe.tempered_sword"
	player.state.position = ItemsModule.FORGE_POSITION
	check(request("item.craft", {"recipe": missing_recipe, "station": ItemsModule.FORGE, "choices": {}}) == "MISSING_INGREDIENTS", "known recipe cannot fabricate absent ingredients")
	check(request("item.craft", {"recipe": "recipe.iron_ingot", "station": "", "choices": {}}) == "STATION_REQUIRED", "station recipe cannot claim a remote or absent station")
	check(request("item.craft", {"recipe": "recipe.iron_ingot", "station": "station.forged", "choices": {}}) == "STATION_UNAVAILABLE", "forged station identity rejects")
	var balm_before := items.inventory.count(ItemsModule.BAG, "item.consumable.healing_balm")
	begin_commits = commits
	accepted = gateway.request("item.craft", work_payload())
	check(accepted.accepted and not host.submit("p2-session", envelope(accepted.sequence, "item.craft", work_payload(), core.clock.tick)).accepted, "duplicate craft envelope rejected")
	step()
	check(host.last_result == "STARTED", "recipe uses actual acquired wood and stone")
	check(request("item.craft", work_payload()) == "ACTION_ACTIVE", "concurrent craft cannot consume ingredients twice")
	settle()
	check(commits == begin_commits + 1 and items.inventory.count(ItemsModule.BAG, "item.consumable.healing_balm") == balm_before + 1 and items.inventory.count(ItemsModule.BAG, "item.wood.common") == 0, "recipe commits exactly one authored output and spends actual ingredients")
	before = items.inventory.capture()
	check(request("item.craft", work_payload()) == "MISSING_INGREDIENTS" and items.inventory.capture() == before, "new-sequence duplicate craft cannot reuse spent inputs")
	fixture_add("item.wood.common", 2)
	check(request("item.craft", work_payload()) == "STARTED", "late ingredient revalidation fixture starts")
	var wood_id := first_entry("item.wood.common")
	items.inventory.remove(owner, ItemsModule.BAG, wood_id, 1)
	var late_before := items.inventory.capture()
	step(12)
	check(player_combat.actions.phase == ActionExecutor.Phase.CANCELLED and player_combat.actions.last_result == "MISSING_INGREDIENTS" and items.inventory.capture() == late_before, "removed ingredient cancels craft without partial output or other input loss")

	# Consumption owns both quantity and health through the same authority action.
	var balm := first_entry("item.consumable.healing_balm")
	player_combat.state.health = 60
	balm_before = items.inventory.count(ItemsModule.BAG, "item.consumable.healing_balm")
	check(request("item.consume", {"entry": balm}) == "STARTED", "owned stable balm starts via semantic intent")
	step(4)
	check(player_combat.state.health == 75 and items.inventory.count(ItemsModule.BAG, "item.consumable.healing_balm") == balm_before - 1, "one commit heals through CombatService and consumes one canonical unit")
	settle()
	check(request("item.consume", {"entry": sword}) == "NOT_CONSUMABLE", "equipment cannot be consumed by forged intent")

	# A full logical container must reject output without spending partly filled
	# ingredient stacks. A competing commit can also fill capacity during work.
	var capacity_base := items.inventory.capture()
	fixture_add("item.wood.common", 3)
	fixture_add("item.stone.common", 3)
	var ingredients_ready := items.inventory.capture()
	var filler := 0
	while items.inventory.entries(ItemsModule.BAG).size() < 24:
		items.inventory.add(owner, ItemsModule.BAG, "item.currency.coin", 1, {"provenance": {"source": "test.capacity", "batch": filler}})
		filler += 1
	before = items.inventory.capture()
	begin_commits = commits
	check(request("item.craft", work_payload("recipe.camp_axe")) == "SLOTS_FULL" and items.inventory.capture() == before and commits == begin_commits, "output capacity preflight rejects without ingredient loss or commit fact")
	check(items.inventory.restore(ingredients_ready) == OK, "trusted fixture restores room before work")
	check(request("item.craft", work_payload("recipe.camp_axe")) == "STARTED", "output capacity revalidation fixture starts")
	filler = 0
	while items.inventory.entries(ItemsModule.BAG).size() < 24:
		items.inventory.add(owner, ItemsModule.BAG, "item.currency.coin", 1, {"provenance": {"source": "test.capacity", "batch": filler}})
		filler += 1
	before = items.inventory.capture()
	step(16)
	check(player_combat.actions.phase == ActionExecutor.Phase.CANCELLED and player_combat.actions.last_result == "SLOTS_FULL" and items.inventory.capture() == before and commits == begin_commits, "capacity lost during windup cancels atomically without spending any ingredients")
	check(items.inventory.restore(capacity_base) == OK, "trusted capacity fixture restores original ledger")

	combat.service.events.unsubscribe(committed_token)
	host.dispose()
	player_combat.actions.position_of = Callable()
	registry.shutdown()
	print("P2 authority tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
