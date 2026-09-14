class_name ShelfState
extends RefCounted

var fixture_instance_id: StringName
var shelf_index: int = 0
var side_index: int = 0
var width_m: float = 1.0
var depth_m: float = 0.4
var clearance_height_m: float = 0.35
var placements: Array[ProductPlacementState] = []
