class_name BuildManager
extends Node

const GRID_SIZE := 0.5

signal open_store_requested
signal hint_requested(text: String)
signal order_requested

@export var fixture_scene: PackedScene
@export var fixture_definition: FixtureDefinition

var store: StoreRoom
var store_manager: StoreManager
var camera_rig: CameraRig
var economy: EconomyManager
var context_menu: BuildContextMenu
var build_enabled: bool = true

var _ghost: Node3D
var _rotation_y_deg: float = 0.0
var _ghost_rot: float = 0.0
var _ghost_valid: bool = false
var _selected_instance_id: StringName = &""
var _menu_target_id: StringName = &""
var _active_product_id: StringName = &"freshpop_cola_500"
var _place_mode: bool = false


func setup(p_store: StoreRoom, p_store_manager: StoreManager, p_camera: CameraRig, p_economy: EconomyManager, p_menu: BuildContextMenu) -> void:
	store = p_store
	store_manager = p_store_manager
	camera_rig = p_camera
	economy = p_economy
	context_menu = p_menu
	if context_menu:
		context_menu.action_chosen.connect(_on_context_action)
	_create_ghost()


func set_build_enabled(enabled: bool) -> void:
	build_enabled = enabled
	if _ghost and not enabled:
		_ghost.visible = false
		_place_mode = false


func _process(_delta: float) -> void:
	if not build_enabled or store == null or camera_rig == null:
		return
	if _ghost == null:
		return
	if not _place_mode or (context_menu != null and context_menu.visible):
		_ghost.visible = false
		return
	var mouse := get_viewport().get_mouse_position()
	if _is_mouse_over_ui(mouse):
		_ghost.visible = false
		return
	_ghost.visible = true
	var ground := camera_rig.ray_to_ground(mouse)
	var grid_pos := _snap_to_grid(ground)
	var layout := StoreLayout.snap(fixture_definition, grid_pos, _rotation_y_deg)
	var place_pos: Vector3 = layout.get("pos", grid_pos)
	_ghost_rot = float(layout.get("rot", _rotation_y_deg))
	_ghost.global_position = place_pos
	_ghost.rotation.y = deg_to_rad(_ghost_rot)
	_ghost_valid = _can_place(place_pos, _ghost_rot) and _can_afford(fixture_definition)
	_set_ghost_valid(_ghost_valid)


func _unhandled_input(event: InputEvent) -> void:
	if not build_enabled:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			_rotation_y_deg = fmod(_rotation_y_deg + 90.0, 360.0)
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_ESCAPE:
			_place_mode = false
			if _ghost:
				_ghost.visible = false
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_RIGHT:
			if _is_mouse_over_ui(mouse_button.position):
				return
			_open_context_menu(mouse_button.position)
			get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if context_menu != null and context_menu.visible:
				return
			if _is_mouse_over_ui(mouse_button.position):
				return
			var hit := _pick_fixture(mouse_button.position)
			if hit != null:
				_select_and_assign(hit)
				get_viewport().set_input_as_handled()
				return
			if _place_mode and _ghost_valid:
				_place_fixture()
				get_viewport().set_input_as_handled()


func _place_fixture() -> void:
	place_fixture_at(_ghost.global_position, _ghost_rot)


func open_place_picker() -> void:
	if context_menu == null or store_manager == null:
		return
	var screen_pos := Vector2(220, 180)
	var vp := get_viewport()
	if vp != null:
		screen_pos = vp.get_visible_rect().size * Vector2(0.28, 0.32)
	_menu_target_id = &""
	context_menu.open_for_floor(screen_pos, _ghost_valid, not store_manager.runtime.is_empty(), store_manager.list_fixtures())
	context_menu.call_deferred("_build_fixture_type_picker")


