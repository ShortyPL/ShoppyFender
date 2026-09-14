class_name UpgradeManager
extends RefCounted

const EXTRA_WORKER := &"extra_worker"
const FASTER_CHECKOUT := &"faster_checkout"
const SECOND_CHECKOUT := &"second_checkout"
const EXTRA_WORKER_COST := 250.0
const FASTER_CHECKOUT_COST := 200.0
const SECOND_CHECKOUT_COST := 400.0
const FAST_PAY_SEC := 1.2

var owned: Dictionary = {}


func catalog() -> Array[Dictionary]:
	return [
		{"id": EXTRA_WORKER, "cost": EXTRA_WORKER_COST, "title": "Extra worker"},
		{"id": FASTER_CHECKOUT, "cost": FASTER_CHECKOUT_COST, "title": "Faster checkout"},
		{"id": SECOND_CHECKOUT, "cost": SECOND_CHECKOUT_COST, "title": "Second checkout"},
	]


func has_upgrade(id: StringName) -> bool:
	return bool(owned.get(id, false))


func worker_slots() -> int:
	return 2 if has_upgrade(EXTRA_WORKER) else 1


func buy(id: StringName, economy: EconomyManager) -> Dictionary:
	if has_upgrade(id):
		return {"ok": false, "reason": &"owned", "cost": 0.0}
	var cost := _cost_of(id)
	if cost <= 0.0:
		return {"ok": false, "reason": &"unknown", "cost": 0.0}
	if economy == null or not economy.can_afford(cost):
		return {"ok": false, "reason": &"insufficient_cash", "cost": cost}
	var spent := economy.spend(cost, &"upgrade")
	if not bool(spent.get("ok", false)):
		return spent
	owned[id] = true
	return {"ok": true, "reason": &"ok", "cost": cost}


func apply(
	staff: StaffManager,
	customers: CustomerManager,
	worker_scene: PackedScene,
	place_cb: Callable = Callable(),
	cashier_scene: PackedScene = null
) -> void:
	if has_upgrade(FASTER_CHECKOUT) and customers != null:
		customers.set_all_pay_sec(FAST_PAY_SEC)
	if has_upgrade(SECOND_CHECKOUT) and customers != null:
		customers.set_lane_count(2)
		if staff != null and cashier_scene != null:
			staff.ensure_cashier_lanes(2, cashier_scene)
	if staff == null or not has_upgrade(EXTRA_WORKER):
		return
	while staff.worker_count() < worker_slots():
		var worker := staff.spawn_worker(worker_scene)
		if worker == null:
			break
		if place_cb.is_valid():
			place_cb.call(worker)


func owned_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for key in owned.keys():
		if bool(owned[key]):
			ids.append(String(key))
	return ids


func load_owned(ids: PackedStringArray) -> void:
	owned.clear()
	for raw in ids:
		owned[StringName(raw)] = true


func _cost_of(id: StringName) -> float:
	match id:
		EXTRA_WORKER:
			return EXTRA_WORKER_COST
		FASTER_CHECKOUT:
			return FASTER_CHECKOUT_COST
		SECOND_CHECKOUT:
			return SECOND_CHECKOUT_COST
		_:
			return 0.0
