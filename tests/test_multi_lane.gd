extends RefCounted
class_name TestMultiLane


static func run() -> int:
	var failures := 0
	failures += _assert("default one lane", _one_lane_default())
	failures += _assert("three joins split 2/1", _split_shorter_line())
	return failures


static func _one_lane_default() -> bool:
	var manager := CustomerManager.new()
	var ok := manager.queues.size() == 1
	manager.free()
	return ok


static func _split_shorter_line() -> bool:
	var manager := CustomerManager.new()
	manager.set_lane_count(2)
	var a := _fake_customer(&"a")
	var b := _fake_customer(&"b")
	var c := _fake_customer(&"c")
	manager.join_shortest_queue(a)
	manager.join_shortest_queue(b)
	manager.join_shortest_queue(c)
	var sizes: Array[int] = [manager.queues[0].size(), manager.queues[1].size()]
	sizes.sort()
	var ok: bool = sizes[0] == 1 and sizes[1] == 2 and manager.get_queue_length() == 3
	a.free()
	b.free()
	c.free()
	manager.free()
	return ok


static func _fake_customer(id: StringName) -> CustomerController:
	var customer := CustomerController.new()
	customer.runtime = CustomerRuntimeState.new()
	customer.runtime.runtime_id = id
	return customer


static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
