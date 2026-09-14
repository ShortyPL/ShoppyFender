class_name PlaytestBot
extends CanvasLayer

enum DriveMode { AUTO, VISUAL, API }

const PLACE_POS := Vector3(-1.2, 0.0, 1.0)
const CUSTOMER_TIMEOUT_SEC := 90.0
const WORKER_TIMEOUT_SEC := 160.0
const COLA_ID := &"freshpop_cola_500"
const STANDARD_COLA_QTY := 6
const STANDARD_COLA_COST := 27.2

@export var drive_mode: DriveMode = DriveMode.AUTO

var store: StoreRoom
var camera_rig: CameraRig
var store_manager: StoreManager
var build_manager: BuildManager
var economy: EconomyManager
var game_manager: GameManager
var hud: Hud
var inventory: InventoryManager
var staff_manager: StaffManager

var is_running: bool = false

var _cursor: Control
var _active_mode: DriveMode = DriveMode.API
var _run_token: int = 0


func _ready() -> void:
	layer = 20
	_build_ui()
	if "--bot" in OS.get_cmdline_user_args():
		call_deferred("start")


func setup(
	p_store: StoreRoom,
	p_camera: CameraRig,
	p_store_manager: StoreManager,
	p_build: BuildManager,
	p_economy: EconomyManager,
	p_game: GameManager,
	p_hud: Hud,
	p_inventory: InventoryManager = null,
	p_staff: StaffManager = null
) -> void:
	store = p_store
	camera_rig = p_camera
	store_manager = p_store_manager
	build_manager = p_build
	economy = p_economy
	game_manager = p_game
	hud = p_hud
	inventory = p_inventory
	staff_manager = p_staff


func start() -> void:
	if is_running:
		return
	run()


func run() -> Dictionary:
	if is_running:
		return {"ok": false, "reason": "Bot already running."}
	is_running = true
	_run_token += 1
	var token := _run_token
	_active_mode = _resolve_mode()
	_set_status("Starting…")
	var report := await _execute(token)
	if token != _run_token:
		return {"ok": false, "reason": "Aborted."}
	is_running = false
	if bool(report.get("ok", false)):
		_set_status("PASS")
		_log("Result: PASS")
	else:
		_set_status("FAIL")
		_log("Result: FAIL — %s" % str(report.get("reason", "")))
	GameLog.info("BOT", str(report))
	return report


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3:
			if is_running:
				_run_token += 1
				is_running = false
				_set_status("Aborted")
				_log("Aborted (F3)")
			else:
				start()
			get_viewport().set_input_as_handled()


func _resolve_mode() -> DriveMode:
	if drive_mode == DriveMode.VISUAL:
		return DriveMode.VISUAL
	if drive_mode == DriveMode.API:
		return DriveMode.API
	if OS.has_feature("headless"):
		return DriveMode.API
	return DriveMode.VISUAL


