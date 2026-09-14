extends RefCounted
class_name TestRunSave


static func run() -> int:
	var failures := 0
	failures += _assert("save round-trip keeps cash", _cash_round_trip())
	failures += _assert("save round-trip keeps meta fields", _meta_round_trip())
	return failures


static func _cash_round_trip() -> bool:
	RunSave.clear()
	RunSave.write_snapshot({
		"cash": 1234.5,
		"auto_fill": true,
		"owned": PackedStringArray(["extra_worker"]),
		"warehouse": {&"freshpop_cola_500": 9},
		"fixtures": [],
	})
	var data := RunSave.read_snapshot()
	var ok := (
		RunSave.exists()
		and is_equal_approx(float(data.get("cash", 0.0)), 1234.5)
		and bool(data.get("auto_fill", false))
		and PackedStringArray(data.get("owned", PackedStringArray())).has("extra_worker")
		and int(data.get("warehouse", {}).get(&"freshpop_cola_500", 0)) == 9
	)
	RunSave.clear()
	return ok and not RunSave.exists()


static func _meta_round_trip() -> bool:
	RunSave.clear()
	RunSave.write_snapshot({
		"cash": 500.0,
		"start_cash": 10000.0,
		"wave_number": 3,
		"clock_minutes": 780,
		"stars_history": [3, 2],
		"ordered": {&"freshpop_cola_500": 6},
		"pending": [{
			"id": &"delivery_1",
			"product_id": &"freshpop_cola_500",
			"quantity": 6,
			"delivery_type": &"standard",
			"eta_minutes": 780,
		}],
		"warehouse": {},
		"fixtures": [],
		"owned": PackedStringArray(),
		"auto_fill": false,
	})
	var data := RunSave.read_snapshot()
	var pending: Array = data.get("pending", [])
	var ok := (
		int(data.get("wave_number", 0)) == 3
		and int(data.get("clock_minutes", 0)) == 780
		and int(data.get("stars_history", [])[0]) == 3
		and int(data.get("ordered", {}).get(&"freshpop_cola_500", 0)) == 6
		and pending.size() == 1
		and int(pending[0].get("quantity", 0)) == 6
	)
	RunSave.clear()
	return ok


static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
