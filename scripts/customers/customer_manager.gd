class_name CustomerManager
extends Node

signal customer_spawned(customer_id: StringName)
signal customer_exited(customer_id: StringName, served: bool)
signal sale_completed(revenue: float, cogs: float)

const WAVE_SIZE := 10
const SPAWN_INTERVAL_SEC := 1.25
const WAVE_GROWTH := 2
const WAVE_CAP := 24

@export var customer_scene: PackedScene

var store: StoreRoom
var store_manager: StoreManager
var economy: EconomyManager
var customers_root: Node3D
var ids: RuntimeIdGenerator = RuntimeIdGenerator.new()
var wave: WaveRuntimeState = WaveRuntimeState.new()
var queues: Array[CheckoutQueue] = []
var path_debug: bool = false
var spawn_interval_sec: float = SPAWN_INTERVAL_SEC

var _active: Dictionary = {}
var _spawn_wait: float = 0.0


var checkout_queue: CheckoutQueue:
	get:
		_ensure_lanes(maxi(_lane_count(), 1))
		return queues[0]


func _lane_count() -> int:
	return maxi(queues.size(), 1)


func _init() -> void:
	queues = [CheckoutQueue.new()]


func setup(p_store: StoreRoom, p_store_manager: StoreManager, p_economy: EconomyManager, p_root: Node3D) -> void:
	store = p_store
	store_manager = p_store_manager
	economy = p_economy
	customers_root = p_root


func set_path_debug(enabled: bool) -> void:
	path_debug = enabled
	for customer: CustomerController in _active.values():
		customer.set_path_debug(enabled)


func get_active_count() -> int:
	return _active.size()


func get_queue_length() -> int:
	var n := 0
	for q in queues:
		n += q.size()
	return n


func set_lane_count(count: int) -> void:
	_ensure_lanes(clampi(count, 1, 2))


func set_all_pay_sec(pay_sec: float) -> void:
	_ensure_lanes(maxi(queues.size(), 1))
	for q in queues:
		q.pay_sec = pay_sec


func join_shortest_queue(customer: CustomerController) -> int:
	_ensure_lanes(maxi(queues.size(), 1))
	var best := 0
	var best_size := queues[0].size()
	for i in queues.size():
		var size := queues[i].size()
		if size < best_size:
			best = i
			best_size = size
	customer.queue_lane = best
	customer.checkout_queue = queues[best]
	return queues[best].enqueue(customer.runtime.runtime_id)


func wave_progress() -> float:
	if wave.total_to_spawn <= 0:
		return 0.0
	var spawn_p := float(wave.spawned_count) / float(wave.total_to_spawn)
	var exit_p := 0.0
	var exited := wave.completed_customer_count + wave.failed_count
	if wave.total_to_spawn > 0:
		exit_p = float(exited) / float(wave.total_to_spawn)
	return clampf(spawn_p * 0.55 + exit_p * 0.45, 0.0, 1.0)


func get_first_customer_state() -> String:
	if _active.is_empty():
		return "-"
	var first: CustomerController = _active.values()[0]
	return String(first.runtime.state)


func get_first_customer_type_id() -> String:
	if _active.is_empty():
		return "-"
	var first: CustomerController = _active.values()[0]
	if first == null or first.runtime == null:
		return "-"
	var type_id := first.runtime.customer_type_id
	if type_id == &"":
		return "-"
	return String(type_id)


func reset_wave(total: int = WAVE_SIZE) -> void:
	clear_customers()
	var pay_secs: Array[float] = []
	for q in queues:
		pay_secs.append(q.pay_sec)
	var lane_n := maxi(queues.size(), 1)
	queues.clear()
	for i in lane_n:
		var q := CheckoutQueue.new()
		if i < pay_secs.size():
			q.pay_sec = pay_secs[i]
		elif not pay_secs.is_empty():
			q.pay_sec = pay_secs[0]
		queues.append(q)
	wave.wave_id = &"prototype_002_wave_01"
	wave.state = &"prepare"
	wave.total_to_spawn = maxi(total, 1)
	wave.spawned_count = 0
	wave.active_customer_count = 0
	wave.reset_metrics()
	_spawn_wait = 0.0


func start_wave(total: int = WAVE_SIZE, interval: float = SPAWN_INTERVAL_SEC) -> void:
	spawn_interval_sec = interval
	reset_wave(total)
	wave.state = &"running"
	spawn_one()
	_spawn_wait = spawn_interval_sec


