class_name StoreRoom
extends Node3D

const TexLib := preload("res://scripts/store/store_textures.gd")
const WIDTH_M := 10.0
const DEPTH_M := 12.0
const WALL_HEIGHT_M := 3.0
const WALL_THICKNESS_M := 0.15
const DOOR_WIDTH_M := 2.0
const BACKROOM_WIDTH_M := 6.0
const BACKROOM_DEPTH_M := 4.0
const BACKROOM_CENTER := Vector3(0.0, -0.05, -8.0)
const WAREHOUSE_SKUS: Array[StringName] = [
	&"freshpop_cola_500",
	&"aquapure_water_500",
	&"sunnyjuice_orange_330",
	&"crunchbox_cereal_375",
	&"quickbite_chips_150",
]
const WAREHOUSE_TINTS: Array[Color] = [
	Color(0.78, 0.12, 0.16),
	Color(0.22, 0.55, 0.86),
	Color(0.95, 0.58, 0.12),
	Color(0.62, 0.42, 0.18),
	Color(0.90, 0.74, 0.20),
]

@onready var entrance: Marker3D = $Entrance
@onready var exit_point: Marker3D = $Exit
@onready var checkout_pay: Marker3D = $CheckoutPay
@onready var cashier_stand: Marker3D = $CashierStand
@onready var backroom_pick: Marker3D = $BackroomPick
@onready var fixtures_root: Node3D = $NavigationRegion3D/Fixtures
@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D

var _crate_meshes: Array[MeshInstance3D] = []
var _crate_labels: Array[Label3D] = []


func _ready() -> void:
	_build_room()
	_configure_navigation_mesh()
	rebake_navigation()


func get_half_extents() -> Vector2:
	return Vector2(WIDTH_M * 0.5, DEPTH_M * 0.5)


func get_entrance_position() -> Vector3:
	return entrance.global_position


func get_exit_position() -> Vector3:
	return exit_point.global_position


func get_checkout_position() -> Vector3:
	return checkout_pay.global_position


func get_checkout_approach_position(lane: int = 0) -> Vector3:
	return get_queue_slot_position(lane, 0)


func get_cashier_position(lane: int = 0) -> Vector3:
	if lane >= 1:
		var stand_b := get_node_or_null("CashierStandB") as Marker3D
		if stand_b != null:
			return stand_b.global_position
		return Vector3(3.7, 0.0, 5.42)
	if cashier_stand != null:
		return cashier_stand.global_position
	return Vector3(3.7, 0.0, 4.52)


func get_cashier_b_position() -> Vector3:
	return get_cashier_position(1)


func get_cashier_facing() -> float:
	return 0.0


func get_backroom_pick_position() -> Vector3:
	return backroom_pick.global_position


func get_queue_slot_position(lane_or_index: int, index: int = -1) -> Vector3:
	var lane := 0
	var slot := lane_or_index
	if index >= 0:
		lane = lane_or_index
		slot = index
	var i := clampi(slot, 0, 3)
	if lane <= 0:
		var marker := get_node_or_null("QueueSlot%d" % i) as Marker3D
		if marker != null:
			return marker.global_position
		return Vector3(3.5 - 0.9 * float(i), 0.0, 2.8)
	var marker_b := get_node_or_null("QueueSlotB%d" % i) as Marker3D
	if marker_b != null:
		return marker_b.global_position
	return Vector3(3.5 - 0.9 * float(i), 0.0, 3.7)


func contains_point(world_xz: Vector3, margin: float = 0.25) -> bool:
	var half := get_half_extents()
	return absf(world_xz.x) <= half.x - margin and absf(world_xz.z) <= half.y - margin


func is_sales_floor(world_xz: Vector3, margin: float = 0.25) -> bool:
	return contains_point(world_xz, margin)


func refresh_warehouse_visuals(counts: Dictionary) -> void:
	for i in _crate_meshes.size():
		var sku: StringName = WAREHOUSE_SKUS[i]
		var count := int(counts.get(sku, 0))
		var height := clampf(0.25 + float(count) * 0.015, 0.25, 1.1)
		_crate_meshes[i].scale.y = height / 0.6
		_crate_meshes[i].position.y = height * 0.5
		if i < _crate_labels.size():
			_crate_labels[i].text = str(count)