func place_fixture_at(world_pos: Vector3, rotation_y_deg: float, definition: FixtureDefinition = null, rebake: bool = true, pay: bool = true) -> StringName:
	var used := definition if definition != null else fixture_definition
	if used == null or used.packed_scene == null:
		push_error("BuildManager missing fixture definition")
		return &""
	if not _can_place(world_pos, rotation_y_deg, [], used):
		return &""
	if pay and not _pay_for_fixture(used):
		return &""
	var instance := _spawn_fixture(used)
	store.fixtures_root.add_child(instance)
	instance.global_position = world_pos
	instance.rotation.y = deg_to_rad(rotation_y_deg)
	var state := store_manager.register_placed_fixture(used, instance, instance.global_position, rotation_y_deg, rebake)
	if rebake:
		store.rebake_navigation()
	return state.instance_id


func fill_supermarket_layout() -> int:
	if store_manager != null and store_manager.runtime.size() >= 16:
		_place_mode = false
		if _ghost:
			_ghost.visible = false
		return store_manager.runtime.size()
	var placed := 0
	for row in StoreLayout.plan_for(store_manager):
		var definition: FixtureDefinition = row.get("definition", null)
		var pos: Vector3 = row.get("pos", Vector3.ZERO)
		var rot := float(row.get("rot", 0.0))
		if not place_fixture_at(pos, rot, definition, false).is_empty():
			placed += 1
	_place_mode = false
	if _ghost:
		_ghost.visible = false
	if placed > 0 and store != null:
		store.rebake_navigation()
	return placed


func next_layout_slot(definition: FixtureDefinition) -> Dictionary:
	if definition == null:
		return {}
	for slot in StoreLayout.slots_for(definition):
		var pos: Vector3 = slot.get("pos", Vector3.ZERO)
		var rot := float(slot.get("rot", 0.0))
		if _can_place(pos, rot, [], definition):
			return slot
	return {}


func select_fixture(definition_id: StringName) -> bool:
	if store_manager == null:
		return false
	var definition := store_manager.get_fixture_definition(definition_id)
	if definition == null:
		return false
	fixture_definition = definition
	fixture_scene = definition.packed_scene
	_place_mode = true
	_rebuild_ghost()
	return true


func _open_context_menu(screen_pos: Vector2) -> void:
	if context_menu == null:
		return
	var hit := _pick_fixture(screen_pos)
	var fixture_node := _find_fixture_node(hit) if hit else null
	if fixture_node != null:
		var instance_id := store_manager.find_fixture_id_for_node(fixture_node)
		if instance_id == &"":
			return
		_highlight_fixture(instance_id)
		_menu_target_id = instance_id
		context_menu.open_for_fixture(screen_pos, store_manager.describe_fixture_shelves(instance_id), store_manager.list_catalog())
		return
	_menu_target_id = &""
	context_menu.open_for_floor(screen_pos, _ghost_valid, not store_manager.runtime.is_empty(), store_manager.list_fixtures())


