extends SceneTree

class Relations extends CombatTargetPolicy:
	var selected := Relationship.ENEMY
	func relationship(_source: String, _target: String) -> Relationship:
		return selected

var checks := 0
var failures := 0
var core := CoreRuntimeServicesModule.new()
var module := CombatModule.new()
var registry := CoreModuleRegistry.new()
var service: CombatService
var defeats := 0
var order: Array[String] = []

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func actor() -> Combatant:
	return service.register(core.entities.create(), "combat.profile.standard")

func run() -> void:
	registry.add(module)
	registry.add(core)
	check(registry.boot() == OK, "generic Combat boots with only declared Core dependency")
	service = module.service
	check(module.requires == ["core.runtime"] and registry.order[0] == core, "generic combat has no Player/World dependency")
	var source := actor()
	var target := actor()
	check(source != null and service.combatant(source.entity_id) == source, "stable entity combat capability registered")
	check(service.register(source.entity_id, source.profile_id) == null and service.register(CoreIds.generate(), source.profile_id) == null, "duplicate and unknown Core identities rejected")
	check(service.relationship(source.entity_id, CoreIds.generate()) == CombatTargetPolicy.Relationship.INVALID, "unavailable target query")
	check(service.relationship(source.entity_id, target.entity_id) == CombatTargetPolicy.Relationship.NEUTRAL, "safe neutral default")
	check(service.relationship(source.entity_id, source.entity_id) == CombatTargetPolicy.Relationship.SELF, "self query")
	check(not service.damage(DamageRequest.new(source.entity_id, target.entity_id, 1)).accepted, "default neutral damage denied")
	var relation := Relations.new()
	service.target_policy = relation
	var applied := core.events.subscribe(DamageApplied, func(event: DamageApplied) -> void:
		order.append("damage")
		check(event.source_entity == source.entity_id and event.target_entity == target.entity_id, "damage event stable IDs")
		check(service.damage(DamageRequest.new(source.entity_id, target.entity_id, 1)).code == "BUSY", "event subscriber cannot reenter transaction")
	)
	var changed := core.events.subscribe(HealthChanged, func(_event: HealthChanged) -> void: order.append("health"))
	var defeated := core.events.subscribe(CombatantDefeated, func(event: CombatantDefeated) -> void:
		defeats += 1
		order.append("defeated")
		check(service.combatant(event.target_entity).lifecycle == Combatant.Lifecycle.DEFEATED, "defeat state committed before event")
	)
	var request := DamageRequest.new(source.entity_id, target.entity_id, 25)
	request.tags.assign(["test.tag.hit"])
	request.action_id = "test.action.strike"
	request.has_impact = true
	request.impact_position = Vector3(1, 2, 3)
	var result := service.damage(request)
	check(result.accepted and result.actual == 25 and target.health == 75 and result.health_before == 100 and result.health_after == 75, "basic exact damage transaction")
	check(order == ["damage", "health"], "bounded applied then health facts")
	check(service.damage(request).code == "REQUEST_CONSUMED" and target.health == 75, "same command object cannot apply twice")
	var health_before := target.health
	for amount in [-1.0, NAN, INF, -INF, 0.5, 1e300, float(CombatNumbers.MAX_UNITS) + 1]:
		check(service.damage(DamageRequest.new(source.entity_id, target.entity_id, amount)).code == "INVALID_AMOUNT" and target.health == health_before, "invalid damage amount rejected")
		check(service.heal(HealingRequest.new(source.entity_id, target.entity_id, amount)).code == "INVALID_AMOUNT" and target.health == health_before, "invalid healing amount rejected")
	var zero_events := order.size()
	check(service.damage(DamageRequest.new(source.entity_id, target.entity_id, 0)).code == "NO_CHANGE" and order.size() == zero_events, "zero amount emits no events")
	var invalid := DamageRequest.new(source.entity_id, target.entity_id, 1)
	invalid.damage_type_id = "combat.damage.unknown"
	check(not service.damage(invalid).accepted, "unknown damage type rejected")
	invalid.damage_type_id = "combat.damage.physical"
	invalid.has_impact = true
	invalid.impact_position = Vector3(INF, 0, 0)
	check(not service.damage(invalid).accepted, "invalid impact rejected")
	invalid.has_impact = false
	invalid.tags.assign(["bad tag"])
	check(not service.damage(invalid).accepted, "invalid metadata rejected")
	check(service.damage(DamageRequest.new("missing", target.entity_id, 1)).code == "TARGET_UNAVAILABLE", "missing source rejected")
	relation.selected = CombatTargetPolicy.Relationship.ALLY
	var friendly := DamageRequest.new(source.entity_id, target.entity_id, 5)
	friendly.relationship_hint = CombatTargetPolicy.Relationship.ENEMY
	check(service.damage(friendly).code == "RELATIONSHIP_REJECTED", "client relationship hint cannot bypass ally policy")
	friendly.friendly_fire = true
	check(service.damage(friendly).accepted and target.health == 70, "explicit friendly fire")
	var healing := service.heal(HealingRequest.new(source.entity_id, target.entity_id, 10))
	check(healing.accepted and healing.actual == 10 and target.health == 80, "healing distinct transaction")
	healing = service.heal(HealingRequest.new(source.entity_id, target.entity_id, 100))
	check(healing.actual == 20 and healing.overage == 80 and target.health == target.max_health(), "overheal clamps and reports actual")
	relation.selected = CombatTargetPolicy.Relationship.ENEMY
	check(service.heal(HealingRequest.new(source.entity_id, target.entity_id, 1)).code == "RELATIONSHIP_REJECTED", "enemy healing denied")
	order.clear()
	result = service.damage(DamageRequest.new(source.entity_id, target.entity_id, 1000))
	check(result.actual == 100 and result.overage == 900 and target.health == 0 and result.defeated, "overkill clamps and defeats")
	check(order == ["damage", "health", "defeated"] and defeats == 1, "defeat event ordered and once")
	check(service.damage(DamageRequest.new(source.entity_id, target.entity_id, 1)).code == "COMBATANT_DEFEATED" and defeats == 1, "further damage rejected without repeated death")
	relation.selected = CombatTargetPolicy.Relationship.ALLY
	check(service.heal(HealingRequest.new(source.entity_id, target.entity_id, 100)).code == "COMBATANT_DEFEATED", "ordinary healing does not revive")
	check(service.combatant(target.entity_id) == target, "defeat never removes entity or capability")
	core.events.unsubscribe(applied)
	core.events.unsubscribe(changed)
	core.events.unsubscribe(defeated)
	var exact := actor()
	relation.selected = CombatTargetPolicy.Relationship.ENEMY
	check(service.damage(DamageRequest.new(source.entity_id, exact.entity_id, 100)).defeated and exact.health == 0, "exact-zero transition")
	var self_hit := DamageRequest.new(source.entity_id, source.entity_id, 1)
	check(service.damage(self_hit).code == "RELATIONSHIP_REJECTED", "self damage is opt-in")
	self_hit.allow_self = true
	check(service.damage(self_hit).actual == 1, "explicit self damage")
	check(service.heal(HealingRequest.new(source.entity_id, source.entity_id, 1)).actual == 1, "self healing")
	check(service.spend_resource(source.entity_id, 13) == OK and source.resource == 37, "generic resource spend")
	check(service.restore_resource(source.entity_id, 100) == 13 and source.resource == 50, "resource regeneration hook clamps")
	check(service.spend_resource(source.entity_id, 51) != OK and service.restore_resource(source.entity_id, NAN) == -1 and source.resource == 50, "invalid resource operations rejected")
	var bonus := CombatModifier.new("test.source.health", CombatModifier.Stat.MAX_HEALTH, CombatModifier.Operator.ADD, 50)
	check(service.add_modifier(source.entity_id, bonus) == OK and source.max_health() == 150 and source.health == 100, "flat max-health modifier preserves current health")
	check(service.add_modifier(source.entity_id, bonus) == ERR_ALREADY_EXISTS and source.max_health() == 150, "duplicate source rejected")
	bonus.value = 999
	check(source.max_health() == 150, "modifier stored as detached value")
	var factor := CombatModifier.new("test.source.scale", CombatModifier.Stat.MAX_HEALTH, CombatModifier.Operator.SCALE, 15000)
	check(service.add_modifier(source.entity_id, factor) == OK and source.max_health() == 225, "flat then scale pipeline")
	service.heal(HealingRequest.new(source.entity_id, source.entity_id, 1000))
	check(service.remove_modifier(source.entity_id, factor.source_id) == OK and source.health == 150, "max reduction clamps canonical health")
	check(service.remove_modifier(source.entity_id, bonus.source_id) == OK and source.max_health() == 100 and source.health == 100, "remove by stable source restores base without drift")
	check(service.remove_modifier(source.entity_id, bonus.source_id) == ERR_DOES_NOT_EXIST, "missing modifier removal explicit")
	var power := CombatModifier.new("test.source.power", CombatModifier.Stat.DAMAGE_SCALE, CombatModifier.Operator.ADD, 5000)
	service.add_modifier(source.entity_id, power)
	var powered := actor()
	check(service.damage(DamageRequest.new(source.entity_id, powered.entity_id, 20)).actual == 30, "supported outgoing damage modifier")
	check(service.damage(DamageRequest.new(source.entity_id, powered.entity_id, 1)).actual == 1, "integer floor rounding explicit")
	service.remove_modifier(source.entity_id, power.source_id)
	var profile := core.data.lookup("combat.profile.standard")
	var forward := CombatAttributes.new(profile)
	var reverse := CombatAttributes.new(profile)
	for modifier in [bonus, factor]:
		forward.add(modifier)
	for modifier in [factor, bonus]:
		reverse.add(modifier)
	check(forward.value(CombatModifier.Stat.MAX_HEALTH) == reverse.value(CombatModifier.Stat.MAX_HEALTH), "modifier insertion order cannot change result")
	check(forward.capture_modifiers() == reverse.capture_modifiers(), "stable modifier serialization order")
	var large := CombatModifier.new("test.source.large", CombatModifier.Stat.DAMAGE_SCALE, CombatModifier.Operator.SCALE, CombatNumbers.MAX_SCALE)
	service.add_modifier(source.entity_id, large)
	var huge := actor()
	result = service.damage(DamageRequest.new(source.entity_id, huge.entity_id, CombatNumbers.MAX_UNITS))
	check(result.evaluated == CombatNumbers.MAX_UNITS and result.actual == 100, "large supported values saturate without overflow")
	service.remove_modifier(source.entity_id, large.source_id)
	var twin_a := actor()
	var twin_b := actor()
	var a := service.damage(DamageRequest.new(source.entity_id, twin_a.entity_id, 17))
	var b := service.damage(DamageRequest.new(source.entity_id, twin_b.entity_id, 17))
	check(a.actual == b.actual and twin_a.health == twin_b.health, "same inputs/state deterministic without frame dependency")
	check(core.data.lookup("combat.resource.energy").kind == "resource" and core.data.lookup("combat.modifier.add").value == 0, "production namespaced definitions registered")
	check(core.data.register("combat.profile.standard", "combat.profile", profile) != OK, "duplicate data ID rejected")
	var bad_profile := profile.duplicate(true)
	bad_profile.max_health = NAN
	check(CombatDefinitions.valid_profile(bad_profile) != OK, "invalid numeric tuning rejected")
	var bad_state := source.capture()
	bad_state.health = INF
	check(not Combatant.valid(bad_state, profile), "invalid saved numeric combat state rejected")
	bad_state = source.capture()
	bad_state.modifiers = [power.capture(), power.capture()]
	check(not Combatant.valid(bad_state, profile), "duplicate persisted modifier sources rejected")
	var neutral := actor()
	service.target_policy = CombatTargetPolicy.new()
	var neutral_hit := DamageRequest.new(source.entity_id, neutral.entity_id, 1)
	neutral_hit.allow_neutral = true
	check(service.damage(neutral_hit).actual == 1, "explicit neutral targeting")
	var neutral_heal := HealingRequest.new(source.entity_id, neutral.entity_id, 1)
	neutral_heal.allow_neutral = true
	var heal_fact: Array[int] = []
	var heal_token := core.events.subscribe(HealingApplied, func(event: HealingApplied) -> void: heal_fact.append(event.actual))
	check(service.heal(neutral_heal).actual == 1 and heal_fact == [1], "typed healing event reports actual restored health")
	check(service.heal(HealingRequest.new(neutral.entity_id, neutral.entity_id, 10)).code == "NO_CHANGE" and heal_fact == [1], "full health healing emits no extra facts")
	core.events.unsubscribe(heal_token)
	service.target_policy = relation
	relation.selected = CombatTargetPolicy.Relationship.ENEMY
	var frozen := DamageRequest.new(source.entity_id, neutral.entity_id, 1)
	var original_target := neutral.entity_id
	var mutate_token := core.events.subscribe(DamageApplied, func(_event: DamageApplied) -> void: frozen.target_entity = "mutated")
	var frozen_ids: Array[String] = []
	var frozen_token := core.events.subscribe(HealthChanged, func(event: HealthChanged) -> void: frozen_ids.append(event.target_entity))
	service.damage(frozen)
	check(frozen_ids == [original_target], "all facts frozen before subscriber delivery")
	core.events.unsubscribe(mutate_token)
	core.events.unsubscribe(frozen_token)
	service.add_modifier(source.entity_id, CombatModifier.new("test.source.healing", CombatModifier.Stat.HEAL_SCALE, CombatModifier.Operator.ADD, 5000))
	var ally := actor()
	service.damage(DamageRequest.new(source.entity_id, ally.entity_id, 50))
	relation.selected = CombatTargetPolicy.Relationship.ALLY
	check(service.heal(HealingRequest.new(source.entity_id, ally.entity_id, 20)).actual == 30, "supported outgoing healing modifier")
	check(core.data.register("bad id", "combat.token", {"id": "bad id", "kind": "damage"}) != OK, "invalid production definition ID rejected")
	var limited := CombatAttributes.new(profile)
	for i in CombatNumbers.MAX_MODIFIERS:
		limited.add(CombatModifier.new("test.limit.m%d" % i, CombatModifier.Stat.MAX_HEALTH, CombatModifier.Operator.ADD, 1))
	check(limited.add(CombatModifier.new("test.limit.extra", CombatModifier.Stat.MAX_HEALTH, CombatModifier.Operator.ADD, 1)) != OK, "bounded modifier count rejects excess contributions")
	check(limited.value(CombatModifier.Stat.MAX_HEALTH) == 100 + CombatNumbers.MAX_MODIFIERS, "bounded contributions accumulate exactly")
	check(limited.add(CombatModifier.new("test.limit.negative", CombatModifier.Stat.MAX_HEALTH, CombatModifier.Operator.SCALE, -1)) != OK, "negative scale modifier rejected")
	var old_depth := core.events.max_dispatch_depth
	core.events.max_dispatch_depth = 0
	var delivery := DamageRequest.new(source.entity_id, source.entity_id, 1)
	delivery.allow_self = true
	var delivery_result := service.damage(delivery)
	check(delivery_result.accepted and delivery_result.actual == 1 and delivery_result.code == "APPLIED_EVENT_DELIVERY_FAILED", "delivery failure reports committed result explicitly")
	check(service.damage(delivery).code == "REQUEST_CONSUMED", "delivery failure cannot replay committed health change")
	core.events.max_dispatch_depth = old_depth
	var minimum := actor()
	service.add_modifier(minimum.entity_id, CombatModifier.new("test.minimum.health", CombatModifier.Stat.MAX_HEALTH, CombatModifier.Operator.ADD, -CombatNumbers.MAX_UNITS))
	check(minimum.max_health() == 1 and minimum.health == 1 and minimum.lifecycle == Combatant.Lifecycle.ALIVE, "negative flat contribution clamps max health without accidental death")
	service.remove_modifier(minimum.entity_id, "test.minimum.health")
	check(minimum.max_health() == 100 and minimum.health == 1, "increasing cap after removal does not grant free healing")
	relation.selected = CombatTargetPolicy.Relationship.ENEMY
	service.add_modifier(source.entity_id, CombatModifier.new("test.zero.damage", CombatModifier.Stat.DAMAGE_SCALE, CombatModifier.Operator.SCALE, 0))
	check(service.damage(DamageRequest.new(source.entity_id, minimum.entity_id, 10)).code == "NO_CHANGE" and minimum.health == 1, "zero derived damage scale is a deterministic no-op")
	registry.shutdown()
	print("Combat tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