func blocks_doorway(world_pos: Vector3, size: Vector3) -> bool:
	var half_x := size.x * 0.5
	var half_z := size.z * 0.5
	var min_x := world_pos.x - half_x
	var max_x := world_pos.x + half_x
	var min_z := world_pos.z - half_z
	var max_z := world_pos.z + half_z
	if _aabb_overlaps(min_x, max_x, min_z, max_z, -4.5, -2.5, 4.6, 6.4):
		return true
	if _aabb_overlaps(min_x, max_x, min_z, max_z, 2.5, 4.5, 4.6, 6.4):
		return true
	if _aabb_overlaps(min_x, max_x, min_z, max_z, -1.2, 1.2, -6.6, -5.4):
		return true
	return false


func rebake_navigation() -> void:
	if navigation_region.navigation_mesh == null:
		_configure_navigation_mesh()
	navigation_region.bake_navigation_mesh(false)
	var baked: NavigationMesh = navigation_region.navigation_mesh
	GameLog.info("NAV", "Baked polygons=%d vertices=%d" % [baked.get_polygon_count(), baked.get_vertices().size()])


func _configure_navigation_mesh() -> void:
	var mesh := NavigationMesh.new()
	mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	mesh.agent_height = 1.75
	mesh.agent_radius = 0.5
	mesh.agent_max_climb = 0.25
	mesh.agent_max_slope = 45.0
	mesh.cell_size = 0.25
	mesh.cell_height = 0.25
	navigation_region.navigation_mesh = mesh


func _build_room() -> void:
	_apply_floor_texture()
	var walls: Node3D = $NavigationRegion3D/Walls
	var half_w := WIDTH_M * 0.5
	var half_d := DEPTH_M * 0.5
	var wall_tex := TexLib.wall_tex()
	var north_z := -half_d - WALL_THICKNESS_M * 0.5
	_add_wall(walls, "WallNorthWest", Vector3(4.0, WALL_HEIGHT_M, WALL_THICKNESS_M), Vector3(-3.0, WALL_HEIGHT_M * 0.5, north_z), wall_tex)
	_add_wall(walls, "WallNorthEast", Vector3(4.0, WALL_HEIGHT_M, WALL_THICKNESS_M), Vector3(3.0, WALL_HEIGHT_M * 0.5, north_z), wall_tex)
	_add_wall(walls, "WallWest", Vector3(WALL_THICKNESS_M, WALL_HEIGHT_M, DEPTH_M + WALL_THICKNESS_M), Vector3(-half_w - WALL_THICKNESS_M * 0.5, WALL_HEIGHT_M * 0.5, 0.0), wall_tex)
	_add_wall(walls, "WallEast", Vector3(WALL_THICKNESS_M, WALL_HEIGHT_M, DEPTH_M + WALL_THICKNESS_M), Vector3(half_w + WALL_THICKNESS_M * 0.5, WALL_HEIGHT_M * 0.5, 0.0), wall_tex)
	var south_z := half_d + WALL_THICKNESS_M * 0.5
	_add_wall(walls, "WallSouthWest", Vector3(0.5, WALL_HEIGHT_M, WALL_THICKNESS_M), Vector3(-4.75, WALL_HEIGHT_M * 0.5, south_z), wall_tex)
	_add_wall(walls, "WallSouthMid", Vector3(5.0, WALL_HEIGHT_M, WALL_THICKNESS_M), Vector3(0.0, WALL_HEIGHT_M * 0.5, south_z), wall_tex)
	_add_wall(walls, "WallSouthEast", Vector3(0.5, WALL_HEIGHT_M, WALL_THICKNESS_M), Vector3(4.75, WALL_HEIGHT_M * 0.5, south_z), wall_tex)
	var metal := TexLib.metal_tex()
	_add_box(walls, "EntranceFrameL", Vector3(0.12, 2.4, 0.2), Vector3(-4.5, 1.2, half_d - 0.05), Color(0.22, 0.62, 0.34), 4, 0.45, 0.15, metal, Vector3(2.0, 2.0, 2.0), true)
	_add_box(walls, "EntranceFrameR", Vector3(0.12, 2.4, 0.2), Vector3(-2.5, 1.2, half_d - 0.05), Color(0.22, 0.62, 0.34), 4, 0.45, 0.15, metal, Vector3(2.0, 2.0, 2.0), true)
	_add_box(walls, "ExitFrameL", Vector3(0.12, 2.4, 0.2), Vector3(2.5, 1.2, half_d - 0.05), Color(0.78, 0.24, 0.24), 4, 0.45, 0.15, metal, Vector3(2.0, 2.0, 2.0), true)
	_add_box(walls, "ExitFrameR", Vector3(0.12, 2.4, 0.2), Vector3(4.5, 1.2, half_d - 0.05), Color(0.78, 0.24, 0.24), 4, 0.45, 0.15, metal, Vector3(2.0, 2.0, 2.0), true)
	var checkout_root: Node3D = $NavigationRegion3D/Checkout
	_add_box(checkout_root, "CheckoutCounter", Vector3(1.8, 0.9, 0.8), Vector3(3.5, 0.45, 3.8), Color(1.0, 1.0, 1.0), 2, 0.5, 0.08, TexLib.counter_tex(), Vector3(1.6, 1.6, 1.6), true)
	_build_backroom()
	_build_interior()
	_build_exterior()