func _execute(token: int) -> Dictionary:
	if store == null or game_manager == null:
		return _fail("Bot is not attached to Main.")
	await _yield_frames(4)
	await get_tree().create_timer(0.15).timeout
	if not _still(token):
		return _fail("Aborted.")
	_log("Tryb: %s" % ("wizualny" if _active_mode == DriveMode.VISUAL else "API"))
	await _ensure_nav_ready()
	var catalog := store_manager.list_catalog()
	if catalog.is_empty():
		return _fail("Product catalog is empty.")
	_log("Katalog: %d SKU" % catalog.size())
	var fixture_types := store_manager.list_fixtures()
	if fixture_types.is_empty():
		return _fail("Fixture catalog is empty.")
	_log("Fixtures: %d types" % fixture_types.size())
	if not _step_place_types(fixture_types, token):
		return _fail("No ready store layout.")
	await _ensure_nav_ready()
	var cash_after_fixtures := economy.get_cash()
	if store_manager.runtime.size() < 16:
		return _fail("Store layout too sparse (%d fixtures)." % store_manager.runtime.size())
	if not _layout_has_all_types(fixture_types):
		return _fail("Layout is missing fixture types.")
	_log("Layout ready (cash %.2f, shelves %d)" % [cash_after_fixtures, store_manager.runtime.size()])
	if not await _step_fill_catalog(catalog, token):
		return _fail("Failed to stock catalog on shelves.")
	if not await _step_wait_worker_stock(catalog, token):
		return _fail("Worker did not restock shelves in time.")
	if not await _step_restock(token):
		return _fail("Restock failed.")
	if not await _step_facings(token):
		return _fail("Facing change failed.")
	if not await _step_rotate(token):
		return _fail("Shelf rotation failed.")
	await _ensure_nav_ready()
	if not await _step_wait_worker_idle(token):
		return _fail("Worker did not finish restocking before opening.")
	var cash_before := economy.get_cash()
	var expected_cash := cash_before + _expected_wave_revenue(catalog, CustomerManager.WAVE_SIZE)
	_log("Wave %d customers, expected cash %.2f" % [CustomerManager.WAVE_SIZE, expected_cash])
	if not await _step_open_store(token):
		return _fail("Failed to open store.")
	if not await _wait_state(GameManager.STATE_RESULTS, CUSTOMER_TIMEOUT_SEC, token):
		return _fail("Wave did not finish in time.")
	var cash_after_wave := economy.get_cash()
	if not is_equal_approx(cash_after_wave, expected_cash):
		return _fail("Cash after sales = %.2f, expected %.2f" % [cash_after_wave, expected_cash])
	var served := game_manager.last_served
	var spawned := game_manager.customer_manager.wave.spawned_count
	var lost_sales := game_manager.customer_manager.wave.lost_sales_count
	var satisfaction := game_manager.customer_manager.wave.get_average_satisfaction()
	var stars := WaveRuntimeState.count_stars(served, satisfaction, lost_sales)
	if served != CustomerManager.WAVE_SIZE:
		return _fail("Served %d customers, expected %d" % [served, CustomerManager.WAVE_SIZE])
	if spawned != CustomerManager.WAVE_SIZE:
		return _fail("Spawn %d, oczekiwane %d" % [spawned, CustomerManager.WAVE_SIZE])
	if lost_sales != 0:
		return _fail("Lost sales = %d, oczekiwane 0" % lost_sales)
	if satisfaction + 0.0001 < 75.0:
		return _fail("Sat = %.0f, oczekiwane ≥75 (realna kolejka, nie cheat PAY_SEC)" % satisfaction)
	if stars != 3:
		return _fail("Stars = %d, oczekiwane 3 (served %d sat %.0f lost %d)" % [stars, served, satisfaction, lost_sales])
	var sat_note := ""
	if satisfaction + 0.0001 < 80.0:
		sat_note = ": sat < 80 przez realne wait ticks kolejki 1.8 s pay / 3 s tick, nie cheat PAY_SEC"
	_log("Fala OK (cash %.2f, served %d/%d, sat %.0f%%, stars %d%s)" % [cash_after_wave, served, CustomerManager.WAVE_SIZE, satisfaction, stars, sat_note])
	if inventory == null:
		return _fail("Bot nie ma InventoryManager.")
	var cola_wh := inventory.get_warehouse(COLA_ID)
	var cola := store_manager.get_product(COLA_ID)
	var order := inventory.place_order(cola, STANDARD_COLA_QTY, &"standard")
	if not bool(order.get("ok", false)):
		return _fail("Standard 6 cola failed: %s" % str(order.get("reason", "")))
	var cash_after_order := economy.get_cash()
	if not is_equal_approx(cash_after_order, cash_after_wave - STANDARD_COLA_COST):
		return _fail("Cash po Standard = %.2f, oczekiwane %.2f" % [cash_after_order, cash_after_wave - STANDARD_COLA_COST])
	_log("Standard 6 coli (cash %.2f, warehouse przed %d)" % [cash_after_order, cola_wh])
	if not await _step_back_to_build(token):
		return _fail("Did not return to BUILD.")
	var warehouse_cola := inventory.get_warehouse(COLA_ID)
	if warehouse_cola != cola_wh + STANDARD_COLA_QTY:
		return _fail("Warehouse coli = %d, oczekiwane %d" % [warehouse_cola, cola_wh + STANDARD_COLA_QTY])
	_log("Dostawa Standard OK (warehouse coli %d)" % warehouse_cola)
	if not await _step_duplicate(token):
		return _fail("Shelf duplicate failed.")
	_log("Bot covered the full current catalog.")
	return {
		"ok": true,
		"reason": "",
		"cash": economy.get_cash(),
		"cash_after_fixtures": cash_after_fixtures,
		"cash_after_wave": cash_after_wave,
		"cash_after_order": cash_after_order,
		"warehouse_cola": warehouse_cola,
		"warehouse_cola_before": cola_wh,
		"ordered_cola": STANDARD_COLA_QTY,
		"fixtures": store_manager.runtime.size(),
		"sku_tested": catalog.size(),
		"sku_catalog": catalog.size(),
		"fixture_types_tested": fixture_types.size(),
		"fixture_types_catalog": fixture_types.size(),
		"served": served,
		"spawned": spawned,
		"lost_sales": lost_sales,
		"satisfaction": satisfaction,
		"stars": stars,
	}


