extends RefCounted
class_name TestProductCatalog

const TexLib := preload("res://scripts/store/store_textures.gd")


static func run() -> int:
	var failures := 0
	failures += _assert_eq("catalog loads 5 unique products", _catalog_has_five_sku(), true)
	failures += _assert_eq("product and room textures load", _product_textures_exist(), true)
	failures += _assert_eq("two SKUs can occupy different shelves", _two_skus_on_one_gondola(), true)
	failures += _assert_eq("store opens with water only", _open_store_with_water(), true)
	failures += _assert_eq("customer target is first stocked sku", _first_stocked_product(), true)
	return failures


static func _catalog_has_five_sku() -> bool:
	var ids: Array[StringName] = []
	for path in [
		"res://data/products/freshpop_cola_500.tres",
		"res://data/products/aquapure_water_500.tres",
		"res://data/products/sunnyjuice_orange_330.tres",
		"res://data/products/crunchbox_cereal_375.tres",
		"res://data/products/quickbite_chips_150.tres",
	]:
		var product: ProductDefinition = load(path)
		if product == null or not product.validate().is_empty():
			return false
		if ids.has(product.id):
			return false
		ids.append(product.id)
	return ids.size() == 5


static func _product_textures_exist() -> bool:
	for sku in [
		"freshpop_cola_500",
		"aquapure_water_500",
		"sunnyjuice_orange_330",
		"crunchbox_cereal_375",
		"quickbite_chips_150",
	]:
		if TexLib.product(StringName(sku)) == null:
			return false
	return (
		TexLib.floor_tex() != null
		and TexLib.wall_tex() != null
		and TexLib.metal_tex() != null
		and TexLib.wood_tex() != null
		and TexLib.pegboard_tex() != null
		and TexLib.counter_tex() != null
		and TexLib.cardboard_tex() != null
	)


static func _two_skus_on_one_gondola() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	store.register_product(load("res://data/products/freshpop_cola_500.tres"))
	store.register_product(load("res://data/products/aquapure_water_500.tres"))
	var instance_id: StringName = store.runtime.keys()[0]
	store.assign_product_to_shelf(instance_id, 0, &"freshpop_cola_500", 5)
	store.assign_product_to_shelf(instance_id, 2, &"aquapure_water_500", 3)
	var passed := store.get_total_shelf_stock(&"freshpop_cola_500") == 5 and store.get_total_shelf_stock(&"aquapure_water_500") == 3 and store.list_catalog().size() == 2
	store.free()
	return passed


static func _open_store_with_water() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	store.register_product(load("res://data/products/aquapure_water_500.tres"))
	var instance_id: StringName = store.runtime.keys()[0]
	store.assign_product_to_shelf(instance_id, 1, &"aquapure_water_500", 5)
	var game := GameManager.new()
	game.store_manager = store
	var check := game.can_open_store()
	var passed: bool = check.ok == true
	game.free()
	store.free()
	return passed


static func _first_stocked_product() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	store.register_product(load("res://data/products/sunnyjuice_orange_330.tres"))
	var instance_id: StringName = store.runtime.keys()[0]
	store.assign_product_to_shelf(instance_id, 3, &"sunnyjuice_orange_330", 2)
	var passed := store.get_first_stocked_product_id() == &"sunnyjuice_orange_330"
	store.free()
	return passed


static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
