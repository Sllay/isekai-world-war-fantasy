extends SceneTree

class CandidateQuery extends RegionSurfaceQuery:
	var candidate: RegionSurfaceCandidate
	func expected_height(_position: Vector3, _context: String) -> Variant:
		return 0.0
	func candidate_above(_position: Vector3, _context: String, _offset: float) -> RegionSurfaceCandidate:
		return candidate

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
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.recovery", OS.get_cmdline_user_args()[0].path_join("recovery.json"))
	root.add_child(runtime)
	runtime.set_process(false)
	var region: RegionScene = runtime.world_scene.active_region
	var player: PlayerState = runtime.player.state
	var recovery := region.record.recovery
	var query := recovery.surface_query as HomeValleySurfaceQuery
	var definition := region.record.definition
	var id := player.entity_id
	region.avatar.get_child(0).set_physics_process(false)
	region.avatar.motor.set_physics_process(false)
	region.set_physics_process(false)
	player.position = Vector3(1, 0, 6)
	player.grounded = true
	for i in 100: recovery.observe()
	check(recovery.recovery_count == 0 and query.query_count == 0, "healthy frames never perform heavy candidate/clearance query")
	var safe := recovery.last_safe.duplicate(true)
	player.position.y = 3
	player.grounded = false
	recovery.observe()
	check(recovery.recovery_count == 0 and query.query_count == 0, "normal jump does not recover/query")
	player.position.y = -0.1
	recovery.observe()
	check(recovery.recovery_count == 0 and recovery.last_safe == safe, "small penetration tolerance does not teleport or advance safe point")
	player.position = Vector3(2, -3, 5)
	player.velocity = Vector3(3, -40, 2)
	player.facing = Vector3.RIGHT
	region.avatar.motor.dodge(Vector3.RIGHT, 2)
	recovery.observe()
	check(recovery.last_method == "VERTICAL_SURFACE_RECOVERED" and query.query_count == 1, "underfloor detection queries and recovers")
	check(player.position.is_equal_approx(Vector3(2, 0.12, 5)) and player.entity_id == id, "local surface preserves X/Z and same Player identity")
	check(player.velocity == Vector3.ZERO and player.facing == Vector3.RIGHT and region.avatar.motor._pending_displacement == Vector3.ZERO, "recovery preserves facing and clears fall/dodge motion")
	check(recovery.last_safe == safe, "teleport is not immediately canonical last-safe")
	recovery.observe()
	check(recovery.last_safe == safe, "unconfirmed teleport cannot advance last-safe")
	player.grounded = true
	recovery.observe()
	check(recovery.last_safe.position == [player.position.x, player.position.y, player.position.z], "ground confirmation advances last-safe normally")
	var local_safe := recovery.last_safe.duplicate(true)
	var obstruction := StaticBody3D.new()
	obstruction.collision_layer = 2 # Actor layer must participate in clearance.
	var obstacle_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE
	obstacle_shape.shape = box
	obstruction.add_child(obstacle_shape)
	obstruction.position = Vector3(3, 1, 5)
	region.add_child(obstruction)
	await physics_frame
	check(not region._clearance_at(Vector3(3, 0.12, 5)), "real clearance rejects actor-layer body overlap")
	player.position = Vector3(3, -3, 5)
	recovery.observe()
	check(recovery.last_method == "LAST_SAFE_RECOVERED", "actual obstructed vertical destination falls back")
	obstruction.free()
	await physics_frame
	query.clearance_at = func(_feet: Vector3) -> bool: return false
	player.position = Vector3(3, -3, 5)
	recovery.observe()
	check(recovery.last_method == "LAST_SAFE_RECOVERED" and player.position.x == 2, "clearance rejection falls back to validated last-safe")
	recovery.surface_query = null
	player.position = Vector3(4, -4, 5)
	recovery.observe()
	check(recovery.last_method == "LAST_SAFE_RECOVERED", "missing query fallback")
	recovery.last_safe = {}
	player.position.y = -40
	recovery.observe()
	check(recovery.last_method == "REGION_ENTRY_RECOVERED" and player.position == definition.to_world_position(definition.entries[definition.default_entry]), "missing last-safe falls back to entry")
	# Validate a reusable value port independently of Home Valley interpolation.
	var stub := CandidateQuery.new()
	var candidate := RegionSurfaceCandidate.new()
	candidate.position = Vector3(3, 1, 5)
	candidate.region_id = definition.region_id
	candidate.surface_id = "surface.test.local"
	candidate.clearance = true
	stub.candidate = candidate
	recovery.surface_query = stub
	player.position = Vector3(3, -3, 5)
	check(recovery.valid_candidate(candidate), "valid local layer candidate accepted")
	candidate.region_id = "region.other"
	check(not recovery.valid_candidate(candidate), "foreign Region candidate rejected")
	candidate.region_id = definition.region_id
	candidate.normal = Vector3.RIGHT
	check(not recovery.valid_candidate(candidate), "unwalkable surface rejected")
	candidate.normal = Vector3.UP
	candidate.position.x = INF
	check(not recovery.valid_candidate(candidate), "nonfinite candidate rejected")
	candidate.position = Vector3(10000, 1, 5)
	check(not recovery.valid_candidate(candidate), "out-of-bounds candidate rejected")
	candidate.position = Vector3(3, -4, 5)
	check(not recovery.valid_candidate(candidate), "candidate below Player rejected")
	candidate.position = Vector3(3, 1, 5)
	recovery.observe()
	check(player.position.is_equal_approx(Vector3(3, 1.12, 5)), "Region-selected local candidate used without globally highest surface rule")
	# Restore the real adapter and real clearance for end-to-end debug injection.
	query.clearance_at = region._clearance_at
	recovery.surface_query = query
	recovery.last_safe = local_safe
	player.position = Vector3(2, 0.1, -24)
	var count := recovery.recovery_count
	check(region.test_underfloor(), "debug control injects under current raised terrain")
	check(recovery.recovery_count == count and player.position.y < 3 - definition.penetration_depth, "debug injection does not call recovery")
	var under := player.position
	var snapshot: Dictionary = runtime.persistence.capture_snapshot()
	var saved: Dictionary = snapshot.sections["foundation.player"].state
	check(player.position == under and saved.position[0] == 2 and saved.position[1] > 3, "capture substitutes validated raised surface without live mutation")
	check(not definition.below_surface(Vector3(saved.position[0], saved.position[1], saved.position[2])), "underfloor never canonical in snapshot")
	check(runtime.save_game() == OK and runtime.resume_game() == OK, "underfloor save and resume succeed")
	region = runtime.world_scene.active_region
	recovery = region.record.recovery
	check(player.entity_id == id and player.position.y > 3 and player.velocity == Vector3.ZERO, "resume retains identity above raised local terrain")
	var malformed: Dictionary = runtime.persistence.capture_snapshot()
	malformed.sections["foundation.player"].state.position[1] = NAN
	check(runtime.persistence.integrity.prepare(malformed).is_empty(), "nonfinite corruption still rejects")
	var old: Dictionary = runtime.persistence.capture_snapshot()
	old.sections["foundation.player"].state.position = [2, -4, -24]
	var staged: Dictionary = runtime.persistence.integrity.prepare(old)
	check(not staged.is_empty() and staged.sections["foundation.player"].state.position[1] >= 0, "legacy finite underfloor position repaired in staged memory")
	# Real callbacks, without calling observe/recover from the test after injection.
	region.avatar.get_child(0).set_physics_process(false)
	for i in 5: await physics_frame
	count = recovery.recovery_count
	region.avatar.get_child(0).request_action(8)
	runtime._process(0.05)
	check(player.position.y < 2 and recovery.recovery_count == count, "touch semantic debug slot injects underfloor without directly recovering")
	for i in 12: await physics_frame
	check(recovery.recovery_count == count + 1 and recovery.last_method == "VERTICAL_SURFACE_RECOVERED", "normal production physics callback detects injected underfloor exactly once")
	check(player.position.y > 2.9 and player.entity_id == id and player.velocity.y > -2, "physics resumes on raised terrain with same Player")
	var before := player.position
	region.avatar.intent.movement = Vector2.RIGHT
	region.avatar.intent.camera_delta = 0.5
	region.avatar.intent.jump = true
	for i in 10: await physics_frame
	check(player.position.x > before.x and region.avatar.orbit.yaw > 0.4 and player.position.y > before.y + 0.2, "movement camera and jump work after recovery")
	# Sweep a semantic dodge against real collision, independently of evade timing.
	player.position = Vector3(2, 3.01, -24)
	player.velocity = Vector3.ZERO
	region.avatar.intent.movement = Vector2.ZERO
	for i in 10: await physics_frame
	var wall := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.2, 4, 4)
	collision.shape = shape
	wall.add_child(collision)
	wall.position = Vector3(3, 5, -24)
	region.add_child(wall)
	for i in 2: await physics_frame
	before = player.position
	region.avatar.intent.movement = Vector2.RIGHT
	region.avatar.get_child(0).request_action(4)
	runtime._process(0.05)
	region.avatar.intent.movement = Vector2.ZERO
	for i in 2: await physics_frame
	check(player.position.x > before.x + 0.1 and player.position.x < 2.6, "semantic dodge visibly repositions and sweep stops before wall")
	check(runtime.player_combat.state.resource == 44, "physical dodge spends authored resource exactly once")
	runtime.free()
	print("Vertical recovery tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