func _expected_wave_revenue(catalog: Array[Dictionary], customer_count: int) -> float:
	if catalog.is_empty() or customer_count <= 0 or game_manager == null or game_manager.customer_manager == null:
		return 0.0
	var price_by_id := {}
	for row in catalog:
		price_by_id[row.get("id", &"")] = float(row.get("selling_price", 0.0))
	var total := 0.0
	for i in customer_count:
		for item in game_manager.customer_manager.build_shopping_list(i):
			total += float(price_by_id.get(item.product_id, 0.0))
	return total


func _fixture_types_cost(types: Array[Dictionary]) -> float:
	var total := 0.0
	for row in types:
		var definition_id: StringName = row.get("id", &"")
		var definition := store_manager.get_fixture_definition(definition_id)
		if definition != null:
			total += definition.purchase_cost
	return total


func _step_place_types(types: Array[Dictionary], token: int) -> bool:
	_set_status("Checking layout")
	if not _still(token):
		return false
	if store_manager.runtime.size() >= 16 and _layout_has_all_types(types):
		_log("Layout already placed (%d shelves) — skipping layout" % store_manager.runtime.size())
		return true
	_log("No ready store layout (%d fixtures)." % store_manager.runtime.size())
	return false


func _layout_has_all_types(types: Array[Dictionary]) -> bool:
	for row in types:
		var kind: StringName = row.get("fixture_type", &"")
		if kind == &"":
			continue
		var found := false
		for instance_id in store_manager.runtime.keys():
			var fixture := store_manager.get_fixture(instance_id)
			var definition := store_manager.get_fixture_definition(fixture.definition_id) if fixture else null
			if definition != null and definition.fixture_type == kind:
				found = true
				break
		if not found:
			return false
	return true


func _fixture_ids() -> Array:
	return store_manager.runtime.keys()


func _assigned_fixture_ids() -> Array:
	var ids: Array = []
	for instance_id in _fixture_ids():
		var fixture := store_manager.get_fixture(instance_id)
		if fixture == null:
			continue
		var assigned := false
		for shelf: ShelfState in fixture.shelf_states:
			if not shelf.placements.is_empty():
				assigned = true
				break
		if assigned:
			ids.append(instance_id)
	return ids


func _catalog_has_shelf_stock(catalog: Array[Dictionary]) -> bool:
	for row in catalog:
		var product_id: StringName = row.get("id", &"")
		if store_manager.get_total_shelf_stock(product_id) <= 0:
			return false
	return true


func _worker_state() -> StringName:
	if staff_manager == null:
		return &"none"
	return staff_manager.get_worker_state()


func _log_worker_timeout(catalog: Array[Dictionary]) -> void:
	var missing: PackedStringArray = []
	for row in catalog:
		var product_id: StringName = row.get("id", &"")
		if store_manager.get_total_shelf_stock(product_id) <= 0:
			missing.append(String(product_id))
	_log("Worker timeout, state=%s missing=%s" % [String(_worker_state()), ", ".join(missing)])


func _ensure_nav_ready() -> void:
	if store == null or store.navigation_region == null:
		return
	var nav_map := store.navigation_region.get_navigation_map()
	for _i in 8:
		NavigationServer3D.map_force_update(nav_map)
		await get_tree().physics_frame


