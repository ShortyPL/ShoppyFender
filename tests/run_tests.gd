extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("ShopyFender Prototype 0.04 tests")
	var failures := 0
	print("Economy")
	failures += TestEconomy.run()
	print("Inventory")
	failures += TestInventory.run()
	print("Staff")
	failures += TestStaff.run()
	print("Upgrades")
	failures += TestUpgrades.run()
	print("Run save")
	failures += TestRunSave.run()
	print("Wave snapshot")
	failures += TestWaveSnapshot.run()
	print("Shelf stock")
	failures += TestShelfStock.run()
	print("Product catalog")
	failures += TestProductCatalog.run()
	print("Fixture catalog")
	failures += TestFixtureCatalog.run()
	print("Wave lists")
	failures += TestWaveLists.run()
	print("Checkout queue")
	failures += TestCheckoutQueue.run()
	print("Multi lane")
	failures += TestMultiLane.run()
	print("Characters")
	failures += TestFunnyHuman.run()
	print("Store layout")
	failures += TestStoreLayout.run()
	print("Main menu")
	failures += TestMainMenu.run()
	failures += await _test_main_menu_scene()
	print("Store navigation")
	failures += await _test_store_navigation()
	print("Context menu")
	failures += await _test_context_menu()
	print("Results stars")
	failures += await _test_results_stars()
	print("HUD chrome")
	failures += await _test_hud_chrome()
	print("Playtest bot")
	failures += await _test_playtest_bot()
	if failures == 0:
		print("All tests passed.")
	else:
		print("Failures: %d" % failures)
	quit(failures)


func _test_main_menu_scene() -> int:
	RunSave.clear()
	var menu_scene: PackedScene = load("res://scenes/ui/MainMenu.tscn")
	var menu: MainMenu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	if menu.find_child("Store", true, false) != null:
		print("  FAIL  3D store still in menu")
		menu.queue_free()
		return 1
	if menu.find_child("Camera3D", true, false) != null:
		print("  FAIL  3D camera still in menu")
		menu.queue_free()
		return 1
	if menu.background == null or menu.background.texture == null:
		print("  FAIL  background texture")
		menu.queue_free()
		return 1
	if menu.new_game_button == null or menu.new_game_button.text != "New Game":
		print("  FAIL  new game button")
		menu.queue_free()
		return 1
	if menu.continue_button == null or menu.continue_button.text != "Continue":
		print("  FAIL  continue label")
		menu.queue_free()
		return 1
	if not menu.continue_button.disabled:
		print("  FAIL  continue should be disabled")
		menu.queue_free()
		return 1
	if menu.continue_button.tooltip_text != "No saved game":
		print("  FAIL  continue tooltip")
		menu.queue_free()
		return 1
	if menu.settings_button.text != "Settings" or menu.help_button.text != "Help" or menu.quit_button.text != "Quit":
		print("  FAIL  menu button labels")
		menu.queue_free()
		return 1
	if menu.new_game_button.disabled or menu.settings_button.disabled or menu.help_button.disabled or menu.quit_button.disabled:
		print("  FAIL  primary buttons should be enabled")
		menu.queue_free()
		return 1
	if menu.version_label == null or menu.version_label.text != "v0.05":
		print("  FAIL  version label")
		menu.queue_free()
		return 1
	var logo_backing := menu.get_node_or_null("LogoBacking") as Control
	var menu_column_backing := menu.get_node_or_null("MenuColumnBacking") as Control
	var menu_column := menu.get_node_or_null("MenuColumn") as Control
	var version_backing := menu.get_node_or_null("VersionBacking") as Control
	if logo_backing == null or not logo_backing.get_global_rect().encloses(Rect2(38, 0, 596, 232)):
		print("  FAIL  logo backing covers baked logo and tagline")
		menu.queue_free()
		return 1
	# Baked English UI bounds at 1280×720 from the 1024×576 still ×1.25.
	var baked_menu_buttons := Rect2(52, 271, 286, 337)
	if menu_column_backing == null or not menu_column_backing.get_global_rect().encloses(baked_menu_buttons):
		print("  FAIL  menu column backing covers baked English buttons")
		menu.queue_free()
		return 1
	if menu_column == null or not menu_column.get_global_rect().encloses(baked_menu_buttons):
		print("  FAIL  menu column covers baked English buttons")
		menu.queue_free()
		return 1
	if version_backing == null or not version_backing.get_global_rect().encloses(Rect2(1214, 686, 40, 10)):
		print("  FAIL  version backing covers baked version")
		menu.queue_free()
		return 1
	menu._show_help()
	if not menu.help_panel.visible or menu.new_game_button.is_visible_in_tree():
		print("  FAIL  help panel opens")
		menu.queue_free()
		return 1
	var cancel_event := InputEventAction.new()
	cancel_event.action = &"ui_cancel"
	cancel_event.pressed = true
	menu._unhandled_input(cancel_event)
	if menu.settings_panel.visible or menu.help_panel.visible or not menu_column.is_visible_in_tree() or not menu.new_game_button.is_visible_in_tree():
		print("  FAIL  Esc returns to root menu")
		menu.queue_free()
		return 1
	menu._show_settings()
	if not menu.settings_panel.visible or menu.help_panel.visible:
		print("  FAIL  settings panel opens")
		menu.queue_free()
		return 1
	menu._show_root()
	if menu.settings_panel.visible or not menu.new_game_button.is_visible_in_tree():
		print("  FAIL  root menu returns")
		menu.queue_free()
		return 1
	print("  PASS  main menu buttons and panels")
	menu.queue_free()
	return 0


