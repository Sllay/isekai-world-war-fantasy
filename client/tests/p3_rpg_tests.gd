extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(label)

func run() -> void:
	var catalog := LivingCatalog.defaults()
	check(catalog.valid(), "typed living/race/class/faction catalog validates")
	check(catalog.races.size() == 1 and catalog.classes.size() == 1, "one representative race/class without final roster")
	var race := catalog.race("race.human")
	var visual := catalog.visual(race.visual_profile_id)
	check(visual != null and visual.body_families.has("lpc.body.adult"), "race references curated LPC-compatible visual profile")
	check(visual.palette_ids.size() == 3, "palette references are data, not raw image state")
	visual.uniform_scale = 1.8
	check(catalog.visual(race.visual_profile_id).uniform_scale == 1.0, "visual lookup is detached")
	race.historical_faction_id = "faction.raiders"
	check(catalog.race("race.human").historical_faction_id == "faction.home_valley", "race metadata lookup cannot mutate catalog")
	var invalid := catalog.duplicate(true) as LivingCatalog
	invalid.races[0].visual_profile_id = "race.visual.missing"
	check(not invalid.valid(), "unknown visual reference rejects")
	invalid = catalog.duplicate(true) as LivingCatalog
	invalid.classes[0].progression_id = "progression.missing"
	check(not invalid.valid(), "unknown progression rejects")
	invalid = catalog.duplicate(true) as LivingCatalog
	invalid.factions[0].dispositions["faction.missing"] = "hostile"
	check(not invalid.valid(), "unknown faction disposition rejects")
	invalid = catalog.duplicate(true) as LivingCatalog
	invalid.races.append(invalid.races[0])
	check(not invalid.valid(), "duplicate content identity rejects")
	check(catalog.disposition("faction.home_valley", "faction.raiders") == "hostile", "data-driven hostile relationship")
	check(catalog.disposition("faction.home_valley", "faction.home_valley") == "friendly", "same allegiance is friendly")
	check(catalog.disposition("faction.free", "faction.raiders") == "neutral", "sparse unspecified relationship is neutral")
	check(catalog.disposition("faction.missing", "faction.raiders") == "invalid", "unknown faction never grants arbitrary disposition")
	var actor := LivingActorState.new()
	var id := "a".repeat(32)
	check(actor.configure(id, "bot", catalog) == OK, "logical bot configures without any Node")
	actor.chunk_id = "region.home_valley:1:0"
	actor.position = Vector3(40, 1.25, 4)
	actor.allegiance = "faction.raiders"
	check(actor.player_state.entity_id == id and actor.player_state.position == actor.position, "one canonical PlayerState backs actor identity and movement")
	actor.player_state.position += Vector3.RIGHT
	check(actor.position.x == 41, "movement adapter and logical state cannot diverge")
	check(actor.attributes.value("strength") == 11 and actor.attributes.value("intellect") == 7, "class base plus race source computes RPG attributes")
	check(actor.attributes.install("rpg.source.training", {"strength": 3, "agility": 0, "intellect": 0, "vitality": 2}) == OK and actor.attributes.value("strength") == 14, "typed source modifier influences data-layer attribute")
	actor.attributes.remove("rpg.source.training")
	check(actor.attributes.value("strength") == 11, "removing modifier preserves race and base")
	check(actor.attributes.install("rpg.source.forged", {"strength": 9999}) != OK, "malformed stat soup/modifier rejects")
	var known := func(subject: String) -> bool: return subject == id
	var snapshot := actor.capture()
	check(LivingActorState.valid(snapshot, catalog, known), "race can have current allegiance different from historical association")
	var restored := LivingActorState.new()
	check(restored.restore(snapshot, catalog, known) == OK and restored.capture() == snapshot, "logical actor roundtrips identity/data without physics body")
	var bad := snapshot.duplicate(true)
	bad.movement.entity_id = "b".repeat(32)
	check(not LivingActorState.valid(bad, catalog, known), "actor/movement ownership mismatch rejects")
	bad = snapshot.duplicate(true)
	bad.allegiance = "faction.missing"
	check(not LivingActorState.valid(bad, catalog, known), "invalid faction reference rejects")
	bad = snapshot.duplicate(true)
	bad.relationships["b".repeat(32)] = 10
	check(not LivingActorState.valid(bad, catalog, known), "sparse relationships cannot reference nonexistent actor")
	bad = snapshot.duplicate(true)
	bad.attributes.base["new_overpowered_stat"] = 999
	check(not LivingActorState.valid(bad, catalog, known), "attribute schema rejects undeclared keys")
	var definition := catalog.progression("progression.chapter1_foundation")
	var progression := LivingProgression.new()
	var reward := progression.award("combat.defeat", id, 1, definition)
	check(reward.accepted and reward.amount == 25 and reward.level == 2 and progression.xp == 25, "trusted gameplay cause awards configured XP and level")
	var state := progression.capture()
	check(not progression.award("combat.defeat", id, 1, definition).accepted and progression.capture() == state, "duplicate gameplay reward cannot grant XP twice")
	check(not progression.award("combat.defeat", id, 0, definition).accepted and progression.capture() == state, "stale reward cannot mutate progress")
	check(not progression.award("client.grant_me_xp", id, 2, definition).accepted and progression.capture() == state, "forged XP cause rejected without arbitrary amount API")
	check(not progression.award("combat.defeat", "invalid", 2, definition).accepted, "invalid reward source rejects")
	var resumed := LivingProgression.new()
	check(resumed.restore(JSON.parse_string(JSON.stringify(state)), definition, known) == OK and resumed.capture() == state, "progression/highwater survive serialized resume")
	check(not resumed.award("combat.defeat", id, 1, definition).accepted, "reload cannot replay earlier reward")
	check(resumed.award("combat.defeat", id, 2, definition).accepted and resumed.xp == 50, "later trusted source occurrence remains eligible")
	check(resumed.award("resource.harvest", "resource.node.proof", 1, definition).accepted and resumed.xp == 53, "another gameplay cause derives its own configured amount")
	check(not LivingProgression.valid(resumed.capture(), definition, known), "cross-reference validator rejects unknown reward source")
	var capacity := LivingProgression.new()
	for index in LivingProgression.MAX_SOURCES:
		capacity.award("world.discovery", "world.source.e%d" % index, 1, definition)
	var before := capacity.capture()
	check(not capacity.award("world.discovery", "world.source.overflow", 1, definition).accepted and capacity.capture() == before, "bounded replay ledger fails closed instead of forgetting old rewards")
	var attributes_state := actor.attributes.capture()
	check(RpgAttributes.valid(attributes_state), "attribute persistent schema validates")
	attributes_state.modifiers["rpg.source.race"].strength = NAN
	check(not RpgAttributes.valid(attributes_state), "nonfinite attributes reject")
	test_class_capabilities(catalog)
	print("P3 RPG tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func test_class_capabilities(catalog: LivingCatalog) -> void:
	# Explicit authority-domain harness: the same host and ItemsAuthorityPort
	# consume the class policy. No client receives a grant/equip bypass API.
	var registry := CoreModuleRegistry.new()
	var core := CoreRuntimeServicesModule.new()
	var combat := CombatModule.new()
	registry.add(core)
	registry.add(combat)
	check(registry.boot() == OK, "class capability harness uses real Core/Combat catalog")
	var items := ItemCatalog.defaults()
	var warrior := catalog.character_class("class.warrior")
	for id: String in items.ids():
		var definition := items.lookup(id)
		if not definition.equipment_slot.is_empty(): check(warrior.allows_equipment(definition), "representative class accepts existing P2 equipment tags: " + id)
	var known := LearnedSkillSet.new("c".repeat(32))
	check(warrior.seed_skills(known, combat.actions) == OK and known.known_ids().size() == warrior.starting_actions.size(), "class definition atomically seeds its declared starting ownership")
	var before := known.capture()
	check(warrior.seed_skills(known, combat.actions) == OK and known.capture() == before, "class starting ownership seeding is idempotent")
	var invalid := warrior.duplicate(true) as ClassDefinition
	invalid.starting_actions.append("combat.action.missing")
	check(invalid.seed_skills(known, combat.actions) != OK and known.capture() == before, "unknown class starting action cannot partially mutate skill ownership")
	var restricted := warrior.duplicate(true) as ClassDefinition
	restricted.starting_actions.assign(["combat.action.basic_strike", "combat.action.strong_strike"])
	restricted.equipment_tags.assign(["tool.axe"])
	var actor := LivingActorState.new()
	actor.configure(core.entities.create(), "bot", catalog)
	actor.fidelity = LivingActorState.Fidelity.L0
	var resources := ResourceService.new()
	resources.configure(InventoryService.new(items), ResourceCatalog.defaults())
	var bundle := LivingCapabilities.new()
	bundle.configure(actor, combat.service, combat.actions, items, ResourceCatalog.defaults(), resources, restricted)
	bundle.seed_stock()
	check(bundle.items.skills.known_ids().size() == 2 and not bundle.items.skills.eligible("combat.action.basic_heal", combat.actions), "LivingCapabilities derives skills from selected class, not a hardcoded list")
	check(not bundle.items.equipment.capture().slots.has("weapon") and bundle.items.equipment.capture().slots.has("tool"), "initial owned equipment respects the same class compatibility policy")
	check(bundle.items.loadout.slots.skill_2.is_empty(), "starting loadout removes optional slots whose action was not class-owned")
	var host := LocalAuthorityHost.new()
	host.configure(combat.service, bundle.actions, actor.player_state, "")
	host.server_intent_epoch = 1
	var port := ItemsAuthorityPort.new()
	port.bind_context(host, bundle.items)
	var inventory := bundle.items.inventory.capture()
	var equipment := bundle.items.equipment.capture()
	var combatant := bundle.combatant.capture()
	var pick := entry_id(bundle, "item.tool.pickaxe")
	var result := host.submit_authority_intent(actor.actor_id, 1, "item.equip", {"slot": "tool", "entry": pick})
	check(result.code == "CLASS_EQUIPMENT_REJECTED", "shared authority port rejects owned but class-ineligible equipment")
	check(bundle.items.inventory.capture() == inventory and bundle.items.equipment.capture() == equipment and bundle.combatant.capture() == combatant, "class rejection commits neither custody, equipment nor combat effects")
	check(bundle.items.inventory.add(actor.actor_id, bundle.items.bag_id, "item.weapon.tempered_sword", 1).ok, "trusted fixture owns a weapon with a real P2 combat modifier")
	inventory = bundle.items.inventory.capture()
	result = host.submit_authority_intent(actor.actor_id, 1, "item.equip", {"slot": "weapon", "entry": entry_id(bundle, "item.weapon.tempered_sword")})
	check(result.code == "CLASS_EQUIPMENT_REJECTED" and bundle.items.inventory.capture() == inventory and bundle.items.equipment.capture() == equipment and bundle.combatant.capture() == combatant, "class-ineligible weapon cannot install its authoritative damage bonus")
	result = host.submit_authority_intent(actor.actor_id, 1, "item.equip", {"slot": "tool", "entry": entry_id(bundle, "item.tool.axe")})
	check(result.code == "EQUIPPED", "shared authority port equips a class-compatible owned tool")
	result = host.submit_authority_intent(actor.actor_id, 1, "skill.equip", {"slot": "skill_2", "action": "combat.action.basic_heal"})
	check(result.code == "SKILL_NOT_OWNED", "shared skill equip requires starting or learned ownership")
	check(bundle.items.skills.learn("combat.action.basic_heal", "skill.source.learning", combat.actions) == OK, "future learning remains distinct from starting class actions")
	result = host.submit_authority_intent(actor.actor_id, 1, "skill.equip", {"slot": "skill_2", "action": "combat.action.basic_heal"})
	check(result.code == "SKILL_EQUIPPED", "later learned skill can equip without expanding starting-action allowlist")
	host.dispose()
	check(not bundle.items.equipment_eligibility.is_valid(), "transient authority disposal releases class eligibility callback")
	bundle.bind_item_eligibility()
	check(bundle.items.equipment_eligibility.is_valid() and not bool(bundle.items.equipment_eligibility.call(items.lookup("item.tool.pickaxe"))), "rematerialization reinstalls the actor's class policy")
	bundle.dispose()
	registry.shutdown()

func entry_id(bundle: LivingCapabilities, definition_id: String) -> String:
	for entry: Dictionary in bundle.items.inventory.entries(bundle.items.bag_id):
		if entry.definition_id == definition_id: return entry.id
	return ""