func finish_wave() -> void:
	wave.state = &"complete"
	_spawn_wait = 0.0


func clear_customers() -> void:
	var live: Array = _active.values()
	_active.clear()
	for customer in live:
		if not is_instance_valid(customer):
			continue
		var node := customer as CustomerController
		if node.customer_finished.is_connected(_on_customer_finished):
			node.customer_finished.disconnect(_on_customer_finished)
		if node.customer_paid.is_connected(_on_customer_paid):
			node.customer_paid.disconnect(_on_customer_paid)
		node.queue_free()
	wave.active_customer_count = 0


func is_wave_complete() -> bool:
	return wave.spawned_count >= wave.total_to_spawn and _active.is_empty()


func product_id_for_wave_index(index: int) -> StringName:
	if store_manager == null or store_manager.catalog_order.is_empty():
		if store_manager != null:
			var stocked := store_manager.get_first_stocked_product_id()
			if stocked != &"":
				return stocked
		return &"freshpop_cola_500"
	return store_manager.catalog_order[index % store_manager.catalog_order.size()]


static func list_length_for_spawn(spawn_index: int) -> int:
	return 2 + (1 if absi(spawn_index) % 5 < 2 else 0)


func build_shopping_list(spawn_index: int) -> Array[ShoppingListItem]:
	var items: Array[ShoppingListItem] = []
	var length := list_length_for_spawn(spawn_index)
	var catalog: Array[StringName] = []
	if store_manager != null and not store_manager.catalog_order.is_empty():
		for id in store_manager.catalog_order:
			catalog.append(id)
	else:
		catalog = [
			&"freshpop_cola_500",
			&"aquapure_water_500",
			&"sunnyjuice_orange_330",
			&"crunchbox_cereal_375",
			&"quickbite_chips_150",
		]
	var n := catalog.size()
	var used: Dictionary = {}
	for k in length:
		var product_id := catalog[(spawn_index + k) % n]
		var guard := 0
		while used.has(product_id) and guard < n:
			product_id = catalog[(spawn_index + k + guard + 1) % n]
			guard += 1
		used[product_id] = true
		var list_item := ShoppingListItem.new()
		list_item.product_id = product_id
		items.append(list_item)
	return items


static func customers_for_wave(wave_number: int) -> int:
	return mini(WAVE_CAP, WAVE_SIZE + maxi(wave_number - 1, 0) * WAVE_GROWTH)


static func spawn_interval_for_wave(wave_number: int) -> float:
	return maxf(0.75, SPAWN_INTERVAL_SEC - float(maxi(wave_number - 1, 0)) * 0.08)


func preview_wave(total: int = WAVE_SIZE) -> Dictionary:
	var size := maxi(total, 1)
	var sku_qty := {}
	var regular := 0
	var impatient := 0
	for i in size:
		var list := build_shopping_list(i)
		for item in list:
			sku_qty[item.product_id] = int(sku_qty.get(item.product_id, 0)) + 1
		if i % 2 == 0:
			regular += 1
		else:
			impatient += 1
	var skus: Array[Dictionary] = []
	if store_manager != null:
		for product_id in store_manager.catalog_order:
			if sku_qty.has(product_id):
				skus.append({"product_id": product_id, "qty": int(sku_qty[product_id])})
	else:
		for product_id in sku_qty.keys():
			skus.append({"product_id": product_id, "qty": int(sku_qty[product_id])})
	return {
		"total": size,
		"regular": regular,
		"impatient": impatient,
		"skus": skus,
	}


func spawn_one() -> CustomerController:
	if customer_scene == null:
		push_error("CustomerManager missing customer scene")
		return null
	if wave.total_to_spawn > 0 and wave.spawned_count >= wave.total_to_spawn:
		return null
	var customer := customer_scene.instantiate() as CustomerController
	var runtime := CustomerRuntimeState.new()
	runtime.runtime_id = ids.next(&"customer")
	runtime.state = &"spawning"
	var spawn_index := wave.spawned_count
	runtime.shopping_list = build_shopping_list(spawn_index)
	var wanted := runtime.shopping_list[0].product_id if not runtime.shopping_list.is_empty() else product_id_for_wave_index(spawn_index)
	customer.runtime = runtime
	customer.store = store
	customer.store_manager = store_manager
	customer.customer_manager = self
	customer.checkout_queue = checkout_queue
	customer.queue_lane = 0
	customer.product_id = wanted
	customers_root.add_child(customer)
	customer.global_position = store.get_entrance_position()
	customer.set_path_debug(path_debug)
	if spawn_index % 2 == 0:
		customer.apply_archetype(&"regular_customer")
	else:
		customer.apply_archetype(&"impatient_customer")
	customer.customer_finished.connect(_on_customer_finished)
	customer.customer_paid.connect(_on_customer_paid)
	_active[runtime.runtime_id] = customer
	wave.spawned_count += 1
	wave.active_customer_count += 1
	customer_spawned.emit(runtime.runtime_id)
	var product := store_manager.get_product(wanted) if store_manager != null else null
	var label := product.display_name if product != null else String(wanted)
	GameLog.info("CUSTOMER", "%s spawned for %s (%d/%d)" % [String(runtime.runtime_id), label, wave.spawned_count, wave.total_to_spawn])
	customer.begin_shopping()
	return customer


