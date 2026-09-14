class_name GameManager
extends Node

signal state_changed(new_state: StringName)
signal results_ready(served: int, cash: float)

const STATE_BUILD := &"BUILD"
const STATE_SIMULATION := &"SIMULATION"
const STATE_RESULTS := &"RESULTS"

var current_state: StringName = STATE_BUILD
var store_manager: StoreManager
var build_manager: BuildManager
var customer_manager: CustomerManager
var inventory: InventoryManager
var staff_manager: StaffManager
var economy: EconomyManager
var last_served: int = 0
var wave_number: int = 1
var wave_snapshot: WaveSnapshot


func setup(
	p_store_manager: StoreManager,
	p_build_manager: BuildManager,
	p_customer_manager: CustomerManager,
	p_inventory: InventoryManager = null,
	p_staff: StaffManager = null,
	p_economy: EconomyManager = null
) -> void:
	store_manager = p_store_manager
	build_manager = p_build_manager
	customer_manager = p_customer_manager
	inventory = p_inventory
	staff_manager = p_staff
	economy = p_economy
	if customer_manager != null and not customer_manager.customer_exited.is_connected(_on_customer_exited):
		customer_manager.customer_exited.connect(_on_customer_exited)
	_set_state(STATE_BUILD)


func can_open_store() -> Dictionary:
	if store_manager.runtime.is_empty():
		return {"ok": false, "reason": "Place a shelf first."}
	if not store_manager.has_assigned_product():
		return {"ok": false, "reason": "RMB on a shelf → Place product on shelf…"}
	if store_manager.get_total_any_shelf_stock() <= 0:
		return {"ok": false, "reason": "Shelves are empty — restock from the warehouse first."}
	return {"ok": true, "reason": ""}


func open_store() -> Dictionary:
	if current_state != STATE_BUILD:
		return {"ok": false, "reason": "Store is not in build mode."}
	var check := can_open_store()
	if not check.ok:
		GameLog.info("GAME", "Cannot open store: %s" % check.reason)
		return check
	return _begin_wave()


func next_wave() -> Dictionary:
	if current_state != STATE_RESULTS:
		return {"ok": false, "reason": "No wave results yet."}
	var check := can_open_store()
	if not check.ok:
		GameLog.info("GAME", "Cannot start next wave: %s" % check.reason)
		return check
	if staff_manager != null:
		staff_manager.clear_tasks()
	wave_number += 1
	return _begin_wave()


func repeat_wave() -> Dictionary:
	if current_state != STATE_RESULTS:
		return {"ok": false, "reason": "No wave results yet."}
	if wave_snapshot == null:
		return {"ok": false, "reason": "Nothing to repeat."}
	if staff_manager != null:
		staff_manager.clear_tasks()
	wave_snapshot.restore(economy, inventory, store_manager)
	return _begin_wave()


func _begin_wave() -> Dictionary:
	wave_snapshot = WaveSnapshot.capture(economy, inventory, store_manager)
	last_served = 0
	_set_state(STATE_SIMULATION)
	if staff_manager != null:
		staff_manager.set_auto_fill_empties(staff_manager.auto_fill_preference)
		staff_manager.set_worker_active(true)
	if build_manager != null:
		build_manager.set_build_enabled(false)
	if customer_manager != null:
		var size := CustomerManager.customers_for_wave(wave_number)
		var interval := CustomerManager.spawn_interval_for_wave(wave_number)
		customer_manager.start_wave(size, interval)
		GameLog.info("GAME", "Wave %d customers=%d" % [wave_number, size])
	return {"ok": true, "reason": ""}


func preview_wave_number() -> int:
	if current_state == STATE_RESULTS:
		return wave_number + 1
	return wave_number


func deliver_arrivals() -> void:
	if inventory != null:
		inventory.deliver_pending()


func return_to_build() -> void:
	deliver_arrivals()
	if staff_manager != null:
		staff_manager.restore_auto_fill_preference()
		staff_manager.set_worker_active(true)
	if customer_manager != null:
		customer_manager.finish_wave()
		customer_manager.clear_customers()
	_set_state(STATE_BUILD)
	if build_manager != null:
		build_manager.set_build_enabled(true)
	wave_number += 1


func _on_customer_exited(_customer_id: StringName, served: bool) -> void:
	if served:
		last_served += 1
	if customer_manager.is_wave_complete() and current_state == STATE_SIMULATION:
		customer_manager.finish_wave()
		_set_state(STATE_RESULTS)
		results_ready.emit(last_served, 0.0)


func _set_state(new_state: StringName) -> void:
	current_state = new_state
	if new_state == STATE_RESULTS and staff_manager != null:
		staff_manager.set_auto_fill_empties(false)
		staff_manager.set_worker_active(false)
	state_changed.emit(new_state)
	GameLog.info("GAME", "State -> %s" % String(new_state))