func _test_store_navigation() -> int:
	var store_scene: PackedScene = load("res://scenes/store/Store.tscn")
	var store: StoreRoom = store_scene.instantiate()
	root.add_child(store)
	await physics_frame
	await physics_frame
	await create_timer(0.15).timeout
	var mesh: NavigationMesh = store.navigation_region.navigation_mesh
	if mesh == null or mesh.get_polygon_count() <= 0:
		print("  FAIL  navigation mesh has polygons")
		store.queue_free()
		return 1
	print("  PASS  navigation mesh has polygons (%d)" % mesh.get_polygon_count())
	if store.get_node_or_null("Exterior/StoreSign") == null or store.get_node_or_null("Decor/EntranceGlass") == null:
		print("  FAIL  storefront sign and glass")
		store.queue_free()
		return 1
	print("  PASS  storefront sign and glass")
	var nav_map := store.navigation_region.get_navigation_map()
	var path := await _wait_nav_path(nav_map, store.get_entrance_position(), store.get_checkout_position())
	if path.size() < 2:
		print("  FAIL  path from entrance to checkout")
		store.queue_free()
		return 1
	print("  PASS  path from entrance to checkout (%d points)" % path.size())
	var gondola_scene: PackedScene = load("res://scenes/fixtures/Gondola.tscn")
	var gondola: Node3D = gondola_scene.instantiate()
	store.fixtures_root.add_child(gondola)
	gondola.global_position = Vector3(0.0, 0.0, 0.0)
	store.rebake_navigation()
	path = await _wait_nav_path(nav_map, store.get_entrance_position(), store.get_checkout_position())
	if path.size() < 2:
		print("  FAIL  path after placing gondola")
		store.queue_free()
		return 1
	print("  PASS  path after placing gondola (%d points)" % path.size())
	var pick: Vector3 = store.get_backroom_pick_position()
	var worker_path := await _wait_nav_path(nav_map, pick, Vector3(0.0, 0.0, 0.0))
	if worker_path.size() < 2:
		print("  FAIL  path from backroom to gondola")
		store.queue_free()
		return 1
	print("  PASS  path from backroom to gondola (%d points)" % worker_path.size())
	var slot3: Vector3 = store.get_queue_slot_position(3)
	var queue_path := await _wait_nav_path(nav_map, slot3, store.get_checkout_position())
	if queue_path.size() < 2:
		print("  FAIL  path from queue slot 3 to checkout")
		store.queue_free()
		return 1
	print("  PASS  path from queue slot 3 to checkout (%d points)" % queue_path.size())
	store.queue_free()
	return 0


