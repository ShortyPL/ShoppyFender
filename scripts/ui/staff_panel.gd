class_name StaffPanel
extends PanelContainer

const ThemeLib := preload("res://scripts/ui/game_theme.gd")

signal closed
signal auto_fill_toggled(enabled: bool)
signal restock_empties_pressed

var _status: Label
var _auto: CheckBox


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(360, 0)
	ThemeLib.style_hud_panel(self)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title := Label.new()
	title.text = "Staff"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	root.add_child(title)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_color_override("font_color", Color(1, 1, 1))
	root.add_child(_status)
	_auto = CheckBox.new()
	_auto.text = "Auto-fill empty shelves"
	_auto.add_theme_color_override("font_color", Color(1, 1, 1))
	_auto.toggled.connect(func(on: bool) -> void: auto_fill_toggled.emit(on))
	root.add_child(_auto)
	var restock := Button.new()
	restock.text = "Restock empties now"
	restock.pressed.connect(func() -> void: restock_empties_pressed.emit())
	ThemeLib.style_hud_action(restock, false)
	root.add_child(restock)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close)
	root.add_child(close_btn)


func open(worker_state: StringName, workers: int, cashier_ok: bool, auto_fill: bool) -> void:
	_status.text = "Workers: %d   State: %s\nCashier: %s" % [
		workers,
		String(worker_state),
		"on station" if cashier_ok else "missing",
	]
	_auto.set_pressed_no_signal(auto_fill)
	show()
	move_to_front()


func close() -> void:
	hide()
	closed.emit()
