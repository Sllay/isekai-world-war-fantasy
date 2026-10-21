extends SceneTree

class Relations extends CombatTargetPolicy:
	func relationship(_source: String, _target: String) -> Relationship:
		return Relationship.ENEMY

var checks := 0
var failures := 0
var core := CoreRuntimeServicesModule.new()
var combat := CombatModule.new()
var registry := CoreModuleRegistry.new()
var host := LocalAuthorityHost.new()
var gateway: LoopbackAuthorityGateway
var player := PlayerState.new()
var executor: ActionExecutor
var positions: Dictionary = {}
var query_targets: Array[String] = []
var committed_targets: Array[String] = []
var query_direction := Vector3.ZERO

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func step(count := 1) -> void:
	for i in range(count):
		core.clock.tick += 1
		host.advance()

func action(slot := "skill_3", point := Vector3(0, 0, 2), direction := Vector3.FORWARD) -> void:
	gateway.request("action", {"slot": slot, "target": "", "point": point, "direction": direction})
	step()

func run() -> void:
	registry.add(core)
	registry.add(combat)
	check(registry.boot() == OK, "C1 foundation boots without world/UI")
	combat.service.target_policy = Relations.new()
	player.entity_id = core.entities.create()
	var owner := combat.service.register(player.entity_id, "combat.profile.standard")
	var a := combat.service.register(core.entities.create(), "combat.profile.standard")
	var b := combat.service.register(core.entities.create(), "combat.profile.standard")
	positions[player.entity_id] = Vector3.ZERO
	positions[a.entity_id] = Vector3(0, 0, 2)
	positions[b.entity_id] = Vector3(1, 0, 2)
	executor = ActionExecutor.new(combat.service, combat.actions, player.entity_id)
	executor.position_of = func(id: String) -> Variant: return positions.get(id)
	host.configure(combat.service, executor, player, "c1-session")
	host.defense.position_of = executor.position_of
	host.defense.facing_of = func(_id: String) -> Vector3: return player.facing
	gateway = LoopbackAuthorityGateway.new(host, "c1-session")
	check(host.loadout_state().slots.size() == 4 and host.loadout_state().slots.skill_3.is_empty(), "primary plus three real slots; third intentionally empty")
	action()
	check(host.last_result == "SLOT_EMPTY" and owner.resource == 50, "empty slot rejects without cost")
	check(not gateway.request("equip", {"skill_3": "combat.action.strong_strike"}).accepted, "client cannot install action IDs")
	check(not gateway.request("action", {"slot": "skill_4", "target": ""}).accepted, "invalid skill slot rejected")
	check(not gateway.request("action", {"slot": "skill_1", "target": a.entity_id, "actor": b.entity_id}).accepted, "actor mismatch cannot override bound ownership")
	check(not gateway.request("action", {"slot": "skill_1", "target": a.entity_id, "point": Vector3(NAN, 0, 0), "direction": Vector3.FORWARD}).accepted, "NaN point rejected at ingress")
	check(not gateway.request("action", {"slot": "skill_1", "target": a.entity_id, "point": Vector3.ZERO, "direction": Vector3(0, 0, 90)}).accepted, "unnormalized direction rejected at ingress")
	var area := combat.actions.lookup("combat.action.strong_strike")
	area.action_id = "combat.action.foundation_test_area"
	area.target_mode = ActionDefinition.TargetMode.POINT
	area.target_query_id = "combat.query.test_area"
	area.max_targets = 2
	area.max_range = 5
	area.cast_ticks = 2
	area.recovery_ticks = 1
	area.cooldown_ticks = 10
	area.resource_cost = 5
	area.effects[0].amount = 3
	area.tags.clear()
	var invalid_area := area.duplicate(true) as ActionDefinition
	invalid_area.max_targets = 9
	check(not invalid_area.valid(core.data), "content cannot exceed spatial target budget")
	invalid_area.max_targets = 0
	check(not invalid_area.valid(core.data), "zero target budget is invalid content")
	invalid_area = area.duplicate(true) as ActionDefinition
	invalid_area.target_query_id = "not a stable query id"
	check(not invalid_area.valid(core.data), "query identity is validated content")
	check(combat.actions.register(area) == OK, "spatial content registers in same typed catalog")
	var loadout := preload("res://data/actions/player_loadout.tres").duplicate(true) as ActionLoadout
	loadout.slots.skill_3 = area.action_id
	var bad := loadout.duplicate(true) as ActionLoadout
	bad.slots.skill_3 = "combat.action.missing"
	check(host.install_loadout(bad) == ERR_INVALID_DATA, "unknown equipped action fails closed")
	bad = loadout.duplicate(true) as ActionLoadout
	bad.slots.erase("skill_2")
	check(host.install_loadout(bad) == ERR_INVALID_DATA, "incomplete slot schema rejected")
	check(host.install_loadout(loadout) == OK, "authority installs validated slot 3")
	loadout.slots.skill_3 = ""
	var snapshot: Dictionary = gateway.snapshot().loadout
	snapshot.slots.skill_3 = ""
	check(host.loadout_state().slots.skill_3 == area.action_id, "loadout input and result are detached copies")
	action()
	check(host.last_result == "TARGET_QUERY_UNAVAILABLE", "spatial action without trusted query fails closed")
	executor.target_resolver.world_query = func(definition: ActionDefinition, _id: String, hint: ActionTarget) -> Array[String]:
		query_direction = hint.direction
		return query_targets.duplicate() if definition.target_query_id == "combat.query.test_area" else []
	query_targets.assign([b.entity_id, a.entity_id])
	action("skill_3", Vector3(100, 0, 0))
	check(host.last_result == "OUT_OF_RANGE" and owner.resource == 50, "client world point cannot bypass canonical range")
	query_targets.assign([a.entity_id, a.entity_id])
	action()
	check(host.last_result == "INVALID_TARGET_QUERY", "duplicate target cannot multiply an effect")
	query_targets.assign([a.entity_id, b.entity_id, player.entity_id])
	action()
	check(host.last_result == "INVALID_TARGET_QUERY", "query fan-out is bounded by authored maximum")
	query_targets.assign([b.entity_id, a.entity_id])
	executor.target_gate = func(_source: String, destination: String) -> bool: return destination != b.entity_id
	action()
	check(host.last_result == "TARGET_OCCLUDED" and owner.resource == 50, "AoE query cannot bypass per-target visibility")
	executor.target_gate = Callable()
	var token := core.events.subscribe(ActionCommitted, func(fact: ActionCommitted) -> void: committed_targets.assign(fact.target_ids))
	action()
	check(host.last_result == "STARTED" and host.install_loadout(loadout) == ERR_BUSY, "loadout cannot change during execution")
	step(2)
	check(a.health == 97 and b.health == 97 and owner.resource == 45, "two targets use CombatService with one cost")
	var ordered := [a.entity_id, b.entity_id]
	ordered.sort()
	check(committed_targets == ordered and executor.effect_results.size() == 2, "authoritative facts and results use stable target order")
	check(executor.remaining_cooldown(area.action_id) == 10, "multi-target commit starts one cooldown")
	step()
	check(host.install_loadout(loadout) == OK, "idle host can switch to empty skill slot")
	loadout.slots.skill_3 = area.action_id
	check(host.install_loadout(loadout) == OK, "authority can re-equip same action")
	action()
	check(host.last_result == "COOLDOWN", "loadout switching cannot reset cooldown")
	step(10)
	var before_cancel := owner.resource
	action()
	positions[b.entity_id] = Vector3(50, 0, 0)
	step(2)
	check(executor.last_result == "OUT_OF_RANGE" and a.health == 97 and owner.resource == before_cancel, "commit revalidates every candidate before spending or damaging")
	positions[b.entity_id] = Vector3(1, 0, 2)
	var directional := area.duplicate(true) as ActionDefinition
	directional.action_id = "combat.action.foundation_test_direction"
	directional.target_mode = ActionDefinition.TargetMode.DIRECTION
	directional.max_targets = 1
	check(combat.actions.register(directional) == OK, "directional content shares executor and effect definitions")
	loadout.slots.skill_3 = directional.action_id
	host.install_loadout(loadout)
	query_targets.assign([a.entity_id])
	action("skill_3", Vector3.ZERO, Vector3.ZERO)
	check(host.last_result == "INVALID_AIM", "directional action requires unit aim")
	var payload := {"slot": "skill_3", "target": "", "point": Vector3.ZERO, "direction": Vector3.FORWARD}
	gateway.request("action", payload)
	payload.direction = Vector3.RIGHT
	step()
	step(2)
	check(a.health == 94 and executor.effect_results.size() == 1, "directional query commits through shared effects")
	check(query_direction == Vector3.FORWARD, "client edits after enqueue cannot redirect committed aim")
	step()
	# The same world aim works independently of camera-relative movement.
	var avatar := PlayerAvatar.new()
	avatar.state = player
	root.add_child(avatar)
	var adapter := PlayerAuthorityAdapter.new()
	adapter.gateway = gateway
	check(PlayerAimAdapter.apply(avatar.intent, Vector3(3, 0, 0), Vector3.ZERO), "view adapter creates normalized world aim")
	avatar.orbit.yaw = 1.8
	adapter.consume(avatar, a.entity_id, positions[a.entity_id])
	step()
	check(player.facing.is_equal_approx(Vector3.RIGHT), "authority receives world facing independent of camera yaw")
	avatar.orbit.camera.global_position = Vector3(0, 8, 8)
	avatar.orbit.camera.look_at(Vector3(2, 0, 1))
	var viewport_center := avatar.orbit.camera.get_viewport().get_visible_rect().get_center()
	var projected: Variant = PlayerAimAdapter.project(avatar.orbit.camera, viewport_center, Vector3.ZERO)
	check(projected is Vector3 and projected.distance_to(Vector3(2, 0, 1)) < 0.01, "screen-center projection creates a world candidate: %s at %s" % [str(projected), str(viewport_center)])
	check(not PlayerAimAdapter.apply(avatar.intent, Vector3(INF, 0, 0), Vector3.ZERO), "invalid projection cannot become aim intent")
	avatar.intent.request_skill(3)
	avatar.intent.target_entity_id = a.entity_id
	avatar.intent.clear_transient()
	check(avatar.intent.skill_slot == 0 and avatar.intent.target_entity_id.is_empty() and avatar.intent.aim_direction == Vector3.ZERO, "reset clears slot and targeting one-shots")
	var targeting := TargetingService.new()
	targeting.combat = combat.service
	for id: String in positions:
		targeting.register(id, func() -> Variant: return positions.get(id))
	targeting.visibility = func(_source: String, destination: String) -> bool: return destination != a.entity_id
	check(not targeting.select(player.entity_id, a.entity_id, 10), "occluded target cannot be locked")
	check(targeting.select(player.entity_id, b.entity_id, 10), "visible hostile remains selectable")
	targeting.clear_selection(player.entity_id)
	check(targeting.current(player.entity_id, 10).is_empty(), "respawn can clear selection without erasing world registrations")
	targeting.clear()
	targeting.visibility = Callable()
	# A failed guard is not stagger immunity. Other actors retain their state when
	# this Player dies; respawn resets only the defeated owner's active windows.
	player.facing = Vector3.FORWARD
	host.defense.set_guard(player.entity_id, true)
	var hit := DamageRequest.new(a.entity_id, player.entity_id, 2)
	hit.tags.assign(["combat.tag.strong"])
	var impact := combat.service.damage(hit)
	check(impact.defense == "GUARD_FAILED" and host.defense.staggered(player.entity_id), "rear strong impact staggers through failed guard")
	host.defense.state(b.entity_id).stagger_until = core.clock.tick + 50
	host.safe_spawn = func() -> void: player.position = Vector3(0, 0, 8)
	combat.service.damage(DamageRequest.new(a.entity_id, player.entity_id, 999))
	step()
	check(host.defense.staggered(b.entity_id), "player death cannot clear another actor's stagger")
	step(30)
	check(host.respawns == 1 and host.defense.staggered(b.entity_id), "respawn preserves unrelated actor state")
	core.events.unsubscribe(token)
	avatar.free()
	host.dispose()
	executor.target_resolver.world_query = Callable()
	executor.position_of = Callable()
	registry.shutdown()
	print("C1 foundation tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