func _build_interior() -> void:
	var decor := Node3D.new()
	decor.name = "Decor"
	add_child(decor)
	var wood := TexLib.wood_tex()
	var metal := TexLib.metal_tex()
	_add_decor(decor, "BoardWest", Vector3(0.04, 0.12, DEPTH_M), Vector3(-WIDTH_M * 0.5 + 0.08, 0.06, 0.0), Color(1.0, 0.95, 0.88), 0.7, 0.0, wood, Vector3(4.0, 4.0, 4.0), true)
	_add_decor(decor, "BoardEast", Vector3(0.04, 0.12, DEPTH_M), Vector3(WIDTH_M * 0.5 - 0.08, 0.06, 0.0), Color(1.0, 0.95, 0.88), 0.7, 0.0, wood, Vector3(4.0, 4.0, 4.0), true)
	_add_decor(decor, "AisleStripe", Vector3(1.1, 0.004, 9.5), Vector3(0.0, 0.004, 0.2), Color(0.92, 0.93, 0.94), 0.55, 0.0, TexLib.floor_tex(), Vector3(2.0, 8.0, 1.0))
	_add_decor(decor, "Belt", Vector3(1.5, 0.04, 0.28), Vector3(3.5, 0.92, 3.55), Color(0.18, 0.18, 0.2), 0.45, 0.2, metal, Vector3(3.0, 3.0, 3.0), true)
	_add_decor(decor, "Scanner", Vector3(0.12, 0.7, 0.12), Vector3(4.25, 1.25, 3.8), Color(0.22, 0.22, 0.24), 0.4, 0.35, metal, Vector3(2.0, 2.0, 2.0), true)
	_add_mesh(decor, "Screen", Vector3(0.28, 0.2, 0.04), Vector3(4.25, 1.72, 3.8), _emissive_surface(Color(0.25, 0.72, 0.95), 2.4))
	_add_mesh(decor, "ScannerGlow", Vector3(0.08, 0.04, 0.18), Vector3(3.55, 0.95, 3.45), _emissive_surface(Color(0.2, 0.95, 0.45), 3.5))
	_add_mesh(decor, "EntranceMat", Vector3(1.8, 0.02, 1.1), Vector3(-3.5, 0.01, 5.15), _surface(Color(0.12, 0.48, 0.28), 0.92, 0.0))
	_add_mesh(decor, "ExitMat", Vector3(1.8, 0.02, 1.1), Vector3(3.5, 0.01, 5.15), _surface(Color(0.55, 0.14, 0.14), 0.92, 0.0))
	_add_mesh(decor, "QueueTape", Vector3(0.08, 0.01, 2.4), Vector3(2.55, 0.012, 2.4), _emissive_surface(Color(0.95, 0.78, 0.12), 0.6))
	_add_mesh(decor, "BackroomStripe", Vector3(2.4, 0.02, 0.18), Vector3(0.0, 0.02, -5.85), _emissive_surface(Color(0.95, 0.78, 0.08), 0.45))
	_add_glass(decor, "EntranceGlass", Vector3(1.85, 2.15, 0.04), Vector3(-3.5, 1.12, 5.92), Color(0.55, 0.78, 0.92, 0.22))
	_add_glass(decor, "ExitGlass", Vector3(1.85, 2.15, 0.04), Vector3(3.5, 1.12, 5.92), Color(0.55, 0.78, 0.92, 0.22))
	_add_poster(decor, "PosterCola", Vector3(-4.88, 1.55, -1.6), TexLib.product(&"freshpop_cola_500"), Color(0.78, 0.12, 0.16))
	_add_poster(decor, "PosterWater", Vector3(-4.88, 1.55, 1.4), TexLib.product(&"aquapure_water_500"), Color(0.22, 0.55, 0.86))
	_add_poster(decor, "PosterChips", Vector3(4.88, 1.55, -1.2), TexLib.product(&"quickbite_chips_150"), Color(0.90, 0.74, 0.20), true)
	_add_hanging_sign(decor, "SignDrinks", "DRINKS", Vector3(-1.5, 2.42, -1.2), Color(0.2, 0.55, 0.85))
	_add_hanging_sign(decor, "SignSnacks", "SNACKS", Vector3(1.5, 2.42, -1.2), Color(0.92, 0.55, 0.12))
	_build_lighting(decor)


