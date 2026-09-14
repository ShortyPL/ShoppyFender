extends RefCounted
class_name TestShelfStock


static func run() -> int:
	var failures := 0
	failures += _assert_eq("take_from_shelf decreases stock 5 to 4", _take_decreases_stock(), true)
	failures += _assert_eq("take_from_shelf fails at zero", _take_fails_when_empty(), true)
	failures += _assert_eq("assign_product_to_shelf fills independent shelves", _assign_two_shelves(), true)
	failures += _assert_eq("assign default stock is zero", _assign_default_empty(), true)
	failures += _assert_eq("restock_fixture does not spawn stock", _restock_fixture(), true)
	failures += _assert_eq("add_shelf_stock fills toward capacity", _add_shelf_stock(), true)
	failures += _assert_eq("clear_fixture_products removes stock", _clear_products(), true)
	failures += _assert_eq("remove_fixture clears runtime fixture", _remove_fixture(), true)
	failures += _assert_eq("capacity is facings times units deep", _capacity_formula(), true)
	failures += _assert_eq("more facings increase capacity", _more_facings_raise_capacity(), true)
	failures += _assert_eq("stock cannot exceed capacity", _stock_clamped_to_capacity(), true)
	failures += _assert_eq("deeper shelf holds more units", _deeper_shelf_more_units(), true)
	return failures


static func _take_decreases_stock() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var placement := store.assign_product_to_first_shelf(&"freshpop_cola_500", 5)
	if placement == null:
		store.free()
		return false
	var ok := store.take_from_shelf(placement.placement_id)
	var passed := ok and placement.shelf_stock == 4
	store.free()
	return passed


static func _take_fails_when_empty() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var placement := store.assign_product_to_first_shelf(&"freshpop_cola_500", 0)
	if placement == null:
		store.free()
		return false
	var ok := store.take_from_shelf(placement.placement_id)
	var passed := (not ok) and placement.shelf_stock == 0
	store.free()
	return passed


static func _assign_two_shelves() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var shelf_a := store.assign_product_to_shelf(instance_id, 0, &"freshpop_cola_500", 5)
	var shelf_b := store.assign_product_to_shelf(instance_id, 2, &"freshpop_cola_500", 3)
	var total := store.get_total_shelf_stock(&"freshpop_cola_500")
	var passed := shelf_a != null and shelf_b != null and shelf_a.placement_id != shelf_b.placement_id and total == 8
	store.free()
	return passed


static func _assign_default_empty() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var placement := store.assign_product_to_first_shelf(&"freshpop_cola_500", -1)
	var passed := placement != null and placement.shelf_stock == 0 and placement.capacity > 0
	store.free()
	return passed


static func _restock_fixture() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, &"freshpop_cola_500", 1)
	store.restock_fixture(instance_id)
	var passed := placement != null and placement.shelf_stock == 1
	store.free()
	return passed


static func _add_shelf_stock() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var placement := store.assign_product_to_first_shelf(&"freshpop_cola_500", 0)
	var added: int = store.add_shelf_stock(placement.placement_id, 6)
	var passed: bool = added == 6 and placement.shelf_stock == 6
	store.free()
	return passed


static func _clear_products() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	store.assign_product_to_shelf(instance_id, 1, &"freshpop_cola_500", 5)
	var cleared := store.clear_fixture_products(instance_id)
	var passed := cleared and store.get_total_shelf_stock(&"freshpop_cola_500") == 0 and not store.has_assigned_product()
	store.free()
	return passed


static func _remove_fixture() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var removed := store.remove_fixture(instance_id)
	var passed := removed and store.runtime.is_empty()
	store.free()
	return passed


static func _capacity_formula() -> bool:
	var deep := StoreManager.units_deep_from(0.40, 0.065)
	var facings := StoreManager.max_facings_from(1.0, 0.065)
	return deep == 6 and facings == 15 and (3 * deep) == 18


static func _more_facings_raise_capacity() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	store.register_product(load("res://data/products/freshpop_cola_500.tres"))
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 0, &"freshpop_cola_500")
	if placement == null:
		store.free()
		return false
	var old_cap := placement.capacity
	var old_facings := placement.facings
	store.adjust_facings(instance_id, 1)
	var passed: bool = placement.facings == old_facings + 1 and placement.capacity > old_cap
	store.free()
	return passed


static func _stock_clamped_to_capacity() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 0, &"freshpop_cola_500", 999)
	var passed := placement != null and placement.shelf_stock == placement.capacity
	store.free()
	return passed


static func _deeper_shelf_more_units() -> bool:
	var gondola_deep := StoreManager.units_deep_from(0.5, 0.065)
	var wall_deep := StoreManager.units_deep_from(0.3, 0.065)
	return gondola_deep > wall_deep and wall_deep >= 1


static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
