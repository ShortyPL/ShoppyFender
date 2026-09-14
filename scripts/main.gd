extends Node3D

const Settings := preload("res://scripts/ui/game_settings.gd")
const STARTING_CASH := 10000.0
const COLA := preload("res://data/products/freshpop_cola_500.tres")
const WATER := preload("res://data/products/aquapure_water_500.tres")
const JUICE := preload("res://data/products/sunnyjuice_orange_330.tres")
const CEREAL := preload("res://data/products/crunchbox_cereal_375.tres")
const CHIPS := preload("res://data/products/quickbite_chips_150.tres")
const WAREHOUSE_SHORT := {
	&"freshpop_cola_500": "Cola",
	&"aquapure_water_500": "Water",
	&"sunnyjuice_orange_330": "Juice",
	&"crunchbox_cereal_375": "Cereal",
	&"quickbite_chips_150": "Chips",
}
const GONDOLA := preload("res://data/fixtures/gondola_basic_100.tres")
const WALL_SHELF := preload("res://data/fixtures/wall_shelf_150.tres")
const ENDCAP := preload("res://data/fixtures/endcap_basic_80.tres")

@onready var store: StoreRoom = $Store
@onready var camera_rig: CameraRig = $CameraRig
@onready var store_manager: StoreManager = $StoreManager
@onready var build_manager: BuildManager = $BuildManager
@onready var customer_manager: CustomerManager = $CustomerManager
@onready var economy: EconomyManager = $EconomyManager
@onready var inventory: InventoryManager = $InventoryManager
@onready var staff_manager: StaffManager = $StaffManager
@onready var game_manager: GameManager = $GameManager
@onready var hud: Hud = $HUD
@onready var debug_overlay: DebugOverlay = $Debug
@onready var playtest_bot: PlaytestBot = $PlaytestBot

const WORKER_SCENE := preload("res://scenes/staff/Worker.tscn")
const CASHIER_SCENE := preload("res://scenes/staff/Cashier.tscn")

var upgrades := UpgradeManager.new()
var store_clock := StoreClock.new()
var _stars_history: Array[int] = []
var _start_cash: float = STARTING_CASH
const SPEED_STEPS: Array[float] = [1.0, 2.0, 4.0]
var _speed_index: int = 0
var _speed_paused: bool = false


func _ready() -> void:
	Settings.apply_saved()
	Engine.time_scale = 1.0
	_speed_index = 0
	_speed_paused = false
	_start_cash = STARTING_CASH
	economy.setup(STARTING_CASH)
	for product in [COLA, WATER, JUICE, CEREAL, CHIPS]:
		store_manager.register_product(product)
	for fixture in [GONDOLA, WALL_SHELF, ENDCAP]:
		store_manager.register_fixture(fixture)
	inventory.setup(economy)
	for product in [COLA, WATER, JUICE, CEREAL, CHIPS]:
		inventory.seed_warehouse(product.id, 24)
	store_manager.staff_manager = staff_manager
	staff_manager.setup(store, store_manager, inventory, $Workers)
	var worker := staff_manager.spawn_worker(WORKER_SCENE)
	_place_worker_in_shop(worker, 0)
	staff_manager.spawn_cashier(CASHIER_SCENE)
	inventory.stock_changed.connect(_on_stock_changed)
	store.refresh_warehouse_visuals(inventory.state.warehouse_stock)
	_refresh_stock_labels()
	build_manager.fixture_scene = GONDOLA.packed_scene
	build_manager.fixture_definition = GONDOLA
	customer_manager.customer_scene = preload("res://scenes/customers/Customer.tscn")
	build_manager.setup(store, store_manager, camera_rig, economy, hud.context_menu)
	customer_manager.setup(store, store_manager, economy, $Customers)
	game_manager.setup(store_manager, build_manager, customer_manager, inventory, staff_manager, economy)
	debug_overlay.setup(game_manager, store_manager, customer_manager, economy, inventory, staff_manager)
	playtest_bot.setup(store, camera_rig, store_manager, build_manager, economy, game_manager, hud, inventory, staff_manager)
	var loaded := false
	if RunSave.load_on_next_main:
		loaded = _load_run()
		RunSave.load_on_next_main = false
	if not loaded:
		var laid_out := build_manager.fill_supermarket_layout()
		GameLog.info("STORE", "Supermarket layout: %d fixtures" % laid_out)
	upgrades.apply(staff_manager, customer_manager, WORKER_SCENE, _place_upgrade_worker, CASHIER_SCENE)
	hud.set_cash(economy.get_cash())
	hud.set_state(String(game_manager.current_state))
	hud.set_clock(StoreClock.format_clock(store_clock.minutes))
	hud.configure_session_metrics(_start_cash)
	_refresh_hud_metrics()
	economy.cash_changed.connect(_on_cash_changed)
	game_manager.state_changed.connect(_on_state_changed)
	game_manager.results_ready.connect(_on_results_ready)
	hud.open_store_pressed.connect(_on_open_store)
	hud.menu_pressed.connect(_on_menu)
	hud.continue_pressed.connect(_on_continue_build)
	hud.next_wave_pressed.connect(_on_next_wave)
	hud.repeat_wave_pressed.connect(_on_repeat_wave)
	hud.order_requested.connect(_on_order_requested)
	hud.order_confirmed.connect(_on_order_confirmed)
	hud.build_pressed.connect(_on_build_pressed)
	hud.staff_open_requested.connect(_on_staff_open)
	hud.upgrades_open_requested.connect(_on_upgrades_open)
	hud.staff_auto_fill_toggled.connect(_on_staff_auto_fill)
	hud.staff_restock_empties.connect(_on_staff_restock)
	hud.upgrade_buy_pressed.connect(_on_upgrade_buy)
	build_manager.open_store_requested.connect(_on_open_store)
	build_manager.hint_requested.connect(hud.show_message)
	build_manager.order_requested.connect(_on_order_requested)
	store_manager.stock_changed.connect(_on_shelf_stock_changed)
	GameLog.info("GAME", "Prototype 0.04 queue ready")


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_SPACE:
			_toggle_speed_pause()
			get_viewport().set_input_as_handled()
		KEY_1:
			_set_game_speed(0)
			get_viewport().set_input_as_handled()
		KEY_2:
			_set_game_speed(1)
			get_viewport().set_input_as_handled()
		KEY_3:
			_set_game_speed(2)
			get_viewport().set_input_as_handled()
		KEY_BRACKETRIGHT, KEY_EQUAL, KEY_KP_ADD:
			_cycle_game_speed(1)
			get_viewport().set_input_as_handled()
		KEY_BRACKETLEFT, KEY_MINUS, KEY_KP_SUBTRACT:
			_cycle_game_speed(-1)
			get_viewport().set_input_as_handled()
		_:
			pass


