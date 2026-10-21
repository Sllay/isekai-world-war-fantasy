extends SceneTree

var checks := 0
var failures := 0
const ACTOR := "actor.test.player"
const BAG := "container.test.bag"
const TREE := "resource.node.common_tree"
const STONE := "resource.node.stone"
const ORE := "resource.node.iron_ore"

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func run() -> void:
	test_content_and_loot()
	test_gathering_and_persistence()
	test_atomic_gather()
	test_crafting_and_materials()
	test_atomic_craft()
	print("Resource foundation tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func inventory(slots: int = 20) -> InventoryService:
	var result := InventoryService.new(ItemCatalog.defaults())
	check(result.register_container(BAG, ACTOR, slots, 100000) == OK, "test inventory registered")
	return result

func test_content_and_loot() -> void:
	var items := ItemCatalog.defaults()
	var content := ResourceCatalog.defaults()
	check(content != null and content.valid(items), "authored resource/recipe data validates")
	check(content.nodes.size() == 4 and content.recipes.size() == 4, "small reusable content catalog")
	var detached := content.node(TREE)
	detached.position = Vector3.ONE
	check(content.node(TREE).position == Vector3(-4, 0, 5), "catalog lookup returns detached content")
	var loot := content.loot("loot.actor.skirmisher_initial")
	var first := LootResolver.resolve(loot, 7821, items)
	check(first.ok and first == LootResolver.resolve(loot, 7821, items), "seeded stock resolves deterministically")
	var quantities: Dictionary = {}
	for value: Dictionary in first.outputs:
		quantities[value.definition_id] = value.quantity
	check(quantities.get("item.weapon.sword") == 1, "stock guaranteed yield")
	check(quantities.get("item.currency.coin", 0) >= 2 and quantities.get("item.currency.coin", 0) <= 5, "stock quantity range")
	check(quantities.has("item.stone.common") != quantities.has("item.consumable.healing_balm"), "weighted roll selects one optional yield")
	loot.rolls = 17
	check(not LootResolver.resolve(loot, 7821, items).ok, "unbounded loot roll count rejected")
	loot = content.loot("loot.resource.stone")
	loot.guaranteed[0].definition_id = "item.missing"
	check(not LootResolver.resolve(loot, 1, items).ok, "unknown loot definition fails closed")
	content.node_profiles[0].interaction_range = NAN
	check(not content.valid(items), "nonfinite resource content rejected")

func test_gathering_and_persistence() -> void:
	var bag := inventory()
	var content := ResourceCatalog.defaults()
	var service := ResourceService.new()
	check(service.configure(bag, content, 12) == OK, "resource service configured")
	var axe := bag.catalog.lookup("item.tool.axe")
	var pickaxe := bag.catalog.lookup("item.tool.pickaxe")
	var before := service.capture()
	check(service.gather_check(ACTOR, BAG, TREE, 10, Vector3(-4, 0, 5), axe).ok, "gather preflight")
	check(service.capture() == before, "preflight does not mutate nodes")
	check(service.gather(ACTOR, BAG, TREE, 10, Vector3(-4, 0, 5), pickaxe).code == "WRONG_TOOL", "wrong tool rejected")
	var weak := axe.duplicate(true) as ItemDefinition
	check(service.gather(ACTOR, BAG, "resource.node.mountain_tree", 10, Vector3(-5, 0, 1), weak).code == "TOOL_TOO_WEAK", "harder material rejects weak tool")
	weak = pickaxe.duplicate(true) as ItemDefinition
	weak.tool_power = 1
	check(service.gather(ACTOR, BAG, ORE, 10, Vector3(-11, 0, 6), weak).code == "TOOL_TOO_WEAK", "ore hardness gate")
	check(service.gather(ACTOR, BAG, TREE, 10, Vector3(4, 0, 5), axe).code == "OUT_OF_RANGE", "canonical range revalidated")
	check(service.gather(ACTOR, BAG, TREE, 10, Vector3(NAN, 0, 5), axe).code == "INVALID_GATHER", "nonfinite position rejected")
	check(service.capture() == before and bag.quantity(BAG, "item.wood.common") == 0, "rejected gathers leave custody and node unchanged")
	for tick in [10, 20, 30]:
		check(service.gather(ACTOR, BAG, TREE, tick, Vector3(-4, 0, 5), axe).ok, "bounded extraction succeeds")
	check(bag.quantity(BAG, "item.wood.common") == 6, "gather yields actual inventory stock")
	var depleted := service.capture()
	check(depleted.nodes[TREE].remaining == 0 and depleted.nodes[TREE].regeneration_tick == 330, "depletion deadline persists")
	check(service.gather(ACTOR, BAG, TREE, 329, Vector3(-4, 0, 5), axe).code == "DEPLETED", "cannot gather before regeneration")
	check(service.snapshot(TREE, 330).remaining == 3 and service.snapshot(TREE, 330).cycle == 1, "due regeneration evaluates lazily")
	check(service.capture() == depleted, "lazy snapshots do not commit regeneration")
	var restored := ResourceService.new()
	check(restored.configure(bag, content, 12) == OK and restored.validate_state(depleted), "node snapshot validates for restart")
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(depleted))
	check(restored.validate_state(serialized), "JSON process-boundary numeric representation validates")
	restored.restore(serialized)
	check(restored.snapshot(TREE, 329).remaining == 0 and restored.capture() == depleted, "restart does not refill depleted defaults")
	check(restored.gather(ACTOR, BAG, TREE, 330, Vector3(-4, 0, 5), axe).ok, "successful gather settles due regeneration")
	check(restored.capture().nodes[TREE].cycle == 1 and restored.capture().nodes[TREE].remaining == 2, "one regeneration cycle committed")
	var corrupt := depleted.duplicate(true)
	corrupt.nodes[TREE].remaining = -1
	check(not restored.validate_state(corrupt), "negative reserves rejected")
	corrupt = depleted.duplicate(true)
	corrupt.nodes[TREE].position[0] = 99
	check(not restored.validate_state(corrupt), "authored node position cannot be overwritten")
	corrupt = depleted.duplicate(true)
	corrupt.nodes.erase(TREE)
	check(not restored.validate_state(corrupt), "missing node cannot refill defaults")
	for tick in [40, 50, 60, 70]:
		check(service.gather(ACTOR, BAG, ORE, tick, Vector3(-11, 0, 6), pickaxe).ok, "ore extraction")
	check(service.snapshot(ORE, 900000).remaining == 0 and service.snapshot(ORE, 900000).regeneration_tick == -1, "nonrenewable ore remains depleted")