func _process(delta: float) -> void:
	if wave.state != &"running":
		return
	wave.elapsed_sec += delta
	_tick_checkout_queue(delta)
	if wave.spawned_count >= wave.total_to_spawn:
		return
	_spawn_wait -= delta
	if _spawn_wait > 0.0:
		return
	spawn_one()
	_spawn_wait = spawn_interval_sec


func _tick_checkout_queue(delta: float) -> void:
	for q in queues:
		_tick_one_queue(q, delta)


func _tick_one_queue(queue: CheckoutQueue, delta: float) -> void:
	if queue == null:
		return
	var front_id := queue.front()
	var front_customer := _active.get(front_id) as CustomerController
	var front_ready := (
		front_customer != null
		and front_customer.runtime != null
		and (
			front_customer.runtime.state == CustomerController.STATE_PAYING
			or front_customer.runtime.state == CustomerController.STATE_QUEUED
		)
	)
	if front_ready and front_customer.runtime.state == CustomerController.STATE_QUEUED:
		queue.start_pay_if_idle()
		front_customer.runtime.state = CustomerController.STATE_PAYING
	if front_ready and queue.advance_pay(delta):
		if front_customer != null:
			front_customer._complete_pay()
		elif front_id != &"":
			queue.dequeue(front_id)
		_retarget_queue_slots()
	if not queue.wait_tick_due(delta):
		return
	var abandoned := false
	var live: Array = _active.values()
	for customer in live:
		var node := customer as CustomerController
		if node == null or node.runtime == null:
			continue
		if node.checkout_queue != queue:
			continue
		if node.runtime.state != CustomerController.STATE_QUEUED:
			continue
		var raw := queue.index_of(node.runtime.runtime_id)
		if raw < 0 or queue.display_index(raw) < 1:
			continue
		if node.apply_queue_wait_tick():
			node._fail(&"queue")
			abandoned = true
	if abandoned:
		_retarget_queue_slots()


func _retarget_queue_slots() -> void:
	for customer: CustomerController in _active.values():
		if customer == null:
			continue
		customer.retarget_queue_slot()


func _ensure_lanes(count: int) -> void:
	var n := clampi(count, 1, 2)
	var pay := CheckoutQueue.PAY_SEC
	if not queues.is_empty():
		pay = queues[0].pay_sec
	while queues.size() < n:
		var q := CheckoutQueue.new()
		q.pay_sec = pay
		queues.append(q)
	while queues.size() > n:
		queues.pop_back()


func _lost_value_for(runtime: CustomerRuntimeState) -> float:
	if runtime == null or runtime.shopping_list.is_empty() or store_manager == null:
		return 0.0
	var total := 0.0
	for item in runtime.shopping_list:
		var product := store_manager.get_product(item.product_id)
		if product != null:
			total += product.selling_price
	return total


func _on_customer_paid(_customer_id: StringName, revenue: float, cogs: float) -> void:
	economy.add_revenue(revenue, &"sale", cogs)
	sale_completed.emit(revenue, cogs)


func _on_customer_finished(customer_id: StringName, served: bool) -> void:
	var node := _active.get(customer_id) as CustomerController
	if node != null and node.runtime != null:
		var lost_value := 0.0 if served else _lost_value_for(node.runtime)
		wave.record_customer_exit(served, node.runtime.satisfaction, lost_value, node.runtime.fail_reason)
		if not served:
			GameLog.info("WAVE", "Lost sale %s value=%.2f sat=%.0f" % [String(node.runtime.fail_reason), lost_value, node.runtime.satisfaction])
	wave.active_customer_count = maxi(wave.active_customer_count - 1, 0)
	_active.erase(customer_id)
	customer_exited.emit(customer_id, served)
