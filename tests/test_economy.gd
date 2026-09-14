extends RefCounted
class_name TestEconomy


static func run() -> int:
	var failures := 0
	failures += _assert_eq("sale increases cash by selling price", _sale_increases_cash(), true)
	failures += _assert_eq("spend rejects insufficient cash", _spend_rejects_shortfall(), true)
	failures += _assert_eq("spend deducts when affordable", _spend_deducts(), true)
	failures += _assert_eq("refund returns fixture cost", _refund_returns_cost(), true)
	return failures


static func _sale_increases_cash() -> bool:
	var economy := EconomyManager.new()
	economy.setup(100.0)
	economy.add_revenue(2.50, &"sale")
	var ok := is_equal_approx(economy.get_cash(), 102.50)
	economy.free()
	return ok


static func _spend_rejects_shortfall() -> bool:
	var economy := EconomyManager.new()
	economy.setup(100.0)
	var result: Dictionary = economy.spend(400.0, &"fixture")
	var ok: bool = result["ok"] == false and result["reason"] == &"insufficient_cash" and is_equal_approx(economy.get_cash(), 100.0)
	economy.free()
	return ok


static func _spend_deducts() -> bool:
	var economy := EconomyManager.new()
	economy.setup(500.0)
	var result: Dictionary = economy.spend(400.0, &"fixture")
	var ok: bool = result["ok"] == true and is_equal_approx(economy.get_cash(), 100.0)
	economy.free()
	return ok


static func _refund_returns_cost() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	economy.spend(400.0, &"fixture")
	economy.refund(400.0, &"fixture_refund")
	var ok := is_equal_approx(economy.get_cash(), 10000.0)
	economy.free()
	return ok


static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
