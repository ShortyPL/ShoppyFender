class_name Hud
extends CanvasLayer

const ThemeLib := preload("res://scripts/ui/game_theme.gd")

signal open_store_pressed
signal continue_pressed
signal menu_pressed
signal order_requested
signal order_confirmed(product_id: StringName, qty: int, delivery_type: StringName)
signal build_pressed
signal staff_open_requested
signal upgrades_open_requested
signal staff_auto_fill_toggled(enabled: bool)
signal staff_restock_empties
signal upgrade_buy_pressed(id: StringName)
signal next_wave_pressed
signal repeat_wave_pressed

@onready var cash_label: Label = $Root/StatsRow/CashPill/CashLabel
@onready var rating_label: Label = $Root/StatsRow/RatingPill/RatingLabel
@onready var queue_label: Label = $Root/QueueChip/QueueLabel
@onready var toast_label: Label = $Root/ToastLabel
@onready var shopy_label: Label = $Root/LogoBlock/LogoRow/ShopyLabel
@onready var fender_label: Label = $Root/LogoBlock/LogoRow/FenderLabel
@onready var tagline_label: Label = $Root/LogoBlock/TaglineRibbon/Tagline
@onready var tagline_ribbon: PanelContainer = $Root/LogoBlock/TaglineRibbon
@onready var cash_pill: PanelContainer = $Root/StatsRow/CashPill
@onready var day_pill: PanelContainer = $Root/StatsRow/DayPill
@onready var day_label: Label = $Root/StatsRow/DayPill/DayBox/DayLabel
@onready var time_label: Label = $Root/StatsRow/DayPill/DayBox/TimeLabel
@onready var rating_pill: PanelContainer = $Root/StatsRow/RatingPill
@onready var level_pill: PanelContainer = $Root/StatsRow/LevelPill
@onready var goals_panel: PanelContainer = $Root/GoalsPanel
@onready var queue_chip: PanelContainer = $Root/QueueChip
@onready var action_bar: PanelContainer = $Root/ActionBar
@onready var order_button: Button = $Root/ActionBar/ActionBox/OrderSlot/OrderButton
@onready var order_dot: ColorRect = $Root/ActionBar/ActionBox/OrderSlot/OrderDot
@onready var build_button: Button = $Root/ActionBar/ActionBox/BuildButton
@onready var staff_button: Button = $Root/ActionBar/ActionBox/StaffButton
@onready var upgrades_button: Button = $Root/ActionBar/ActionBox/UpgradesButton
@onready var more_button: Button = $Root/ActionBar/ActionBox/MoreButton
@onready var more_dimmer: ColorRect = $Root/MoreDimmer
@onready var more_popup: PanelContainer = $Root/MorePopup
@onready var open_button: Button = $Root/MorePopup/MoreBox/OpenButton
@onready var menu_button: Button = $Root/MorePopup/MoreBox/MenuButton
@onready var continue_button: Button = $Root/MorePopup/MoreBox/ContinueButton
@onready var results_panel: PanelContainer = $Root/ResultsPanel
@onready var results_label: Label = $Root/ResultsPanel/ResultsBox/ResultsLabel
@onready var results_continue_button: Button = $Root/ResultsPanel/ResultsBox/ResultsContinueButton
@onready var results_next_wave_button: Button = $Root/ResultsPanel/ResultsBox/ResultsNextWaveButton
@onready var results_repeat_button: Button = $Root/ResultsPanel/ResultsBox/ResultsRepeatButton
@onready var context_menu: BuildContextMenu = $Root/ContextMenu
@onready var order_dimmer: ColorRect = $Root/OrderDimmer
@onready var order_panel: OrderPanel = $Root/OrderPanel
@onready var delivery_panel: PanelContainer = $Root/DeliveryPanel
@onready var delivery_label: Label = $Root/DeliveryPanel/DeliveryBox/DeliveryLabel
@onready var delivery_bar: ProgressBar = $Root/DeliveryPanel/DeliveryBox/DeliveryBar
@onready var warehouse_panel: PanelContainer = $Root/WarehousePanel
@onready var warehouse_label: Label = $Root/WarehousePanel/WarehouseLabel
@onready var wave_preview_panel: PanelContainer = $Root/WavePreviewPanel
@onready var wave_preview_label: Label = $Root/WavePreviewPanel/WavePreviewLabel
@onready var goal1_label: Label = $Root/GoalsPanel/GoalsBox/Goal1
@onready var goal2_label: Label = $Root/GoalsPanel/GoalsBox/Goal2
@onready var goal3_label: Label = $Root/GoalsPanel/GoalsBox/Goal3