func test_atomic_gather() -> void:
	var bag := inventory(1)
	check(bag.add(ACTOR, BAG, "item.currency.coin", 1).ok, "fill single slot")
	var service := ResourceService.new()
	check(service.configure(bag, ResourceCatalog.defaults()) == OK, "capacity scenario configured")
	var before := service.capture()
	var custody := bag.capture()
	check(service.gather_check(ACTOR, BAG, TREE, 1, Vector3(-4, 0, 5), bag.catalog.lookup("item.tool.axe")).code == "SLOTS_FULL", "full bag fails preflight before work starts")
	check(service.capture() == before and bag.capture() == custody, "capacity preflight changes neither custody nor node state")
	check(not service.gather(ACTOR, BAG, TREE, 1, Vector3(-4, 0, 5), bag.catalog.lookup("item.tool.axe")).ok, "full bag rejects gather")
	check(service.capture() == before and bag.capture() == custody, "failed gather preserves all state and RNG counters")
	check(not service.gather("actor.other", BAG, TREE, 1, Vector3(-4, 0, 5), bag.catalog.lookup("item.tool.axe")).ok, "foreign custody cannot receive gathered stock")
	check(service.capture() == before and bag.capture() == custody, "ownership failure is atomic")

func test_crafting_and_materials() -> void:
	var bag := inventory()
	var crafting := CraftingService.new()
	check(crafting.configure(bag, ResourceCatalog.defaults()) == OK, "crafting configured")
	check(bag.add(ACTOR, BAG, "item.wood.common", 6).ok, "common material stocked")
	check(bag.add(ACTOR, BAG, "item.wood.mountain", 4).ok, "alternative material stocked")
	check(bag.add(ACTOR, BAG, "item.stone.common", 5).ok, "stone stocked")
	check(bag.add(ACTOR, BAG, "item.ore.iron", 4).ok, "ore stocked")
	var before := bag.capture()
	check(crafting.craft(ACTOR, BAG, "recipe.iron_ingot", 20).code == "STATION_REQUIRED", "forge station required")
	check(bag.capture() == before, "missing station leaves stock intact")
	check(crafting.craft(ACTOR, BAG, "recipe.iron_ingot", 20, {}, ["station.forge"]).ok, "ore is atomically processed to ingot")
	check(bag.quantity(BAG, "item.ore.iron") == 2 and bag.quantity(BAG, "item.component.iron_ingot") == 1, "processing quantities conserve stock")
	check(crafting.craft(ACTOR, BAG, "recipe.tempered_sword", 30, {}, ["station.forge"]).code == "RECIPE_NOT_KNOWN", "recipe knowledge required")
	var choices := {"ingredient.wood": "item.wood.mountain"}
	var plan := crafting.preview(ACTOR, BAG, "recipe.tempered_sword", choices, ["station.forge"], ["recipe.tempered_sword"])
	check(plan.ok and plan.composition["ingredient.wood"] == "material.wood.mountain", "preview resolves chosen material composition")
	before = bag.capture()
	check(crafting.preview(ACTOR, BAG, "recipe.tempered_sword", choices, ["station.forge"], ["recipe.tempered_sword"]).ok and bag.capture() == before, "craft preview leaves custody untouched")
	check(crafting.craft(ACTOR, BAG, "recipe.tempered_sword", 30, choices, ["station.forge"], ["recipe.tempered_sword"]).ok, "chosen family material crafts")
	var sword: Dictionary = {}
	for entry: Dictionary in bag.entries(BAG):
		if entry.definition_id == "item.weapon.tempered_sword":
			sword = entry
	check(sword.get("composition", {}).get("ingredient.wood") == "material.wood.mountain", "crafted item retains selected composition")
	check(bag.quantity(BAG, "item.wood.common") == 6 and bag.quantity(BAG, "item.wood.mountain") == 3, "chosen variant only is consumed")
	var roundtrip := InventoryService.new(bag.catalog)
	check(roundtrip.restore(bag.capture()) == OK and roundtrip.entries(BAG) == bag.entries(BAG), "crafted composition and quantities survive restore")
	check(crafting.craft(ACTOR, BAG, "recipe.healing_balm", 40, {"ingredient.wood": "item.ore.iron"}).code == "INVALID_MATERIAL_CHOICE", "incompatible material choice rejected")
	check(crafting.craft(ACTOR, BAG, "recipe.healing_balm", 40, {"ingredient.forged": "item.wood.common"}).code == "INVALID_MATERIAL_CHOICE", "unknown recipe slot rejected")
	check(crafting.craft(ACTOR, BAG, "recipe.healing_balm", 40).ok, "hand crafted survival consumable")
	check(bag.quantity(BAG, "item.consumable.healing_balm") == 1 and bag.catalog.lookup("item.consumable.healing_balm").consume_heal > 0, "balm exposes existing combat healing hook")

func test_atomic_craft() -> void:
	var bag := inventory(2)
	check(bag.add(ACTOR, BAG, "item.wood.common", 3).ok and bag.add(ACTOR, BAG, "item.stone.common", 2).ok, "fill two ingredient slots with leftovers")
	var crafting := CraftingService.new()
	check(crafting.configure(bag, ResourceCatalog.defaults()) == OK, "atomic crafting configured")
	var before := bag.capture()
	check(not crafting.craft(ACTOR, BAG, "recipe.healing_balm", 1).ok, "full output capacity rejects craft")
	check(bag.capture() == before, "failed output does not consume any ingredients")
	check(crafting.craft("actor.other", BAG, "recipe.healing_balm", 1).code == "NOT_OWNER", "foreign crafting rejected")
	check(crafting.craft(ACTOR, BAG, "recipe.camp_axe", 1, {"ingredient.wood": "item.wood.mountain"}).code == "MISSING_INGREDIENTS", "unavailable chosen stock rejected")
	check(bag.capture() == before, "invalid selected input leaves inventory unchanged")
