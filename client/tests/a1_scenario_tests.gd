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
	Engine.time_scale = 2.0
	var world := preload("res://tests/worlds/a1_acceptance.tscn").instantiate()
	root.add_child(world)
	var deadline := Time.get_ticks_msec() + 80000
	while world.scenario.result.is_empty() and Time.get_ticks_msec() < deadline:
		await physics_frame
	var result: Dictionary = world.scenario.result
	check(result.get("passed", false), "integrated semantic-input scenario completes: %s" % str(world.scenario._mcp_state()))
	check(result.get("guarded", 0) > 0 and result.get("confirmed_hits", 0) > 0, "guard and damage facts reach presentation")
	check(result.get("stagger", false) and result.get("death", false) and result.get("respawn", false) and result.get("reentered_combat", false), "strong stagger, defeat, safe respawn and return to combat")
	world.set_process(false)
	world.scenario.set_physics_process(false)
	var initial: Dictionary = world.persistence.capture_snapshot()
	# The final confirmed strike still has committed recovery; defense cannot
	# cancel that recovery. Let the authority finish it before testing dodge save.
	for i in range(20):
		world.core.clock.tick += 1
		world.authority_host.advance()
	# Real physics occlusion, through the same query used by targeting and commit.
	var obstacle := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 3, 0.5)
	collider.shape = box
	obstacle.add_child(collider)
	world.add_child(obstacle)
	obstacle.global_position = (world.player.state.position + world.enemies.companions[0].position) * 0.5 + Vector3.UP
	await physics_frame
	var enemy_id: String = world.enemies.companions[0].entity_id
	check(not world._authority_line_of_sight(world.player.state.entity_id, enemy_id), "real collider occludes authority line of effect")
	check(not world.targeting.service.select(world.player.state.entity_id, enemy_id, 20), "real wall prevents lock-on, independent of camera")
	world.authority_gateway.request("action", {"slot": "primary", "target": enemy_id})
	world.core.clock.tick += 1
	world.authority_host.advance()
	check(world.authority_host.last_result == "TARGET_OCCLUDED", "authority rejects attack through actual wall: %s" % world.authority_host.last_result)
	obstacle.free()
	await physics_frame
	check(world._authority_line_of_sight(world.player.state.entity_id, enemy_id), "removing occluder restores line of effect")
	world.authority_gateway.request("dodge")
	world.core.clock.tick += 1
	world.authority_host.advance()
	var defense_before: Dictionary = world.authority_host.defense.capture(world.player.state.entity_id)
	var first_health: int = world.enemies.actor.combatant.health
	var second_health: int = world.enemies.companions[0].combatant.health
	check(world.save_game() == OK and world.resume_game() == OK, "authority-owned scenario persists and resumes")
	check(defense_before.dodge_ready > 0 and world.authority_host.defense.capture(world.player.state.entity_id) == defense_before and not world.authority_host.defense.dodging(world.player.state.entity_id), "resume clears dodge window but preserves its cooldown")
	check(world.enemies.actor.combatant.health == first_health and world.enemies.companions[0].combatant.health == second_health, "both opponents retain canonical health")
	var broken := initial.duplicate(true)
	broken.sections["foundation.regions"].state.regions["region.home_valley"].actors.erase("spawn.melee_skirmisher_second")
	check(world.persistence.integrity.prepare(broken).is_empty(), "missing current-release opponent cannot reset to defaults")
	var previous := broken.duplicate(true)
	previous.game_version = "0.2.0"
	previous.sections["foundation.player_combat"].version = 2
	previous.sections["foundation.player_combat"].state.erase("defense")
	previous.sections["core.runtime"].state.entities.ids.erase(world.enemies.companions[0].entity_id)
	var upgraded: Dictionary = world.persistence.integrity.prepare(previous)
	check(not upgraded.is_empty() and upgraded.game_version == "0.3.0", "explicit old release introduces second opponent safely")
	check(not upgraded.is_empty() and upgraded.sections["foundation.regions"].state.regions["region.home_valley"].actors[EnemyModule.SPAWN].combatant.health == first_health, "migration cannot heal the existing enemy")
	var path: String = world.save_slot.path
	world.free()
	DirAccess.remove_absolute(path)
	Engine.time_scale = 1.0
	await process_frame
	print("A1 scenario tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
