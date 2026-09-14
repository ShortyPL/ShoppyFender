class_name ProductDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var width_m: float = 0.065
@export var height_m: float = 0.22
@export var depth_m: float = 0.065
@export var purchase_price: float = 0.0
@export var selling_price: float = 0.0
@export var package_type: StringName = &"bottle_small"
@export var preview_color: Color = Color(0.78, 0.12, 0.16)


func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if String(id).is_empty():
		errors.append("id is empty")
	if display_name.is_empty():
		errors.append("display_name is empty")
	if width_m <= 0.0 or height_m <= 0.0 or depth_m <= 0.0:
		errors.append("dimensions must be > 0")
	if purchase_price < 0.0 or selling_price < 0.0:
		errors.append("prices must be >= 0")
	return errors