var _state_name: String = "BUILD"
var _queue_length: int = 0
var _waves_seen: int = 0
var _day_served: int = 0
var _live_served: int = 0
var _shelf_stock: int = 0
var _start_cash: float = 10000.0
var _stars_history: Array[int] = []
var _goal_served: int = 0
var _goal_served_need: int = 8
var _goal_sat: float = -1.0
var _goal_lost: int = -1
var _goal_total: int = 10
var staff_panel: StaffPanel
var upgrades_panel: UpgradesPanel
var _panel_dimmer: ColorRect


func _ready() -> void:
	_style_chrome()
	ThemeLib.apply(order_panel)
	ThemeLib.apply(context_menu)
	ThemeLib.apply(results_panel)
	ThemeLib.style_primary(open_button)
	ThemeLib.style_primary(continue_button)
	ThemeLib.style_primary(results_continue_button)
	ThemeLib.style_hud_action(results_next_wave_button, false)
	ThemeLib.style_hud_action(results_repeat_button, false)
	open_button.pressed.connect(_on_open_store)
	order_button.pressed.connect(_on_order_requested)
	menu_button.pressed.connect(_on_menu)
	continue_button.pressed.connect(_on_continue)
	results_continue_button.pressed.connect(_on_continue)
	results_next_wave_button.pressed.connect(_on_next_wave)
	results_repeat_button.pressed.connect(_on_repeat_wave)
	more_button.pressed.connect(_toggle_more)
	build_button.pressed.connect(_on_build)
	staff_button.pressed.connect(_on_staff)
	staff_button.disabled = false
	staff_button.tooltip_text = ""
	upgrades_button.pressed.connect(_on_upgrades)
	upgrades_button.disabled = false
	upgrades_button.tooltip_text = ""
	more_dimmer.gui_input.connect(_on_more_dimmer_input)
	_build_meta_panels()
	continue_button.visible = false
	results_panel.visible = false
	order_panel.confirmed.connect(_on_order_panel_confirmed)
	order_panel.closed.connect(_on_order_panel_closed)
	order_dimmer.gui_input.connect(_on_dimmer_input)
	set_queue_length(0)
	_paint_build_slot(true)
	_paint_goals()


func set_cash(amount: float) -> void:
	cash_label.text = "$%.2f" % amount


func set_state(state_name: String) -> void:
	_state_name = state_name
	var is_build := state_name == "BUILD"
	var is_results := state_name == "RESULTS"
	order_button.disabled = not is_build
	order_dot.visible = is_build
	open_button.visible = is_build
	continue_button.visible = is_results
	results_panel.visible = is_results
	_paint_build_slot(is_build)
	if not is_build:
		_hide_more()
	close_meta_panels()


func set_queue_length(n: int) -> void:
	_queue_length = n
	queue_label.text = "%d in queue" % n


func set_warehouse_line(text: String) -> void:
	warehouse_label.text = text
	warehouse_panel.visible = not text.is_empty()


func set_wave_preview(text: String) -> void:
	wave_preview_label.text = text
	wave_preview_panel.visible = not text.is_empty()


func set_in_transit_line(_text: String) -> void:
	pass


func set_goal_progress(shelf_stock: int, live_served: int = 0) -> void:
	_shelf_stock = maxi(0, shelf_stock)
	_live_served = maxi(0, live_served)
	_paint_goals()

func set_clock(text: String) -> void:
	time_label.text = text


func set_wave_number(n: int) -> void:
	day_label.text = "Wave %d" % n


