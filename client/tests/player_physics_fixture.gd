extends PlayerAvatar

func _ready() -> void:
	super._ready()
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -30, 0)
	add_child(light)
	_ground(Vector3(0, -0.5, 0), Vector3(40, 1, 40))
	_ground(Vector3(4, 0.5, -4), Vector3(4, 1, 4))
	var slope := _ground(Vector3(-4, 0, -4), Vector3(3, 0.3, 7))
	slope.rotation_degrees.x = -20

func _ground(at: Vector3, dimensions: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	visual.mesh = mesh
	body.add_child(visual)
	add_child(body)
	return body
