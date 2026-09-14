class_name CharacterModel
extends Node3D

const TexLib := preload("res://scripts/store/store_textures.gd")
const ANIM_IDLE := &"Idle_Neutral"
const ANIM_IDLE_FALLBACK := &"Idle"
const ANIM_WALK := &"Walk"
const ANIM_IDLE_CARRY := &"Idle_Carry"
const ANIM_WALK_CARRY := &"Walk_Carry"
const MODELS := "res://assets/characters/ready/quaternius-men/"

var look_id: StringName = &""
var _player: AnimationPlayer
var _instance: Node
var _kind: StringName = &""
var _variety: int = -1
var _current: StringName = &""
var _moving := false
var _carrying := false
var _basket_item: MeshInstance3D
var _carry: Node3D
var _mat_cache: Dictionary = {}


func set_kind(kind: StringName, variety: int = 0) -> void:
	if kind == _kind and variety == _variety and _instance != null:
		return
	if _instance != null:
		_instance.queue_free()
		_instance = null
		_player = null
		_current = &""
		_basket_item = null
		_carry = null
	_kind = kind
	_variety = variety
	_carrying = false
	var spec := _look_spec(kind, variety)
	look_id = StringName(spec[0])
	var packed: PackedScene = load(MODELS + spec[0])
	if packed == null:
		push_error("Missing character model %s" % spec[0])
		return
	_instance = packed.instantiate()
	if _instance == null:
		push_error("Failed to instantiate %s" % spec[0])
		return
	add_child(_instance)
	_player = _instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_loop_locomotion_clips()
	_attach_props(StringName(spec[1]), kind == &"worker")
	play_idle()


func set_moving(moving: bool) -> void:
	_moving = moving
	_play(_clip_name())


func set_basket_product(product: ProductDefinition) -> void:
	if _basket_item == null:
		return
	if product == null:
		_basket_item.visible = false
		return
	_apply_package(_basket_item, product.preview_color, product.package_type, TexLib.product(product.id))
	_basket_item.visible = true


func clear_basket_product() -> void:
	if _basket_item != null:
		_basket_item.visible = false


func set_carry_goods(product: ProductDefinition, count: int) -> void:
	_carrying = count > 0 and _carry != null
	if _carry == null:
		_play(_clip_name())
		return
	_carry.visible = _carrying
	var color := product.preview_color if product != null else Color(0.78, 0.12, 0.16)
	var package_type := product.package_type if product != null else &"bottle_small"
	var texture: Texture2D = TexLib.product(product.id) if product != null else null
	for i in 3:
		var pack := _carry.get_node_or_null("Pack%d" % i) as MeshInstance3D
		if pack == null:
			continue
		var pack_visible := _carrying and i < count
		pack.visible = pack_visible
		if pack_visible:
			_apply_package(pack, color, package_type, texture)
	_current = &""
	_play(_clip_name())


func clear_carry_goods() -> void:
	set_carry_goods(null, 0)


func play_idle() -> void:
	_moving = false
	_play(_clip_name())


func play_walk() -> void:
	_moving = true
	_play(_clip_name())


func _look_spec(kind: StringName, variety: int) -> PackedStringArray:
	if kind == &"worker":
		return PackedStringArray(["Worker.gltf", "none"])
	if kind == &"cashier":
		return PackedStringArray(["Suit.gltf", "none"])
	if kind == &"impatient":
		if variety % 2 == 0:
			return PackedStringArray(["Punk.gltf", "basket"])
		return PackedStringArray(["Beach.gltf", "gym"])
	if kind != &"regular":
		push_warning("Unhandled character kind: %s" % String(kind))
	match variety % 9:
		0:
			return PackedStringArray(["Casual_Hoodie.gltf", "basket"])
		1:
			return PackedStringArray(["Suit.gltf", "briefcase"])
		2:
			return PackedStringArray(["Farmer.gltf", "basket"])
		3:
			return PackedStringArray(["Casual_2.gltf", "tote"])
		4:
			return PackedStringArray(["Beach.gltf", "gym"])
		5:
			return PackedStringArray(["Adventurer.gltf", "shop"])
		6:
			return PackedStringArray(["Punk.gltf", "basket"])
		7:
			return PackedStringArray(["Farmer.gltf", "bio"])
		8:
			return PackedStringArray(["Suit.gltf", "briefcase"])
		_:
			push_warning("Unhandled regular variety: %d" % variety)
			return PackedStringArray(["Casual_2.gltf", "basket"])


