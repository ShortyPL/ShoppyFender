extends RefCounted
class_name TestInventory

const COLA := preload("res://data/products/freshpop_cola_500.tres")

static func run() -> int:
	var failures := 0
	failures += _assert_eq("express adds warehouse and charges fee", _express_cola_12(), true)
	failures += _assert_eq("standard waits then delivers", _standard_then_deliver(), true)
	failures += _assert_eq("pending_total tracks standard orders", _pending_total(), true)
	failures += _assert_eq("standard stamps arrival clock", _standard_eta_minutes(), true)
	failures += _assert_eq("store clock formats 12-hour time", _store_clock_format(), true)
	failures += _assert_eq("order rejects insufficient cash", _order_rejects_shortfall(), true)
	failures += _assert_eq("take_from_warehouse rejects empty", _take_rejects_empty(), true)
	failures += _assert_eq("continue delivers standard", _continue_delivers_standard(), true)
	return failures

static func _express_cola_12() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.seed_warehouse(&"freshpop_cola_500", 12)
	var result: Dictionary = inv.place_order(COLA, 12, &"express")
	var cost := 1.2 * 12.0 + 45.0
	var ok: bool = bool(result.get("ok", false)) and is_equal_approx(economy.get_cash(), 10000.0 - cost) and inv.get_warehouse(&"freshpop_cola_500") == 24
	economy.free()
	inv.free()
	return ok

static func _standard_then_deliver() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.seed_warehouse(&"freshpop_cola_500", 12)
	var result: Dictionary = inv.place_order(COLA, 6, &"standard")
	var cost := 1.2 * 6.0 + 20.0
	var mid: bool = bool(result.get("ok", false)) and inv.get_ordered(&"freshpop_cola_500") == 6 and inv.get_warehouse(&"freshpop_cola_500") == 12 and is_equal_approx(economy.get_cash(), 10000.0 - cost)
	inv.deliver_pending()
	var ok := mid and inv.get_ordered(&"freshpop_cola_500") == 0 and inv.get_warehouse(&"freshpop_cola_500") == 18
	economy.free()
	inv.free()
	return ok


static func _pending_total() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.place_order(COLA, 6, &"standard")
	var mid := inv.pending_total() == 6
	inv.deliver_pending()
	var ok := mid and inv.pending_total() == 0
	economy.free()
	inv.free()
	return ok


static func _standard_eta_minutes() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.place_order(COLA, 6, &"standard", StoreClock.OPEN_MINUTES + StoreClock.WAVE_MINUTES)
	var ok := inv.pending_eta_minutes() == StoreClock.OPEN_MINUTES + StoreClock.WAVE_MINUTES
	inv.deliver_pending()
	ok = ok and inv.pending_eta_minutes() == -1
	economy.free()
	inv.free()
	return ok


static func _store_clock_format() -> bool:
	var clock := StoreClock.new()
	var sim := clock.displayed_minutes(GameManager.STATE_SIMULATION, 0.5) == StoreClock.OPEN_MINUTES + int(StoreClock.WAVE_MINUTES / 2.0)
	clock.advance_wave()
	return StoreClock.format_clock(9 * 60) == "9:00 AM" \
		and StoreClock.format_clock(11 * 60) == "11:00 AM" \
		and StoreClock.format_clock(13 * 60) == "1:00 PM" \
		and StoreClock.format_clock(0) == "12:00 AM" \
		and sim \
		and clock.minutes == StoreClock.OPEN_MINUTES + StoreClock.WAVE_MINUTES



static func _order_rejects_shortfall() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	var result: Dictionary = inv.place_order(COLA, 24, &"express")
	var ok: bool = result.get("ok", true) == false and result.get("reason", &"") == &"insufficient_cash" and inv.get_warehouse(&"freshpop_cola_500") == 0
	economy.free()
	inv.free()
	return ok

static func _take_rejects_empty() -> bool:
	var inv := InventoryManager.new()
	inv.setup(EconomyManager.new())
	var taken := inv.take_from_warehouse(&"freshpop_cola_500", 6)
	var ok := taken == 0
	inv.free()
	return ok

static func _continue_delivers_standard() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.place_order(COLA, 6, &"standard")
	var game := GameManager.new()
	game.inventory = inv
	game.return_to_build()
	var ok := inv.get_warehouse(&"freshpop_cola_500") == 6 and inv.get_ordered(&"freshpop_cola_500") == 0
	game.free()
	inv.free()
	economy.free()
	return ok

static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