func _test_context_menu() -> int:
	var hud_scene: PackedScene = load("res://scenes/ui/Hud.tscn")
	var hud: Hud = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	var menu := hud.context_menu
	if menu == null or not (menu is PanelContainer):
		print("  FAIL  context menu is a PanelContainer in the HUD")
		hud.queue_free()
		return 1
	if not menu.is_inside_tree():
		print("  FAIL  context menu is inside the tree")
		hud.queue_free()
		return 1
	menu.open_for_floor(Vector2(40, 40), true, true)
	if not menu.visible:
		print("  FAIL  floor menu becomes visible")
		hud.queue_free()
		return 1
	var order_btn := menu.find_button("Order")
	if order_btn == null:
		print("  FAIL  floor menu has Order")
		hud.queue_free()
		return 1
	var rows: Array[Dictionary] = [
		{"shelf_index": 0, "stock": 0, "product_id": &"", "display_name": "", "occupied": false},
		{"shelf_index": 1, "stock": 5, "product_id": &"freshpop_cola_500", "display_name": "FreshPop Cola 500 ml", "occupied": true},
	]
	var catalog: Array[Dictionary] = [
		{"id": &"freshpop_cola_500", "display_name": "FreshPop Cola 500 ml", "selling_price": 2.5},
		{"id": &"aquapure_water_500", "display_name": "AquaPure Water 500 ml", "selling_price": 1.5},
	]
	menu.open_for_fixture(Vector2(40, 40), rows, catalog)
	if not menu.visible:
		print("  FAIL  fixture menu becomes visible")
		hud.queue_free()
		return 1
	print("  PASS  context menu opens inside the tree")
	hud.queue_free()
	return 0


func _test_results_stars() -> int:
	var hud_scene: PackedScene = load("res://scenes/ui/Hud.tscn")
	var hud: Hud = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	hud.show_results(10, 9000.0, 10, 1, 2.50, 100.0, 2, true, true, false, 8, 1, 0, 0)
	var text := hud.results_label.text
	if not text.contains("Stars:") or not text.contains("☆") or not hud.results_panel.visible:
		print("  FAIL  results stars copy")
		hud.queue_free()
		return 1
	if not text.contains("oos:1"):
		print("  FAIL  results lost breakdown")
		hud.queue_free()
		return 1
	if hud.goal1_label == null or not hud.goal1_label.text.contains("10/8") or not hud.goal1_label.text.begins_with("☑"):
		print("  FAIL  goals served 10/8")
		hud.queue_free()
		return 1
	if hud.results_continue_button == null or hud.results_continue_button.text != "Continue":
		print("  FAIL  results Continue")
		hud.queue_free()
		return 1
	if hud.results_next_wave_button == null or hud.results_next_wave_button.text != "Next wave":
		print("  FAIL  results Next wave")
		hud.queue_free()
		return 1
	if hud.results_repeat_button == null or hud.results_repeat_button.text != "Repeat":
		print("  FAIL  results Repeat")
		hud.queue_free()
		return 1
	print("  PASS  results stars copy")
	hud.queue_free()
	return 0