func _attach_props(bag: StringName, worker: bool) -> void:
	var skeleton := _instance.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null:
		push_error("Character model has no Skeleton3D")
		return
	if worker:
		var chest := _bone_hold(skeleton, "Chest", "CarryAnchor")
		chest.position = Vector3(0.0, -0.12, 0.34)
		_carry = _add_carry(chest)
		return
	if bag == &"none":
		return
	var hand := _bone_hold(skeleton, "Wrist.L", "BagAnchor")
	hand.position = Vector3(0.04, 0.1, -0.03)
	hand.basis = Basis(Vector3(0.0, 0.0, 1.0), Vector3(0.0, -1.0, 0.0), Vector3(1.0, 0.0, 0.0))
	hand.scale = Vector3(0.9, 0.9, 0.9)
	_add_bag(hand, bag)
	_basket_item = _instance.find_child("BasketItem", true, false) as MeshInstance3D


func _bone_hold(skeleton: Skeleton3D, bone_name: String, anchor_name: String) -> Node3D:
	var attach := BoneAttachment3D.new()
	attach.name = anchor_name
	skeleton.add_child(attach)
	attach.bone_name = bone_name
	var hold := Node3D.new()
	hold.name = "Hold"
	attach.add_child(hold)
	return hold


func _loop_locomotion_clips() -> void:
	if _player == null:
		return
	for clip_name: StringName in [ANIM_IDLE, ANIM_IDLE_FALLBACK, ANIM_WALK, &"Run"]:
		if not _player.has_animation(clip_name):
			continue
		var anim := _player.get_animation(clip_name)
		if anim != null:
			anim.loop_mode = Animation.LOOP_LINEAR


func _clip_name() -> StringName:
	if _moving:
		if _carrying and _player != null and _player.has_animation(ANIM_WALK_CARRY):
			return ANIM_WALK_CARRY
		return ANIM_WALK
	if _carrying and _player != null and _player.has_animation(ANIM_IDLE_CARRY):
		return ANIM_IDLE_CARRY
	if _player != null and _player.has_animation(ANIM_IDLE):
		return ANIM_IDLE
	return ANIM_IDLE_FALLBACK


func _play(anim_name: StringName) -> void:
	if _player == null or not _player.has_animation(anim_name):
		return
	if _current == anim_name and _player.is_playing():
		return
	_current = anim_name
	_player.play(anim_name)


func _apply_package(mesh_inst: MeshInstance3D, color: Color, package_type: StringName, texture: Texture2D = null) -> void:
	mesh_inst.mesh = _make_package_mesh(package_type)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0) if texture != null else color
	mat.roughness = 0.55
	if texture != null:
		TexLib.apply_to_material(mat, texture)
	mesh_inst.material_override = mat


func _make_package_mesh(package_type: StringName) -> Mesh:
	match package_type:
		&"box_small":
			var box := BoxMesh.new()
			box.size = Vector3(0.14, 0.18, 0.08)
			return box
		&"carton":
			var carton := BoxMesh.new()
			carton.size = Vector3(0.08, 0.16, 0.08)
			return carton
		&"bag":
			var bag := BoxMesh.new()
			bag.size = Vector3(0.12, 0.16, 0.04)
			return bag
		&"bottle_small":
			var bottle := CylinderMesh.new()
			bottle.top_radius = 0.05
			bottle.bottom_radius = 0.055
			bottle.height = 0.2
			bottle.radial_segments = 12
			return bottle
		_:
			push_warning("Unhandled package type: %s" % String(package_type))
			var fallback := CylinderMesh.new()
			fallback.top_radius = 0.05
			fallback.bottom_radius = 0.055
			fallback.height = 0.2
			fallback.radial_segments = 12
			return fallback


