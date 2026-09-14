class_name FixtureNode
extends StaticBody3D

const TexLib := preload("res://scripts/store/store_textures.gd")
const FRAME_THICKNESS := 0.04
const BASE_HEIGHT := 0.08
const SHELF_THICKNESS := 0.03
const BACK_THICKNESS := 0.02

var instance_state: FixtureInstanceState
var _frame_material: StandardMaterial3D
var _shelf_material: StandardMaterial3D
var _highlight_material: StandardMaterial3D
var _preview_material: StandardMaterial3D
var _shelf_local_y: Array[float] = []
var _visual_root: Node3D
var _product_visuals: Array[MeshInstance3D] = []
var _is_preview: bool = false
var _body_width: float = 1.0
var _body_depth: float = 0.5
var _body_height: float = 1.8
var _body_shelves: int = 4
var _style: StringName = &"gondola"


func configure(definition: FixtureDefinition) -> void:
	if definition == null:
		return
	_body_width = definition.width_m
	_body_depth = definition.depth_m
	_body_height = definition.height_m
	_body_shelves = maxi(definition.shelf_count, 1)
	_style = definition.fixture_type


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("fixtures")
	_visual_root = $VisualRoot
	var template := $ProductVisual as MeshInstance3D
	template.visible = false
	_product_visuals.append(template)
	for i in range(1, _body_shelves):
		var clone := template.duplicate() as MeshInstance3D
		clone.name = "ProductVisual_%d" % i
		add_child(clone)
		_product_visuals.append(clone)
	_frame_material = _make_material(_frame_color(), _frame_roughness(), _frame_metallic(), _frame_texture())
	_shelf_material = _make_material(Color(1.0, 0.96, 0.88), 0.74, 0.0, TexLib.wood_tex(), Vector3(2.4, 2.4, 2.4))
	_highlight_material = _make_material(Color(0.35, 0.62, 0.95), 0.45, 0.05)
	_resize_collision()
	_build_body()


func set_preview_color(color: Color) -> void:
	_is_preview = true
	if _preview_material == null:
		_preview_material = StandardMaterial3D.new()
		_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.albedo_color = color
	_apply_material_to_group("gondola_frame", _preview_material)
	_apply_material_to_group("gondola_shelf", _preview_material)
	_hide_all_product_visuals()


func bind_state(state: FixtureInstanceState) -> void:
	instance_state = state
	refresh_product_visual()


func set_highlighted(enabled: bool) -> void:
	if _is_preview:
		return
	_apply_material_to_group("gondola_frame", _highlight_material if enabled else _frame_material)
	_apply_material_to_group("gondola_shelf", _shelf_material)


func refresh_product_visual() -> void:
	if _product_visuals.is_empty():
		return
	if instance_state == null:
		_hide_all_product_visuals()
		return
	for i in _product_visuals.size():
		var vis := _product_visuals[i]
		var placement := _placement_on_shelf(i)
		if placement == null or placement.shelf_stock <= 0:
			vis.visible = false
			continue
		vis.visible = true
		_apply_product_look(vis, placement)
		var shelf_y := _shelf_height(placement.shelf_index)
		var cap := maxf(float(placement.capacity), 1.0)
		var stock_ratio := clampf(float(placement.shelf_stock) / cap, 0.25, 1.0)
		var facing_x := clampf(float(placement.facings) * 0.22, 0.4, 1.5)
		vis.position = Vector3(0.0, shelf_y + 0.18 * stock_ratio, -0.08)
		vis.scale = Vector3(facing_x, stock_ratio, stock_ratio)


func _placement_on_shelf(shelf_index: int) -> ProductPlacementState:
	if instance_state == null:
		return null
	for shelf: ShelfState in instance_state.shelf_states:
		if shelf.shelf_index != shelf_index:
			continue
		for placement: ProductPlacementState in shelf.placements:
			return placement
	return null


func _hide_all_product_visuals() -> void:
	for vis in _product_visuals:
		vis.visible = false