func _build_lighting(parent: Node3D) -> void:
	var cool := Color(0.92, 0.95, 1.0)
	var zs: Array[float] = [-3.6, -0.4, 2.6]
	var xs: Array[float] = [-3.15, 0.0, 3.15]
	var n := 0
	for x in xs:
		for z in zs:
			_add_fluorescent(parent, "Lamp%d" % n, Vector3(x, 2.88, z), cool, 1.55)
			n += 1
	_add_fluorescent(parent, "LampWarehouse", Vector3(0.0, 2.7, -8.0), Color(0.82, 0.88, 1.0), 1.2)
	_add_omni(parent, "LampCheckout", Vector3(3.5, 2.35, 3.6), Color(1.0, 0.93, 0.82), 0.9, 5.0)


func _add_fluorescent(parent: Node3D, lamp_name: String, pos: Vector3, color: Color, energy: float) -> void:
	_add_decor(parent, lamp_name + "Housing", Vector3(2.2, 0.05, 0.16), pos + Vector3(0.0, 0.08, 0.0), Color(0.92, 0.93, 0.94), 0.35, 0.15, TexLib.metal_tex(), Vector3(2.5, 2.5, 2.5), true)
	_add_mesh(parent, lamp_name + "Tube", Vector3(2.05, 0.04, 0.07), pos + Vector3(0.0, 0.04, 0.0), _emissive_surface(color, 4.2))
	_add_omni(parent, lamp_name, pos, color, energy, 6.5)


func _build_exterior() -> void:
	var exterior := Node3D.new()
	exterior.name = "Exterior"
	add_child(exterior)
	_add_mesh(exterior, "Grass", Vector3(36.0, 0.06, 36.0), Vector3(0.0, -0.16, 2.0), _surface(Color(0.28, 0.42, 0.22), 0.95, 0.0))
	_add_mesh(exterior, "Asphalt", Vector3(16.0, 0.05, 10.0), Vector3(0.0, -0.1, 11.2), _surface(Color(0.18, 0.19, 0.21), 0.9, 0.0))
	_add_mesh(exterior, "Sidewalk", Vector3(11.2, 0.06, 1.8), Vector3(0.0, -0.02, 7.15), _surface(Color(0.62, 0.62, 0.6), 0.88, 0.0))
	_add_mesh(exterior, "ParkingLineL", Vector3(0.08, 0.02, 4.2), Vector3(-2.4, -0.06, 11.4), _surface(Color(0.92, 0.88, 0.35), 0.55, 0.0))
	_add_mesh(exterior, "ParkingLineR", Vector3(0.08, 0.02, 4.2), Vector3(2.4, -0.06, 11.4), _surface(Color(0.92, 0.88, 0.35), 0.55, 0.0))
	_add_mesh(exterior, "Canopy", Vector3(10.6, 0.12, 1.6), Vector3(0.0, 2.78, 6.75), _surface(Color(0.12, 0.38, 0.3), 0.55, 0.05, TexLib.metal_tex(), Vector3(2.0, 2.0, 2.0), true))
	_add_mesh(exterior, "SignBoard", Vector3(8.6, 0.85, 0.12), Vector3(0.0, 2.58, 6.22), _emissive_surface(Color(0.1, 0.36, 0.28), 0.85))
	_add_world_label(exterior, "StoreSign", "SHOPYFENDER", Vector3(0.0, 2.58, 6.32), 64, Color(0.98, 0.96, 0.88), 180.0)
	_add_mesh(exterior, "OpenBoard", Vector3(0.95, 0.38, 0.06), Vector3(-3.5, 2.18, 6.18), _emissive_surface(Color(0.12, 0.72, 0.32), 2.8))
	_add_world_label(exterior, "OpenSign", "OTWARTE", Vector3(-3.5, 2.18, 6.24), 28, Color(0.95, 1.0, 0.95), 180.0)
	_add_omni(exterior, "CanopyLight", Vector3(0.0, 2.55, 6.5), Color(1.0, 0.92, 0.75), 1.15, 7.0)
	_add_omni(exterior, "OpenGlow", Vector3(-3.5, 2.2, 6.1), Color(0.25, 0.95, 0.4), 0.7, 4.0)