func _add_bag(hand: Node3D, bag: StringName) -> void:
	match bag:
		&"bio":
			_add_bio_bag(hand)
		&"shop":
			_add_shop_bags(hand)
		&"handbag":
			_add_handbag(hand)
		&"tote":
			_add_tote(hand)
		&"gym":
			_add_gym_bag(hand)
		&"briefcase":
			_add_briefcase(hand)
		&"none":
			pass
		_:
			_add_basket(hand)


func _add_basket(hand: Node3D) -> void:
	var basket := Node3D.new()
	basket.name = "Basket"
	basket.position = Vector3(0.0, -0.2, 0.02)
	hand.add_child(basket)
	var plastic := Color(0.82, 0.14, 0.16)
	var dark := _shade(plastic, 0.18)
	_part(basket, "Bottom", _box(0.18, 0.012, 0.12), dark, Vector3(0.0, 0.006, 0.0))
	_part(basket, "Rim", _box(0.2, 0.012, 0.14), plastic, Vector3(0.0, 0.11, 0.0))
	for i in 3:
		var y := 0.03 + 0.03 * float(i)
		_part(basket, "SlatF%d" % i, _box(0.18, 0.01, 0.01), plastic, Vector3(0.0, y, 0.06))
		_part(basket, "SlatB%d" % i, _box(0.18, 0.01, 0.01), plastic, Vector3(0.0, y, -0.06))
		_part(basket, "SlatL%d" % i, _box(0.01, 0.01, 0.12), plastic, Vector3(-0.09, y, 0.0))
		_part(basket, "SlatR%d" % i, _box(0.01, 0.01, 0.12), plastic, Vector3(0.09, y, 0.0))
	_part(basket, "PostFL", _box(0.012, 0.11, 0.012), dark, Vector3(-0.09, 0.055, 0.06))
	_part(basket, "PostFR", _box(0.012, 0.11, 0.012), dark, Vector3(0.09, 0.055, 0.06))
	_part(basket, "PostBL", _box(0.012, 0.11, 0.012), dark, Vector3(-0.09, 0.055, -0.06))
	_part(basket, "PostBR", _box(0.012, 0.11, 0.012), dark, Vector3(0.09, 0.055, -0.06))
	_part(basket, "HandleL", _box(0.012, 0.1, 0.012), plastic, Vector3(-0.05, 0.16, 0.0))
	_part(basket, "HandleR", _box(0.012, 0.1, 0.012), plastic, Vector3(0.05, 0.16, 0.0))
	_part(basket, "Handle", _box(0.12, 0.012, 0.012), plastic, Vector3(0.0, 0.21, 0.0))
	_part(basket, "Baguette", _cyl(0.016, 0.018, 0.14), Color(0.86, 0.68, 0.32), Vector3(-0.04, 0.05, 0.0), Vector3(0.0, 0.0, 90.0))
	_part(basket, "Greens", _box(0.07, 0.05, 0.05), Color(0.28, 0.55, 0.22), Vector3(0.04, 0.06, 0.01))
	_hide_item(basket, _make_package_mesh(&"bottle_small"), Vector3(0.0, 0.1, 0.0), 0.55)


func _add_bio_bag(hand: Node3D) -> void:
	var bag := Node3D.new()
	bag.name = "Basket"
	bag.position = Vector3(0.0, -0.2, 0.02)
	hand.add_child(bag)
	var green := Color(0.22, 0.55, 0.28)
	_part(bag, "Body", _box(0.16, 0.16, 0.05), green, Vector3(0.0, 0.08, 0.0))
	_part(bag, "Fold", _box(0.16, 0.02, 0.06), _shade(green, 0.15), Vector3(0.0, 0.16, 0.0))
	_part(bag, "HandleL", _box(0.01, 0.08, 0.01), Color(0.18, 0.42, 0.22), Vector3(-0.04, 0.2, 0.0))
	_part(bag, "HandleR", _box(0.01, 0.08, 0.01), Color(0.18, 0.42, 0.22), Vector3(0.04, 0.2, 0.0))
	_part(bag, "Handle", _box(0.09, 0.01, 0.01), Color(0.18, 0.42, 0.22), Vector3(0.0, 0.24, 0.0))
	_part(bag, "Greens", _box(0.06, 0.04, 0.04), Color(0.35, 0.62, 0.22), Vector3(0.0, 0.16, 0.02))
	_hide_item(bag, _make_package_mesh(&"bag"), Vector3(0.0, 0.18, 0.0), 0.55)