func configure_session_metrics(start_cash: float) -> void:
	_start_cash = start_cash
	set_cash_delta(0.0)
	set_stars_history([])


func set_cash_delta(delta: float) -> void:
	var xp := $Root/StatsRow/LevelPill/LevelBox/XpLabel as Label
	if xp == null:
		return
	if delta >= 0.0:
		xp.text = "Δ +%.0f" % delta
	else:
		xp.text = "Δ %.0f" % delta


func set_stars_history(history: Array) -> void:
	_stars_history.clear()
	for value in history:
		_stars_history.append(int(value))
	var level := $Root/StatsRow/LevelPill/LevelBox/LevelLabel as Label
	if level == null:
		return
	if _stars_history.is_empty():
		level.text = "Avg —"
		return
	var total := 0
	for stars in _stars_history:
		total += stars
	level.text = "Avg %.1f★" % (float(total) / float(_stars_history.size()))


func set_wave_goals(served: int, served_need: int, sat: float, lost: int, total: int) -> void:
	_goal_served = maxi(0, served)
	_goal_served_need = maxi(1, served_need)
	_goal_sat = sat
	_goal_lost = lost
	_goal_total = maxi(1, total)
	_paint_goals()


func set_delivery(text: String, ratio: float) -> void:
	if text.is_empty():
		delivery_panel.visible = false
		return
	delivery_panel.visible = true
	delivery_label.text = text
	delivery_bar.value = clampf(ratio, 0.0, 1.0)


func show_staff_panel(worker_state: StringName, workers: int, cashier_ok: bool, auto_fill: bool) -> void:
	_hide_more()
	_panel_dimmer.visible = true
	if upgrades_panel != null:
		upgrades_panel.hide()
	staff_panel.open(worker_state, workers, cashier_ok, auto_fill)


func show_upgrades_panel(rows: Array[Dictionary], cash: float) -> void:
	_hide_more()
	_panel_dimmer.visible = true
	if staff_panel != null:
		staff_panel.hide()
	upgrades_panel.open(rows, cash)


func close_meta_panels() -> void:
	if staff_panel != null:
		staff_panel.hide()
	if upgrades_panel != null:
		upgrades_panel.hide()
	if _panel_dimmer != null:
		_panel_dimmer.visible = false


func open_order_panel(catalog: Array[Dictionary], quote_cb: Callable) -> void:
	_hide_more()
	order_dimmer.visible = true
	order_panel.open(catalog, quote_cb)


func show_results(served: int, cash: float, total: int = 10, lost_count: int = 0, lost_value: float = 0.0, satisfaction: float = 100.0, stars: int = 0, served_ok: bool = false, sat_ok: bool = false, lost_ok: bool = false, served_need: int = 8, lost_oos: int = 0, lost_queue: int = 0, lost_path: int = 0) -> void:
	results_panel.visible = true
	_waves_seen += 1
	_day_served += served
	_live_served = 0
	rating_label.text = "%.1f (%d)" % [float(stars), _waves_seen]
	var served_glyph := "★" if served_ok else "☆"
	var sat_glyph := "★" if sat_ok else "☆"
	var lost_glyph := "★" if lost_ok else "☆"
	results_label.text = "Wave results\nServed: %d / %d\nLost: %d (oos:%d queue:%d path:%d) (%.2f)\nSatisfaction: %.0f%%\nCash: %.2f\n%s  Served ≥ %d\n%s  Satisfaction ≥ 80%%\n%s  Zero lost sales\nStars: %d/3" % [
		served,
		total,
		lost_count,
		lost_oos,
		lost_queue,
		lost_path,
		lost_value,
		satisfaction,
		cash,
		served_glyph,
		served_need,
		sat_glyph,
		lost_glyph,
		stars
	]
	set_wave_goals(served, served_need, satisfaction, lost_count, total)
	_paint_goals()


func show_message(text: String) -> void:
	toast_label.text = text


