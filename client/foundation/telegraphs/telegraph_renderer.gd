class_name TelegraphRenderer
extends Node3D

var tracker: TelegraphTracker
var targeting: TargetingService
@export_flags_3d_physics var ground_mask: int = 4
var _markers: Dictionary[String, MeshInstance3D] = {}

func _process(_delta: float) -> void:
	for id in _markers.keys():
		if not tracker.active.has(id) or targeting.position_of(tracker.active[id].owner_id) == null:
			_markers[id].free()
			_markers.erase(id)
	for id in tracker.active:
		var value: Dictionary = tracker.active[id]
		var origin: Variant = targeting.position_of(value.owner_id)
		if origin == null:
			continue
		if not _markers.has(id):
			var marker := MeshInstance3D.new()
			var definition := tracker.definitions[value.telegraph_id]
			marker.mesh = _circle(origin, value.range, definition.band_width)
			var material := StandardMaterial3D.new()
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			material.albedo_color = definition.color
			marker.material_override = material
			marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(marker)
			_markers[id] = marker
		var material := _markers[id].material_override as StandardMaterial3D
		material.albedo_color = tracker.definitions[value.telegraph_id].color.lerp(Color(1, 0.85, 0.15), tracker.progress(value))

# Opaque narrow ground-conforming band; no fullscreen transparency or particles.
func _circle(origin: Vector3, radius: float, width: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	for i in range(48):
		var a := TAU * i / 48.0
		var b := TAU * (i + 1) / 48.0
		var outer_a := _ground(origin + Vector3(cos(a), 0, sin(a)) * radius)
		var outer_b := _ground(origin + Vector3(cos(b), 0, sin(b)) * radius)
		var inner_a := _ground(origin + Vector3(cos(a), 0, sin(a)) * (radius - width))
		var inner_b := _ground(origin + Vector3(cos(b), 0, sin(b)) * (radius - width))
		vertices.append_array(PackedVector3Array([outer_a, inner_a, outer_b, outer_b, inner_a, inner_b]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _ground(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 8, point + Vector3.DOWN * 8, ground_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return (hit.position if not hit.is_empty() else point) + Vector3.UP * 0.04