func _toggle_speed_pause() -> void:
	_speed_paused = not _speed_paused
	_apply_game_speed()
	if _speed_paused:
		hud.show_message("Paused")
	else:
		hud.show_message("Speed %sx" % _speed_label())


func _set_game_speed(index: int) -> void:
	_speed_index = clampi(index, 0, SPEED_STEPS.size() - 1)
	_speed_paused = false
	_apply_game_speed()
	hud.show_message("Speed %sx" % _speed_label())


func _cycle_game_speed(delta: int) -> void:
	_set_game_speed(_speed_index + delta)


func _apply_game_speed() -> void:
	if _speed_paused:
		Engine.time_scale = 0.0
	else:
		Engine.time_scale = SPEED_STEPS[_speed_index]


func _speed_label() -> String:
	var value := SPEED_STEPS[_speed_index]
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return "%.1f" % value


func _on_shelf_stock_changed(_product_id: StringName, _placement_id: StringName, _old_stock: int, _new_stock: int) -> void:
	_refresh_goals()


func _on_cash_changed(_old_cash: float, new_cash: float, _reason: StringName) -> void:
	hud.set_cash(new_cash)
	_refresh_stock_labels()
	_refresh_hud_metrics()


func _refresh_hud_metrics() -> void:
	hud.set_cash_delta(economy.get_cash() - _start_cash)
	hud.set_stars_history(_stars_history)
	var total := CustomerManager.customers_for_wave(game_manager.wave_number)
	var served_need := WaveRuntimeState.served_needed(total)
	var wave := customer_manager.wave
	var live_sat := -1.0
	var live_lost := -1
	if game_manager.current_state == GameManager.STATE_RESULTS:
		live_sat = wave.get_average_satisfaction()
		live_lost = wave.lost_sales_count
	elif game_manager.current_state == GameManager.STATE_SIMULATION:
		live_lost = wave.lost_sales_count
	hud.set_wave_goals(
		game_manager.last_served if game_manager.current_state != GameManager.STATE_BUILD else 0,
		served_need,
		live_sat,
		live_lost,
		total
	)


func _on_stock_changed(_product_id: StringName, _warehouse: int, _ordered: int) -> void:
	store.refresh_warehouse_visuals(inventory.state.warehouse_stock)
	_refresh_stock_labels()


