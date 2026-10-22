class_name ItemsPanel
extends Node3D

# Technical Run 1 view. Buttons produce requests; labels/meshes consume snapshots.
var items: ItemsModule
var gateway: AuthorityGateway
var _panel := PanelContainer.new()
var _list := ItemList.new()
var _status := Label.new()
var _context := Label.new()
var _ids: Array[String] = []
var _markers: Dictionary = {}
var _drop_markers: Dictionary = {}
var _buttons: Array[Button] = []
var _revision := -1
var _elapsed := 0.0
var _token := 0
var _dirty := true
var external_world_markers := false
var candidate_nodes: Callable

func attach_chunk_candidates(provider: Callable) -> void:
	external_world_markers = true
	candidate_nodes = provider
	for marker in _markers.values(): marker.free()
	_markers.clear()

func _ready() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var toggle := _button("Items (I)", func() -> void: _panel.visible = not _panel.visible)
	toggle.position = Vector2(20, 100)
	canvas.add_child(toggle)
	_context.position = Vector2(170, 105)
	_context.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(_context)
	_panel.position = Vector2(20, 255)
	_panel.custom_minimum_size = Vector2(490, 310)
	canvas.add_child(_panel)
	var column := VBoxContainer.new()
	_panel.add_child(column)
	column.add_child(_status)
	_list.custom_minimum_size = Vector2(480, 155)
	column.add_child(_list)
	var row := HBoxContainer.new()
	column.add_child(row)
	row.add_child(_button("Equip selected", _equip_selected))
	row.add_child(_button("Use selected", _use_selected))
	row.add_child(_button("Split 1", _split_selected))
	var tools := HBoxContainer.new()
	column.add_child(tools)
	for spec in [["Axe", "item.tool.axe"], ["Pick", "item.tool.pickaxe"], ["Sword", "item.weapon.sword"], ["Armor", "item.armor.leather"]]:
		var id: String = spec[1]
		tools.add_child(_button(spec[0], func() -> void: _equip_definition(id)))
	var crafts := HBoxContainer.new()
	column.add_child(crafts)
	crafts.add_child(_button("Craft balm (J)", func() -> void: _craft("recipe.healing_balm", "")))
	crafts.add_child(_button("Smelt ore", func() -> void: _craft("recipe.iron_ingot", ItemsModule.FORGE)))
	crafts.add_child(_button("Forge sword", func() -> void: _craft("recipe.tempered_sword", ItemsModule.FORGE)))
	_panel.visible = false
	var utility := HBoxContainer.new()
	utility.position = Vector2(20, 650)
	canvas.add_child(utility)
	utility.add_child(_button("Interact (R)", _interact))
	utility.add_child(_button("Use balm (U)", _use_balm))
	for authored in items.content.nodes:
		if external_world_markers: break
		var profile := items.content.profile(authored.profile_id)
		var marker := _world_marker(authored.position, Color(0.25, 0.6, 0.22) if profile.kind == "tree" else (Color(0.3, 0.6, 0.9) if profile.kind == "ore" else Color(0.55, 0.55, 0.58)), profile.display_name)
		_markers[authored.node_id] = marker
	_world_marker(ItemsModule.FORGE_POSITION, Color(0.85, 0.4, 0.1), "Forge")
	_world_marker(Vector3(-1, 0, 10), Color(0.55, 0.32, 0.14), "Storage")
	_token = items.combat.events.subscribe(ItemOperationResolved, func(_fact: ItemOperationResolved) -> void: _dirty = true)
	_refresh()

