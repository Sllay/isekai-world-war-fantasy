class_name LivingBody
extends PlayerMotor

# Transient L0 physics/presentation over the existing canonical PlayerState.
var bundle: LivingCapabilities
var marker := MeshInstance3D.new()
var caption := Label3D.new()
var _elapsed := 0.0

func _ready() -> void:
	super._ready()
	position = state.position
	collision_layer = 2
	collision_mask = 1
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.6
	marker.mesh = mesh
	marker.position.y = 0.8
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.15, 0.7, 0.85) if bundle.state.kind == "bot" else Color(0.65, 0.7, 0.25)
	marker.material_override = material
	add_child(marker)
	caption.position.y = 2.0
	caption.font_size = 30
	caption.pixel_size = 0.008
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)
	_refresh()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 0.2: return
	_elapsed = 0.0
	_refresh()

func _refresh() -> void:
	marker.scale.y = 0.25 if bundle.combatant.lifecycle == Combatant.Lifecycle.DEFEATED else 1.0
	caption.text = "%s · L0 · %s\nHP%d · memories%d" % [bundle.state.kind.capitalize(), bundle.state.plan.get("goal", "work"), bundle.combatant.health, bundle.state.memory.capture().records.size()]
