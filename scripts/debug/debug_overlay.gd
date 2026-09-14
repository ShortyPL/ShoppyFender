class_name DebugOverlay
extends CanvasLayer

const ThemeLib := preload("res://scripts/ui/game_theme.gd")

var game_manager: GameManager
var store_manager: StoreManager
var customer_manager: CustomerManager
var economy: EconomyManager
var inventory: InventoryManager
var staff_manager: StaffManager

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label


func setup(
	p_game: GameManager,
	p_store: StoreManager,
	p_customers: CustomerManager,
	p_economy: EconomyManager,
	p_inventory: InventoryManager = null,
	p_staff: StaffManager = null
) -> void:
	game_manager = p_game
	store_manager = p_store
	customer_manager = p_customers
	economy = p_economy
	inventory = p_inventory
	staff_manager = p_staff


func _ready() -> void:
	panel.visible = false
	ThemeLib.apply(panel)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", ThemeLib.MUTED)


func _process(_delta: float) -> void:
	if not panel.visible or game_manager == null:
		return
	var stock := store_manager.get_total_any_shelf_stock()
	var sku := store_manager.catalog_order.size()
	var types := store_manager.fixture_order.size()
	var warehouse_total := 0
	if inventory != null:
		for count in inventory.state.warehouse_stock.values():
			warehouse_total += int(count)
	var worker_state := "-"
	if staff_manager != null:
		worker_state = String(staff_manager.get_worker_state())
	label.text = "DEBUG\nState: %s\nCash: %.2f\nFixtures: %d\nTypes: %d\nSKU: %d\nShelf stock: %d\nWarehouse: %d\nWorker: %s\nWave: %d/%d\nLost: %d (%.2f)\nSat: %.0f%%\nCustomers: %d\nCustomer state: %s\nQueue: %d\ncustomer_type_id: %s\nSpeed: %sx\nF1 paths  F2 overlay  F3 bot  1/2/3 speed  Space pause" % [
		String(game_manager.current_state),
		economy.get_cash(),
		store_manager.runtime.size(),
		types,
		sku,
		stock,
		warehouse_total,
		worker_state,
		customer_manager.wave.spawned_count,
		customer_manager.wave.total_to_spawn,
		customer_manager.wave.lost_sales_count,
		customer_manager.wave.lost_sales_value,
		customer_manager.wave.get_average_satisfaction(),
		customer_manager.get_active_count(),
		customer_manager.get_first_customer_state(),
		customer_manager.get_queue_length(),
		customer_manager.get_first_customer_type_id(),
		("%.1f" % Engine.time_scale) if Engine.time_scale > 0.0 and not is_equal_approx(Engine.time_scale, roundf(Engine.time_scale)) else ("0" if Engine.time_scale <= 0.0 else str(int(Engine.time_scale)))
	]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			customer_manager.set_path_debug(not customer_manager.path_debug)
			GameLog.info("DEBUG", "Path debug = %s" % str(customer_manager.path_debug))
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F2:
			panel.visible = not panel.visible
			get_viewport().set_input_as_handled()
