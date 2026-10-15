extends SceneTree

var checks := 0
var failures := 0

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var args := OS.get_cmdline_user_args()
	var path := args[1].path_join("combat-restart.json")
	var proof_path := args[1].path_join("combat-proof.json")
	var runtime := preload("res://scenes/runtime/game_runtime.tscn").instantiate()
	runtime.save_slot = LocalSaveSlot.new("test.combat_restart", path)
	root.add_child(runtime)
	check(runtime.startup_error == OK, "production runtime boots with combat")
	var state: Combatant = runtime.player_combat.state
	var service: CombatService = runtime.combat.service
	if args[0] == "save":
		service.add_modifier(state.entity_id, CombatModifier.new("test.persistent.health", CombatModifier.Stat.MAX_HEALTH, CombatModifier.Operator.ADD, 25))
		service.add_modifier(state.entity_id, CombatModifier.new("test.persistent.resource", CombatModifier.Stat.MAX_RESOURCE, CombatModifier.Operator.ADD, 20))
		var hit := DamageRequest.new(state.entity_id, state.entity_id, 37)
		hit.allow_self = true
		check(service.damage(hit).actual == 37 and service.spend_resource(state.entity_id, 11) == OK, "real transactions create nondefault combat resources")
		check(state.health == 63 and state.resource == 39 and state.max_health() == 125 and state.max_resource() == 70, "nondefault current/max state")
		check(runtime.save_game() == OK, "actual combat section written to disk")
		var file := FileAccess.open(proof_path, FileAccess.WRITE)
		file.store_string(FileAccess.get_file_as_string(path))
		file.close()
	else:
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(proof_path))
		check(runtime.persistence.startup_mode == "resume", "separate OS process selects resume")
		check(JSON.parse_string(JSON.stringify(runtime.persistence.capture_snapshot(), "", true, true)) == expected, "all canonical sections restored across OS process boundary")
		check(state.health == 63 and state.max_health() == 125 and state.resource == 39 and state.max_resource() == 70, "current and derived max resources retained")
		check(state.attributes.capture_modifiers().size() == 2 and state.entity_id == expected.sections["foundation.player"].state.entity_id, "modifier sources and stable Player identity retained")
		check(service.combatant(state.entity_id) == runtime.player.capabilities.capability("foundation.combatant") and runtime.core.entities.capture().ids.size() == 2 and runtime.core.entities.contains(runtime.enemies.actor.entity_id), "no duplicated Player or detached combat capability")
		var hit := DamageRequest.new(state.entity_id, state.entity_id, 1)
		hit.allow_self = true
		check(service.damage(hit).actual == 1 and state.health == 62, "damage still functional after fresh-process restore")
		check(service.heal(HealingRequest.new(state.entity_id, state.entity_id, 2)).actual == 2 and state.health == 64, "healing still functional after fresh-process restore")
		check(runtime.save_game() == OK, "restored combat state can save again")
	runtime.free()
	print("Combat restart %s tests: %d checks, %d failures" % [args[0], checks, failures])
	quit(0 if failures == 0 else 1)
