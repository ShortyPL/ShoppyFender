class_name OrderPanel
extends PanelContainer

const ThemeLib := preload("res://scripts/ui/game_theme.gd")
const QTY_OPTIONS: Array[int] = [6, 12, 24]

signal confirmed(product_id: StringName, qty: int, delivery_type: StringName)
signal closed

var _quote_cb: Callable = Callable()
var _catalog: Array[Dictionary] = []
var _product_id: StringName = &""
var _qty: int = 12
var _delivery_type: StringName = &"standard"

var _sku_row: VBoxContainer
var _qty_row: HBoxContainer
var _delivery_row: HBoxContainer
var _cost_label: Label
var _stock_label: Label
var _hint_label: Label
var _confirm: Button


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(440, 0)
	ThemeLib.apply(self)
	add_theme_stylebox_override("panel", ThemeLib.panel_box(ThemeLib.INK, ThemeLib.BORDER))
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	var title := Label.new()
	title.text = "Order stock"
	title.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
	root.add_child(title)
	_sku_row = VBoxContainer.new()
	_sku_row.add_theme_constant_override("separation", 4)
	root.add_child(_sku_row)
	_qty_row = HBoxContainer.new()
	_qty_row.add_theme_constant_override("separation", 6)
	root.add_child(_qty_row)
	_delivery_row = HBoxContainer.new()
	_delivery_row.add_theme_constant_override("separation", 6)
	root.add_child(_delivery_row)
	_cost_label = Label.new()
	_cost_label.text = "Cost: 0.00"
	root.add_child(_cost_label)
	_stock_label = Label.new()
	_stock_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.9))
	_stock_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_stock_label)
	_hint_label = Label.new()
	_hint_label.add_theme_color_override("font_color", Color(0.92, 0.55, 0.42))
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_hint_label)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	root.add_child(actions)
	_confirm = Button.new()
	_confirm.text = "Order"
	_confirm.pressed.connect(_on_confirm_pressed)
	ThemeLib.style_primary(_confirm)
	actions.add_child(_confirm)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.pressed.connect(close)
	actions.add_child(cancel)


func open(catalog: Array[Dictionary], quote_cb: Callable) -> void:
	_catalog = catalog
	_quote_cb = quote_cb
	if _catalog.is_empty():
		_product_id = &""
	elif not _catalog_has(_product_id):
		_product_id = _catalog[0].get("id", &"") as StringName
	_qty = 12
	_delivery_type = &"standard"
	_rebuild_choices()
	_refresh_quote()
	show()
	move_to_front()


func close() -> void:
	hide()
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _catalog_has(product_id: StringName) -> bool:
	for row in _catalog:
		if row.get("id", &"") == product_id:
			return true
	return false


func _rebuild_choices() -> void:
	_clear_row(_sku_row)
	_clear_row(_qty_row)
	_clear_row(_delivery_row)
	var sku_group := ButtonGroup.new()
	for row in _catalog:
		var product_id: StringName = row.get("id", &"") as StringName
		var warehouse := int(row.get("warehouse", 0))
		var ordered := int(row.get("ordered", 0))
		var caption := str(row.get("display_name", String(product_id)))
		if ordered > 0:
			caption = "%s  (wh. %d, in transit %d)" % [caption, warehouse, ordered]
		else:
			caption = "%s  (wh. %d)" % [caption, warehouse]
		var btn := _choice_button(caption, sku_group, product_id == _product_id)
		btn.pressed.connect(_on_sku_pressed.bind(product_id))
		_sku_row.add_child(btn)
	var qty_group := ButtonGroup.new()
	for qty in QTY_OPTIONS:
		var btn := _choice_button(str(qty), qty_group, qty == _qty)
		btn.pressed.connect(_on_qty_pressed.bind(qty))
		_qty_row.add_child(btn)
	var delivery_group := ButtonGroup.new()
	var standard := _choice_button("Standard (+20)", delivery_group, _delivery_type == &"standard")
	standard.pressed.connect(_on_delivery_pressed.bind(&"standard"))
	_delivery_row.add_child(standard)
	var express := _choice_button("Express (+45)", delivery_group, _delivery_type == &"express")
	express.pressed.connect(_on_delivery_pressed.bind(&"express"))
	_delivery_row.add_child(express)


func _choice_button(text: String, group: ButtonGroup, selected: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.button_group = group
	btn.button_pressed = selected
	return btn


func _clear_row(row: Container) -> void:
	while row.get_child_count() > 0:
		var child := row.get_child(0)
		row.remove_child(child)
		child.free()


func _on_sku_pressed(product_id: StringName) -> void:
	_product_id = product_id
	_refresh_quote()


func _on_qty_pressed(qty: int) -> void:
	_qty = qty
	_refresh_quote()


func _on_delivery_pressed(delivery_type: StringName) -> void:
	_delivery_type = delivery_type
	_refresh_quote()


func _refresh_quote() -> void:
	if not _quote_cb.is_valid() or _product_id == &"":
		_cost_label.text = "Cost: —"
		_stock_label.text = ""
		_hint_label.text = ""
		_confirm.disabled = true
		return
	var quoted: Dictionary = _quote_cb.call(_product_id, _qty, _delivery_type)
	var cost := float(quoted.get("cost", 0.0))
	_cost_label.text = "Cost: %.2f" % cost
	_stock_label.text = _stock_line(quoted)
	var ok := bool(quoted.get("ok", false))
	_confirm.disabled = not ok
	if ok:
		_hint_label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.78))
		_hint_label.text = str(quoted.get("eta_hint", ""))
	elif quoted.get("reason", &"") == &"insufficient_cash":
		_hint_label.add_theme_color_override("font_color", Color(0.92, 0.55, 0.42))
		_hint_label.text = "Not enough cash (%.0f)." % cost
	else:
		_hint_label.add_theme_color_override("font_color", Color(0.92, 0.55, 0.42))
		_hint_label.text = "Cannot place order."


func _stock_line(quoted: Dictionary) -> String:
	var warehouse := int(quoted.get("warehouse", -1))
	if warehouse < 0:
		return ""
	var ordered := int(quoted.get("ordered", 0))
	var after := int(quoted.get("after", warehouse + _qty))
	if _delivery_type == &"express":
		return "Warehouse: %d  →  %d (after Express)" % [warehouse, after]
	if ordered > 0:
		return "Warehouse: %d  ·  in transit: %d  ·  after delivery: %d" % [warehouse, ordered + _qty, after]
	return "Warehouse: %d  →  %d (after delivery)" % [warehouse, after]


func _on_confirm_pressed() -> void:
	if _confirm.disabled or _product_id == &"":
		return
	confirmed.emit(_product_id, _qty, _delivery_type)
	close()
