class_name CombatFeedback
extends Node3D

# Read-only fact consumer. Local pose pauses never pause authority or Engine time.
var host: LocalAuthorityHost
var position_of: Callable
var actors: Dictionary = {}
var _tokens: Array[int] = []
var _impacts: Array[Dictionary] = []
var _sounds: Array[AudioStreamPlayer] = []
var _swing: AudioStreamWAV
var _impact: AudioStreamWAV
var message := "Approach the skirmisher; read the amber wind-up."
var _message_time := 0.0
var _defense_message := ""
var _defense_time := 0.0
var _last_respawns := 0
var _status := Label.new()
var confirmed_hits := 0
var defense_outcomes: Dictionary = {}

func _ready() -> void:
	_swing = _tone(380.0, 0.08)
	_impact = _tone(110.0, 0.10)
	for index in range(3):
		var sound := AudioStreamPlayer.new()
		sound.volume_db = -14
		add_child(sound)
		_sounds.append(sound)
	var ui := CanvasLayer.new()
	add_child(ui)
	_status.position = Vector2(20, 150)
	_status.add_theme_font_size_override("font_size", 20)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(_status)
	_tokens.append(host.combat.events.subscribe(DamageApplied, _hit))
	_tokens.append(host.combat.events.subscribe(DefenseResolved, _defended))
	_tokens.append(host.combat.events.subscribe(ActionStarted, _started))
	_tokens.append(host.combat.events.subscribe(ActionCommitted, _committed))
	_tokens.append(host.combat.events.subscribe(CombatantDefeated, _defeated))

func attach_actor(id: String, marker: MeshInstance3D) -> void:
	var sword := Node3D.new()
	sword.position = Vector3(0.42, 0, -0.15)
	marker.add_child(sword)
	for spec in [[Vector3(0.10, 0.68, 0.08), Vector3(0, 0.35, 0), Color(0.72, 0.85, 0.91)], [Vector3(0.32, 0.08, 0.12), Vector3.ZERO, Color(0.8, 0.57, 0.18)], [Vector3(0.09, 0.22, 0.09), Vector3(0, -0.13, 0), Color(0.23, 0.12, 0.08)]]:
		var part := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = spec[0]
		part.mesh = mesh
		part.position = spec[1]
		var material := StandardMaterial3D.new()
		material.albedo_color = spec[2]
		part.material_override = material
		sword.add_child(part)
	var shield := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.48
	ring.outer_radius = 0.55
	shield.mesh = ring
	shield.rotation.x = PI / 2
	shield.position.z = -0.5
	var guard_material := StandardMaterial3D.new()
	guard_material.albedo_color = Color(0.15, 0.85, 0.95)
	guard_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shield.material_override = guard_material
	marker.add_child(shield)
	actors[id] = {"marker": marker, "sword": sword, "guard": shield, "reaction": 0.0, "swing": 0.0, "freeze": 0.0}

func _started(fact: ActionStarted) -> void:
	if not actors.has(fact.owner_id):
		return
	actors[fact.owner_id].swing = 0.0

func _committed(fact: ActionCommitted) -> void:
	if actors.has(fact.owner_id):
		actors[fact.owner_id].swing = 0.4
		_play(_swing)

func _hit(fact: DamageApplied) -> void:
	confirmed_hits += 1
	message = ("HIT TAKEN" if fact.target_entity == host.player.entity_id else "HIT CONFIRMED") + " · %d damage" % fact.actual
	_message_time = 1.0
	if actors.has(fact.target_entity):
		actors[fact.target_entity].reaction = 0.25
		# Visual pose only, bounded 40 ms. Authority keeps ticking.
		actors[fact.target_entity].freeze = 0.04
	if actors.has(fact.source_entity):
		actors[fact.source_entity].freeze = 0.04
	var point: Variant = position_of.call(fact.target_entity)
	if point is Vector3 and _impacts.size() < 8:
		var flash := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.20
		mesh.height = 0.4
		flash.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.76, 0.22)
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash.material_override = material
		add_child(flash)
		flash.global_position = point + Vector3.UP
		_impacts.append({"node": flash, "time": 0.15})
	_play(_impact)

func _defended(fact: DefenseResolved) -> void:
	defense_outcomes[fact.outcome] = int(defense_outcomes.get(fact.outcome, 0)) + 1
	_defense_message = "%s · prevented %d · energy -%d" % [fact.outcome, fact.prevented, fact.resource_cost]
	_defense_time = 1.2
	_play(_impact)

func _defeated(fact: CombatantDefeated) -> void:
	message = "DEFEATED · safe respawn in 1.5 s" if fact.target_entity == host.player.entity_id else "Enemy defeated · another opponent awaits further north-east"
	_message_time = 2.0

func _process(delta: float) -> void:
	_message_time = maxf(0, _message_time - delta)
	_defense_time = maxf(0, _defense_time - delta)
	for id: String in actors:
		var pose: Dictionary = actors[id]
		if not is_instance_valid(pose.marker):
			continue
		pose.freeze = maxf(0, pose.freeze - delta)
		if pose.freeze == 0:
			pose.reaction = maxf(0, pose.reaction - delta)
			pose.swing = maxf(0, pose.swing - delta)
		pose.marker.rotation.z = sin(pose.reaction * PI * 8) * 0.22
		pose.sword.rotation.z = sin(pose.swing * PI * 4) * 1.1
		if host.actor_executors.has(id):
			var action: ActionExecutor = host.actor_executors[id]
			if action.phase == ActionExecutor.Phase.CASTING:
				pose.sword.rotation.z = -0.9
		pose.guard.visible = host.defense.state(id).guard
		var combatant := host.combat.combatant(id)
		pose.marker.scale.y = 0.2 if combatant.lifecycle == Combatant.Lifecycle.DEFEATED else (0.75 if host.defense.staggered(id) else 1.0)
	for index in range(_impacts.size() - 1, -1, -1):
		_impacts[index].time -= delta
		if _impacts[index].time <= 0:
			_impacts[index].node.queue_free()
			_impacts.remove_at(index)
		else:
			_impacts[index].node.scale = Vector3.ONE * (1.0 + (0.15 - _impacts[index].time) * 4)
	var snapshot := host.snapshot()
	if snapshot.respawns > _last_respawns:
		_last_respawns = snapshot.respawns
		message = "RESPAWNED · ready to fight again"
	var stance: String = "GUARD" if snapshot.defense.guard else ("DODGE" if host.defense.dodging(host.player.entity_id) else ("STAGGER" if host.defense.staggered(host.player.entity_id) else snapshot.actions.phase))
	_status.text = "HP %d  Energy %d  %s\n%s · Strong ready in %.1fs\n%s\n%s" % [snapshot.health, snapshot.resource, snapshot.lifecycle, stance, snapshot.actions.cooldowns.get("combat.action.strong_strike", 0) * host.combat.clock.step_seconds, message, _defense_message if _defense_time > 0 else ""]

func _play(stream: AudioStreamWAV) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for sound in _sounds:
		if not sound.playing:
			sound.stream = stream
			sound.play()
			return

func _tone(frequency: float, seconds: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count := int(seconds * stream.mix_rate)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var envelope := 1.0 - float(i) / count
		bytes.encode_s16(i * 2, int(sin(TAU * frequency * i / stream.mix_rate) * envelope * envelope * 12000))
	stream.data = bytes
	return stream

func _exit_tree() -> void:
	for sound in _sounds:
		sound.stop()
		sound.stream = null
	for token in _tokens:
		host.combat.events.unsubscribe(token)
