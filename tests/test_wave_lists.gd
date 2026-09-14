extends RefCounted
class_name TestWaveLists


static func run() -> int:
	var failures := 0
	failures += _assert_eq("lists use 2-3 unique SKUs", _lists_multi_sku(), true)
	failures += _assert_eq("wave preview lists demand and archetypes", _wave_preview_demand(), true)
	failures += _assert_eq("wave stays open until all 10 spawned", _wave_waits_for_full_spawn(), true)
	failures += _assert_eq("OOS is a lost sale and drops satisfaction", _oos_is_lost_sale(), true)
	failures += _assert_eq("full serve keeps 100 satisfaction", _full_serve_is_perfect(), true)
	return failures


static func _lists_multi_sku() -> bool:
	var store := StoreManager.new()
	store.register_product(load("res://data/products/freshpop_cola_500.tres"))
	store.register_product(load("res://data/products/aquapure_water_500.tres"))
	store.register_product(load("res://data/products/sunnyjuice_orange_330.tres"))
	store.register_product(load("res://data/products/crunchbox_cereal_375.tres"))
	store.register_product(load("res://data/products/quickbite_chips_150.tres"))
	var manager := CustomerManager.new()
	manager.store_manager = store
	var seen: Dictionary = {}
	var cola_count := 0
	var lengths_ok := true
	for i in CustomerManager.WAVE_SIZE:
		var list := manager.build_shopping_list(i)
		var expected_len := CustomerManager.list_length_for_spawn(i)
		if list.size() != expected_len:
			lengths_ok = false
			break
		var ids: Dictionary = {}
		for item in list:
			ids[item.product_id] = true
			seen[item.product_id] = true
			if item.product_id == &"freshpop_cola_500":
				cola_count += 1
		if ids.size() != list.size():
			lengths_ok = false
			break
	var passed: bool = lengths_ok and seen.size() == 5 and cola_count == 4
	manager.free()
	store.free()
	return passed


static func _wave_preview_demand() -> bool:
	var store := StoreManager.new()
	store.register_product(load("res://data/products/freshpop_cola_500.tres"))
	store.register_product(load("res://data/products/aquapure_water_500.tres"))
	store.register_product(load("res://data/products/sunnyjuice_orange_330.tres"))
	store.register_product(load("res://data/products/crunchbox_cereal_375.tres"))
	store.register_product(load("res://data/products/quickbite_chips_150.tres"))
	var manager := CustomerManager.new()
	manager.store_manager = store
	var preview: Dictionary = manager.preview_wave(CustomerManager.WAVE_SIZE)
	var skus: Array = preview.get("skus", [])
	var cola := 0
	var total_qty := 0
	for row in skus:
		total_qty += int(row.get("qty", 0))
		if row.get("product_id", &"") == &"freshpop_cola_500":
			cola = int(row.get("qty", 0))
	var passed: bool = (
		int(preview.get("total", 0)) == 10
		and int(preview.get("regular", 0)) == 5
		and int(preview.get("impatient", 0)) == 5
		and skus.size() == 5
		and cola == 4
		and total_qty >= 20
	)
	manager.free()
	store.free()
	return passed


static func _wave_waits_for_full_spawn() -> bool:
	var manager := CustomerManager.new()
	manager.reset_wave(CustomerManager.WAVE_SIZE)
	manager.wave.spawned_count = 1
	var early := manager.is_wave_complete()
	manager.wave.spawned_count = CustomerManager.WAVE_SIZE
	var done := manager.is_wave_complete()
	manager.free()
	return (not early) and done


static func _oos_is_lost_sale() -> bool:
	var wave := WaveRuntimeState.new()
	wave.record_customer_exit(false, 80.0, 2.50, &"out_of_stock")
	wave.record_customer_exit(true, 100.0, 0.0)
	var passed: bool = (
		wave.lost_sales_count == 1
		and wave.lost_oos == 1
		and wave.failed_count == 1
		and wave.completed_customer_count == 1
		and is_equal_approx(wave.lost_sales_value, 2.50)
		and is_equal_approx(wave.get_average_satisfaction(), 90.0)
	)
	return passed


static func _full_serve_is_perfect() -> bool:
	var wave := WaveRuntimeState.new()
	for _i in 10:
		wave.record_customer_exit(true, 100.0, 0.0)
	return wave.lost_sales_count == 0 and is_equal_approx(wave.get_average_satisfaction(), 100.0) and is_equal_approx(wave.get_service_rate(), 1.0)


static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
