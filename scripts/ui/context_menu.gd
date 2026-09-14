class_name BuildContextMenu
extends PanelContainer

const ThemeLib := preload("res://scripts/ui/game_theme.gd")
const ACTION_PLACE := 0
const ACTION_ASSIGN := 1
const ACTION_ROTATE := 2
const ACTION_DELETE := 3
const ACTION_OPEN_STORE := 4
const ACTION_ROTATE_GHOST := 5
const ACTION_DELETE_ALL := 6
const ACTION_ASSIGN_SHELF := 7
const ACTION_RESTOCK := 8
const ACTION_CLEAR := 9
const ACTION_DUPLICATE := 10
const ACTION_PICK_PRODUCT := 11
const ACTION_PICK_FIXTURE := 12
const ACTION_FACINGS_MORE := 13
const ACTION_FACINGS_LESS := 14
const ACTION_ORDER := 15

signal action_chosen(action_id: int, payload: int)

var _list: VBoxContainer
var _screen_pos: Vector2 = Vector2.ZERO
var _shelf_rows: Array[Dictionary] = []
var _catalog: Array[Dictionary] = []
var _fixtures: Array[Dictionary] = []
var _has_product: bool = false
var pending_product_id: StringName = &"freshpop_cola_500"
var pending_fixture_id: StringName = &"gondola_basic_100"
var _floor_can_place: bool = false
var _floor_has_fixtures: bool = false


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(268, 0)
	ThemeLib.apply(self)
	add_theme_stylebox_override("panel", ThemeLib.panel_box(ThemeLib.INK, ThemeLib.BORDER))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	add_child(_list)


func open_for_floor(screen_pos: Vector2, can_place: bool, has_fixtures: bool = false, fixtures: Array[Dictionary] = []) -> void:
	_screen_pos = screen_pos
	_fixtures = fixtures
	_floor_can_place = can_place
	_floor_has_fixtures = has_fixtures
	_clear_items()
	_add_info("Floor")
	_add_action("Place fixture…", ACTION_PLACE, not can_place)
	_add_action("Rotate preview 90°", ACTION_ROTATE_GHOST)
	_add_separator()
	_add_action("Remove all fixtures", ACTION_DELETE_ALL, not has_fixtures)
	_add_separator()
	_add_action("Order stock…", ACTION_ORDER)
	_add_action("Open store", ACTION_OPEN_STORE)
	_show_at(screen_pos)


func open_for_fixture(screen_pos: Vector2, shelf_rows: Array[Dictionary], catalog: Array[Dictionary] = []) -> void:
	_screen_pos = screen_pos
	_shelf_rows = shelf_rows
	_catalog = catalog
	_has_product = _fixture_has_product(shelf_rows)
	_build_fixture_page()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		if get_global_rect().has_point(event.position):
			return
		hide()
		get_viewport().set_input_as_handled()


func _build_fixture_page() -> void:
	_clear_items()
	_add_info(_fixture_summary_text())
	_add_action("Place product on shelf…", ACTION_ASSIGN)
	_add_action("More facings", ACTION_FACINGS_MORE, not _has_product)
	_add_action("Fewer facings", ACTION_FACINGS_LESS, not _has_product)
	_add_action("Restock to capacity", ACTION_RESTOCK)
	_add_action("Clear product", ACTION_CLEAR, not _has_product)
	_add_separator()
	_add_action("Rotate shelf 90°", ACTION_ROTATE)
	_add_action("Duplicate shelf", ACTION_DUPLICATE)
	_add_action("Remove shelf", ACTION_DELETE)
	_add_separator()
	_add_action("Open store", ACTION_OPEN_STORE)
	_show_at(_screen_pos)


func _build_fixture_type_picker() -> void:
	_clear_items()
	_add_info("Choose fixture")
	var back := Button.new()
	back.text = "← Back"
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.pressed.connect(_on_back_to_floor)
	_list.add_child(back)
	_add_separator()
	if _fixtures.is_empty():
		_add_info("No fixture catalog.")
		_show_at(_screen_pos)
		return
	for i in _fixtures.size():
		var row: Dictionary = _fixtures[i]
		var label := "%s  (%d shelves, %.0f)" % [str(row.get("display_name", "")), int(row.get("shelf_count", 0)), float(row.get("purchase_cost", 0.0))]
		_add_action(label, ACTION_PICK_FIXTURE, false, i)
	_show_at(_screen_pos)


func _build_product_picker() -> void:
	_clear_items()
	_add_info("Choose product")
	var back := Button.new()
	back.text = "← Back"
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.pressed.connect(_on_back_to_fixture)
	_list.add_child(back)
	_add_separator()
	if _catalog.is_empty():
		_add_info("No product catalog.")
		_show_at(_screen_pos)
		return
	for i in _catalog.size():
		var row: Dictionary = _catalog[i]
		var label := "%s  (%.2f)" % [str(row.get("display_name", "")), float(row.get("selling_price", 0.0))]
		_add_action(label, ACTION_PICK_PRODUCT, false, i)
	_show_at(_screen_pos)


