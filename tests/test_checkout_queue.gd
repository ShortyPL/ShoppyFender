extends RefCounted
class_name TestCheckoutQueue

const CUSTOMER_SCENE := preload("res://scenes/customers/Customer.tscn")


static func run() -> int:
	var failures := 0
	failures += _assert("fifo pay order", _fifo())
	failures += _assert("compact after front leaves", _compact())
	failures += _assert("stars 10/100/0 is 3", WaveRuntimeState.count_stars(10, 100.0, 0) == 3)
	failures += _assert("stars 10/100/1 is 2", WaveRuntimeState.count_stars(10, 100.0, 1) == 2)
	failures += _assert("stars 7/100/0 is 2", WaveRuntimeState.count_stars(7, 100.0, 0) == 2)
	failures += _assert("pay completes after 1.8s", _pay_timer())
	failures += _assert("wait_tick false before 3s, true after", _wait_tick())
	failures += _assert("regular leave_threshold 100", CustomerRuntimeState.new().leave_threshold == 100.0)
	failures += _assert("impatient leave 60 vs regular 100", _impatient_archetype())
	failures += _assert("enqueue happens on enter_queued not pick", _enqueue_on_arrival())
	return failures


static func _enqueue_on_arrival() -> bool:
	var q := CheckoutQueue.new()
	var customer := CUSTOMER_SCENE.instantiate() as CustomerController
	if customer == null:
		return false
	customer.runtime = CustomerRuntimeState.new()
	customer.runtime.runtime_id = &"arrival_test"
	customer.checkout_queue = q
	customer.runtime.state = CustomerController.STATE_MOVING_TO_CHECKOUT
	var before := q.index_of(customer.runtime.runtime_id)
	customer._enter_queued()
	var after := q.index_of(customer.runtime.runtime_id)
	var paying := customer.runtime.state == CustomerController.STATE_PAYING
	customer.free()
	return before < 0 and after == 0 and paying

static func _fifo() -> bool:
	var q := CheckoutQueue.new()
	q.enqueue(&"a")
	q.enqueue(&"b")
	q.enqueue(&"c")
	return q.front() == &"a" and q.index_of(&"c") == 2 and q.size() == 3

static func _compact() -> bool:
	var q := CheckoutQueue.new()
	q.enqueue(&"a")
	q.enqueue(&"b")
	q.dequeue(&"a")
	return q.front() == &"b" and q.index_of(&"b") == 0

static func _pay_timer() -> bool:
	var q := CheckoutQueue.new()
	q.enqueue(&"a")
	q.start_pay_if_idle()
	var done_early := q.advance_pay(1.0)
	var done := q.advance_pay(1.0)
	return (not done_early) and done


static func _wait_tick() -> bool:
	var q := CheckoutQueue.new()
	q.enqueue(&"a")
	q.enqueue(&"b")
	var before := q.wait_tick_due(2.9)
	var after := q.wait_tick_due(0.2)
	return (not before) and after


static func _impatient_archetype() -> bool:
	var regular := CUSTOMER_SCENE.instantiate() as CustomerController
	var impatient := CUSTOMER_SCENE.instantiate() as CustomerController
	if regular == null or impatient == null:
		if regular != null:
			regular.free()
		if impatient != null:
			impatient.free()
		return false
	regular.runtime = CustomerRuntimeState.new()
	impatient.runtime = CustomerRuntimeState.new()
	regular.apply_archetype(&"regular_customer")
	impatient.apply_archetype(&"impatient_customer")
	var thresholds_ok := regular.runtime.leave_threshold == 100.0 and impatient.runtime.leave_threshold == 60.0
	regular.apply_queue_wait_tick()
	impatient.apply_queue_wait_tick()
	var ticks_ok := regular.runtime.frustration == 10.0 and impatient.runtime.frustration == 15.0
	regular.free()
	impatient.free()
	return thresholds_ok and ticks_ok

static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
