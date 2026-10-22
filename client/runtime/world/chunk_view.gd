class_name ChunkView
extends Node3D

# Transient projection of one validated canonical record. No timer, simulation,
# harvest, inventory mutation or generated truth belongs in this adapter.
var record: Dictionary = {}
var resources: ResourceService
var clock: CoreClock
var _built := false
var _resource_markers: Dictionary = {}

func _ready() -> void:
	build()

func build() -> void:
	if _built or record.is_empty(): return
	_built = true
	var terrain: Dictionary = record.base.terrain
	var grid: int = terrain.grid_size
	var size := float(terrain.size_mm) / 1000.0
	var step := size / (grid - 1)
	position = Vector3(record.coord[0] * size, 0, record.coord[1] * size)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	vertices.resize(grid * grid)
	normals.resize(grid * grid)
	uvs.resize(grid * grid)
	for z in range(grid):
		for x in range(grid):
			var index := z * grid + x
			vertices[index] = Vector3(x * step, float(terrain.heights_mm[index]) / 1000.0, z * step)
			var left := _height(terrain, maxi(0, x - 1), z)
			var right := _height(terrain, mini(grid - 1, x + 1), z)
			var above := _height(terrain, x, maxi(0, z - 1))
			var below := _height(terrain, x, mini(grid - 1, z + 1))
			normals[index] = Vector3(left - right, 2.0 * step, above - below).normalized()
			uvs[index] = Vector2(x, z)
	var indices := PackedInt32Array()
	for z in range(grid - 1):
		for x in range(grid - 1):
			var a := z * grid + x
			var b := a + 1
			var c := a + grid
			var d := c + 1
			# Godot's front face uses clockwise winding viewed from above.
			indices.append_array(PackedInt32Array([a, b, d, a, d, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var visual := MeshInstance3D.new()
	visual.name = "TerrainMesh"
	visual.mesh = mesh
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.39, 0.43, 0.37) if terrain.surface_id == "material.terrain.rock" else (Color(0.30, 0.44, 0.32) if terrain.biome_id == "biome.chapter1.woodland" else Color(0.40, 0.56, 0.39))
	material.roughness = 1.0
	visual.material_override = material
	add_child(visual)
	var body := StaticBody3D.new()
	body.name = "TerrainCollision"
	# Preserve existing general collision + surface-only aim projection layers.
	body.collision_layer = 1 | 4
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.shape = mesh.create_trimesh_shape()
	body.add_child(shape)
	add_child(body)
	for descriptor: Dictionary in record.base.resources:
		_build_resource(descriptor)
	update_markers()

func _height(terrain: Dictionary, x: int, z: int) -> float:
	return float(terrain.heights_mm[z * int(terrain.grid_size) + x]) / 1000.0

func _build_resource(descriptor: Dictionary) -> void:
	var point: Array = descriptor.position_mm
	var local := Vector3(float(point[0]), float(point[1]), float(point[2])) / 1000.0 - position
	var visual := MeshInstance3D.new()
	visual.name = "Resource_" + descriptor.node_id
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.9, 0.7)
	visual.mesh = box
	visual.position = local + Vector3(0, 0.45, 0)
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	var kind := "stone"
	if resources != null:
		var profile := resources.catalog.profile(descriptor.profile_id)
		if profile != null: kind = profile.kind
	material.albedo_color = Color(0.25, 0.60, 0.22) if kind == "tree" else (Color(0.30, 0.60, 0.90) if kind == "ore" else Color(0.55, 0.55, 0.58))
	material.roughness = 1.0
	visual.material_override = material
	add_child(visual)
	var label := Label3D.new()
	label.text = descriptor.profile_id
	label.font_size = 28
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = local + Vector3(0, 1.25, 0)
	add_child(label)
	_resource_markers[descriptor.node_id] = {"mesh": visual, "label": label, "point": local}

func update_markers() -> void:
	var tick := clock.tick if clock != null else 0
	for node_id: String in _resource_markers:
		var marker: Dictionary = _resource_markers[node_id]
		var hidden: bool = record.delta.removed_resources.has(node_id)
		marker.mesh.visible = not hidden
		marker.label.visible = not hidden
		if resources == null: continue
		var state := resources.snapshot(node_id, tick)
		if state.is_empty(): continue
		marker.label.text = "%s %d/%d" % [state.display_name, state.remaining, state.max_reserves]
		var amount := 0.25 if state.remaining == 0 else 1.0
		marker.mesh.scale.y = amount
		marker.mesh.position.y = marker.point.y + 0.45 * amount