func _apply_product_look(vis: MeshInstance3D, placement: ProductPlacementState) -> void:
	var mat := StandardMaterial3D.new()
	if placement.preview_texture != null:
		mat.albedo_color = Color(1.0, 1.0, 1.0)
		TexLib.apply_to_material(mat, placement.preview_texture, Vector3(2.2, 2.2, 2.2), true)
	else:
		mat.albedo_color = placement.preview_color
	vis.material_override = mat
	match placement.package_type:
		&"box_small":
			var box := BoxMesh.new()
			box.size = Vector3(0.14, 0.18, 0.08)
			vis.mesh = box
		&"carton":
			var carton := BoxMesh.new()
			carton.size = Vector3(0.08, 0.16, 0.08)
			vis.mesh = carton
		&"bag":
			var bag := BoxMesh.new()
			bag.size = Vector3(0.12, 0.16, 0.04)
			vis.mesh = bag
		&"bottle_small":
			var bottle := CylinderMesh.new()
			bottle.top_radius = 0.06
			bottle.bottom_radius = 0.06
			bottle.height = 0.22
			vis.mesh = bottle
		_:
			push_warning("Unknown package type: %s" % String(placement.package_type))
			var fallback := CylinderMesh.new()
			fallback.top_radius = 0.06
			fallback.bottom_radius = 0.06
			fallback.height = 0.22
			vis.mesh = fallback


func _shelf_height(shelf_index: int) -> float:
	if _shelf_local_y.is_empty():
		return 1.0
	var index := clampi(shelf_index, 0, _shelf_local_y.size() - 1)
	return _shelf_local_y[index]


func _build_body() -> void:
	match _style:
		&"wall_shelf":
			_build_wall_shelf()
		&"endcap":
			_build_endcap()
		&"gondola":
			_build_gondola()
		_:
			push_warning("Unknown fixture style: %s" % String(_style))
			_build_gondola()


func _frame_color() -> Color:
	match _style:
		&"wall_shelf":
			return Color(0.52, 0.38, 0.26)
		&"endcap":
			return Color(0.32, 0.42, 0.5)
		&"gondola":
			return Color(0.48, 0.5, 0.54)
		_:
			return Color(0.48, 0.5, 0.54)


func _frame_roughness() -> float:
	return 0.55 if _style == &"wall_shelf" else 0.38


func _frame_metallic() -> float:
	return 0.05 if _style == &"wall_shelf" else 0.42


func _frame_texture() -> Texture2D:
	return TexLib.wood_tex() if _style == &"wall_shelf" else TexLib.metal_tex()


func _resize_collision() -> void:
	var collider := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collider == null:
		return
	var box := BoxShape3D.new()
	box.size = Vector3(_body_width, _body_height, _body_depth)
	collider.shape = box
	collider.position = Vector3(0.0, _body_height * 0.5, 0.0)


func _build_gondola() -> void:
	_add_frame(_body_width, _body_depth, _body_height, true)
	_add_shelves(_body_width, _body_depth, 0.22, minf(1.48, _body_height - 0.25), _body_shelves)


func _build_wall_shelf() -> void:
	_add_frame(_body_width, _body_depth, _body_height, false)
	_add_shelves(_body_width, _body_depth, 0.28, minf(1.32, _body_height - 0.22), _body_shelves)


func _build_endcap() -> void:
	_add_frame(_body_width, _body_depth, _body_height, true)
	_add_shelves(_body_width, _body_depth, 0.26, minf(1.1, _body_height - 0.22), _body_shelves)
	var header := _make_material(Color(0.86, 0.22, 0.2), 0.5, 0.02, TexLib.metal_tex())
	_add_box(
		"Header",
		Vector3(_body_width, 0.12, _body_depth + 0.02),
		Vector3(0.0, _body_height - 0.04, 0.0),
		header,
		"gondola_frame"
	)