func _on_context_action(action_id: int, payload: int = 0) -> void:
	match action_id:
		BuildContextMenu.ACTION_PLACE:
			if _ghost_valid:
				_place_fixture()
			else:
				hint_requested.emit("Cannot place fixture here.")
		BuildContextMenu.ACTION_PICK_FIXTURE:
			if context_menu != null and context_menu.pending_fixture_id != &"":
				select_fixture(context_menu.pending_fixture_id)
			if _ghost_valid:
				_place_fixture()
			else:
				hint_requested.emit("Cannot place fixture here.")
		BuildContextMenu.ACTION_ASSIGN:
			if _menu_target_id != &"":
				store_manager.assign_product_to_fixture(_menu_target_id, _active_product_id)
		BuildContextMenu.ACTION_ASSIGN_SHELF:
			if _menu_target_id != &"":
				if context_menu != null and context_menu.pending_product_id != &"":
					_active_product_id = context_menu.pending_product_id
				store_manager.assign_product_to_shelf(_menu_target_id, payload, _active_product_id)
		BuildContextMenu.ACTION_RESTOCK:
			if _menu_target_id != &"":
				var queued := store_manager.restock_fixture(_menu_target_id)
				if queued <= 0:
					hint_requested.emit(_restock_fail_hint(_menu_target_id))
		BuildContextMenu.ACTION_FACINGS_MORE:
			_adjust_menu_facings(1)
		BuildContextMenu.ACTION_FACINGS_LESS:
			_adjust_menu_facings(-1)
		BuildContextMenu.ACTION_CLEAR:
			if _menu_target_id != &"":
				if not store_manager.clear_fixture_products(_menu_target_id):
					hint_requested.emit("No product on this shelf.")
		BuildContextMenu.ACTION_ROTATE:
			_rotate_menu_target()
		BuildContextMenu.ACTION_ROTATE_GHOST:
			_rotation_y_deg = fmod(_rotation_y_deg + 90.0, 360.0)
		BuildContextMenu.ACTION_DUPLICATE:
			_duplicate_menu_target()
		BuildContextMenu.ACTION_DELETE:
			_delete_menu_target()
		BuildContextMenu.ACTION_DELETE_ALL:
			_delete_all_fixtures()
		BuildContextMenu.ACTION_OPEN_STORE:
			open_store_requested.emit()
		BuildContextMenu.ACTION_ORDER:
			order_requested.emit()
		_:
			push_warning("Unknown context action: %d" % action_id)


func try_rotate_fixture(instance_id: StringName) -> bool:
	_menu_target_id = instance_id
	var fixture := store_manager.get_fixture(instance_id)
	if fixture == null:
		return false
	var old_rot := fixture.rotation_y_deg
	_rotate_menu_target()
	fixture = store_manager.get_fixture(instance_id)
	return fixture != null and not is_equal_approx(fixture.rotation_y_deg, old_rot)


func _highlight_fixture(instance_id: StringName) -> void:
	_clear_selection()
	_selected_instance_id = instance_id
	var node := store_manager.get_fixture_node(instance_id)
	if node != null and node.has_method("set_highlighted"):
		node.set_highlighted(true)


func _restock_fail_hint(instance_id: StringName) -> String:
	var reason: StringName = &"warehouse_empty"
	if store_manager != null:
		reason = store_manager.restock_fail_reason(instance_id)
	match reason:
		&"no_product":
			return "Place a product on the shelf first."
		&"queued":
			return "Already restocking."
		&"full":
			return "Shelf is full."
		_:
			return "Warehouse is empty."


func _adjust_menu_facings(delta: int) -> void:
	if _menu_target_id == &"":
		return
	if store_manager.adjust_facings(_menu_target_id, delta) <= 0:
		hint_requested.emit("Place a product on the shelf first.")
		return
	if context_menu != null:
		context_menu.refresh_fixture_rows(store_manager.describe_fixture_shelves(_menu_target_id))


func _rotate_menu_target() -> void:
	if _menu_target_id == &"":
		return
	var fixture := store_manager.get_fixture(_menu_target_id)
	var node := store_manager.get_fixture_node(_menu_target_id)
	if fixture == null or node == null:
		return
	var definition := store_manager.get_fixture_definition(fixture.definition_id)
	var new_rot := fmod(fixture.rotation_y_deg + 90.0, 360.0)
	var layout_snap := StoreLayout.snap(definition, node.global_position, new_rot)
	new_rot = float(layout_snap.get("rot", new_rot))
	var delta := new_rot - fixture.rotation_y_deg
	if absf(delta) > 180.0:
		delta -= 360.0 * signf(delta)
	if is_equal_approx(delta, 0.0):
		hint_requested.emit("Rotation collides with surroundings.")
		return
	var exclude: Array[RID] = []
	if node is CollisionObject3D:
		exclude.append((node as CollisionObject3D).get_rid())
	if not _can_place(node.global_position, new_rot, exclude, definition):
		hint_requested.emit("Rotation collides with surroundings.")
		return
	store_manager.rotate_fixture(_menu_target_id, delta)
	store.rebake_navigation()