func _button(title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(125, 42)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_buttons.append(button)
	return button

func owns_point(point: Vector2) -> bool:
	if _panel.visible and _panel.get_global_rect().has_point(point): return true
	for button in _buttons:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(point): return true
	return false

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.physical_keycode:
		KEY_I: _panel.visible = not _panel.visible
		KEY_R: _interact()
		KEY_J: _craft("recipe.healing_balm", "")
		KEY_U: _use_balm()

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < 0.15: return
	_elapsed = 0
	_refresh()

func _refresh() -> void:
	var target := nearest()
	_context.text = "Nearby: " + target.get("id", "none") + " · " + items.last_result
	var view := items.state_view()
	for id: String in view.nodes:
		if not _markers.has(id): continue
		var state: Dictionary = view.nodes[id]
		_markers[id].get_node("Label").text = "%s %d/%d" % [state.display_name, state.remaining, state.max_reserves]
		_markers[id].get_node("Mesh").scale.y = 0.25 if state.remaining == 0 else 1.0
	for id: String in view.drops:
		var drop: Dictionary = view.drops[id]
		if not _drop_markers.has(id):
			_drop_markers[id] = _world_marker(Vector3(drop.position[0], drop.position[1], drop.position[2]), Color(0.9, 0.75, 0.1), "Loot · Interact")
		_drop_markers[id].visible = not drop.claimed
	if not _dirty and _revision == items.revision: return
	_dirty = false
	_revision = items.revision
	var selected := _selected()
	_list.clear()
	_ids.clear()
	var gear: Dictionary = items.equipment.capture().slots
	_status.text = "Bag %d/%d · %dg · %s\nEquipment %s" % [view.inventory.entries.size(), view.inventory.slots, view.inventory.mass_grams, items.last_result, str(gear.keys())]
	for entry: Dictionary in view.inventory.entries:
		var definition := items.catalog.lookup(entry.definition_id)
		_list.add_item("%s ×%d%s" % [definition.display_name, entry.quantity, " [equipped]" if items.equipment.is_equipped(ItemsModule.BAG, entry.id) else ""])
		_ids.append(entry.id)
		if entry.id == selected: _list.select(_ids.size() - 1)

func nearest() -> Dictionary:
	var best := {}
	var distance := 7.5625
	for id: String in items.drops:
		var drop: Dictionary = items.drops[id]
		var point := Vector3(drop.position[0], drop.position[1], drop.position[2])
		var squared := items.player.position.distance_squared_to(point)
		if not drop.claimed and squared <= distance: best = {"kind": "item.pickup", "id": id}; distance = squared
	var candidates: Array = candidate_nodes.call() if candidate_nodes.is_valid() else items.resources.node_ids()
	for node_id: String in candidates:
		var node := items.resources.definition(node_id)
		if node == null: continue
		var squared := items.player.position.distance_squared_to(node.position)
		if squared <= distance: best = {"kind": "item.harvest", "id": node.node_id}; distance = squared
	return best

func _interact() -> void:
	var candidate := nearest()
	if candidate.is_empty(): return
	gateway.request(candidate.kind, {"drop" if candidate.kind == "item.pickup" else "node": candidate.id})

func _selected() -> String:
	var selection := _list.get_selected_items()
	return _ids[selection[0]] if not selection.is_empty() and selection[0] < _ids.size() else ""

func _equip_selected() -> void:
	var entry := items.inventory.entry(ItemsModule.BAG, _selected())
	if not entry.is_empty(): gateway.request("item.equip", {"slot": items.catalog.lookup(entry.definition_id).equipment_slot, "entry": entry.id})

func _equip_definition(id: String) -> void:
	for entry: Dictionary in items.inventory.entries(ItemsModule.BAG):
		if entry.definition_id == id:
			gateway.request("item.equip", {"slot": items.catalog.lookup(id).equipment_slot, "entry": entry.id})
			return

func _use_selected() -> void:
	if not _selected().is_empty(): gateway.request("item.consume", {"entry": _selected()})

func _split_selected() -> void:
	if not _selected().is_empty(): gateway.request("item.split", {"entry": _selected(), "quantity": 1})

func _use_balm() -> void:
	for entry: Dictionary in items.inventory.entries(ItemsModule.BAG):
		if entry.definition_id == "item.consumable.healing_balm": gateway.request("item.consume", {"entry": entry.id}); return

func _craft(recipe: String, station: String) -> void:
	gateway.request("item.craft", {"recipe": recipe, "station": station, "choices": {}})

func _world_marker(point: Vector3, color: Color, title: String) -> Node3D:
	var marker := Node3D.new()
	add_child(marker)
	marker.position = point
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	var shape := BoxMesh.new()
	shape.size = Vector3(0.7, 0.9, 0.7)
	mesh.mesh = shape
	mesh.position.y = 0.45
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	marker.add_child(mesh)
	var label := Label3D.new()
	label.name = "Label"
	label.text = title
	label.font_size = 32
	label.pixel_size = 0.007
	label.position.y = 1.25
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.add_child(label)
	return marker

func _exit_tree() -> void:
	items.combat.events.unsubscribe(_token)