func _add_shop_bags(hand: Node3D) -> void:
	var bag := Node3D.new()
	bag.name = "Basket"
	bag.position = Vector3(0.0, -0.2, 0.02)
	hand.add_child(bag)
	var paper := Color(0.93, 0.9, 0.82)
	_part(bag, "BagA", _box(0.12, 0.16, 0.04), paper, Vector3(-0.04, 0.08, 0.0))
	_part(bag, "BagB", _box(0.12, 0.14, 0.04), _shade(paper, 0.08), Vector3(0.05, 0.07, 0.02))
	_part(bag, "HandleA", _box(0.08, 0.01, 0.01), Color(0.55, 0.42, 0.28), Vector3(-0.04, 0.18, 0.0))
	_part(bag, "HandleB", _box(0.08, 0.01, 0.01), Color(0.55, 0.42, 0.28), Vector3(0.05, 0.16, 0.02))
	_hide_item(bag, _make_package_mesh(&"box_small"), Vector3(0.0, 0.16, 0.0), 0.45)


func _add_handbag(hand: Node3D) -> void:
	var bag := Node3D.new()
	bag.name = "Basket"
	bag.position = Vector3(0.0, -0.16, 0.02)
	hand.add_child(bag)
	var leather := Color(0.12, 0.08, 0.08)
	_part(bag, "Body", _box(0.14, 0.1, 0.05), leather, Vector3(0.0, 0.05, 0.0))
	_part(bag, "Flap", _box(0.14, 0.04, 0.055), _shade(leather, 0.12), Vector3(0.0, 0.1, 0.0))
	_part(bag, "Handle", _box(0.08, 0.01, 0.01), leather, Vector3(0.0, 0.16, 0.0))
	_hide_item(bag, _make_package_mesh(&"box_small"), Vector3(0.0, 0.1, 0.03), 0.4)


func _add_tote(hand: Node3D) -> void:
	var bag := Node3D.new()
	bag.name = "Basket"
	bag.position = Vector3(0.0, -0.2, 0.02)
	hand.add_child(bag)
	var cloth := Color(0.55, 0.52, 0.48)
	_part(bag, "Body", _box(0.16, 0.14, 0.05), cloth, Vector3(0.0, 0.07, 0.0))
	_part(bag, "HandleL", _box(0.01, 0.1, 0.01), _shade(cloth, 0.15), Vector3(-0.04, 0.18, 0.0))
	_part(bag, "HandleR", _box(0.01, 0.1, 0.01), _shade(cloth, 0.15), Vector3(0.04, 0.18, 0.0))
	_part(bag, "Handle", _box(0.09, 0.01, 0.01), _shade(cloth, 0.15), Vector3(0.0, 0.23, 0.0))
	_hide_item(bag, _make_package_mesh(&"bag"), Vector3(0.0, 0.14, 0.0), 0.5)


func _add_gym_bag(hand: Node3D) -> void:
	var bag := Node3D.new()
	bag.name = "Basket"
	bag.position = Vector3(0.0, -0.14, 0.02)
	hand.add_child(bag)
	var black := Color(0.14, 0.14, 0.16)
	_part(bag, "Body", _box(0.22, 0.1, 0.1), black, Vector3(0.0, 0.05, 0.0))
	_part(bag, "Stripe", _box(0.22, 0.02, 0.102), Color(0.78, 0.18, 0.16), Vector3(0.0, 0.05, 0.0))
	_part(bag, "StrapL", _box(0.01, 0.08, 0.01), black, Vector3(-0.04, 0.12, 0.0))
	_part(bag, "StrapR", _box(0.01, 0.08, 0.01), black, Vector3(0.04, 0.12, 0.0))
	_part(bag, "Strap", _box(0.1, 0.01, 0.01), black, Vector3(0.0, 0.16, 0.0))
	_hide_item(bag, _make_package_mesh(&"bottle_small"), Vector3(0.0, 0.12, 0.0), 0.5)


