extends RefCounted
class_name TestStaff

const COLA_ID := &"freshpop_cola_500"
const WATER_ID := &"aquapure_water_500"


static func run() -> int:
	var failures := 0
	failures += _assert_eq("instant restock moves 6 from warehouse to shelf", _instant_transfer(), true)
	failures += _assert_eq("empty warehouse queues no restock task", _empty_warehouse_queues_nothing(), true)
	failures += _assert_eq("second instant trip moves remaining 6", _second_trip_moves_six(), true)
	failures += _assert_eq("mid-trip SKU swap returns carry to warehouse", _sku_swap_returns_carry(), true)
	failures += _assert_eq("one crate splits 3 and 3 across two cola fixtures", _split_two_fixtures(), true)
	failures += _assert_eq("last hole takes remainder without DROP_CAP", _last_hole_uncapped(), true)
	failures += _assert_eq("queue_empty_shelves restocks empty assigned shelf", _queue_empty_shelves(), true)
	failures += _assert_eq("queue_empty_shelves assigns unassigned empty shelves", _queue_empty_unassigned(), true)
	failures += _assert_eq("worker has to_home state", WorkerController.STATE_TO_HOME == &"to_home", true)
	failures += _assert_eq("sim respects auto_fill preference", _auto_fill_preference(), true)
	return failures


static func _auto_fill_preference() -> bool:
	var staff := StaffManager.new()
	staff.set_auto_fill_preference(false)
	var off_ok := not staff.is_auto_fill_empties()
	staff.set_auto_fill_preference(true)
	var on_ok := staff.is_auto_fill_empties()
	staff.free()
	return off_ok and on_ok


static func _instant_transfer() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, COLA_ID, 0)
	var economy := EconomyManager.new()
	var inventory := InventoryManager.new()
	inventory.setup(economy)
	inventory.seed_warehouse(COLA_ID, 12)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	var queued := staff.request_restock_fixture(instance_id)
	staff.execute_next_instant()
	var ok := (
		placement != null
		and queued > 0
		and inventory.get_warehouse(COLA_ID) == 6
		and placement.shelf_stock == 6
	)
	staff.free()
	inventory.free()
	economy.free()
	store.free()
	return ok


static func _empty_warehouse_queues_nothing() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	store.assign_product_to_shelf(instance_id, 1, COLA_ID, 0)
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	var queued := staff.request_restock_fixture(instance_id)
	var ok := queued == 0 and inventory.get_warehouse(COLA_ID) == 0
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _second_trip_moves_six() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, COLA_ID, 0)
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 12)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	staff.request_restock_fixture(instance_id)
	staff.execute_next_instant()
	staff.execute_next_instant()
	var ok := (
		placement != null
		and inventory.get_warehouse(COLA_ID) == 0
		and placement.shelf_stock == 12
	)
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _sku_swap_returns_carry() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, COLA_ID, 0)
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 12)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	staff.request_restock_fixture(instance_id)
	staff.execute_next_instant_swap_before_deliver(WATER_ID)
	var ok := (
		placement != null
		and inventory.get_warehouse(COLA_ID) == 12
		and placement.product_id == WATER_ID
		and placement.shelf_stock == 0
		and inventory.get_warehouse(WATER_ID) == 0
	)
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _split_two_fixtures() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var a: StringName = store.runtime.keys()[0]
	var b: StringName = store.add_test_gondola()
	var pa := store.assign_product_to_shelf(a, 1, COLA_ID, 0)
	var pb := store.assign_product_to_shelf(b, 1, COLA_ID, 0)
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 6)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	staff.pick_eligible_index = func(n: int) -> int: return 0
	staff.request_restock_fixture(a)
	staff.execute_next_instant()
	var stocks: Array = [pa.shelf_stock, pb.shelf_stock]
	stocks.sort()
	var ok: bool = (
		inventory.get_warehouse(COLA_ID) == 0
		and int(stocks[0]) == 3
		and int(stocks[1]) == 3
	)
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _last_hole_uncapped() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var a: StringName = store.runtime.keys()[0]
	var b: StringName = store.add_test_gondola()
	var pa := store.assign_product_to_shelf(a, 1, COLA_ID, 0)
	var pb := store.assign_product_to_shelf(b, 1, COLA_ID, 0)
	var started_b := pb.capacity - 2
	pb.shelf_stock = started_b
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 6)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	staff.pick_eligible_index = func(n: int) -> int: return 0
	staff.request_restock_fixture(a)
	staff.execute_next_instant()
	var added_b := pb.shelf_stock - started_b
	var ok := (
		inventory.get_warehouse(COLA_ID) == 0
		and pa.shelf_stock + added_b == 6
		and pb.shelf_stock == pb.capacity
	)
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _queue_empty_shelves() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, COLA_ID, 0)
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 12)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	var queued := staff.queue_empty_shelves()
	staff.execute_next_instant()
	var ok := (
		placement != null
		and queued > 0
		and inventory.get_warehouse(COLA_ID) == 6
		and store.get_total_any_shelf_stock() == 6
	)
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _queue_empty_unassigned() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 12)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	var queued := staff.queue_empty_shelves()
	staff.execute_next_instant()
	var ok := (
		queued > 0
		and store.get_total_any_shelf_stock() == 6
		and inventory.get_warehouse(COLA_ID) == 6
	)
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