func _delete_menu_target() -> void:
	if _menu_target_id == &"":
		return
	if _selected_instance_id == _menu_target_id:
		_selected_instance_id = &""
	_refund_fixture_instance(_menu_target_id)
	store_manager.remove_fixture(_menu_target_id)
	_menu_target_id = &""
	store.rebake_navigation()


func _delete_all_fixtures() -> void:
	_clear_selection()
	_menu_target_id = &""
	var ids: Array = store_manager.runtime.keys()
	for instance_id in ids:
		_refund_fixture_instance(instance_id)
		store_manager.remove_fixture(instance_id)
	store.rebake_navigation()


func duplicate_fixture(instance_id: StringName) -> bool:
	_menu_target_id = instance_id
	var before := store_manager.runtime.size()
	_duplicate_menu_target()
	return store_manager.runtime.size() > before


func _duplicate_menu_target() -> void:
	if _menu_target_id == &"":
		return
	var source := store_manager.get_fixture(_menu_target_id)
	var source_node := store_manager.get_fixture_node(_menu_target_id)
	if source == null or source_node == null:
		return
	var definition := store_manager.get_fixture_definition(source.definition_id)
	if definition == null:
		definition = fixture_definition
	if definition == null:
		return
	var dest := _find_duplicate_position(source_node.global_position, source.rotation_y_deg, definition)
	if dest == Vector3.INF:
		hint_requested.emit("No space to duplicate fixture.")
		return
	if not _pay_for_fixture(definition):
		return
	var instance := _spawn_fixture(definition)
	store.fixtures_root.add_child(instance)
	instance.global_position = dest
	instance.rotation.y = deg_to_rad(source.rotation_y_deg)
	var copy := store_manager.register_placed_fixture(definition, instance, dest, source.rotation_y_deg)
	for row in store_manager.describe_fixture_shelves(_menu_target_id):
		if not bool(row.get("occupied", false)):
			continue
		store_manager.assign_product_to_shelf(
			copy.instance_id,
			int(row.get("shelf_index", 0)),
			row.get("product_id", &"freshpop_cola_500") as StringName,
			0,
			int(row.get("facings", -1))
		)
	store.rebake_navigation()


func _find_duplicate_position(origin: Vector3, rotation_y_deg: float, definition: FixtureDefinition = null) -> Vector3:
	for offset in StoreLayout.duplicate_offsets(rotation_y_deg, definition):
		var candidate := _snap_to_grid(origin + offset)
		if _can_place(candidate, rotation_y_deg, [], definition):
			return candidate
	return Vector3.INF


func _select_and_assign(node: Node) -> void:
	var fixture_node := _find_fixture_node(node)
	if fixture_node == null:
		return
	var instance_id := store_manager.find_fixture_id_for_node(fixture_node)
	if instance_id == &"":
		return
	_highlight_fixture(instance_id)
	store_manager.assign_product_to_fixture(instance_id, _active_product_id)


func _clear_selection() -> void:
	if _selected_instance_id != &"":
		var node := store_manager.get_fixture_node(_selected_instance_id)
		if node != null and node.has_method("set_highlighted"):
			node.set_highlighted(false)
	_selected_instance_id = &""


func _can_afford(definition: FixtureDefinition) -> bool:
	if definition == null or economy == null:
		return true
	return economy.can_afford(definition.purchase_cost)


func _pay_for_fixture(definition: FixtureDefinition) -> bool:
	if definition == null or economy == null:
		return true
	if definition.purchase_cost <= 0.0:
		return true
	if not economy.can_afford(definition.purchase_cost):
		hint_requested.emit("Not enough cash (%.0f)." % definition.purchase_cost)
		return false
	var result := economy.spend(definition.purchase_cost, &"fixture")
	return bool(result.get("ok", false))


