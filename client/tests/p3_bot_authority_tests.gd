extends SceneTree

# Explicit domain harness composes the production host/executor/items adapters.
# Setup is trusted authority data; the Bot itself can only submit semantic intents.
class Relations extends CombatTargetPolicy:
	func relationship(source: String, target: String) -> Relationship:
		return Relationship.SELF if source == target else Relationship.ENEMY

var checks := 0
var failures := 0
var registry := CoreModuleRegistry.new()
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
var actor := LivingActorState.new()
var executor: ActionExecutor
var host := LocalAuthorityHost.new()
var player_host := LocalAuthorityHost.new()
var port := ItemsAuthorityPort.new()
var context := ItemAuthorityContext.new()
var active_epoch := 1

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)

func step(count: int = 1) -> void:
	for _index in count:
		core.clock.tick += 1
		host.advance()

func request(kind: String, payload: Dictionary) -> String:
	return host.submit_authority_intent(actor.actor_id, active_epoch, kind, payload).code

func entry_id(definition_id: String) -> String:
	for entry: Dictionary in context.inventory.entries(context.bag_id):
		if entry.definition_id == definition_id: return entry.id
	return ""

func run() -> void:
	for module: CoreModule in [core, combat, player, player_combat, world, regions, targets, enemies, items]: registry.add(module)
	if registry.boot() != OK:
		check(false, "production module harness boots")
		registry.shutdown()
		quit(1)
		return
	check(true, "Bot uses existing Combat/Player/Items modules without fake client")
	items.bind(enemies, definition)
	items.restore_state(items.initial_state(player.state.entity_id, items.actor_map()))
	var catalog := LivingCatalog.defaults()
	var bot_id := core.entities.create()
	check(actor.configure(bot_id, "bot", catalog) == OK, "persistent Bot owns a stable Core entity identity")
	actor.chunk_id = "region.home_valley:-1:0"
	actor.position = Vector3(-4, 0.1, 6)
	actor.fidelity = LivingActorState.Fidelity.L0
	var bot_combatant := combat.service.register(bot_id, "combat.profile.standard")
	executor = ActionExecutor.new(combat.service, combat.actions, bot_id)
	executor.position_of = func(id: String) -> Variant:
		if id == bot_id: return actor.position
		if id == player.state.entity_id: return player.state.position
		if id == enemies.actor.entity_id: return enemies.actor.position
		return null
	combat.service.target_policy = Relations.new()
	player_host.configure(combat.service, player_combat.actions, player.state, "test.player")
	var shared_damage_policy := combat.service.damage_policy
	# Empty session deliberately disables client-envelope ingress for this actor.
	host.configure(combat.service, executor, actor.player_state, "", player_host.defense)
	host.server_intent_epoch = active_epoch
	host.defense.position_of = executor.position_of
	host.defense.facing_of = func(id: String) -> Vector3: return player.state.facing if id == player.state.entity_id else actor.facing
	check(host.defense == player_host.defense and combat.service.damage_policy == shared_damage_policy, "Bot host reuses the Player defense without replacing canonical damage policy")
	context.catalog = items.catalog
	context.bag_id = actor.inventory_id
	context.stash_id = "inventory.actor_store.a" + bot_id
	context.inventory = InventoryService.new(context.catalog)
	check(context.inventory.register_container(context.bag_id, bot_id, 24, 50000) == OK and context.inventory.register_container(context.stash_id, bot_id, 24, 50000) == OK, "Bot stock uses the same bounded InventoryService")
	for item: String in ["item.weapon.sword", "item.tool.axe", "item.tool.pickaxe"]: context.inventory.add(bot_id, context.bag_id, item, 1)
	context.equipment = EquipmentState.new(bot_id)
	context.equipment.equip("weapon", context.bag_id, entry_id("item.weapon.sword"), context.inventory)
	context.equipment.equip("tool", context.bag_id, entry_id("item.tool.axe"), context.inventory)
	context.skills = LearnedSkillSet.new(bot_id)
	for skill: String in catalog.character_class(actor.class_id).starting_actions: context.skills.learn(skill, "skill.source.class", combat.actions)
	context.content = items.content
	context.resources = items.resources
	context.crafting = CraftingService.new()
	context.crafting.configure(context.inventory, context.content)
	context.loadout = (preload("res://data/actions/player_loadout.tres") as ActionLoadout).duplicate(true) as ActionLoadout
	context.known_recipes.assign(["recipe.healing_balm"])
	context.player = actor.player_state
	context.combat = combat.service
	context.actions = combat.actions
	port.region_id = func() -> String: return actor.region_id
	port.spatial_gate = func(_point: Vector3) -> bool: return true
	port.bind_context(host, context)
	check(host.actions == executor and executor.combat == combat.service and port.items.resources == items.resources, "Bot shares the real action/combat/resource contracts")
	var enemy_position := enemies.actor.position
	enemies.actor.position = actor.position + actor.facing
	var bot_health := bot_combatant.health
	check(request("guard", {"enabled": true}) == "GUARD" and player_host.defense.state(bot_id).guard, "Bot semantic guard enters the same canonical P1 defense state")
	check(request("action", {"slot":"primary","target":enemies.actor.entity_id}) == "DEFENSE_OR_STAGGER", "Bot guard obeys the Player action exclusion rule")
	combat.service.damage(DamageRequest.new(enemies.actor.entity_id, bot_id, 12))
	check(bot_combatant.health == bot_health - 3, "Bot guard produces the same authoritative P1 reduction")
	check(request("guard", {"enabled": false}) == "RELEASED", "Bot semantic guard releases through shared defense")
	enemies.actor.position = enemy_position
	check(not host.submit("", {"version":1,"sequence":1,"tick":0,"kind":"cancel","payload":{}}).accepted, "Bot is not a fake client session")
	var before := context.inventory.capture()
	var resources_before := items.resources.capture()
	check(request("item.grant", {"item":"item.currency.coin","quantity":999}) == "UNKNOWN_COMMAND", "Bot cannot fabricate items through a special cheat API")
	check(request("progression.grant", {"xp":999}) == "UNKNOWN_COMMAND", "Bot cannot grant itself arbitrary XP")
	check(request("item.harvest", {"node":"resource.node.common_tree","yield":999}) == "FORGED_ITEM_FIELDS", "Bot forged yield gets the same P2 payload rejection")
	check(request("item.equip", {"slot":"weapon","entry":entry_id("item.weapon.sword"),"damage":999}) == "FORGED_ITEM_FIELDS", "Bot cannot equip forged combat stats")
	check(request("action", {"slot":"primary","target":enemies.actor.entity_id,"damage":999}) == "INVALID_ACTION", "Bot cannot submit final attack damage")
	check(not host.submit_authority_intent(player.state.entity_id, active_epoch, "cancel", {}).accepted, "Bot producer cannot override bound actor ownership")
	check(not host.submit_authority_intent(bot_id, active_epoch - 1, "cancel", {}).accepted, "stale materialization epoch rejects before action mutation")
	check(context.inventory.capture() == before and items.resources.capture() == resources_before, "invalid Bot commands preserve canonical inventory and world nodes")
	check(request("item.equip", {"slot":"helmet","entry":entry_id("item.weapon.sword")}) == "INVALID_EQUIPMENT_SLOT", "Bot obeys equipment compatibility")
	check(request("item.consume", {"entry":"item.entry.e0000000999"}) == "ITEM_NOT_OWNED", "Bot cannot consume unowned entry")
	check(request("item.craft", {"recipe":"recipe.healing_balm","station":"","choices":{}}) == "MISSING_INGREDIENTS", "Bot crafting cannot bypass stock requirements")
	check(request("item.harvest", {"node":"resource.node.missing"}) == "NODE_UNKNOWN", "Bot rejects nonexistent resource target")
	actor.position = Vector3(100, 0, 100)
	check(request("action", {"slot":"primary","target":enemies.actor.entity_id}) == "OUT_OF_RANGE", "Bot basic attack validates canonical range")
	check(request("item.harvest", {"node":"resource.node.common_tree"}) == "OUT_OF_RANGE", "Bot harvest validates canonical world range")
	actor.position = enemies.actor.position + Vector3(0, 0, 1)
	var health := enemies.actor.combatant.health
	check(request("action", {"slot":"primary","target":enemies.actor.entity_id}) == "STARTED", "Bot starts canonical basic action")
	check(enemies.actor.combatant.health == health, "Bot presentation/intent does not pre-commit damage")
	check(request("action", {"slot":"primary","target":enemies.actor.entity_id}) != "STARTED", "repeated Bot command cannot create duplicate concurrent action")
	step(4)
	check(enemies.actor.combatant.health == health - 12, "Bot basic resolves the exact same authoritative P1 damage")
	step(7)
	check(request("action", {"slot":"primary","target":enemies.actor.entity_id}) == "COOLDOWN", "Bot obeys existing per-action cooldown")
	step(30)
	actor.position = Vector3(-4, 0.1, 6)
	var player_stock := items.inventory.capture()
	var reserve: int = items.resources.snapshot("resource.node.common_tree", core.clock.tick).remaining
	check(request("item.equip", {"slot":"tool","entry":entry_id("item.tool.pickaxe")}) == "EQUIPPED", "Bot equips an actually owned P2 tool")
	check(request("item.harvest", {"node":"resource.node.common_tree"}) == "WRONG_TOOL", "Bot wrong tool cannot bypass harvest capability")
	check(request("item.equip", {"slot":"tool","entry":entry_id("item.tool.axe")}) == "EQUIPPED", "Bot can switch to correct tool through shared adapter")
	check(request("item.harvest", {"node":"resource.node.common_tree"}) == "STARTED", "Bot starts harvest in shared ActionExecutor")
	check(context.inventory.quantity(context.bag_id, "item.wood.common") == 0 and items.resources.snapshot("resource.node.common_tree", core.clock.tick).remaining == reserve, "Bot work has no early inventory/depletion outcome")
	step(15)
	check(context.inventory.quantity(context.bag_id, "item.wood.common") == 2 and items.resources.snapshot("resource.node.common_tree", core.clock.tick).remaining == reserve - 1, "Bot receives authority yield and depletes the shared world node once")
	check(items.inventory.capture() == player_stock, "Bot harvest mutates its own custody without granting resources to Player")
	var committed := context.inventory.capture()
	host.server_intent_epoch = -1
	check(request("item.harvest", {"node":"resource.node.common_tree"}) == "STALE_ACTOR_EPOCH", "dematerialized Bot cannot continue stale active commands")
	check(context.inventory.capture() == committed, "demotion rejection preserves committed custody")
	host.server_intent_epoch = 2
	active_epoch = 2
	check(request("cancel", {}) != "STALE_ACTOR_EPOCH", "rematerialized Bot uses new authority epoch")
	combat.service.damage(DamageRequest.new(enemies.actor.entity_id, bot_id, 1000))
	check(bot_combatant.lifecycle == Combatant.Lifecycle.DEFEATED and request("action", {"slot":"primary","target":enemies.actor.entity_id}) == "OWNER_DEFEATED", "defeated Bot cannot act through server intent ingress")
	# The production Player owns the shared defense. Disposing a transient Bot
	# must neither clear its geometry providers nor detach its damage subscription.
	player.state.facing = Vector3(0, 0, 1)
	enemies.actor.position = player.state.position + Vector3(0, 0, 1)
	check(player_host.defense.set_guard(player.state.entity_id, true) == "GUARD", "Player guard remains available with a materialized Bot host")
	var player_health := player_combat.state.health
	combat.service.damage(DamageRequest.new(enemies.actor.entity_id, player.state.entity_id, 12))
	check(player_combat.state.health == player_health - 3, "Player guarded damage uses shared P1 mitigation while Bot exists")
	var shared_position := player_host.defense.position_of
	var shared_facing := player_host.defense.facing_of
	host.dispose()
	check(player_host.defense.position_of == shared_position and player_host.defense.facing_of == shared_facing and combat.service.damage_policy == shared_damage_policy, "Bot disposal preserves Player spatial ports and shared damage policy")
	check(player_host.defense.state(player.state.entity_id).guard, "Bot disposal preserves another actor's guard window")
	player_health = player_combat.state.health
	combat.service.damage(DamageRequest.new(enemies.actor.entity_id, player.state.entity_id, 12))
	check(player_combat.state.health == player_health - 3, "Player still blocks actual damage after Bot dematerialization")
	player_host.dispose()
	executor.position_of = Callable()
	context.dispose()
	registry.shutdown()
	print("P3 Bot authority tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