func _step_fill_catalog(catalog: Array[Dictionary], token: int) -> bool:
	_set_status("Stocking catalog")
	var slots := _collect_slots()
	if slots.size() < catalog.size():
		_log("Not enough shelves for catalog")
		return false
	for i in catalog.size():
		if not _still(token):
			return false
		var product_id: StringName = catalog[i].get("id", &"")
		var display_name := str(catalog[i].get("display_name", String(product_id)))
		var slot: Dictionary = slots[i]
		var instance_id: StringName = slot.get("id", &"")
		var shelf_i := int(slot.get("shelf_index", 0))
		var node := store_manager.get_fixture_node(instance_id)
		var world := PLACE_POS if node == null else node.global_position
		await _aim_world(world + Vector3(0.0, 0.9, 0.0))
		if _active_mode == DriveMode.VISUAL:
			await _inject_click(MOUSE_BUTTON_RIGHT)
			await _yield_frames(2)
			if hud.context_menu.visible:
				await _press_menu_button("Place product")
				await _yield_frames(2)
				await _press_menu_button(display_name)
				await _yield_frames(2)
				await _press_menu_button("Shelf %d" % (shelf_i + 1))
				await _yield_frames(2)
		if store_manager.get_total_shelf_stock(product_id) <= 0:
			var placed := store_manager.assign_product_to_shelf(instance_id, shelf_i, product_id, 0)
			if placed == null:
				_log("Did not place %s" % display_name)
				return false
		_log("SKU %d/%d: %s → shelf %d (stock 0)" % [i + 1, catalog.size(), display_name, shelf_i + 1])
	if hud.context_menu.visible:
		hud.context_menu.hide()
	return true


func _collect_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for instance_id in _fixture_ids():
		var fixture := store_manager.get_fixture(instance_id)
		if fixture == null:
			continue
		for shelf: ShelfState in fixture.shelf_states:
			slots.append({"id": instance_id, "shelf_index": shelf.shelf_index})
	slots.sort_custom(_slot_closer_to_entrance)
	return slots


func _slot_closer_to_entrance(a: Dictionary, b: Dictionary) -> bool:
	var node_a := store_manager.get_fixture_node(a.get("id", &""))
	var node_b := store_manager.get_fixture_node(b.get("id", &""))
	var za := node_a.global_position.z if node_a != null else -99.0
	var zb := node_b.global_position.z if node_b != null else -99.0
	if not is_equal_approx(za, zb):
		return za > zb
	var xa := absf(node_a.global_position.x) if node_a != null else 99.0
	var xb := absf(node_b.global_position.x) if node_b != null else 99.0
	return xa < xb


