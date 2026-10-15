extends SceneTree

var checks := 0
var failures := 0
var path: String

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	path = OS.get_cmdline_user_args()[0].path_join("combat-owner.json")
	call_deferred("run")

func start_runtime() -> Node:
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.combat", path)
	root.add_child(runtime)
	return runtime

func write_snapshot(value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "", true, true))
	file.close()

func run() -> void:
	var runtime := start_runtime()
	var state: Combatant = runtime.player_combat.state
	var entity_id := state.entity_id
	check(runtime.startup_error == OK and runtime.player.capabilities.capability("foundation.combatant") == state, "runtime attaches real Player capability")
	var definition: Dictionary = runtime.development_state().combat
	check(definition.health == 100 and definition.max_health == 100 and definition.resource == 50 and definition.combat_state == "ALIVE", "structured initial combat diagnostics")
	var hit := DamageRequest.new(entity_id, entity_id, 34)
	hit.allow_self = true
	check(runtime.combat.service.damage(hit).actual == 34 and state.health == 66, "production transaction changes canonical Player health")
	runtime.combat.service.spend_resource(entity_id, 12)
	check(runtime.save_game() == OK, "Player combat state saves to real disk")
	var good: Dictionary = runtime.core.saves.read_snapshot(path)
	check(good.sections.has("foundation.player_combat") and good.game_version == SaveIntegrity.GAME_VERSION, "owner section and application compatibility version")
	var identity: EntityComponents = runtime.player.capabilities
	check(runtime.resume_game() == OK and runtime.player_combat.state == state and runtime.player.capabilities == identity, "restore preserves borrowed capability object")
	check(state.health == 66 and state.resource == 38 and runtime.combat.service.combatant(entity_id) == state, "restored combat lookup and resources")
	var baseline: Dictionary = runtime.persistence.capture_snapshot()
	var bad := good.duplicate(true)
	bad.sections["foundation.player_combat"].state.entity_id = CoreIds.generate()
	write_snapshot(bad)
	check(runtime.resume_game() != OK and runtime.persistence.integrity.reason == "PLAYER_COMBAT_ID_MISMATCH", "combat/Player identity mismatch rejected")
	check(runtime.persistence.capture_snapshot() == baseline and runtime.world_scene.active_region != null, "combat cross-section failure causes no partial mutation")
	bad = good.duplicate(true)
	bad.sections["foundation.player_combat"].state.combatant.health = NAN
	check(runtime.persistence.integrity.prepare(bad).is_empty() and state.health == 66, "nonfinite canonical combat value rejected")
	bad = good.duplicate(true)
	bad.sections["foundation.player_combat"].state.combatant.health = 0
	check(runtime.persistence.integrity.prepare(bad).is_empty(), "inconsistent alive/zero health rejected")
	bad = good.duplicate(true)
	bad.sections.erase("foundation.player_combat")
	check(runtime.persistence.integrity.prepare(bad).is_empty(), "new-format missing combat section rejected without default reset")
	# Old M1.3 is recognized by its original game version and exact module set.
	var legacy := good.duplicate(true)
	legacy.game_version = "0.1.0"
	legacy.modules.erase("foundation.combat")
	legacy.modules.erase("foundation.player_combat")
	legacy.sections.erase("foundation.player_combat")
	write_snapshot(legacy)
	var bytes := FileAccess.get_file_as_string(path)
	var position: Vector3 = runtime.player.state.position
	check(runtime.resume_game() == OK and state.health == 100 and state.resource == 50, "explicit M1.3 upgrade initializes only new combat state")
	check(state.entity_id == entity_id and runtime.player.state.position == position and FileAccess.get_file_as_string(path) == bytes, "upgrade preserves identities/placement and never overwrites original file on read")
	check(runtime.save_game() == OK and runtime.core.saves.read_snapshot(path).game_version == SaveIntegrity.GAME_VERSION, "explicit save writes upgraded application schema")
	bad = legacy.duplicate(true)
	bad.modules["test.unknown"] = "1.0.0"
	check(runtime.persistence.integrity.prepare(bad).is_empty(), "unrecognized legacy module set cannot upgrade")
	hit = DamageRequest.new(entity_id, entity_id, 100)
	hit.allow_self = true
	runtime.combat.service.damage(hit)
	check(state.lifecycle == Combatant.Lifecycle.DEFEATED and runtime.save_game() == OK, "defeated lifecycle persists")
	runtime.free()
	runtime = start_runtime()
	check(runtime.player_combat.state.health == 0 and runtime.player_combat.state.lifecycle == Combatant.Lifecycle.DEFEATED, "fresh runtime retains defeated state without implicit revive")
	check(runtime.combat.service.heal(HealingRequest.new(entity_id, entity_id, 50)).code == "COMBATANT_DEFEATED", "resume cannot heal away defeat")
	runtime.free()
	DirAccess.remove_absolute(path)
	check(not FileAccess.file_exists(path), "combat persistence test cleanup")
	print("Combat persistence tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