func _refresh_stock_labels() -> void:
	var warehouse_parts: PackedStringArray = []
	var transit_parts: PackedStringArray = []
	for product in [COLA, WATER, JUICE, CEREAL, CHIPS]:
		var short_name := str(WAREHOUSE_SHORT.get(product.id, product.display_name))
		warehouse_parts.append("%s %d" % [short_name, inventory.get_warehouse(product.id)])
		var ordered := inventory.get_ordered(product.id)
		if ordered > 0:
			transit_parts.append("%s %d" % [short_name, ordered])
	hud.set_warehouse_line("Warehouse: %s" % " · ".join(warehouse_parts))
	if transit_parts.is_empty():
		hud.set_in_transit_line("")
	else:
		hud.set_in_transit_line("In transit: %s" % " · ".join(transit_parts))
	_refresh_goals()
	_refresh_wave_preview()
	_refresh_delivery_bar()


func _refresh_delivery_bar() -> void:
	_refresh_clock()
	if inventory.pending_total() <= 0:
		hud.set_delivery("", 0.0)
		return
	var parts: PackedStringArray = []
	for product in [COLA, WATER, JUICE, CEREAL, CHIPS]:
		var ordered := inventory.get_ordered(product.id)
		if ordered <= 0:
			continue
		parts.append("%s %d" % [str(WAREHOUSE_SHORT.get(product.id, product.display_name)), ordered])
	var goods := " · ".join(parts)
	var eta := inventory.pending_eta_minutes()
	if eta < 0:
		eta = store_clock.eta_after_wave()
	var arrives := StoreClock.format_clock(eta)
	var state := game_manager.current_state
	if state == GameManager.STATE_SIMULATION:
		var ratio := 0.25 + 0.55 * customer_manager.wave_progress()
		hud.set_delivery("In transit: %s · Arrives %s" % [goods, arrives], ratio)
	elif state == GameManager.STATE_RESULTS:
		hud.set_delivery("Arriving %s — Continue to receive: %s" % [arrives, goods], 0.92)
	else:
		hud.set_delivery("Waiting to open store: %s · Arrives %s" % [goods, arrives], 0.2)


func _refresh_clock() -> void:
	var progress := 0.0
	if game_manager.current_state == GameManager.STATE_SIMULATION:
		progress = customer_manager.wave_progress()
	hud.set_clock(StoreClock.format_clock(store_clock.displayed_minutes(game_manager.current_state, progress)))


func _refresh_goals() -> void:
	var live := 0
	if game_manager.current_state == GameManager.STATE_SIMULATION:
		live = game_manager.last_served
	hud.set_goal_progress(store_manager.get_total_any_shelf_stock(), live)
	_refresh_hud_metrics()


func _refresh_wave_preview() -> void:
	var wave_n := game_manager.preview_wave_number()
	var size := CustomerManager.customers_for_wave(wave_n)
	var preview: Dictionary = customer_manager.preview_wave(size)
	var want_parts: PackedStringArray = []
	var shelf_parts: PackedStringArray = []
	var short_parts: PackedStringArray = []
	for row in preview.get("skus", []):
		var product_id: StringName = row.get("product_id", &"") as StringName
		var qty := int(row.get("qty", 0))
		var short_name := str(WAREHOUSE_SHORT.get(product_id, product_id))
		var on_shelf := store_manager.get_total_shelf_stock(product_id)
		want_parts.append("%s %d" % [short_name, qty])
		shelf_parts.append("%s %d" % [short_name, on_shelf])
		if on_shelf < qty:
			short_parts.append("%s %d/%d" % [short_name, on_shelf, qty])
	var heading := "This wave" if game_manager.current_state == GameManager.STATE_SIMULATION else "Next wave"
	hud.set_wave_number(game_manager.wave_number)
	var lines := PackedStringArray([
		"%s %d: %d customers · %d regular · %d impatient" % [
			heading,
			wave_n,
			int(preview.get("total", size)),
			int(preview.get("regular", 0)),
			int(preview.get("impatient", 0)),
		],
		"Want: %s" % " · ".join(want_parts),
		"On shelves: %s" % " · ".join(shelf_parts),
	])
	if short_parts.is_empty():
		lines.append("Coverage: shelves cover the lists")
	else:
		lines.append("Short on shelves: %s" % " · ".join(short_parts))
	hud.set_wave_preview("\n".join(lines))


func _on_order_requested() -> void:
	var catalog := store_manager.list_catalog()
	for row in catalog:
		var product_id: StringName = row.get("id", &"") as StringName
		row["warehouse"] = inventory.get_warehouse(product_id)
		row["ordered"] = inventory.get_ordered(product_id)
	hud.open_order_panel(catalog, _quote_order)