func _style_chrome() -> void:
	shopy_label.add_theme_color_override("font_color", ThemeLib.LOGO_SHOPY)
	shopy_label.add_theme_font_size_override("font_size", 36)
	shopy_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.12, 0.28, 0.9))
	shopy_label.add_theme_constant_override("shadow_offset_x", 2)
	shopy_label.add_theme_constant_override("shadow_offset_y", 2)
	fender_label.add_theme_color_override("font_color", ThemeLib.LOGO_FENDER)
	fender_label.add_theme_font_size_override("font_size", 36)
	fender_label.add_theme_color_override("font_shadow_color", Color(0.05, 0.12, 0.28, 0.9))
	fender_label.add_theme_constant_override("shadow_offset_x", 2)
	fender_label.add_theme_constant_override("shadow_offset_y", 2)
	tagline_label.add_theme_color_override("font_color", Color(1, 1, 1))
	tagline_label.add_theme_font_size_override("font_size", 13)
	var ribbon := ThemeLib.hud_panel_box(ThemeLib.HUD_BLUE, 14)
	ribbon.content_margin_left = 12
	ribbon.content_margin_right = 12
	ribbon.content_margin_top = 4
	ribbon.content_margin_bottom = 4
	tagline_ribbon.add_theme_stylebox_override("panel", ribbon)
	ThemeLib.style_hud_pill(cash_pill)
	ThemeLib.style_hud_pill(day_pill)
	ThemeLib.style_hud_pill(rating_pill)
	ThemeLib.style_hud_pill(level_pill)
	ThemeLib.style_hud_panel(goals_panel)
	ThemeLib.style_hud_pill(queue_chip)
	ThemeLib.style_hud_pill(warehouse_panel)
	ThemeLib.style_hud_pill(wave_preview_panel)
	ThemeLib.style_hud_panel(action_bar)
	ThemeLib.style_hud_panel(more_popup)
	ThemeLib.style_hud_panel(results_panel)
	ThemeLib.style_hud_panel(delivery_panel)
	delivery_label.add_theme_color_override("font_color", Color(1, 1, 1))
	delivery_label.add_theme_font_size_override("font_size", 13)
	var fill := ThemeLib.button_box(ThemeLib.HUD_BLUE_HI, ThemeLib.HUD_BLUE_BORDER)
	fill.set_corner_radius_all(6)
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	delivery_bar.add_theme_stylebox_override("fill", fill)
	cash_label.add_theme_color_override("font_color", Color(1, 1, 1))
	cash_label.add_theme_font_size_override("font_size", 20)
	_style_white_label(day_label, 15)
	_style_white_label(time_label, 12)
	_style_white_label(rating_label, 18)
	_style_white_label($Root/StatsRow/LevelPill/LevelBox/LevelLabel, 14)
	_style_white_label($Root/StatsRow/LevelPill/LevelBox/XpLabel, 12)
	_style_white_label($Root/GoalsPanel/GoalsBox/GoalsTitle, 16)
	_style_white_label(goal1_label, 13)
	_style_white_label(goal2_label, 13)
	_style_white_label(goal3_label, 13)
	_style_white_label(queue_label, 14)
	_style_white_label(warehouse_label, 13)
	_style_white_label(wave_preview_label, 13)
	toast_label.add_theme_color_override("font_color", Color(1, 1, 1))
	toast_label.add_theme_font_size_override("font_size", 15)
	_setup_action_button(order_button, &"cart")
	_setup_action_button(build_button, &"hammer")
	_setup_action_button(staff_button, &"people")
	_setup_action_button(upgrades_button, &"chart")
	_setup_action_button(more_button, &"more")
	order_dot.color = ThemeLib.HUD_RED_DOT
	order_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_action_button(button: Button, icon_kind: StringName) -> void:
	button.icon = ThemeLib.menu_icon(icon_kind)
	button.expand_icon = false
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	ThemeLib.style_hud_action(button, false)


func _style_white_label(label: Label, size: int) -> void:
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_font_size_override("font_size", size)


