extends PlayerPresentation

# Engine primitives only: visibility aid until the dedicated character content task.
var marker := MeshInstance3D.new()

func _ready() -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.8
	marker.mesh = mesh
	marker.position.y = 0.9
	add_child(marker)
	var nose := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.2, 0.2, 0.45)
	nose.mesh = box
	nose.position = Vector3(0, 0.4, -0.4)
	marker.add_child(nose)

func apply_pose(state: PlayerState, _view: Dictionary) -> void:
	marker.rotation.y = atan2(-state.facing.x, -state.facing.z)
