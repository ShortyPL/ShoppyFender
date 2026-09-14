extends RefCounted
class_name TestUpgrades

const WORKER_SCENE := preload("res://scenes/staff/Worker.tscn")
const CASHIER_SCENE := preload("res://scenes/staff/Cashier.tscn")


static func run() -> int:
	var failures := 0
	failures += _assert("extra worker costs 250 and adds a slot", _extra_worker())
	failures += _assert("faster checkout sets pay_sec to 1.2", _faster_checkout())
	failures += _assert("second checkout enables two lanes", _second_checkout())
	return failures


static func _extra_worker() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var upgrades := UpgradeManager.new()
	var bought := upgrades.buy(UpgradeManager.EXTRA_WORKER, economy)
	if not bool(bought.get("ok", false)):
		economy.free()
		return false
	if upgrades.worker_slots() != 2:
		economy.free()
		return false
	if not is_equal_approx(economy.get_cash(), 9750.0):
		economy.free()
		return false
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		economy.free()
		return false
	var root := Node3D.new()
	tree.root.add_child(root)
	var staff := StaffManager.new()
	staff.setup(null, null, null, root)
	var first := staff.spawn_worker(WORKER_SCENE)
	upgrades.apply(staff, null, WORKER_SCENE)
	var ok := first != null and staff.worker_count() == 2
	root.queue_free()
	staff.free()
	economy.free()
	return ok


static func _faster_checkout() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var upgrades := UpgradeManager.new()
	var customers := CustomerManager.new()
	var bought := upgrades.buy(UpgradeManager.FASTER_CHECKOUT, economy)
	upgrades.apply(null, customers, null)
	customers.checkout_queue.enqueue(&"a")
	customers.checkout_queue.start_pay_if_idle()
	var early := customers.checkout_queue.advance_pay(1.0)
	var done := customers.checkout_queue.advance_pay(0.25)
	var ok := (
		bool(bought.get("ok", false))
		and is_equal_approx(customers.checkout_queue.pay_sec, UpgradeManager.FAST_PAY_SEC)
		and not early
		and done
		and is_equal_approx(economy.get_cash(), 9800.0)
	)
	customers.free()
	economy.free()
	return ok


static func _second_checkout() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var upgrades := UpgradeManager.new()
	var customers := CustomerManager.new()
	var bought := upgrades.buy(UpgradeManager.SECOND_CHECKOUT, economy)
	upgrades.apply(null, customers, null)
	var ok := (
		bool(bought.get("ok", false))
		and customers.queues.size() == 2
		and is_equal_approx(economy.get_cash(), 9600.0)
	)
	customers.free()
	economy.free()
	return ok


static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