func _paint_goals() -> void:
	var served_ok := _goal_served >= _goal_served_need
	var sat_text := "—"
	var sat_ok := false
	if _goal_sat >= 0.0:
		sat_text = "%.0f%%" % _goal_sat
		sat_ok = WaveRuntimeState.sat_star_ok(_goal_sat)
	var lost_text := "—"
	var lost_ok := false
	if _goal_lost >= 0:
		lost_text = str(_goal_lost)
		lost_ok = WaveRuntimeState.lost_star_ok(_goal_lost)
	goal1_label.text = "%s  Served ≥ %d                  %d/%d" % ["☑" if served_ok else "☐", _goal_served_need, _goal_served, _goal_served_need]
	goal2_label.text = "%s  Satisfaction ≥ 80%%           %s" % ["☑" if sat_ok else "☐", sat_text]
	goal3_label.text = "%s  Zero lost sales              %s" % ["☑" if lost_ok else "☐", lost_text]


func _paint_build_slot(is_build: bool) -> void:
	ThemeLib.style_hud_action(build_button, is_build)
	ThemeLib.style_hud_action(order_button, false)
	ThemeLib.style_hud_action(staff_button, false)
	ThemeLib.style_hud_action(upgrades_button, false)
	ThemeLib.style_hud_action(more_button, more_popup.visible)


func _toggle_more() -> void:
	if more_popup.visible:
		_hide_more()
	else:
		more_dimmer.visible = true
		more_popup.visible = true
		ThemeLib.style_hud_action(more_button, true)


func _hide_more() -> void:
	more_dimmer.visible = false
	more_popup.visible = false
	ThemeLib.style_hud_action(more_button, false)


func _on_more_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_more()


func _on_open_store() -> void:
	_hide_more()
	open_store_pressed.emit()


func _on_order_requested() -> void:
	_hide_more()
	order_requested.emit()


func _on_menu() -> void:
	_hide_more()
	menu_pressed.emit()


func _on_continue() -> void:
	_hide_more()
	continue_pressed.emit()


func _on_next_wave() -> void:
	_hide_more()
	next_wave_pressed.emit()


func _on_repeat_wave() -> void:
	_hide_more()
	repeat_wave_pressed.emit()


func _on_order_panel_confirmed(product_id: StringName, qty: int, delivery_type: StringName) -> void:
	order_confirmed.emit(product_id, qty, delivery_type)


func _on_order_panel_closed() -> void:
	order_dimmer.visible = false


func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		order_panel.close()


func _build_meta_panels() -> void:
	_panel_dimmer = ColorRect.new()
	_panel_dimmer.visible = false
	_panel_dimmer.z_index = 12
	_panel_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel_dimmer.color = Color(0.02, 0.03, 0.04, 0.45)
	_panel_dimmer.gui_input.connect(_on_panel_dimmer_input)
	$Root.add_child(_panel_dimmer)
	staff_panel = StaffPanel.new()
	staff_panel.z_index = 13
	staff_panel.set_anchors_preset(Control.PRESET_CENTER)
	staff_panel.offset_left = -180
	staff_panel.offset_right = 180
	staff_panel.offset_top = -140
	staff_panel.offset_bottom = 140
	staff_panel.closed.connect(close_meta_panels)
	staff_panel.auto_fill_toggled.connect(func(on: bool) -> void: staff_auto_fill_toggled.emit(on))
	staff_panel.restock_empties_pressed.connect(func() -> void: staff_restock_empties.emit())
	$Root.add_child(staff_panel)
	upgrades_panel = UpgradesPanel.new()
	upgrades_panel.z_index = 13
	upgrades_panel.set_anchors_preset(Control.PRESET_CENTER)
	upgrades_panel.offset_left = -220
	upgrades_panel.offset_right = 220
	upgrades_panel.offset_top = -140
	upgrades_panel.offset_bottom = 160
	upgrades_panel.closed.connect(close_meta_panels)
	upgrades_panel.buy_pressed.connect(func(id: StringName) -> void: upgrade_buy_pressed.emit(id))
	$Root.add_child(upgrades_panel)


func _on_panel_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_meta_panels()


func _on_build() -> void:
	_hide_more()
	close_meta_panels()
	build_pressed.emit()


func _on_staff() -> void:
	_hide_more()
	staff_open_requested.emit()


func _on_upgrades() -> void:
	_hide_more()
	upgrades_open_requested.emit()
