class_name FixtureDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var fixture_type: StringName = &"gondola"
@export var width_m: float = 1.0
@export var depth_m: float = 0.5
@export var height_m: float = 1.8
@export var purchase_cost: float = 400.0
@export var shelf_count: int = 4
@export var packed_scene: PackedScene


func validate() -> PackedStringArray:
	var errors: PackedStringArray = []
	if String(id).is_empty():
		errors.append("id is empty")
	if width_m <= 0.0 or depth_m <= 0.0 or height_m <= 0.0:
		errors.append("dimensions must be > 0")
	if purchase_cost < 0.0:
		errors.append("purchase_cost must be >= 0")
	return errors
