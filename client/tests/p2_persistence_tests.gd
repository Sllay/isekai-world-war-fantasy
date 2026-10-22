extends SceneTree

const ITEMS := "gameplay.items_resources"
const REGION := "region.home_valley"
const SPAWN := "spawn.melee_skirmisher"
const DROP := "drop.spawn.melee_skirmisher"
var checks := 0
var failures := 0
var slot := ""
var runtime: Node

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func freeze() -> void:
	runtime.set_process(false)
	var avatar: PlayerAvatar = runtime.world_scene.active_region.avatar
	avatar.motor.set_physics_process(false)
	avatar.input.set_physics_process(false)
	avatar.input.set_process_input(false)
	avatar.intent.clear_transient()
	runtime.persistence.suppress_autosave = true

func write(value: Dictionary) -> void:
	var file := FileAccess.open(slot, FileAccess.WRITE)
	file.store_string(JSON.stringify(value))
	file.close()

func bag(value: Dictionary, id: String = ItemsModule.BAG) -> Dictionary:
	for container: Dictionary in value.sections[ITEMS].state.inventory.containers:
		if container.id == id: return container
	return {}

func run() -> void:
	slot = "user://tests/p2-persistence-%s.json" % CoreIds.generate()
	runtime = preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.p2_persistence", slot)
	root.add_child(runtime)
	check(runtime.startup_error == OK, "P2 persistence runtime boots")
	freeze()
	check(runtime.save_game() == OK, "valid starter checkpoint writes")
	var starter: Dictionary = runtime.persistence.capture_snapshot()
	check(not runtime.persistence.integrity.prepare(starter).is_empty(), "current starter snapshot validates")
	var legacy := starter.duplicate(true)
	legacy.game_version = "0.3.0"
	legacy.modules.erase(ITEMS)
	legacy.sections.erase(ITEMS)
	legacy.sections["foundation.player_combat"].state.combatant.health = 73
	legacy.sections["foundation.player_combat"].state.combatant.resource = 29
	legacy.sections["foundation.player_combat"].state.actions.cooldowns["combat.action.strong_strike"] = 17
	var actors: Dictionary = legacy.sections["foundation.regions"].state.regions[REGION].actors
	actors[SPAWN].combatant.health = 0
	actors[SPAWN].combatant.lifecycle = Combatant.Lifecycle.DEFEATED
	actors["spawn.melee_skirmisher_second"].combatant.health = 64
	var old_copy := legacy.duplicate(true)
	var upgraded: Dictionary = runtime.persistence.integrity.prepare(legacy)
	check(not upgraded.is_empty() and upgraded.game_version == "0.4.0", "explicit P1 release upgrades to P2")
	if not upgraded.is_empty():
		check(upgraded.sections["foundation.player_combat"].state == legacy.sections["foundation.player_combat"].state, "P1 upgrade preserves health/resources/actions/defense exactly")
		check(upgraded.sections["foundation.regions"] == legacy.sections["foundation.regions"], "P1 upgrade preserves both actors and region state")
		var tombstone: Dictionary = upgraded.sections[ITEMS].state.drops.get(DROP, {})
		check(bag(upgraded, ItemsModule.npc_container(SPAWN)).entries.is_empty() and upgraded.sections[ITEMS].state.looted[SPAWN] and tombstone.get("claimed", false) and bag(upgraded, "inventory." + DROP).get("entries", [null]).is_empty(), "old dead NPC receives only empty claimed custody tombstone, no retroactive loot")
	check(legacy == old_copy and runtime.persistence.capture_snapshot() == starter, "migration preparation mutates neither input nor live canonical state")
	test_corruption(starter)
	write(legacy)
	check(runtime.resume_game() == OK, "actual save coordinator resumes explicit old release")
	freeze()
	check(runtime.player_combat.state.health == 73 and runtime.player_combat.state.resource == 29 and runtime.player_combat.actions.remaining_cooldown("combat.action.strong_strike") == 17, "disk migration preserves old effects/cooldown")
	check(runtime.items.inventory.entries(ItemsModule.npc_container(SPAWN)).is_empty() and runtime.items.drops.get(DROP, {}).get("claimed", false) and runtime.items.inventory.entries("inventory." + DROP).is_empty(), "disk migration does not invent loot for old defeated actor")
	var migrated: Dictionary = runtime.items.capture_state()
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "upgraded state saves and resumes as current release")
	freeze()
	check(runtime.items.capture_state() == migrated, "subsequent reload never reapplies migration stock")
	test_drop_custody(starter)
	test_drop_float_roundtrip(starter)
	test_pending_work(starter)
	runtime.free()
	DirAccess.remove_absolute(slot)
	await process_frame
	print("P2 persistence tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_corruption(starter: Dictionary) -> void:
	var cases: Array[Dictionary] = []
	var broken := starter.duplicate(true)
	broken.sections.erase(ITEMS)
	cases.append({"label": "missing current item section", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections.erase(ITEMS)
	broken.modules.erase(ITEMS)
	cases.append({"label": "current save cannot masquerade as pre-items release", "snapshot": broken})
	broken = starter.duplicate(true)
	bag(broken).entries.append(bag(broken).entries[0].duplicate(true))
	cases.append({"label": "duplicate entry ID", "snapshot": broken})
	broken = starter.duplicate(true)
	bag(broken).entries[0].definition_id = "item.missing"
	cases.append({"label": "orphan item definition", "snapshot": broken})
	broken = starter.duplicate(true)
	bag(broken).entries[0].owner_id = CoreIds.generate()
	cases.append({"label": "orphan item legal owner", "snapshot": broken})
	broken = starter.duplicate(true)
	bag(broken, ItemsModule.npc_container(SPAWN)).owner_id = broken.sections[ITEMS].state.owner_id
	cases.append({"label": "NPC carried container with foreign holder", "snapshot": broken})
	broken = starter.duplicate(true)
	bag(broken, ItemsModule.STASH).id = "inventory.unknown"
	cases.append({"label": "missing authored stash container", "snapshot": broken})
	broken = starter.duplicate(true)
	var extra_ledger := InventoryService.new(runtime.items.catalog)
	extra_ledger.restore(broken.sections[ITEMS].state.inventory)
	extra_ledger.register_container("inventory.unknown", broken.sections[ITEMS].state.owner_id, 8, 10000)
	broken.sections[ITEMS].state.inventory = extra_ledger.capture()
	cases.append({"label": "unregistered extra container", "snapshot": broken})
	broken = starter.duplicate(true)
	bag(broken).slots = 25
	cases.append({"label": "authored container capacity tampering", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections[ITEMS].state.skills.owner_id = CoreIds.generate()
	cases.append({"label": "foreign learned-skill owner", "snapshot": broken})
	broken = starter.duplicate(true)
	var foreign_owner: String = broken.sections["foundation.regions"].state.regions[REGION].actors[SPAWN].entity_id
	broken.sections[ITEMS].state.owner_id = foreign_owner
	broken.sections[ITEMS].state.equipment.owner_id = foreign_owner
	broken.sections[ITEMS].state.skills.owner_id = foreign_owner
	bag(broken).owner_id = foreign_owner
	bag(broken, ItemsModule.STASH).owner_id = foreign_owner
	cases.append({"label": "coherent item header bound to wrong actor", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections[ITEMS].state.loadout.slots.skill_3 = "combat.action.enemy.basic_strike"
	cases.append({"label": "unowned skill inserted into loadout", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections[ITEMS].state.loadout.slots.primary = ""
	cases.append({"label": "missing required primary loadout action", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections[ITEMS].state.skills.grants["combat.action.basic_heal"] = ["skill.source.equipment_tool"]
	cases.append({"label": "phantom equipment-granted skill source", "snapshot": broken})
	broken = starter.duplicate(true)
	var foreign := bag(broken, ItemsModule.npc_container(SPAWN))
	broken.sections[ITEMS].state.equipment.slots.weapon = {"container_id": foreign.id, "entry_id": foreign.entries[0].id}
	cases.append({"label": "foreign equipment reference", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections[ITEMS].state.equipment.slots.weapon.entry_id = "entry.missing"
	cases.append({"label": "orphan equipment entry", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections[ITEMS].state.resources.nodes["resource.node.common_tree"].profile_id = "resource.profile.stone"
	cases.append({"label": "resource profile substitution", "snapshot": broken})
	broken = starter.duplicate(true)
	var node: Dictionary = broken.sections[ITEMS].state.resources.nodes["resource.node.common_tree"]
	node.remaining = 0
	node.extractions = 3
	node.regeneration_tick = broken.sections["core.runtime"].state.clock.tick + 301
	cases.append({"label": "impossible future regeneration deadline", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections["foundation.player_combat"].state.combatant.modifiers.append(CombatModifier.new(ItemsModule.EQUIPMENT_SOURCE, CombatModifier.Stat.DAMAGE_SCALE, CombatModifier.Operator.ADD, 2000).capture())
	cases.append({"label": "forged equipment combat contribution", "snapshot": broken})
	broken = starter.duplicate(true)
	broken.sections[ITEMS].state.pending = {"kind": "item.harvest"}
	cases.append({"label": "pending job injected into persistent schema", "snapshot": broken})
	var resident: RegionScene = runtime.world_scene.active_region
	for item: Dictionary in cases:
		write(item.snapshot)
		check(runtime.resume_game() != OK, "reject %s" % item.label)
		check(runtime.persistence.capture_snapshot() == starter and runtime.world_scene.active_region == resident, "invalid %s preserves every live section and residency" % item.label)
	write(starter)
	check(runtime.resume_game() == OK, "repaired current checkpoint restores normally")
	freeze()
	var tempered := starter.duplicate(true)
	for entry: Dictionary in bag(tempered).entries:
		if entry.definition_id == "item.weapon.sword": entry.definition_id = "item.weapon.tempered_sword"
	tempered.sections["foundation.player_combat"].state.combatant.modifiers.append(CombatModifier.new(ItemsModule.EQUIPMENT_SOURCE, CombatModifier.Stat.DAMAGE_SCALE, CombatModifier.Operator.ADD, 2000).capture())
	check(not runtime.persistence.integrity.prepare(tempered).is_empty(), "matching equipped weapon and combat contribution validates")
	tempered.sections["foundation.player_combat"].state.combatant.modifiers[0].value = 1999
	check(runtime.persistence.integrity.prepare(tempered).is_empty(), "corrupted equipped weapon contribution rejects")

func test_drop_custody(starter: Dictionary) -> void:
	# A fixture transaction models the actual death transition without fabricating
	# stock: transfer the current carried entries with their existing identities.
	var value := starter.duplicate(true)
	var state: Dictionary = value.sections[ITEMS].state
	var actor: Dictionary = value.sections["foundation.regions"].state.regions[REGION].actors[SPAWN]
	actor.combatant.health = 0
	actor.combatant.lifecycle = Combatant.Lifecycle.DEFEATED
	var ledger := InventoryService.new(runtime.items.catalog)
	check(ledger.restore(state.inventory) == OK, "death fixture starts from exact carried ledger")
	var cache := "inventory." + DROP
	check(ledger.register_container(cache, state.owner_id, 16, 50000) == OK, "persistent world cache registered")
	var operations: Array = []
	for entry: Dictionary in ledger.entries(ItemsModule.npc_container(SPAWN)):
		operations.append({"kind": "transfer", "source_id": ItemsModule.npc_container(SPAWN), "destination_id": cache, "entry_id": entry.id, "quantity": entry.quantity})
	check(ledger.transact(actor.entity_id, operations).ok, "current carried stock transfers atomically to cache")
	state.inventory = ledger.capture()
	state.looted[SPAWN] = true
	state.drops[DROP] = {"source": SPAWN, "container": cache, "owner": state.owner_id, "position": actor.position.duplicate(), "region": REGION, "claimed": false}
	check(not runtime.persistence.integrity.prepare(value).is_empty(), "valid dead NPC and unclaimed stock cache validates")
	var orphan := value.duplicate(true)
	orphan.sections[ITEMS].state.drops.erase(DROP)
	check(runtime.persistence.integrity.prepare(orphan).is_empty(), "drop mapping cannot disappear while its canonical stock remains")
	write(value)
	check(runtime.resume_game() == OK, "unclaimed persistent cache resumes")
	freeze()
	check(runtime.items.capture_state() == state, "reload preserves unclaimed stock, ownership and identity exactly")
	operations.clear()
	for entry: Dictionary in ledger.entries(cache):
		operations.append({"kind": "transfer", "source_id": cache, "destination_id": ItemsModule.BAG, "entry_id": entry.id, "quantity": entry.quantity})
	check(ledger.transact(state.owner_id, operations).ok, "pickup fixture transfers existing stock instead of granting replacement")
	state.inventory = ledger.capture()
	state.drops[DROP].claimed = true
	write(value)
	check(runtime.resume_game() == OK, "claimed cache resumes")
	freeze()
	check(runtime.items.capture_state() == state and runtime.items.inventory.entries(cache).is_empty(), "claimed cache never refills on reload")
	var bad := value.duplicate(true)
	bad.sections[ITEMS].state.drops[DROP].container = "inventory.missing"
	check(runtime.persistence.integrity.prepare(bad).is_empty(), "orphan drop custody rejects")
	bad = value.duplicate(true)
	bad.sections[ITEMS].state.drops[DROP].position[0] += 1
	check(runtime.persistence.integrity.prepare(bad).is_empty(), "drop source position cannot diverge from canonical actor")

func test_drop_float_roundtrip(starter: Dictionary) -> void:
	# Real death at a float32 world position whose JSON float64 representation is
	# not byte-identical after parsing. Repeated production saves must retain the
	# same canonical point and actual stock; tolerance must not admit moved loot.
	write(starter)
	check(runtime.resume_game() == OK, "fractional death fixture restores pristine actors")
	freeze()
	var actor: EnemyActor = runtime.enemies.actor
	actor.position = Vector3(3.968990325927734, 0.000220715650357306, 3.067920684814453)
	var expected_position := actor.position
	var carried: Array = runtime.items.inventory.entries(ItemsModule.npc_container(SPAWN))
	var damage: CombatResult = runtime.combat.service.damage(DamageRequest.new(runtime.player.state.entity_id, actor.entity_id, 1000))
	check(damage.accepted and actor.combatant.lifecycle == Combatant.Lifecycle.DEFEATED and runtime.items.drops.has(DROP), "actual defeat creates cache at fractional authoritative position")
	var expected_inventory: Dictionary = runtime.items.inventory.capture()
	var cache := "inventory." + DROP
	var expected_entries: Array = carried.duplicate(true)
	for entry: Dictionary in expected_entries: entry.container_id = cache
	check(runtime.items.inventory.entries(cache) == expected_entries and runtime.items.inventory.entries(ItemsModule.npc_container(SPAWN)).is_empty(), "fractional death moves the same stock identities and custody")
	for cycle in range(2):
		check(runtime.save_game() == OK and runtime.resume_game() == OK, "fractional loot survives production save/resume cycle %d" % cycle)
		freeze()
		var point: Array = runtime.items.drops[DROP].position
		check(runtime.items.inventory.capture() == expected_inventory and not runtime.items.drops[DROP].claimed and Vector3(point[0], point[1], point[2]) == expected_position and actor.position == expected_position, "roundtrip %d preserves exact engine position and carried stock without refill" % cycle)
	var coherent: Dictionary = runtime.persistence.capture_snapshot()
	var displaced := coherent.duplicate(true)
	displaced.sections[ITEMS].state.drops[DROP].position[0] += 0.01
	check(runtime.persistence.integrity.prepare(displaced).is_empty(), "fractional normalization still rejects genuinely displaced world cache")
	var resident: RegionScene = runtime.world_scene.active_region
	write(displaced)
	check(runtime.resume_game() != OK and runtime.persistence.capture_snapshot() == coherent and runtime.world_scene.active_region == resident, "displaced cache rejects without changing stock, canonical actor or residency")

func test_pending_work(starter: Dictionary) -> void:
	var value := starter.duplicate(true)
	value.sections["foundation.player"].state.position = [-4, 0.1, 5]
	write(value)
	check(runtime.resume_game() == OK, "authored gather-position fixture resumes")
	freeze()
	var inventory_before: Dictionary = runtime.items.inventory.capture()
	var nodes_before: Dictionary = runtime.items.resources.capture()
	check(runtime.authority_gateway.request("item.harvest", {"node": "resource.node.common_tree"}).get("accepted", false), "pending harvest enters real gateway")
	runtime._process(0.05)
	check(runtime.player_combat.actions.phase == ActionExecutor.Phase.CASTING, "harvest is saved during actual shared-executor windup")
	check(runtime.items.inventory.capture() == inventory_before and runtime.items.resources.capture() == nodes_before, "uncommitted harvest has produced no items or depletion")
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "pending harvest checkpoint resumes")
	freeze()
	check(runtime.player_combat.actions.phase == ActionExecutor.Phase.IDLE and runtime.player_combat.actions.current == null, "pending item action is discarded on resume")
	check(runtime.items.inventory.capture() == inventory_before and runtime.items.resources.capture() == nodes_before, "resume preserves exact precommit custody and reserves")
	for _step in range(20): runtime._process(0.05)
	check(runtime.items.inventory.capture() == inventory_before and runtime.items.resources.capture() == nodes_before, "discarded pending context cannot commit later")