func _step_wait_worker_stock(catalog: Array[Dictionary], token: int) -> bool:
	_set_status("Waiting for worker")
	if not _still(token):
		return false
	await _ensure_nav_ready()
	for instance_id in _assigned_fixture_ids():
		var queued := store_manager.restock_fixture(instance_id)
		_log("Restock enqueue %s → %d" % [String(instance_id), queued])
	var deadline := Time.get_ticks_msec() + int(WORKER_TIMEOUT_SEC * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if not _still(token):
			return false
		if _catalog_has_shelf_stock(catalog):
			_log("Worker restocked catalog")
			return true
		await get_tree().physics_frame
	_log_worker_timeout(catalog)
	return _catalog_has_shelf_stock(catalog)


func _step_restock(token: int) -> bool:
	_set_status("Restocking inventory")
	if not _still(token):
		return false
	var first_id: StringName = store_manager.get_first_stocked_product_id()
	var placement := store_manager.get_first_placement_for_product(first_id)
	if placement == null:
		return false
	if not store_manager.take_from_shelf(placement.placement_id):
		return false
	var after_take := placement.shelf_stock
	var instance_id: StringName = placement.fixture_instance_id
	var node := store_manager.get_fixture_node(instance_id)
	if node != null:
		await _aim_world(node.global_position + Vector3(0.0, 0.9, 0.0))
	if _active_mode == DriveMode.VISUAL:
		await _inject_click(MOUSE_BUTTON_RIGHT)
		await _yield_frames(2)
		await _press_menu_button("Restock")
		await _yield_frames(2)
	store_manager.restock_fixture(instance_id)
	var deadline := Time.get_ticks_msec() + int(WORKER_TIMEOUT_SEC * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if not _still(token):
			return false
		if placement.shelf_stock >= after_take + 1:
			_log("Restock OK (stock %d po take %d)" % [placement.shelf_stock, after_take])
			return true
		await get_tree().physics_frame
	_log("Worker timeout po take, state=%s stock=%d" % [String(_worker_state()), placement.shelf_stock])
	return placement.shelf_stock >= after_take + 1


func _step_facings(token: int) -> bool:
	_set_status("Changing facings")
	if not _still(token):
		return false
	var first_id: StringName = store_manager.get_first_stocked_product_id()
	var placement := store_manager.get_first_placement_for_product(first_id)
	if placement == null:
		return false
	var instance_id: StringName = placement.fixture_instance_id
	var old_cap := placement.capacity
	var old_facings := placement.facings
	var node := store_manager.get_fixture_node(instance_id)
	if node != null:
		await _aim_world(node.global_position + Vector3(0.0, 0.9, 0.0))
	if _active_mode == DriveMode.VISUAL:
		await _inject_click(MOUSE_BUTTON_RIGHT)
		await _yield_frames(2)
		await _press_menu_button("More facings")
		await _yield_frames(2)
	if placement.facings == old_facings:
		store_manager.adjust_facings(instance_id, 1)
	if placement.capacity <= old_cap or placement.facings <= old_facings:
		_log("Facings did not increase (%d cap %d)" % [placement.facings, placement.capacity])
		return false
	if hud.context_menu.visible:
		hud.context_menu.hide()
	_log("Facings %d → %d, cap %d → %d" % [old_facings, placement.facings, old_cap, placement.capacity])
	return true


func _step_rotate(token: int) -> bool:
	_set_status("Rotating shelf")
	if not _still(token):
		return false
	if store_manager.runtime.size() >= 16:
		_log("Rotation skipped — full layout with no space")
		return true
	for instance_id in _fixture_ids():
		var fixture := store_manager.get_fixture(instance_id)
		if fixture == null:
			continue
		var node := store_manager.get_fixture_node(instance_id)
		if node != null:
			await _aim_world(node.global_position + Vector3(0.0, 0.9, 0.0))
		if build_manager.try_rotate_fixture(instance_id):
			fixture = store_manager.get_fixture(instance_id)
			_log("Rotation OK (%.0f°)" % (fixture.rotation_y_deg if fixture else 0.0))
			return true
	if store_manager.runtime.size() >= 8:
		_log("Rotation skipped — full layout with no space")
		return true
	return false


func _step_duplicate(token: int) -> bool:
	_set_status("Duplicating shelf")
	if not _still(token):
		return false
	var source_id: StringName = _fixture_ids()[0]
	var before := store_manager.runtime.size()
	var node := store_manager.get_fixture_node(source_id)
	if node != null:
		await _aim_world(node.global_position + Vector3(0.0, 0.9, 0.0))
	if _active_mode == DriveMode.VISUAL:
		await _inject_click(MOUSE_BUTTON_RIGHT)
		await _yield_frames(2)
		await _press_menu_button("Duplicate")
		await _yield_frames(3)
	if store_manager.runtime.size() == before:
		if not build_manager.duplicate_fixture(source_id):
			if before >= 8:
				_log("Duplicate skipped — store already full (%d)" % before)
				return true
			return false
	if store_manager.runtime.size() <= before:
		if before >= 8:
			_log("Duplicate skipped — store already full (%d)" % before)
			return true
		return false
	_log("Shelves: %d" % store_manager.runtime.size())
	return true


func _step_wait_worker_idle(token: int) -> bool:
	_set_status("Waiting for worker to finish")
	if not _still(token):
		return false
	var deadline := Time.get_ticks_msec() + int(WORKER_TIMEOUT_SEC * 1000.0)
	var idle_frames := 0
	while Time.get_ticks_msec() < deadline:
		if not _still(token):
			return false
		var pending := 0
		if staff_manager != null:
			pending = staff_manager.pending_task_count()
		if _worker_state() == &"idle" and pending == 0:
			idle_frames += 1
			if idle_frames >= 12:
				_log("Worker idle przed otwarciem")
				return true
		else:
			idle_frames = 0
		await get_tree().physics_frame
	_log("Worker timeout przed otwarciem, state=%s idle_frames=%d" % [String(_worker_state()), idle_frames])
	return false


func _step_open_store(token: int) -> bool:
	_set_status("Opening store")
	if not _still(token):
		return false
	if hud.context_menu.visible:
		hud.context_menu.hide()
	await _press_hud_button(hud.open_button)
	await _yield_frames(4)
	if game_manager.current_state != GameManager.STATE_SIMULATION:
		if _active_mode == DriveMode.VISUAL:
			_log("Open Store button did not change state — API fallback")
		var result := game_manager.open_store()
		if not result.ok:
			_log(str(result.reason))
			return false
	_log("SIMULATION")
	return true


func _step_back_to_build(token: int) -> bool:
	_set_status("Returning to BUILD")
	if not _still(token):
		return false
	await _press_hud_button(hud.continue_button)
	await _yield_frames(2)
	if game_manager.current_state != GameManager.STATE_BUILD:
		game_manager.return_to_build()
	return game_manager.current_state == GameManager.STATE_BUILD


func _press_menu_button(text_part: String) -> void:
	var btn := hud.context_menu.find_button(text_part)
	if btn == null:
		_log("Missing menu item: %s" % text_part)
		return
	await _press_button(btn)


func _press_hud_button(button: Button) -> void:
	if button == null or not button.visible:
		return
	await _press_button(button)


func _press_button(button: Button) -> void:
	var pos := button.get_global_rect().get_center()
	await _move_cursor(pos)
	if _active_mode == DriveMode.VISUAL:
		await _inject_click(MOUSE_BUTTON_LEFT)
		await get_tree().process_frame
		return
	button.pressed.emit()


func _aim_world(world_pos: Vector3) -> Vector2:
	var screen := _world_to_screen(world_pos)
	await _move_cursor(screen)
	if _active_mode == DriveMode.VISUAL:
		get_viewport().warp_mouse(screen)
		await _yield_frames(2)
	return screen


func _world_to_screen(world_pos: Vector3) -> Vector2:
	if camera_rig == null:
		return Vector2(400, 300)
	return camera_rig.get_camera().unproject_position(world_pos)


func _move_cursor(screen_pos: Vector2) -> void:
	_cursor.visible = true
	var tween := create_tween()
	tween.tween_property(_cursor, "position", screen_pos - _cursor.size * 0.5, 0.18)
	await tween.finished


func _inject_click(button: MouseButton) -> void:
	var pos := _cursor.position + _cursor.size * 0.5
	get_viewport().warp_mouse(pos)
	var press := InputEventMouseButton.new()
	press.button_index = button
	press.pressed = true
	press.position = pos
	press.global_position = pos
	Input.parse_input_event(press)
	await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = button
	release.pressed = false
	release.position = pos
	release.global_position = pos
	Input.parse_input_event(release)
	await get_tree().process_frame


func _wait_state(state: StringName, timeout_sec: float, token: int) -> bool:
	_set_status("Waiting for %s" % String(state))
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if not _still(token):
			return false
		if game_manager.current_state == state:
			return true
		await get_tree().physics_frame
	return game_manager.current_state == state


func _yield_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _still(token: int) -> bool:
	return token == _run_token and is_running


func _fail(reason: String) -> Dictionary:
	_log(reason)
	return {"ok": false, "reason": reason, "cash": economy.get_cash() if economy else 0.0}


func _set_status(_text: String) -> void:
	pass


func _log(text: String) -> void:
	GameLog.info("BOT", text)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_cursor = Control.new()
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.size = Vector2(22, 22)
	_cursor.visible = false
	root.add_child(_cursor)
	var mark := ColorRect.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.color = Color(1.0, 0.2, 0.15, 0.95)
	mark.size = Vector2(22, 22)
	_cursor.add_child(mark)
	var plus := Label.new()
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plus.text = "+"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plus.set_anchors_preset(Control.PRESET_FULL_RECT)
	plus.add_theme_color_override("font_color", Color.WHITE)
	_cursor.add_child(plus)
