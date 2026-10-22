extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)

func authored_blueprint() -> Dictionary:
	var definitions := ResourceCatalog.defaults()
	var authored: Array = []
	for node in definitions.nodes:
		authored.append({"node_id": node.node_id, "profile_id": node.profile_id, "region_id": node.region_id, "position_mm": [roundi(node.position.x * 1000), roundi(node.position.y * 1000), roundi(node.position.z * 1000)]})
	return WorldBlueprint.create("world.primary", 77231, 32, 4, authored)

func run() -> void:
	var blueprint := authored_blueprint()
	var generator := WorldGenesis.new()
	var ridge: Dictionary = generator.generate(blueprint, Vector2i(-1, -1), 0).record
	var view := ChunkView.new()
	view.record = ridge
	root.add_child(view)
	check(view.get_child_count() == 2 and view.get_node("TerrainMesh") is MeshInstance3D and view.get_node("TerrainCollision") is StaticBody3D, "one terrain mesh and one physics body per canonical chunk")
	var mesh: ArrayMesh = view.get_node("TerrainMesh").mesh
	check(mesh.get_surface_count() == 1 and mesh.surface_get_array_len(0) == 81 and mesh.surface_get_array_index_len(0) == 384, "bounded nine-by-nine indexed terrain geometry")
	view.build()
	check(view.get_child_count() == 2, "repeated build is idempotent and never duplicates runtime body")
	check(view.position == Vector3(-32, 0, -32), "view placement derives chunk record and parameterized size")
	await physics_frame
	await physics_frame
	var space := view.get_world_3d().direct_space_state
	var ridge_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-12, 10, -24), Vector3(-12, -10, -24), 1))
	var ramp_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-12, 10, -12), Vector3(-12, -10, -12), 1))
	var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-12, 10, -2), Vector3(-12, -10, -2), 1))
	check(not ridge_hit.is_empty() and is_equal_approx(ridge_hit.position.y, 3.0), "actual chunk collision preserves authored ridge elevation")
	check(not ramp_hit.is_empty() and is_equal_approx(ramp_hit.position.y, 2.0), "actual chunk collision follows canonical ramp height")
	check(not floor_hit.is_empty() and is_equal_approx(floor_hit.position.y, 0.0), "actual chunk collision has navigable valley floor")
	check(not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-12, 10, -12), Vector3(-12, -10, -12), 4)).is_empty(), "canonical chunk keeps existing surface-only aim layer")
	view.free()
	await physics_frame
	check(space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-12, 10, -24), Vector3(-12, -10, -24), 1)).is_empty(), "dematerialization releases physics residency")
	var inventory := InventoryService.new(ItemCatalog.defaults())
	var owner_id := CoreIds.generate()
	inventory.register_container("container.view.test", owner_id, 20, 100000)
	var resources := ResourceService.new()
	resources.configure(inventory, ResourceCatalog.defaults())
	var clock := CoreClock.new()
	clock.tick = 1
	var resource_record: Dictionary = generator.generate(blueprint, Vector2i(-1, 0), 0).record
	var resource_view := ChunkView.new()
	resource_view.record = resource_record
	resource_view.resources = resources
	resource_view.clock = clock
	root.add_child(resource_view)
	check(resource_view.get_child_count() == 10, "four existing P2 resources represented by bounded mesh/label pairs")
	var before := resources.capture()
	resource_view.update_markers()
	check(resources.capture() == before, "presentation refresh never settles canonical harvest/regen state")
	var axe := inventory.catalog.lookup("item.tool.axe")
	for tick in [1, 2, 3]: resources.gather(owner_id, "container.view.test", "resource.node.common_tree", tick, Vector3(-4, 0, 5), axe)
	clock.tick = 3
	resource_view.update_markers()
	var marker: Dictionary = resource_view._resource_markers["resource.node.common_tree"]
	check(marker.label.text.contains("0/3") and marker.mesh.scale.y == 0.25, "authoritative depletion updates placeholder/label without becoming outcome source")
	var depleted := resources.capture()
	clock.tick = 303
	resource_view.update_markers()
	check(marker.label.text.contains("3/3") and resources.capture() == depleted, "borrowed clock shows lazy renewal without presentation mutating canonical node")
	resource_view.record.delta.removed_resources.append("resource.node.common_tree")
	resource_view.update_markers()
	check(not marker.mesh.visible and not marker.label.visible, "canonical removed-resource delta hides only presentation")
	resource_view.free()
	await process_frame
	var base_nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var base_orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var memory_samples: Array[int] = []
	var peak_nodes := base_nodes
	var canonical_hash: String = ridge.base_hash
	for cycle in range(4):
		var views: Array[ChunkView] = []
		for x in [-1, 0, 1, 2]:
			var selected: Dictionary = generator.generate(blueprint, Vector2i(x, -1), 0).record
			var instance := ChunkView.new()
			instance.record = selected
			root.add_child(instance)
			views.append(instance)
		peak_nodes = maxi(peak_nodes, int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		for instance in views: instance.free()
		views.clear()
		await process_frame
		check(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) == base_nodes and int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == base_orphans, "streaming roundtrip %d releases all runtime Nodes/orphans" % cycle)
		memory_samples.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	check(ridge.base_hash == canonical_hash, "runtime build/free never changes canonical terrain record")
	check(peak_nodes - base_nodes <= 40, "materialized Node cost remains bounded for the four-chunk scenario")
	check(memory_samples.back() - memory_samples[0] < 2097152, "repeated view cycles have no unbounded static-memory growth after warmup")
	print("P3 streaming metrics ", JSON.stringify({"peak_node_delta": peak_nodes - base_nodes, "post_unload_memory_samples": memory_samples, "post_warmup_memory_delta": memory_samples.back() - memory_samples[0], "materialized_peak": 4}))
	await process_frame
	print("P3 streaming tests: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
