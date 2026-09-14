class_name ProductPlacementState
extends RefCounted

var placement_id: StringName
var product_id: StringName
var fixture_instance_id: StringName
var shelf_index: int = 0
var side_index: int = 0
var horizontal_start_m: float = 0.0
var facings: int = 1
var units_deep: int = 1
var capacity: int = 1
var shelf_stock: int = 0
var display_name: String = ""
var preview_color: Color = Color(0.78, 0.12, 0.16)
var preview_texture: Texture2D
var package_type: StringName = &"bottle_small"