func _refund_fixture_instance(instance_id: StringName) -> void:
	if economy == null or store_manager == null:
		return
	var fixture := store_manager.get_fixture(instance_id)
	if fixture == null:
		return
	var definition := store_manager.get_fixture_definition(fixture.definition_id)
	if definition == null or definition.purchase_cost <= 0.0:
		return
	economy.refund(definition.purchase_cost, &"fixture_refund")


func _can_place(world_pos: Vector3, rotation_y_deg: float, exclude: Array[RID] = [], definition: FixtureDefinition = null) -> bool:
	var used := definition if definition != null else fixture_definition
	if used == null:
		return false
	var size := _rotated_size(rotation_y_deg, used)
	if not store.contains_point(world_pos, 0.35):
		return false
	if store.blocks_doorway(world_pos, size):
		return false
	if _overlaps_existing(world_pos, size, exclude):
		return false
	return true


func _rotated_size(rotation_y_deg: float, definition: FixtureDefinition = null) -> Vector3:
	var used := definition if definition != null else fixture_definition
	if used == null:
		return Vector3.ONE
	var yaw := fmod(rotation_y_deg, 180.0)
	if is_equal_approx(yaw, 90.0) or is_equal_approx(yaw, -90.0):
		return Vector3(used.depth_m, used.height_m, used.width_m)
	return Vector3(used.width_m, used.height_m, used.depth_m)


func _overlaps_existing(world_pos: Vector3, size: Vector3, exclude: Array[RID] = []) -> bool:
	var space := store.get_world_3d().direct_space_state
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x - 0.05, size.y - 0.05, size.z - 0.05)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, world_pos + Vector3(0.0, size.y * 0.5, 0.0))
	query.collision_mask = 2 | 4
	query.collide_with_bodies = true
	query.exclude = exclude
	var hits := space.intersect_shape(query, 8)
	return not hits.is_empty()


func _pick_fixture(mouse_pos: Vector2) -> Node:
	var cam := camera_rig.get_camera()
	var origin := cam.project_ray_origin(mouse_pos)
	var end := origin + cam.project_ray_normal(mouse_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(origin, end, 2)
	var hit := store.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return hit.get("collider") as Node


func _find_fixture_node(node: Node) -> FixtureNode:
	var current := node
	while current:
		if current is FixtureNode:
			return current
		current = current.get_parent()
	return null


func _snap_to_grid(point: Vector3) -> Vector3:
	return Vector3(
		round(point.x / GRID_SIZE) * GRID_SIZE,
		0.0,
		round(point.z / GRID_SIZE) * GRID_SIZE
	)


func _spawn_fixture(definition: FixtureDefinition) -> Node3D:
	var scene := definition.packed_scene if definition != null else fixture_scene
	var instance := scene.instantiate() as Node3D
	if instance.has_method("configure") and definition != null:
		instance.configure(definition)
	return instance


func _rebuild_ghost() -> void:
	if store == null:
		return
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	_create_ghost()


func _create_ghost() -> void:
	if fixture_definition == null and fixture_scene == null:
		return
	_ghost = _spawn_fixture(fixture_definition)
	_ghost.name = "PlacementGhost"
	store.add_child(_ghost)
	if _ghost is CollisionObject3D:
		(_ghost as CollisionObject3D).collision_layer = 0
		(_ghost as CollisionObject3D).collision_mask = 0
	_set_ghost_valid(false)


func _set_ghost_valid(valid: bool) -> void:
	if _ghost == null:
		return
	var color := Color(0.25, 0.85, 0.4, 0.45) if valid else Color(0.85, 0.2, 0.2, 0.45)
	if _ghost.has_method("set_preview_color"):
		_ghost.set_preview_color(color)


func _is_mouse_over_ui(_mouse_pos: Vector2) -> bool:
	var hovered := get_viewport().gui_get_hovered_control()
	return hovered != null