func _add_omni(parent: Node3D, lamp_name: String, pos: Vector3, color: Color, energy: float, omni_range: float) -> void:
	var light := OmniLight3D.new()
	light.name = lamp_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.light_specular = 0.35
	light.omni_range = omni_range
	light.omni_attenuation = 1.4
	light.shadow_enabled = false
	parent.add_child(light)


func _apply_floor_texture() -> void:
	var mesh_instance := $NavigationRegion3D/Floor/MeshInstance3D as MeshInstance3D
	if mesh_instance == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.97, 0.9)
	mat.roughness = 0.78
	TexLib.apply_to_material(mat, TexLib.floor_tex(), Vector3(1.25, 1.5, 1.0))
	mesh_instance.material_override = mat


func _build_backroom() -> void:
	var backroom: Node3D = $NavigationRegion3D/Backroom
	var wall_tex := TexLib.wall_tex()
	var half_w := BACKROOM_WIDTH_M * 0.5
	var half_d := BACKROOM_DEPTH_M * 0.5
	_add_box(backroom, "BackroomFloor", Vector3(BACKROOM_WIDTH_M, 0.1, BACKROOM_DEPTH_M), BACKROOM_CENTER, Color(0.82, 0.8, 0.76), 1, 0.82, 0.0, TexLib.floor_tex(), Vector3(0.75, 0.5, 1.0))
	_add_wall(backroom, "BackroomWallWest", Vector3(WALL_THICKNESS_M, WALL_HEIGHT_M, BACKROOM_DEPTH_M + WALL_THICKNESS_M), Vector3(-half_w - WALL_THICKNESS_M * 0.5, WALL_HEIGHT_M * 0.5, BACKROOM_CENTER.z), wall_tex)
	_add_wall(backroom, "BackroomWallEast", Vector3(WALL_THICKNESS_M, WALL_HEIGHT_M, BACKROOM_DEPTH_M + WALL_THICKNESS_M), Vector3(half_w + WALL_THICKNESS_M * 0.5, WALL_HEIGHT_M * 0.5, BACKROOM_CENTER.z), wall_tex)
	_add_wall(backroom, "BackroomWallNorth", Vector3(BACKROOM_WIDTH_M + WALL_THICKNESS_M, WALL_HEIGHT_M, WALL_THICKNESS_M), Vector3(0.0, WALL_HEIGHT_M * 0.5, BACKROOM_CENTER.z - half_d - WALL_THICKNESS_M * 0.5), wall_tex)
	_crate_meshes.clear()
	_crate_labels.clear()
	var crate_xs: Array[float] = [-2.0, -1.0, 0.0, 1.0, 2.0]
	for i in WAREHOUSE_SKUS.size():
		_add_crate(backroom, WAREHOUSE_SKUS[i], Vector3(crate_xs[i], 0.3, -8.6), WAREHOUSE_TINTS[i])
	refresh_warehouse_visuals({})


