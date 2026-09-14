extends RefCounted
class_name TestFixtureCatalog


static func run() -> int:
	var failures := 0
	failures += _assert_eq("three fixture types load", _three_types_load(), true)
	failures += _assert_eq("wall shelf has 3 shelf states", _wall_shelf_shelf_count(), true)
	failures += _assert_eq("endcap has 2 shelf states", _endcap_shelf_count(), true)
	failures += _assert_eq("fixtures have purchase costs", _fixtures_have_costs(), true)
	return failures


static func _three_types_load() -> bool:
	var seen: Array[StringName] = []
	for path in [
		"res://data/fixtures/gondola_basic_100.tres",
		"res://data/fixtures/wall_shelf_150.tres",
		"res://data/fixtures/endcap_basic_80.tres",
	]:
		var definition: FixtureDefinition = load(path)
		if definition == null or not definition.validate().is_empty():
			return false
		if seen.has(definition.id):
			return false
		seen.append(definition.id)
	return seen.size() == 3


static func _wall_shelf_shelf_count() -> bool:
	var store := StoreManager.new()
	var definition: FixtureDefinition = load("res://data/fixtures/wall_shelf_150.tres")
	store.register_fixture(definition)
	var rows := store.list_fixtures()
	var count := int(rows[0].get("shelf_count", 0)) if not rows.is_empty() else 0
	var passed: bool = definition.shelf_count == 3 and rows.size() == 1 and count == 3
	store.free()
	return passed


static func _endcap_shelf_count() -> bool:
	var definition: FixtureDefinition = load("res://data/fixtures/endcap_basic_80.tres")
	return definition != null and definition.shelf_count == 2 and definition.fixture_type == &"endcap"


static func _fixtures_have_costs() -> bool:
	var gondola: FixtureDefinition = load("res://data/fixtures/gondola_basic_100.tres")
	var wall: FixtureDefinition = load("res://data/fixtures/wall_shelf_150.tres")
	var endcap: FixtureDefinition = load("res://data/fixtures/endcap_basic_80.tres")
	return (
		gondola != null and is_equal_approx(gondola.purchase_cost, 400.0)
		and wall != null and is_equal_approx(wall.purchase_cost, 300.0)
		and endcap != null and is_equal_approx(endcap.purchase_cost, 250.0)
	)


static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