func _build_shelf_picker() -> void:
	_clear_items()
	_add_info("Choose shelf")
	var back := Button.new()
	back.text = "← Back"
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.pressed.connect(_on_back_to_product_picker)
	_list.add_child(back)
	_add_separator()
	for row in _shelf_rows:
		var shelf_index := int(row.get("shelf_index", 0))
		var label := _shelf_button_label(row)
		_add_action(label, ACTION_ASSIGN_SHELF, false, shelf_index)
	_show_at(_screen_pos)


func _fixture_summary_text() -> String:
	if _shelf_rows.is_empty():
		return "Shelf"
	var lines: PackedStringArray = ["Shelf"]
	for row in _shelf_rows:
		lines.append(_shelf_status_line(row))
	return "\n".join(lines)


func _shelf_status_line(row: Dictionary) -> String:
	var shelf_no := int(row.get("shelf_index", 0)) + 1
	var suffix := "bottom" if shelf_no == 1 else ("top" if shelf_no == _shelf_rows.size() else "")
	var title := "Shelf %d" % shelf_no
	if suffix != "":
		title += " (%s)" % suffix
	if bool(row.get("occupied", false)):
		var product_name := str(row.get("display_name", "product"))
		return "%s: %s ×%d/%d (%d facings)" % [title, product_name, int(row.get("stock", 0)), int(row.get("capacity", 0)), int(row.get("facings", 1))]
	return "%s: empty" % title


func _shelf_button_label(row: Dictionary) -> String:
	var shelf_no := int(row.get("shelf_index", 0)) + 1
	if bool(row.get("occupied", false)):
		return "Shelf %d — %s ×%d/%d (replace)" % [shelf_no, str(row.get("display_name", "product")), int(row.get("stock", 0)), int(row.get("capacity", 0))]
	return "Shelf %d — place product (empty)" % shelf_no


func _fixture_has_product(rows: Array[Dictionary]) -> bool:
	for row in rows:
		if bool(row.get("occupied", false)):
			return true
	return false


func _clear_items() -> void:
	while _list.get_child_count() > 0:
		var child := _list.get_child(0)
		_list.remove_child(child)
		child.free()


func _add_info(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(248, 0)
	label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.88))
	_list.add_child(label)


func _add_separator() -> void:
	_list.add_child(HSeparator.new())


func _add_action(text: String, action_id: int, disabled: bool = false, payload: int = 0) -> void:
	var btn := Button.new()
	btn.text = text
	btn.disabled = disabled
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.pressed.connect(_on_item_pressed.bind(action_id, payload))
	_list.add_child(btn)


func _on_item_pressed(action_id: int, payload: int) -> void:
	if action_id == ACTION_PLACE:
		call_deferred("_build_fixture_type_picker")
		return
	if action_id == ACTION_PICK_FIXTURE:
		if payload >= 0 and payload < _fixtures.size():
			pending_fixture_id = _fixtures[payload].get("id", &"gondola_basic_100") as StringName
		hide()
		action_chosen.emit(action_id, payload)
		return
	if action_id == ACTION_ASSIGN:
		call_deferred("_build_product_picker")
		return
	if action_id == ACTION_PICK_PRODUCT:
		if payload >= 0 and payload < _catalog.size():
			pending_product_id = _catalog[payload].get("id", &"freshpop_cola_500") as StringName
		call_deferred("_build_shelf_picker")
		return
	if action_id == ACTION_FACINGS_MORE or action_id == ACTION_FACINGS_LESS:
		action_chosen.emit(action_id, payload)
		return
	hide()
	action_chosen.emit(action_id, payload)


func find_button(text_part: String) -> Button:
	if _list == null:
		return null
	for child in _list.get_children():
		if child is Button and String((child as Button).text).findn(text_part) >= 0:
			return child as Button
	return null


func refresh_fixture_rows(shelf_rows: Array[Dictionary]) -> void:
	_shelf_rows = shelf_rows
	_has_product = _fixture_has_product(shelf_rows)
	call_deferred("_build_fixture_page")


func _on_back_to_fixture() -> void:
	call_deferred("_build_fixture_page")


func _on_back_to_floor() -> void:
	open_for_floor(_screen_pos, _floor_can_place, _floor_has_fixtures, _fixtures)


func _on_back_to_product_picker() -> void:
	call_deferred("_build_product_picker")


func _show_at(screen_pos: Vector2) -> void:
	global_position = screen_pos
	show()
	move_to_front()
	reset_size()
	var vp := get_viewport().get_visible_rect().size
	var sz := get_combined_minimum_size()
	if sz.x < 8.0 or sz.y < 8.0:
		sz = size
	var pos := screen_pos
	pos.x = clampf(pos.x, 8.0, maxf(8.0, vp.x - sz.x - 8.0))
	pos.y = clampf(pos.y, 8.0, maxf(8.0, vp.y - sz.y - 8.0))
	global_position = pos