func _test_hud_chrome() -> int:
	var hud_scene: PackedScene = load("res://scenes/ui/Hud.tscn")
	var hud: Hud = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame
	if hud.order_button == null or hud.order_button.text != "Order Stock":
		print("  FAIL  Order Stock label")
		hud.queue_free()
		return 1
	if hud.cash_label == null or not hud.cash_label.text.begins_with("$"):
		print("  FAIL  cash uses $")
		hud.queue_free()
		return 1
	var goals := hud.get_node_or_null("Root/GoalsPanel/GoalsBox/GoalsTitle") as Label
	if goals == null or goals.text != "Today's Goals":
		print("  FAIL  Today's Goals")
		hud.queue_free()
		return 1
	var queue := hud.get_node_or_null("Root/QueueChip/QueueLabel") as Label
	if queue == null or not queue.text.contains("queue"):
		print("  FAIL  queue chip")
		hud.queue_free()
		return 1
	var staff := hud.get_node_or_null("Root/ActionBar/ActionBox/StaffButton") as Button
	var upgrades := hud.get_node_or_null("Root/ActionBar/ActionBox/UpgradesButton") as Button
	if staff == null or upgrades == null or staff.disabled or upgrades.disabled:
		print("  FAIL  Staff/Upgrades should be enabled")
		hud.queue_free()
		return 1
	if hud.open_button == null or hud.open_button.text != "Open Store":
		print("  FAIL  Open Store label")
		hud.queue_free()
		return 1
	if not ResourceLoader.exists("res://assets/ui/hud_concept.png"):
		print("  FAIL  hud concept file")
		hud.queue_free()
		return 1
	hud.set_delivery("In transit: Cola 6 · Arrives 11:00 AM", 0.4)
	if not hud.delivery_panel.visible or hud.delivery_label.text != "In transit: Cola 6 · Arrives 11:00 AM":
		print("  FAIL  delivery bar show")
		hud.queue_free()
		return 1
	if hud.delivery_bar.value < 0.39 or hud.delivery_bar.value > 0.41:
		print("  FAIL  delivery bar value")
		hud.queue_free()
		return 1
	hud.set_clock("11:00 AM")
	if hud.time_label == null or hud.time_label.text != "11:00 AM":
		print("  FAIL  clock label")
		hud.queue_free()
		return 1
	hud.set_warehouse_line("Warehouse: Cola 12 · Water 12")
	if hud.warehouse_label == null or hud.warehouse_label.text != "Warehouse: Cola 12 · Water 12" or not hud.warehouse_panel.visible:
		print("  FAIL  warehouse line")
		hud.queue_free()
		return 1
	hud.set_wave_preview("Next wave: 10 customers · 5 regular · 5 impatient\nWant: Cola 2")
	if hud.wave_preview_label == null or not hud.wave_preview_label.text.contains("Want: Cola 2") or not hud.wave_preview_panel.visible:
		print("  FAIL  wave preview")
		hud.queue_free()
		return 1
	var quoted := {"ok": true, "cost": 27.2, "eta_hint": "Standard: arrives at 11:00 AM (after the wave).", "warehouse": 12, "ordered": 0, "after": 24}
	hud.order_panel.open([{
		"id": &"freshpop_cola_500",
		"display_name": "Cola",
		"warehouse": 12,
		"ordered": 0,
	}], func(_pid, _qty, _dtype): return quoted)
	if not str(hud.order_panel._sku_row.get_child(0).text).contains("wh. 12"):
		print("  FAIL  order sku warehouse")
		hud.queue_free()
		return 1
	if hud.order_panel._stock_label == null or not hud.order_panel._stock_label.text.contains("Warehouse: 12"):
		print("  FAIL  order stock line")
		hud.queue_free()
		return 1
	hud.order_panel.close()
	hud.set_delivery("", 0.0)
	if hud.delivery_panel.visible:
		print("  FAIL  delivery bar hide")
		hud.queue_free()
		return 1
	print("  PASS  HUD chrome labels")
	hud.queue_free()
	return 0


