class_name UpgradesPanel
extends PanelContainer

const ThemeLib := preload("res://scripts/ui/game_theme.gd")

signal closed
signal buy_pressed(id: StringName)

var _list: VBoxContainer


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(420, 0)
	ThemeLib.style_hud_panel(self)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	var title := Label.new()
	title.text = "Upgrades"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	root.add_child(title)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	root.add_child(_list)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(close)
	root.add_child(close_btn)


func open(rows: Array[Dictionary], cash: float) -> void:
	while _list.get_child_count() > 0:
		var child := _list.get_child(0)
		_list.remove_child(child)
		child.free()
	for row in rows:
		var id: StringName = row.get("id", &"")
		var cost := float(row.get("cost", 0.0))
		var title := str(row.get("title", ""))
		var owned := bool(row.get("owned", false))
		var line := HBoxContainer.new()
		var label := Label.new()
		if owned:
			label.text = "%s  —  Owned" % title
		else:
			label.text = "%s  $%.0f" % [title, cost]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		line.add_child(label)
		var buy := Button.new()
		buy.text = "Buy"
		buy.disabled = owned or cash + 0.0001 < cost
		buy.pressed.connect(func() -> void: buy_pressed.emit(id))
		line.add_child(buy)
		_list.add_child(line)
	show()
	move_to_front()


func close() -> void:
	hide()
	closed.emit()
