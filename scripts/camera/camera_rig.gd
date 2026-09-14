class_name CameraRig
extends Node3D

const Settings := preload("res://scripts/ui/game_settings.gd")

@export var move_speed: float = 10.0
@export var zoom_min: float = 8.0
@export var zoom_max: float = 28.0
@export var zoom_step: float = 1.5
@export var pan_sensitivity: float = 0.02
@export var rotate_sensitivity: float = 0.2
@export var store_half_extents: Vector2 = Vector2(5.0, 6.0)
@export var store_z_min: float = -10.5

@onready var arm: Node3D = $Arm
@onready var camera: Camera3D = $Arm/Camera3D

var _distance: float = 18.0
var _panning := false


func _ready() -> void:
	pan_sensitivity = float(Settings.load_values().get("pan_sensitivity", pan_sensitivity))
	arm.rotation_degrees.x = -52.0
	_apply_zoom()


func get_camera() -> Camera3D:
	return camera


func ray_to_ground(mouse_pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(mouse_pos)
	var direction := camera.project_ray_normal(mouse_pos)
	if absf(direction.y) < 0.0001:
		return Vector3.ZERO
	var t := -origin.y / direction.y
	if t < 0.0:
		return Vector3.ZERO
	return origin + direction * t


func _process(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		move.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		move.z += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		move.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		move.x += 1.0
	if move != Vector3.ZERO:
		move = move.normalized().rotated(Vector3.UP, rotation.y)
		global_position += move * move_speed * delta
		_clamp_to_store()
	if Input.is_physical_key_pressed(KEY_Q):
		rotate_y(deg_to_rad(60.0) * delta)
	if Input.is_physical_key_pressed(KEY_E):
		rotate_y(-deg_to_rad(60.0) * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = mouse_button.pressed
			get_viewport().set_input_as_handled()
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			_distance = maxf(zoom_min, _distance - zoom_step)
			_apply_zoom()
			get_viewport().set_input_as_handled()
		elif mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			_distance = minf(zoom_max, _distance + zoom_step)
			_apply_zoom()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _panning:
		var motion := event as InputEventMouseMotion
		var right := Vector3.RIGHT.rotated(Vector3.UP, rotation.y)
		var forward := Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
		global_position -= right * motion.relative.x * pan_sensitivity * (_distance * 0.15)
		global_position += forward * motion.relative.y * pan_sensitivity * (_distance * 0.15)
		_clamp_to_store()
		get_viewport().set_input_as_handled()


func _apply_zoom() -> void:
	camera.position = Vector3(0.0, 0.0, _distance)


func _clamp_to_store() -> void:
	global_position.x = clampf(global_position.x, -store_half_extents.x, store_half_extents.x)
	global_position.z = clampf(global_position.z, store_z_min, store_half_extents.y)
	global_position.y = 0.0