func _test_playtest_bot() -> int:
	var main_scene: PackedScene = load("res://scenes/main/Main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)
	await physics_frame
	await physics_frame
	await create_timer(0.2).timeout
	var staff: StaffManager = main.get_node("StaffManager")
	var cashier := staff.get_cashier()
	var till: StoreRoom = main.get_node("Store")
	if cashier == null or cashier.global_position.distance_to(till.get_cashier_position()) > 0.4:
		print("  FAIL  cashier stands behind checkout")
		main.queue_free()
		return 1
	print("  PASS  cashier stands behind checkout")
	var bot = main.get_node_or_null("PlaytestBot")
	if bot == null or not bot.has_method("run"):
		print("  FAIL  PlaytestBot is in Main")
		main.queue_free()
		return 1
	bot.drive_mode = 2
	var report: Dictionary = await bot.run()
	if not bool(report.get("ok", false)):
		print("  FAIL  playtest bot loop: %s" % str(report.get("reason", "")))
		main.queue_free()
		return 1
	var sku_tested := int(report.get("sku_tested", 0))
	var sku_catalog := int(report.get("sku_catalog", 0))
	if sku_tested < 1 or sku_tested != sku_catalog:
		print("  FAIL  bot did not cover catalog (%d / %d)" % [sku_tested, sku_catalog])
		main.queue_free()
		return 1
	var types_tested := int(report.get("fixture_types_tested", 0))
	var types_catalog := int(report.get("fixture_types_catalog", 0))
	if types_tested < 3 or types_tested != types_catalog:
		print("  FAIL  bot did not cover fixture types (%d / %d)" % [types_tested, types_catalog])
		main.queue_free()
		return 1
	var served := int(report.get("served", 0))
	var spawned := int(report.get("spawned", 0))
	if served != 10 or spawned != 10:
		print("  FAIL  bot wave served %d / spawned %d (expected 10/10)" % [served, spawned])
		main.queue_free()
		return 1
	var lost_sales := int(report.get("lost_sales", -1))
	var satisfaction := float(report.get("satisfaction", 0.0))
	var stars := int(report.get("stars", -1))
	var expected_stars := WaveRuntimeState.count_stars(served, satisfaction, lost_sales)
	if stars != expected_stars:
		print("  FAIL  bot stars %d != count_stars(%d, %.0f, %d)=%d" % [stars, served, satisfaction, lost_sales, expected_stars])
		main.queue_free()
		return 1
	if lost_sales != 0 or stars != 3 or satisfaction + 0.0001 < 75.0:
		print("  FAIL  bot wave lost=%d sat=%.0f stars=%d (expected 0 / sat ≥75 / stars 3)" % [lost_sales, satisfaction, stars])
		main.queue_free()
		return 1
	var cash_after_fixtures := float(report.get("cash_after_fixtures", 0.0))
	var cash_after_wave := float(report.get("cash_after_wave", 0.0))
	var wave_revenue := 0.0
	for i in CustomerManager.WAVE_SIZE:
		for item in main.customer_manager.build_shopping_list(i):
			var product: ProductDefinition = main.store_manager.get_product(item.product_id)
			if product != null:
				wave_revenue += product.selling_price
	if not is_equal_approx(cash_after_wave, cash_after_fixtures + wave_revenue):
		print("  FAIL  bot cash after wave %.2f (expected fixtures %.2f + %.2f)" % [cash_after_wave, cash_after_fixtures, wave_revenue])
		main.queue_free()
		return 1
	var warehouse_cola_before := int(report.get("warehouse_cola_before", -1))
	var warehouse_cola := int(report.get("warehouse_cola", -1))
	if warehouse_cola != warehouse_cola_before + 6:
		print("  FAIL  bot warehouse cola %d (expected %d + 6)" % [warehouse_cola, warehouse_cola_before])
		main.queue_free()
		return 1
	print("  PASS  playtest bot covers catalog (%d SKU, %d fixtures, wave %d/%d, sat %.0f, stars %d, cola +6)" % [sku_tested, types_tested, served, spawned, satisfaction, stars])
	main.queue_free()
	return 0


func _wait_nav_path(nav_map: RID, from: Vector3, to: Vector3) -> PackedVector3Array:
	var path: PackedVector3Array = PackedVector3Array()
	for _i in 8:
		NavigationServer3D.map_force_update(nav_map)
		await physics_frame
		path = _nav_path(nav_map, from, to)
		if path.size() >= 2:
			return path
	return path


func _nav_path(nav_map: RID, from: Vector3, to: Vector3) -> PackedVector3Array:
	var start := NavigationServer3D.map_get_closest_point(nav_map, from)
	var end := NavigationServer3D.map_get_closest_point(nav_map, to)
	return NavigationServer3D.map_get_path(nav_map, start, end, true)