func _quote_order(product_id: StringName, qty: int, delivery_type: StringName) -> Dictionary:
	var quoted := inventory.quote_order(store_manager.get_product(product_id), qty, delivery_type)
	var warehouse := inventory.get_warehouse(product_id)
	var ordered := inventory.get_ordered(product_id)
	var after := warehouse + ordered + qty
	quoted["warehouse"] = warehouse
	quoted["ordered"] = ordered
	quoted["after"] = after
	var arrives := StoreClock.format_clock(store_clock.eta_after_wave())
	if delivery_type == &"express":
		quoted["eta_hint"] = "Express: arrives at the warehouse immediately."
	else:
		quoted["eta_hint"] = "Standard: arrives at %s (after the wave)." % arrives
	return quoted


func _on_order_confirmed(product_id: StringName, qty: int, delivery_type: StringName) -> void:
	var eta := store_clock.eta_after_wave() if delivery_type == &"standard" else -1
	var result := inventory.place_order(store_manager.get_product(product_id), qty, delivery_type, eta)
	if not bool(result.get("ok", false)):
		if result.get("reason", &"") == &"insufficient_cash":
			hud.show_message("Not enough cash (%.0f)." % float(result.get("cost", 0.0)))
		else:
			hud.show_message("Cannot place order.")
		return
	if delivery_type == &"express":
		hud.show_message("Express arrived at the warehouse.")
	_refresh_delivery_bar()


func _on_state_changed(new_state: StringName) -> void:
	hud.set_state(String(new_state))
	_refresh_delivery_bar()
	_refresh_wave_preview()


func _process(_delta: float) -> void:
	if game_manager.current_state == GameManager.STATE_SIMULATION:
		hud.set_queue_length(customer_manager.get_queue_length())
		var any_paying := false
		for q in customer_manager.queues:
			if q.is_paying():
				any_paying = true
				break
		staff_manager.set_cashier_busy(any_paying)
		_refresh_delivery_bar()
		_refresh_goals()
	else:
		staff_manager.set_cashier_busy(false)


func _on_results_ready(served: int, _cash_unused: float) -> void:
	var wave := customer_manager.wave
	var sat := wave.get_average_satisfaction()
	var lost := wave.lost_sales_count
	var total := wave.total_to_spawn
	var served_need := WaveRuntimeState.served_needed(total)
	var stars := WaveRuntimeState.count_stars(served, sat, lost, total)
	_stars_history.append(stars)
	hud.set_stars_history(_stars_history)
	hud.show_results(
		served,
		economy.get_cash(),
		total,
		lost,
		wave.lost_sales_value,
		sat,
		stars,
		WaveRuntimeState.served_star_ok(served, total),
		WaveRuntimeState.sat_star_ok(sat),
		WaveRuntimeState.lost_star_ok(lost),
		served_need,
		wave.lost_oos,
		wave.lost_queue,
		wave.lost_path
	)
	_refresh_goals()
	_refresh_hud_metrics()


func _on_open_store() -> void:
	var result := game_manager.open_store()
	if not result.ok:
		hud.show_message(result.reason)
		return
	_save_run()


func _on_continue_build() -> void:
	game_manager.return_to_build()
	store_clock.advance_wave()
	_refresh_clock()
	_save_run()


func _on_next_wave() -> void:
	var result := game_manager.next_wave()
	if not result.ok:
		hud.show_message(result.reason)


func _on_repeat_wave() -> void:
	var result := game_manager.repeat_wave()
	if not result.ok:
		hud.show_message(result.reason)


func _on_build_pressed() -> void:
	match game_manager.current_state:
		GameManager.STATE_BUILD:
			build_manager.open_place_picker()
		GameManager.STATE_RESULTS:
			_on_continue_build()
		GameManager.STATE_SIMULATION:
			hud.show_message("Finish the wave before building.")


func _on_staff_open() -> void:
	hud.show_staff_panel(
		staff_manager.get_worker_state(),
		staff_manager.worker_count(),
		staff_manager.get_cashier() != null,
		staff_manager.auto_fill_preference
	)


func _on_upgrades_open() -> void:
	hud.show_upgrades_panel(_upgrade_rows(), economy.get_cash())


func _on_staff_auto_fill(enabled: bool) -> void:
	staff_manager.set_auto_fill_preference(enabled)
	if game_manager.current_state == GameManager.STATE_SIMULATION:
		staff_manager.set_auto_fill_empties(true)


