extends RefCounted
class_name TestWaveSnapshot

const COLA_ID := &"freshpop_cola_500"


static func run() -> int:
	var failures := 0
	failures += _assert("restore_cash keeps lifetime revenue", _restore_cash_keeps_lifetime())
	failures += _assert("wave snapshot round-trips cash warehouse stock", _snapshot_round_trip())
	failures += _assert("repeat_wave restores snapshot from RESULTS", _repeat_from_results())
	failures += _assert("next_wave from RESULTS without rollback", _next_wave_keeps_current())
	failures += _assert("later waves spawn more customers", _wave_size_grows())
	return failures


static func _restore_cash_keeps_lifetime() -> bool:
	var economy := EconomyManager.new()
	economy.setup(100.0)
	economy.add_revenue(10.0, &"sale")
	economy.restore_cash(100.0)
	var ok := is_equal_approx(economy.get_cash(), 100.0) and is_equal_approx(economy.state.lifetime_revenue, 10.0)
	economy.free()
	return ok


static func _snapshot_round_trip() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, COLA_ID, 5)
	var economy := EconomyManager.new()
	economy.setup(250.0)
	var inventory := InventoryManager.new()
	inventory.setup(economy)
	inventory.seed_warehouse(COLA_ID, 12)
	var snap := WaveSnapshot.capture(economy, inventory, store)
	economy.add_revenue(20.0, &"sale")
	store.take_from_shelf(placement.placement_id)
	inventory.take_from_warehouse(COLA_ID, 4)
	snap.restore(economy, inventory, store)
	var ok := (
		placement != null
		and is_equal_approx(economy.get_cash(), 250.0)
		and inventory.get_warehouse(COLA_ID) == 12
		and placement.shelf_stock == 5
	)
	inventory.free()
	economy.free()
	store.free()
	return ok


static func _repeat_from_results() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, COLA_ID, 5)
	var economy := EconomyManager.new()
	economy.setup(250.0)
	var inventory := InventoryManager.new()
	inventory.setup(economy)
	inventory.seed_warehouse(COLA_ID, 12)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	var game := GameManager.new()
	game.setup(store, null, null, inventory, staff, economy)
	game.current_state = GameManager.STATE_RESULTS
	game.wave_snapshot = WaveSnapshot.capture(economy, inventory, store)
	economy.add_revenue(20.0, &"sale")
	store.take_from_shelf(placement.placement_id)
	inventory.take_from_warehouse(COLA_ID, 4)
	var result := game.repeat_wave()
	var ok := (
		bool(result.get("ok", false))
		and game.current_state == GameManager.STATE_SIMULATION
		and is_equal_approx(economy.get_cash(), 250.0)
		and inventory.get_warehouse(COLA_ID) == 12
		and placement.shelf_stock == 5
	)
	game.free()
	staff.free()
	inventory.free()
	economy.free()
	store.free()
	return ok


static func _next_wave_keeps_current() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	store.assign_product_to_shelf(instance_id, 1, COLA_ID, 5)
	var economy := EconomyManager.new()
	economy.setup(250.0)
	var inventory := InventoryManager.new()
	inventory.setup(economy)
	inventory.seed_warehouse(COLA_ID, 8)
	var game := GameManager.new()
	game.setup(store, null, null, inventory, null, economy)
	game.current_state = GameManager.STATE_RESULTS
	economy.add_revenue(20.0, &"sale")
	var result := game.next_wave()
	var ok := (
		bool(result.get("ok", false))
		and game.current_state == GameManager.STATE_SIMULATION
		and is_equal_approx(economy.get_cash(), 270.0)
		and inventory.get_warehouse(COLA_ID) == 8
		and store.get_total_any_shelf_stock() == 5
	)
	game.free()
	inventory.free()
	economy.free()
	store.free()
	return ok


static func _wave_size_grows() -> bool:
	var size_ok := (
		CustomerManager.customers_for_wave(1) == 10
		and CustomerManager.customers_for_wave(2) == 12
		and CustomerManager.customers_for_wave(3) == 14
		and CustomerManager.customers_for_wave(20) == 24
	)
	var stars_ok := (
		WaveRuntimeState.served_needed(10) == 8
		and WaveRuntimeState.served_needed(12) == 10
		and WaveRuntimeState.count_stars(10, 100.0, 0, 12) == 3
		and WaveRuntimeState.count_stars(9, 100.0, 0, 12) == 2
	)
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	store.assign_product_to_shelf(instance_id, 1, COLA_ID, 5)
	var economy := EconomyManager.new()
	economy.setup(250.0)
	var inventory := InventoryManager.new()
	inventory.setup(economy)
	inventory.seed_warehouse(COLA_ID, 8)
	var game := GameManager.new()
	game.setup(store, null, null, inventory, null, economy)
	game.current_state = GameManager.STATE_RESULTS
	game.wave_number = 1
	game.next_wave()
	var next_ok := game.wave_number == 2
	game.current_state = GameManager.STATE_RESULTS
	game.return_to_build()
	var continue_ok := game.wave_number == 3 and game.preview_wave_number() == 3
	game.current_state = GameManager.STATE_RESULTS
	var repeat_before := game.wave_number
	game.wave_snapshot = WaveSnapshot.capture(economy, inventory, store)
	game.repeat_wave()
	var repeat_ok := game.wave_number == repeat_before
	game.free()
	inventory.free()
	economy.free()
	store.free()
	return size_ok and stars_ok and next_ok and continue_ok and repeat_ok


static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
