extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var catalog := ItemCatalog.defaults()
	check(catalog.ids().size() >= 13, "authored typed item catalog loads")
	var definition := catalog.lookup("item.weapon.sword")
	check(definition != null and definition.max_stack == 1 and definition.damage_bonus == 0, "starter sword keeps established damage")
	definition.damage_bonus = 999
	check(catalog.lookup(definition.item_id).damage_bonus == 0, "catalog lookups are detached")
	definition.item_id = "item.weapon.test_sword"
	check(catalog.register(definition) == OK, "valid extensible item content registers")
	definition.damage_bonus = 888
	check(catalog.lookup(definition.item_id).damage_bonus == 999, "catalog registration copies input")
	check(catalog.register(definition) == ERR_ALREADY_EXISTS, "duplicate definition cannot replace canonical content")
	definition.item_id = "item.weapon.invalid"
	definition.max_stack = 2
	check(catalog.register(definition) == ERR_INVALID_DATA, "equipment cannot form fungible stacks")
	definition = catalog.lookup("item.wood.common")
	definition.unit_mass_grams = -1
	check(catalog.register(definition) == ERR_INVALID_DATA, "negative canonical mass rejects")
	check(catalog.lookup("item.missing") == null, "unknown definition fails closed")
	check(catalog.lookup("item.tool.pickaxe").tool_power == 2, "ore-grade pickaxe is trusted tool data")
	check(catalog.lookup("item.consumable.healing_balm").consume_heal == 15, "stable balm exposes effect data without combat mutation")

	var inventory := InventoryService.new(catalog)
	check(inventory.register_container("player.bag", "actor.player", 2, 50000) == OK, "bounded owner container registers")
	check(inventory.register_container("player.stash", "actor.player", 4, 50000) == OK, "property storage is a distinct container")
	check(inventory.register_container("npc.bag", "actor.npc", 4, 50000) == OK, "other actor custody registers")
	check(inventory.register_container("player.bag", "actor.player", 2, 50000) == ERR_ALREADY_EXISTS, "containers cannot reset by duplicate registration")
	check(inventory.register_container("bad.slots", "actor.player", 0, 50000) == ERR_INVALID_PARAMETER, "zero fixed capacity rejects")
	check(inventory.register_container("bad.weight", "actor.player", 2, -1) == ERR_INVALID_PARAMETER, "negative capacity rejects")
	var result := inventory.add("actor.player", "player.bag", "item.wood.common", 25)
	check(result.ok and result.created_ids.size() == 2, "addition allocates bounded stacks")
	var wood: Array = inventory.entries("player.bag")
	check(wood[0].quantity == 20 and wood[1].quantity == 5, "stable order fills first stack before allocating")
	check(inventory.snapshot("player.bag").mass_grams == 12500, "canonical grams derive from definition times quantity")
	var before := inventory.capture()
	check(not inventory.split("actor.player", "player.bag", wood[0].id, 3).ok and inventory.capture() == before, "split with no slot rolls back exactly")
	check(inventory.remove("actor.player", "player.bag", wood[0].id, 10).ok, "remove consumes only actual source quantity")
	check(inventory.add("actor.player", "player.bag", "item.wood.common", 6).ok, "compatible addition uses available stack space")
	check(inventory.entry("player.bag", wood[0].id).quantity == 16 and inventory.entry("player.bag", wood[1].id).quantity == 5, "fill order remains deterministic")
	check(inventory.transfer("actor.player", "player.bag", "player.stash", wood[1].id, 5).ok, "property transfer commits source and destination together")
	check(inventory.entry("player.stash", wood[1].id).quantity == 5 and inventory.entry("player.bag", wood[1].id).is_empty(), "full unmerged transfer preserves lot identity and exclusive custody")
	result = inventory.split("actor.player", "player.bag", wood[0].id, 3)
	var split_id: String = result.created_ids[0]
	check(result.ok and inventory.entry("player.bag", split_id).quantity == 3, "split allocates a new stable lot")
	check(inventory.merge("actor.player", "player.bag", split_id, wood[0].id).ok and inventory.count("player.bag", "item.wood.common") == 16, "explicit merge conserves quantity")
	check(inventory.entries("player.bag").size() == 1, "merge retires only the absorbed lot")
	check(inventory.transfer("actor.player", "player.bag", "player.stash", wood[0].id, 3).ok and inventory.entry("player.bag", wood[0].id).quantity == 13 and inventory.entry("player.stash", wood[1].id).quantity == 8, "partial transfer merges destination without duplicating source identity")
	check(inventory.add("actor.player", "player.bag", "item.wood.common", 3).ok, "restore quantity for permission cases")
	before = inventory.capture()
	check(not inventory.remove("actor.npc", "player.bag", wood[0].id, 1).ok and inventory.capture() == before, "forged owner cannot consume custody")
	check(not inventory.remove("actor.player", "player.bag", wood[0].id, 99).ok and inventory.capture() == before, "overdraw cannot create negative lots")
	check(not inventory.merge("actor.player", "player.bag", wood[0].id, wood[0].id).ok and inventory.capture() == before, "self merge rejects without duplication")
	var detached := inventory.snapshot("player.bag")
	detached.entries[0].quantity = 999
	check(inventory.count("player.bag", "item.wood.common") == 16, "snapshot cannot mutate authority ledger")

	check(inventory.register_container("player.small", "actor.player", 2, 1000) == OK, "independent gram constraint fixture")
	check(inventory.add("actor.player", "player.small", "item.wood.common", 2).ok, "exact mass boundary accepts")
	var small_entry: String = inventory.entries("player.small")[0].id
	before = inventory.capture()
	result = inventory.transact("actor.player", [{"kind": "remove", "container_id": "player.small", "entry_id": small_entry, "quantity": 1}, {"kind": "add", "container_id": "player.small", "definition_id": "item.weapon.sword", "quantity": 1}])
	check(not result.ok and result.code == "MASS_CAPACITY" and inventory.capture() == before, "late output capacity failure restores inputs IDs and revisions")
	result = inventory.transact("actor.player", [{"kind": "remove", "container_id": "player.small", "entry_id": small_entry, "quantity": 2}, {"kind": "add", "container_id": "player.small", "definition_id": "item.stone.common", "quantity": 1}], {"player.small": inventory.snapshot("player.small").revision})
	check(result.ok and inventory.count("player.small", "item.wood.common") == 0 and inventory.count("player.small", "item.stone.common") == 1, "atomic conversion sees staged freed capacity")
	before = inventory.capture()
	check(not inventory.transact("actor.player", [{"kind": "add", "container_id": "player.stash", "definition_id": "item.currency.coin", "quantity": 1}], {"player.small": 0}).ok and inventory.capture() == before, "stale revision rejects before any write")
	for amount: Variant in [-1, 0, 0.5, NAN, INF, "2", true]:
		check(not inventory.transact("actor.player", [{"kind": "add", "container_id": "player.stash", "definition_id": "item.currency.coin", "quantity": amount}]).ok and inventory.capture() == before, "invalid quantity rejects: %s" % str(amount))
	check(not inventory.transact("actor.player", [{"kind": "add", "container_id": "player.stash", "definition_id": "item.currency.coin", "quantity": 1, "trusted_outcome": true}]).ok and inventory.capture() == before, "unknown mutation fields reject")
	check(not inventory.add("actor.player", "player.stash", "item.missing", 1).ok and inventory.capture() == before, "unknown item cannot enter state")
	check(not inventory.add("actor.player", "player.stash", "item.currency.coin", 1, {"condition": NAN}).ok and inventory.capture() == before, "nonfinite condition rejects")
	check(not inventory.add("actor.player", "player.stash", "item.currency.coin", 1, {"composition": {"object": RefCounted.new()}}).ok and inventory.capture() == before, "object metadata cannot cross serialization boundary")
	var excessive_ops: Array = []
	for i: int in InventoryService.MAX_OPERATIONS + 1:
		excessive_ops.append({"kind": "add", "container_id": "player.stash", "definition_id": "item.currency.coin", "quantity": 1})
	check(not inventory.transact("actor.player", excessive_ops).ok and inventory.capture() == before, "oversized command batch rejects before work")
	var capacity_test := InventoryService.new(catalog)
	capacity_test.register_container("dynamic.bag", "actor.player", -1, 1000000)
	var empty_dynamic := capacity_test.capture()
	check(not capacity_test.add("actor.player", "dynamic.bag", "item.weapon.sword", InventoryService.MAX_SLOTS + 1).ok and capacity_test.capture() == empty_dynamic, "dynamic allocation has a finite hard ceiling and atomic overflow")
	check(capacity_test.add("actor.player", "dynamic.bag", "item.weapon.sword", InventoryService.MAX_SLOTS).ok and capacity_test.entries("dynamic.bag").size() == InventoryService.MAX_SLOTS, "exact dynamic logical stack ceiling accepts")

	check(inventory.register_container("player.layers", "actor.player", -1, 100000) == OK, "dynamic logical slots remain bounded and weight limited")
	check(inventory.add("actor.player", "player.layers", "item.consumable.healing_balm", 3, {"condition": 5000, "composition": {"base": "material.wood.common"}, "provenance": {"source": "craft", "tick": 1}}).ok, "condition composition and provenance are canonical metadata")
	check(inventory.add("actor.player", "player.layers", "item.consumable.healing_balm", 1).ok, "fresh compatible definition keeps distinct metadata")
	var layers := inventory.entries("player.layers")
	check(layers.size() == 2 and layers[0].condition == 5000 and layers[1].condition == 10000, "condition is never averaged refreshed or inherited during stacking")
	before = inventory.capture()
	check(not inventory.merge("actor.player", "player.layers", layers[0].id, layers[1].id).ok and inventory.capture() == before, "incompatible conditions compositions and history cannot merge")
	check(inventory.add("actor.player", "player.layers", "item.consumable.healing_balm", 1, {"condition": 5000, "composition": {"base": "material.wood.common"}, "provenance": {"source": "craft", "tick": 1}}).ok and inventory.entries("player.layers")[0].quantity == 4, "exact metadata matches may share a lot")
	var restored := InventoryService.new(catalog)
	var serialized: Dictionary = JSON.parse_string(JSON.stringify(inventory.capture()))
	check(restored.restore(serialized) == OK and restored.capture() == inventory.capture(), "serialization restores current quantities custody and metadata exactly")
	if failures:
		quit(1)
		return
	serialized.containers[1].entries[0].quantity = -1
	before = restored.capture()
	check(restored.restore(serialized) == ERR_INVALID_DATA and restored.capture() == before, "corrupt restore is side effect free")
	serialized = inventory.capture()
	serialized.containers[1].entries.append(serialized.containers[1].entries[0].duplicate(true))
	check(restored.validate_state(serialized) == ERR_INVALID_DATA, "duplicate instance identity rejects on restore")
	serialized = inventory.capture()
	serialized.next_entry = 1
	check(restored.validate_state(serialized) == ERR_INVALID_DATA, "restore cannot reset identity allocator")
	serialized = inventory.capture()
	serialized.containers[1].entries[0].container_id = "wrong.custody"
	check(restored.validate_state(serialized) == ERR_INVALID_DATA, "orphaned custody rejects on restore")
	serialized = inventory.capture()
	serialized.containers[1].max_mass_grams = 0
	check(restored.validate_state(serialized) == ERR_INVALID_DATA, "overweight serialized state rejects")

	result = inventory.add("actor.npc", "npc.bag", "item.weapon.sword", 1)
	var sword_id: String = result.created_ids[0]
	check(inventory.transfer("actor.npc", "npc.bag", "player.stash", sword_id, 1).ok, "trusted give changes holder without forging legal ownership")
	var equipment := EquipmentState.new("actor.player")
	check(equipment.equip("weapon", "player.stash", sword_id, inventory) == OK, "valid possession can equip the same transferred instance")
	check(inventory.entry("player.stash", sword_id).owner_id == "actor.npc", "legal ownership remains distinct from possession")
	check(equipment.references()[0].entry_id == sword_id and equipment.definitions(inventory).weapon.item_id == "item.weapon.sword", "equipment exposes instance references and copied definitions")
	check(equipment.equip("tool", "player.stash", sword_id, inventory) == ERR_INVALID_DATA, "equipment slot mismatch rejects")
	check(EquipmentState.new("actor.npc").equip("weapon", "player.stash", sword_id, inventory) == ERR_INVALID_DATA, "another holder cannot equip stored property")
	var equipment_copy := EquipmentState.new("actor.player")
	check(equipment_copy.restore(equipment.capture(), inventory) == OK, "equipment references serialize without second item copies")
	check(inventory.remove("actor.player", "player.stash", sword_id, 1).ok and equipment.validate(inventory) == ERR_INVALID_DATA, "stale equipment references are detectable at owning host boundary")
	check(equipment.unequip("weapon") == OK and equipment.validate(inventory) == OK, "unequipping removes only the reference")

	var core := CoreRuntimeServicesModule.new()
	var combat := CombatModule.new()
	var modules := CoreModuleRegistry.new()
	modules.add(core)
	modules.add(combat)
	check(modules.boot() == OK, "skill eligibility uses the real action catalog in isolation")
	var skills := LearnedSkillSet.new("actor.player")
	var loadout := preload("res://data/actions/player_loadout.tres").duplicate(true) as ActionLoadout
	check(skills.validate_loadout(loadout, combat.actions) == ERR_UNAUTHORIZED, "catalog existence alone does not grant a skill")
	check(skills.learn("combat.action.basic_strike", "skill.source.starter", combat.actions) == OK, "authority records explicit learned source")
	check(skills.learn("combat.action.strong_strike", "skill.source.trainer", combat.actions) == OK, "independent world learning uses same eligibility")
	check(skills.grant("combat.action.basic_heal", "skill.source.equipment", combat.actions) == OK and skills.validate_loadout(loadout, combat.actions) == OK, "temporary item grant can satisfy validated loadout")
	skills.revoke_source("skill.source.equipment")
	check(not skills.eligible("combat.action.basic_heal", combat.actions) and skills.validate_loadout(loadout, combat.actions) == ERR_UNAUTHORIZED, "removing grant removes eligibility")
	check(skills.learn("combat.action.basic_heal", "skill.source.book", combat.actions) == OK and skills.grant("combat.action.basic_heal", "skill.source.equipment", combat.actions) == OK, "learned and granted ownership coexist")
	skills.revoke_source("skill.source.equipment")
	check(skills.eligible("combat.action.basic_heal", combat.actions), "revoking equipment cannot erase learned ability")
	check(skills.learn("combat.action.unknown", "skill.source.book", combat.actions) == ERR_INVALID_PARAMETER, "unknown abilities cannot be learned")
	check(skills.learn("combat.action.basic_heal", "skill.source.book", combat.actions) == ERR_ALREADY_EXISTS, "duplicate source records do not grow unbounded")
	var skill_copy := LearnedSkillSet.new("actor.player")
	check(skill_copy.restore(JSON.parse_string(JSON.stringify(skills.capture())), combat.actions) == OK and skill_copy.capture() == skills.capture(), "learned source state persists without template reconstruction")
	var bad_skills := skills.capture()
	bad_skills.known["combat.action.missing"] = ["skill.source.book"]
	before = skill_copy.capture()
	check(skill_copy.restore(bad_skills, combat.actions) == ERR_INVALID_DATA and skill_copy.capture() == before, "corrupt unknown action restore leaves learned ownership intact")
	modules.shutdown()
	print("Item inventory tests: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
