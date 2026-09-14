class_name FixtureInstanceState
extends RefCounted

var instance_id: StringName
var definition_id: StringName
var position: Vector3 = Vector3.ZERO
var rotation_y_deg: float = 0.0
var is_active: bool = true
var shelf_states: Array[ShelfState] = []