func _add_wall(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, texture: Texture2D) -> void:
	var uv := Vector3(maxf(size.x, size.z) / 2.0, size.y / 2.0, 1.0)
	_add_box(parent, node_name, size, pos, Color(1.0, 1.0, 1.0), 4, 0.88, 0.0, texture, uv, true)


func _add_box(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, color: Color, collision_layer: int, roughness: float = 0.7, metallic: float = 0.0, texture: Texture2D = null, uv_scale: Vector3 = Vector3.ONE, triplanar: bool = false) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.collision_layer = collision_layer
	body.collision_mask = 0
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = _surface(color, roughness, metallic, texture, uv_scale, triplanar)
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)


func _add_decor(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, color: Color, roughness: float = 0.7, metallic: float = 0.0, texture: Texture2D = null, uv_scale: Vector3 = Vector3.ONE, triplanar: bool = false) -> void:
	_add_mesh(parent, node_name, size, pos, _surface(color, roughness, metallic, texture, uv_scale, triplanar))


func _add_mesh(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, material: Material, rot_y: float = 0.0) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.position = pos
	mesh_instance.rotation_degrees.y = rot_y
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = material
	parent.add_child(mesh_instance)
	return mesh_instance


func _add_glass(parent: Node3D, node_name: String, size: Vector3, pos: Vector3, tint: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = tint
	mat.roughness = 0.06
	mat.metallic = 0.18
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_mesh(parent, node_name, size, pos, mat)


func _add_poster(parent: Node3D, node_name: String, pos: Vector3, texture: Texture2D, fallback: Color, flip: bool = false) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1)
	mat.roughness = 0.55
	if texture != null:
		TexLib.apply_to_material(mat, texture, Vector3(1.0, 1.0, 1.0), true)
	else:
		mat.albedo_color = fallback
	_add_mesh(parent, node_name, Vector3(0.03, 1.05, 0.72), pos, mat, 180.0 if flip else 0.0)


func _add_hanging_sign(parent: Node3D, node_name: String, text: String, pos: Vector3, color: Color) -> void:
	_add_mesh(parent, node_name + "Bar", Vector3(1.15, 0.28, 0.04), pos, _emissive_surface(color, 1.4))
	_add_world_label(parent, node_name, text, pos + Vector3(0.0, 0.0, 0.04), 22, Color(1, 1, 1), 180.0)


func _add_world_label(parent: Node3D, node_name: String, text: String, pos: Vector3, font_size: int, color: Color, rot_y: float) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = pos
	label.rotation_degrees.y = rot_y
	label.font_size = font_size
	label.outline_size = 8
	label.modulate = color
	label.no_depth_test = false
	parent.add_child(label)


func _emissive_surface(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.32
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material


func _surface(color: Color, roughness: float, metallic: float, texture: Texture2D = null, uv_scale: Vector3 = Vector3.ONE, triplanar: bool = false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	if texture != null:
		TexLib.apply_to_material(material, texture, uv_scale, triplanar)
	return material


func _add_crate(parent: Node3D, sku: StringName, pos: Vector3, color: Color) -> void:
	var crate := MeshInstance3D.new()
	crate.name = "Crate_%s" % String(sku)
	crate.position = pos
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.6, 0.55)
	crate.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color.lerp(Color(1.0, 1.0, 1.0), 0.35)
	var label_tex := TexLib.product(sku)
	if label_tex != null:
		TexLib.apply_to_material(material, label_tex, Vector3(1.2, 1.2, 1.2), true)
	else:
		TexLib.apply_to_material(material, TexLib.cardboard_tex(), Vector3(1.8, 1.8, 1.8), true)
	crate.material_override = material
	var label := Label3D.new()
	label.name = "Count"
	label.position = Vector3(0.0, 0.5, 0.0)
	label.text = "0"
	label.font_size = 28
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	crate.add_child(label)
	parent.add_child(crate)
	_crate_meshes.append(crate)
	_crate_labels.append(label)
	crate.set_meta("sku", sku)


func _aabb_overlaps(a_min_x: float, a_max_x: float, a_min_z: float, a_max_z: float, b_min_x: float, b_max_x: float, b_min_z: float, b_max_z: float) -> bool:
	return a_min_x < b_max_x and a_max_x > b_min_x and a_min_z < b_max_z and a_max_z > b_min_z
