class_name StoreTextures
extends RefCounted

const ENV_DIR := "res://assets/textures/environment/"
const PRODUCT_DIR := "res://assets/textures/products/"

static var _cache: Dictionary = {}


static func floor_tex() -> Texture2D:
	return _env("floor_vinyl")


static func wall_tex() -> Texture2D:
	return _env("wall_paint")


static func metal_tex() -> Texture2D:
	return _env("metal_brushed")


static func wood_tex() -> Texture2D:
	return _env("wood_shelf")


static func pegboard_tex() -> Texture2D:
	return _env("pegboard")


static func counter_tex() -> Texture2D:
	return _env("counter_laminate")


static func cardboard_tex() -> Texture2D:
	return _env("cardboard")


static func product(product_id: StringName) -> Texture2D:
	var id := String(product_id)
	if id.is_empty():
		return null
	return _load("%s%s.png" % [PRODUCT_DIR, id])


static func apply_to_material(mat: StandardMaterial3D, texture: Texture2D, uv_scale: Vector3 = Vector3.ONE, triplanar: bool = false) -> void:
	if texture == null:
		return
	mat.albedo_texture = texture
	mat.uv1_scale = uv_scale
	mat.uv1_triplanar = triplanar
	if triplanar:
		mat.uv1_world_triplanar = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


static func _env(stem: String) -> Texture2D:
	return _load("%s%s.png" % [ENV_DIR, stem])


static func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var texture: Texture2D = null
	if ResourceLoader.exists(path):
		texture = load(path) as Texture2D
	_cache[path] = texture
	return texture
