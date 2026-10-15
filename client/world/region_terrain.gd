class_name RegionTerrain
extends Node3D

# Authored cross-section, not seeded terrain generation. Coordinates are (z, y).
# Future chunk providers replace this content adapter under the same Terrain root.
@export var width := 96.0
@export var profile := PackedVector2Array([Vector2(48, 0), Vector2(-4, 0), Vector2(-16, 3), Vector2(-48, 3)])
@export var surface_material: Material

func _ready() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in range(profile.size() - 1):
		var near_point := profile[i]
		var far_point := profile[i + 1]
		var a := Vector3(-width / 2, near_point.y, near_point.x)
		var b := Vector3(width / 2, near_point.y, near_point.x)
		var c := Vector3(-width / 2, far_point.y, far_point.x)
		var d := Vector3(width / 2, far_point.y, far_point.x)
		var normal := (b - a).cross(c - a).normalized()
		# Godot front faces are clockwise; vertex normals point upward.
		for vertex in [a, c, b, b, c, d]:
			vertices.append(vertex)
			normals.append(normal)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = surface_material
	add_child(visual)
	var ground := StaticBody3D.new()
	# Layer 1 remains general collision; layer 3 is surface-only projection.
	ground.collision_layer = 1 | 4
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	ground.add_child(collision)
	add_child(ground)