func _on_staff_restock() -> void:
	var queued := staff_manager.queue_empty_shelves()
	if queued > 0:
		hud.show_message("Queued empty shelves.")
	elif staff_manager.has_any_warehouse():
		hud.show_message("No empty shelves to fill.")
	else:
		hud.show_message("Warehouse is empty.")


func _on_upgrade_buy(id: StringName) -> void:
	var result := upgrades.buy(id, economy)
	if not bool(result.get("ok", false)):
		if result.get("reason", &"") == &"insufficient_cash":
			hud.show_message("Not enough cash.")
		else:
			hud.show_message("Upgrade not available.")
		return
	upgrades.apply(staff_manager, customer_manager, WORKER_SCENE, _place_upgrade_worker, CASHIER_SCENE)
	_save_run()
	hud.show_upgrades_panel(_upgrade_rows(), economy.get_cash())
	hud.show_message("Upgrade purchased.")


func _upgrade_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for row in upgrades.catalog():
		var copy: Dictionary = row.duplicate()
		copy["owned"] = upgrades.has_upgrade(row.get("id", &""))
		rows.append(copy)
	return rows


func _on_menu() -> void:
	_save_run()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _place_worker_in_shop(worker: WorkerController, slot: int = 0) -> void:
	if worker == null:
		return
	worker.global_position = Vector3(float(slot) * 1.2, 0.0, -4.6)
	worker.rotation.y = deg_to_rad(180.0)


func _place_upgrade_worker(worker: WorkerController) -> void:
	_place_worker_in_shop(worker, staff_manager.worker_count() - 1)


func _save_run() -> void:
	RunSave.write_snapshot({
		"cash": economy.get_cash(),
		"start_cash": _start_cash,
		"auto_fill": staff_manager.auto_fill_preference,
		"owned": upgrades.owned_ids(),
		"warehouse": inventory.state.warehouse_stock.duplicate(),
		"ordered": inventory.state.ordered_stock.duplicate(),
		"pending": inventory.state.pending_deliveries.duplicate(true),
		"fixtures": store_manager.export_layout(),
		"wave_number": game_manager.wave_number,
		"clock_minutes": store_clock.minutes,
		"stars_history": _stars_history.duplicate(),
	})


func _load_run() -> bool:
	if not RunSave.exists():
		return false
	var data := RunSave.read_snapshot()
	if data.is_empty():
		return false
	_start_cash = float(data.get("start_cash", STARTING_CASH))
	economy.setup(float(data.get("cash", STARTING_CASH)))
	staff_manager.set_auto_fill_preference(bool(data.get("auto_fill", false)))
	upgrades.load_owned(data.get("owned", PackedStringArray()))
	game_manager.wave_number = maxi(1, int(data.get("wave_number", 1)))
	store_clock.minutes = int(data.get("clock_minutes", StoreClock.OPEN_MINUTES))
	_stars_history.clear()
	for value in data.get("stars_history", []):
		_stars_history.append(int(value))
	var warehouse: Dictionary = data.get("warehouse", {})
	for product in [COLA, WATER, JUICE, CEREAL, CHIPS]:
		inventory.seed_warehouse(product.id, int(warehouse.get(product.id, 0)))
	inventory.state.ordered_stock.clear()
	var ordered: Dictionary = data.get("ordered", {})
	for key in ordered.keys():
		inventory.state.ordered_stock[key] = int(ordered[key])
	inventory.state.pending_deliveries.clear()
	for row in data.get("pending", []):
		inventory.state.pending_deliveries.append(row)
	var fixtures: Array = data.get("fixtures", [])
	if fixtures.is_empty():
		return false
	for row in fixtures:
		var definition := store_manager.get_fixture_definition(row.get("definition_id", &""))
		if definition == null:
			continue
		var pos := Vector3(float(row.get("x", 0.0)), 0.0, float(row.get("z", 0.0)))
		var rot := float(row.get("rot", 0.0))
		var instance_id := build_manager.place_fixture_at(pos, rot, definition, false, false)
		if instance_id == &"":
			continue
		for shelf in row.get("shelves", []):
			var product_id := StringName(str(shelf.get("product_id", "")))
			if product_id == &"":
				continue
			store_manager.assign_product_to_shelf(
				instance_id,
				int(shelf.get("index", 0)),
				product_id,
				int(shelf.get("stock", 0)),
				int(shelf.get("facings", -1))
			)
	store.rebake_navigation()
	store.refresh_warehouse_visuals(inventory.state.warehouse_stock)
	GameLog.info("STORE", "Loaded run: %d fixtures" % store_manager.runtime.size())
	return not store_manager.runtime.is_empty()