func _add_briefcase(hand: Node3D) -> void:
	var bag := Node3D.new()
	bag.name = "Basket"
	bag.position = Vector3(0.0, -0.14, 0.02)
	hand.add_child(bag)
	var leather := Color(0.16, 0.1, 0.07)
	_part(bag, "Body", _box(0.18, 0.12, 0.05), leather, Vector3(0.0, 0.06, 0.0))
	_part(bag, "Edge", _box(0.185, 0.012, 0.055), Color(0.72, 0.6, 0.28), Vector3(0.0, 0.12, 0.0))
	_part(bag, "HandleL", _box(0.01, 0.04, 0.01), leather, Vector3(-0.03, 0.15, 0.0))
	_part(bag, "HandleR", _box(0.01, 0.04, 0.01), leather, Vector3(0.03, 0.15, 0.0))
	_part(bag, "Handle", _box(0.07, 0.01, 0.01), leather, Vector3(0.0, 0.17, 0.0))
	_hide_item(bag, _make_package_mesh(&"box_small"), Vector3(0.0, 0.12, 0.0), 0.4)


func _add_carry(parent: Node3D) -> Node3D:
	var carry := Node3D.new()
	carry.name = "Carry"
	carry.visible = false
	parent.add_child(carry)
	var wood := Color(0.55, 0.36, 0.18)
	var dark := Color(0.42, 0.26, 0.12)
	_part(carry, "Bottom", _box(0.32, 0.02, 0.22), dark, Vector3(0.0, -0.07, 0.0))
	_part(carry, "WallF", _box(0.32, 0.14, 0.016), wood, Vector3(0.0, 0.0, 0.102))
	_part(carry, "WallB", _box(0.32, 0.14, 0.016), wood, Vector3(0.0, 0.0, -0.102))
	_part(carry, "WallL", _box(0.016, 0.14, 0.22), wood, Vector3(-0.152, 0.0, 0.0))
	_part(carry, "WallR", _box(0.016, 0.14, 0.22), wood, Vector3(0.152, 0.0, 0.0))
	_part(carry, "CrateRim", _box(0.34, 0.02, 0.24), dark, Vector3(0.0, 0.08, 0.0))
	for i in 3:
		var pack := _part(carry, "Pack%d" % i, _make_package_mesh(&"bottle_small"), Color(0.78, 0.12, 0.16), Vector3(-0.09 + 0.09 * float(i), 0.12, 0.0))
		pack.scale = Vector3(0.55, 0.55, 0.55)
		pack.visible = false
	return carry


func _hide_item(parent: Node3D, mesh: Mesh, pos: Vector3, item_scale: float) -> void:
	var item := _part(parent, "BasketItem", mesh, Color(0.78, 0.12, 0.16), pos)
	item.scale = Vector3(item_scale, item_scale, item_scale)
	item.visible = false


func _part(parent: Node3D, part_name: String, mesh: Mesh, color: Color, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.name = part_name
	inst.mesh = mesh
	inst.position = pos
	inst.rotation_degrees = rot_deg
	inst.material_override = _mat(color)
	parent.add_child(inst)
	return inst


func _mat(color: Color) -> StandardMaterial3D:
	var key := color.to_html(true)
	if _mat_cache.has(key):
		return _mat_cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.52
	_mat_cache[key] = mat
	return mat


func _box(x: float, y: float, z: float) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(x, y, z)
	return mesh


func _cyl(r_top: float, r_bot: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = height
	mesh.radial_segments = 12
	return mesh


func _shade(color: Color, amount: float) -> Color:
	return color.lerp(Color(0.05, 0.04, 0.04, color.a), amount)
