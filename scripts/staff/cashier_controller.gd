class_name CashierController
extends CharacterBody3D

@onready var model: CharacterModel = $Model

var _busy := false


func _ready() -> void:
	var visual := get_node_or_null("Visual") as MeshInstance3D
	if visual != null:
		visual.visible = false
	if model != null:
		model.set_kind(&"cashier")
		model.play_idle()


func station_at(world_pos: Vector3, facing_y: float) -> void:
	global_position = world_pos
	rotation.y = facing_y
	velocity = Vector3.ZERO


func set_busy(busy: bool) -> void:
	_busy = busy
	if model == null:
		return
	if busy:
		model.set_moving(false)
		model.play_idle()
	else:
		model.play_idle()