func _add_frame(width: float, depth: float, height: float, with_kick: bool) -> void:
	var kick_h := 0.14 if with_kick else BASE_HEIGHT
	var kick_mat := _frame_material
	if with_kick:
		kick_mat = _make_material(Color(0.22, 0.23, 0.25), 0.42, 0.28, TexLib.metal_tex(), Vector3(2.8, 2.8, 2.8))
	_add_box(
		"Base",
		Vector3(width, kick_h, depth),
		Vector3(0.0, kick_h * 0.5, 0.0),
		kick_mat,
		"gondola_frame"
	)
	var side_height := height - kick_h
	var side_y := kick_h + side_height * 0.5
	_add_box(
		"SideLeft",
		Vector3(FRAME_THICKNESS, side_height, depth),
		Vector3(-width * 0.5 + FRAME_THICKNESS * 0.5, side_y, 0.0),
		_frame_material,
		"gondola_frame"
	)
	_add_box(
		"SideRight",
		Vector3(FRAME_THICKNESS, side_height, depth),
		Vector3(width * 0.5 - FRAME_THICKNESS * 0.5, side_y, 0.0),
		_frame_material,
		"gondola_frame"
	)
	_add_box(
		"Back",
		Vector3(width - FRAME_THICKNESS * 2.0, side_height, BACK_THICKNESS),
		Vector3(0.0, side_y, depth * 0.5 - BACK_THICKNESS * 0.5),
		_frame_material,
		"gondola_frame"
	)
	var peg := _make_material(Color(0.92, 0.93, 0.94), 0.62, 0.08, TexLib.pegboard_tex(), Vector3(3.2, 3.2, 3.2))
	_add_box(
		"Pegboard",
		Vector3(width - FRAME_THICKNESS * 2.2, side_height - 0.06, 0.012),
		Vector3(0.0, side_y, depth * 0.5 - BACK_THICKNESS - 0.008),
		peg,
		"gondola_frame"
	)
	_add_box(
		"Top",
		Vector3(width, 0.045, depth),
		Vector3(0.0, height - 0.022, 0.0),
		_frame_material,
		"gondola_frame"
	)


func _add_shelves(width: float, depth: float, first_y: float, last_y: float, count: int) -> void:
	var inner_width := width - FRAME_THICKNESS * 2.0
	var inner_depth := maxf(depth - BACK_THICKNESS - 0.02, 0.12)
	var rail := _make_material(Color(0.76, 0.18, 0.16), 0.48, 0.04, TexLib.metal_tex(), Vector3(4.0, 4.0, 4.0))
	var front_z := -inner_depth * 0.5 - 0.01
	for i in count:
		var t := 0.0 if count == 1 else float(i) / float(count - 1)
		var y := lerpf(first_y, last_y, t)
		_shelf_local_y.append(y)
		_add_box(
			"Shelf_%d" % i,
			Vector3(inner_width, SHELF_THICKNESS, inner_depth),
			Vector3(0.0, y, -0.01),
			_shelf_material,
			"gondola_shelf"
		)
		_add_box(
			"Rail_%d" % i,
			Vector3(inner_width, 0.018, 0.014),
			Vector3(0.0, y + 0.016, front_z),
			rail,
			"gondola_shelf"
		)


func _add_box(part_name: String, size: Vector3, pos: Vector3, material: Material, group_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = part_name
	mesh_instance.position = pos
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	mesh_instance.set_meta("gondola_part", group_name)
	_visual_root.add_child(mesh_instance)


func _apply_material_to_group(group_name: String, material: Material) -> void:
	if _visual_root == null:
		return
	for child in _visual_root.get_children():
		if child.get_meta("gondola_part", "") == group_name and child is MeshInstance3D:
			(child as MeshInstance3D).material_override = material


func _make_material(color: Color, roughness: float = 0.55, metallic: float = 0.0, texture: Texture2D = null, uv_scale: Vector3 = Vector3(2.2, 2.2, 2.2)) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if texture != null:
		TexLib.apply_to_material(material, texture, uv_scale, true)
	return material
