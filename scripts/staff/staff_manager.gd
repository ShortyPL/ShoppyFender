class_name StaffManager
extends Node

signal task_started(task_id: StringName)
signal task_finished(task_id: StringName)

const CARRY_LIMIT := 6
const DROP_CAP := 3
const PRIORITY_PPM := 1
const PRIORITY_AUTO := 0

var store: StoreRoom
var store_manager: StoreManager
var inventory: InventoryManager
var workers_root: Node3D
var ids := RuntimeIdGenerator.new()
var pick_eligible_index: Callable = func(n: int) -> int:
	if n <= 0:
		return 0
	return randi() % n

var _queue: Array[ReplenishmentTask] = []
var _busy_keys: Dictionary = {}
var _workers: Array[WorkerController] = []
var _cashier: CashierController
var _cashiers: Array[CashierController] = []
var _worker_active: bool = true
var _auto_fill_empties: bool = false
var auto_fill_preference: bool = false
var worker_scene: PackedScene
var cashier_scene: PackedScene


func setup(p_store: StoreRoom, p_store_manager: StoreManager, p_inventory: InventoryManager, p_workers_root: Node3D) -> void:
	store = p_store
	store_manager = p_store_manager
	inventory = p_inventory
	workers_root = p_workers_root


func spawn_worker(scene: PackedScene) -> WorkerController:
	var used := scene if scene != null else worker_scene
	if used == null or workers_root == null:
		return null
	if scene != null:
		worker_scene = scene
	var worker := used.instantiate() as WorkerController
	worker.store = store
	worker.store_manager = store_manager
	worker.inventory = inventory
	worker.staff_manager = self
	workers_root.add_child(worker)
	if store != null:
		worker.global_position = store.get_backroom_pick_position()
	worker.begin_idle()
	_workers.append(worker)
	GameLog.info("STAFF", "Worker spawned (%d)" % _workers.size())
	return worker


func spawn_cashier(scene: PackedScene) -> CashierController:
	if scene == null or workers_root == null:
		return null
	cashier_scene = scene
	_cashier = scene.instantiate() as CashierController
	workers_root.add_child(_cashier)
	_cashiers = [_cashier]
	if store != null:
		_cashier.station_at(store.get_cashier_position(0), store.get_cashier_facing())
	GameLog.info("STAFF", "Cashier spawned")
	return _cashier


func ensure_cashier_lanes(lane_count: int, scene: PackedScene = null) -> void:
	var used := scene if scene != null else cashier_scene
	if used == null or workers_root == null:
		return
	cashier_scene = used
	while _cashiers.size() < clampi(lane_count, 1, 2):
		var lane := _cashiers.size()
		var cashier := used.instantiate() as CashierController
		workers_root.add_child(cashier)
		if store != null:
			cashier.station_at(store.get_cashier_position(lane), store.get_cashier_facing())
		_cashiers.append(cashier)
		if _cashier == null:
			_cashier = cashier
		GameLog.info("STAFF", "Cashier lane %d spawned" % lane)


func get_cashier() -> CashierController:
	return _cashier


func set_cashier_busy(busy: bool) -> void:
	for cashier in _cashiers:
		if cashier != null:
			cashier.set_busy(busy)
	if _cashiers.is_empty() and _cashier != null:
		_cashier.set_busy(busy)


func request_restock_fixture(instance_id: StringName) -> int:
	if store_manager == null or inventory == null:
		return 0
	var fixture := store_manager.get_fixture(instance_id)
	if fixture == null:
		return 0
	var queued := 0
	var seen: Dictionary = {}
	for shelf: ShelfState in fixture.shelf_states:
		var placement := _placement_on_shelf(shelf)
		if placement == null:
			continue
		if seen.has(placement.product_id):
			continue
		if placement.shelf_stock >= placement.capacity:
			continue
		if inventory.get_warehouse(placement.product_id) <= 0:
			continue
		if _enqueue(instance_id, shelf.shelf_index, placement.product_id, PRIORITY_PPM):
			seen[placement.product_id] = true
			queued += 1
	return queued


func restock_fail_reason(instance_id: StringName) -> StringName:
	if store_manager == null:
		return &"warehouse_empty"
	var fixture := store_manager.get_fixture(instance_id)
	if fixture == null:
		return &"warehouse_empty"
	var has_product := false
	var has_room := false
	var already_queued := false
	for shelf: ShelfState in fixture.shelf_states:
		var placement := _placement_on_shelf(shelf)
		if placement == null:
			continue
		has_product = true
		if placement.shelf_stock >= placement.capacity:
			continue
		has_room = true
		if _busy_keys.has(placement.product_id):
			already_queued = true
	if not has_product:
		return &"no_product"
	if not has_room:
		return &"full"
	if already_queued:
		return &"queued"
	return &"warehouse_empty"


func set_auto_fill_empties(enabled: bool) -> void:
	_auto_fill_empties = enabled


func is_auto_fill_empties() -> bool:
	return _auto_fill_empties


func set_auto_fill_preference(enabled: bool) -> void:
	auto_fill_preference = enabled
	_auto_fill_empties = enabled


func restore_auto_fill_preference() -> void:
	_auto_fill_empties = auto_fill_preference


func queue_empty_shelves() -> int:
	var before := _queue.size()
	_assign_unassigned_empties()
	_scan_auto_empties()
	return _queue.size() - before


func has_any_warehouse() -> bool:
	if inventory == null:
		return false
	for key in inventory.state.warehouse_stock.keys():
		if inventory.get_warehouse(key) > 0:
			return true
	return false


func clear_tasks() -> void:
	_queue.clear()
	_busy_keys.clear()


func worker_count() -> int:
	return _workers.size()


func set_worker_active(active: bool) -> void:
	_worker_active = active
	if active:
		return
	for worker in _workers:
		var interrupted := worker.current_task
		worker.deactivate()
		if interrupted != null:
			_busy_keys.erase(interrupted.product_id)


func pending_task_count() -> int:
	return _queue.size()


func get_worker_state() -> StringName:
	for worker in _workers:
		if worker.state != WorkerController.STATE_IDLE:
			return worker.state
	return WorkerController.STATE_IDLE


func execute_next_instant() -> int:
	if _queue.is_empty():
		return 0
	var task := _pop_next()
	task_started.emit(task.task_id)
	var added := _execute_task_instant(task)
	_finish_task(task)
	return added


func execute_next_instant_swap_before_deliver(new_product_id: StringName) -> int:
	if _queue.is_empty() or store_manager == null or inventory == null:
		return 0
	var task := _pop_next()
	task_started.emit(task.task_id)
	var product_id := task.product_id
	var want := pick_want(product_id)
	var carry := inventory.take_from_warehouse(product_id, want)
	store_manager.assign_product_to_shelf(task.instance_id, task.shelf_index, new_product_id, 0)
	var added := run_hop_loop(task, product_id, carry)
	_finish_task(task)
	return added


func finish_trip(task: ReplenishmentTask) -> void:
	if task == null:
		return
	_finish_task(task)
	_try_dispatch()


func sku_room(product_id: StringName) -> int:
	var total := 0
	for entry: Dictionary in list_eligible_shelves(product_id, {}):
		var placement: ProductPlacementState = entry["placement"]
		total += maxi(0, placement.capacity - placement.shelf_stock)
	return total


func pick_want(product_id: StringName) -> int:
	if inventory == null:
		return 0
	return mini(CARRY_LIMIT, mini(inventory.get_warehouse(product_id), sku_room(product_id)))


func drop_amount(carry: int, room: int, others_with_room: int) -> int:
	if others_with_room <= 0:
		return mini(carry, room)
	return mini(carry, mini(room, DROP_CAP))


func list_eligible_shelves(product_id: StringName, visited: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if store_manager == null or product_id == &"":
		return out
	for fixture_state: FixtureInstanceState in store_manager.runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			var placement := _placement_on_shelf(shelf)
			if placement == null:
				continue
			if placement.product_id != product_id:
				continue
			if placement.shelf_stock >= placement.capacity:
				continue
			var key := _shelf_key(fixture_state.instance_id, shelf.shelf_index)
			if not visited.is_empty() and visited.has(key):
				continue
			out.append({
				"instance_id": fixture_state.instance_id,
				"shelf_index": shelf.shelf_index,
				"placement": placement,
			})
	return out


func run_hop_loop(_task: ReplenishmentTask, carry_product: StringName, carry: int) -> int:
	var visited := {}
	var added_total := 0
	var leftover := carry
	while leftover > 0:
		var preferred := list_eligible_shelves(carry_product, visited)
		if preferred.is_empty():
			preferred = list_eligible_shelves(carry_product, {})
		if preferred.is_empty():
			break
		var idx := int(pick_eligible_index.call(preferred.size()))
		idx = clampi(idx, 0, preferred.size() - 1)
		var target: Dictionary = preferred[idx]
		var placement: ProductPlacementState = target["placement"]
		var room := maxi(0, placement.capacity - placement.shelf_stock)
		var others := list_eligible_shelves(carry_product, {}).size() - 1
		var drop := drop_amount(leftover, room, others)
		if drop <= 0:
			break
		var added := store_manager.add_shelf_stock(placement.placement_id, drop)
		if added <= 0:
			visited[_shelf_key(target["instance_id"], int(target["shelf_index"]))] = true
			if visited.size() >= list_eligible_shelves(carry_product, {}).size():
				break
			continue
		leftover -= added
		added_total += added
		visited[_shelf_key(target["instance_id"], int(target["shelf_index"]))] = true
	if leftover > 0 and inventory != null:
		inventory.add_to_warehouse(carry_product, leftover)
	return added_total


func _process(_delta: float) -> void:
	if _auto_fill_empties and _worker_active:
		_scan_auto_empties()
	_try_dispatch()


func _try_dispatch() -> void:
	if not _worker_active or _workers.is_empty():
		return
	if _queue.is_empty():
		return
	var idle: WorkerController = null
	for worker in _workers:
		if worker.state == WorkerController.STATE_IDLE:
			idle = worker
			break
	if idle == null:
		return
	var task := _pop_next()
	task_started.emit(task.task_id)
	idle.start_task(task)


func _skus_with_warehouse() -> Array[StringName]:
	var skus: Array[StringName] = []
	if inventory == null:
		return skus
	if store_manager != null:
		for product_id in store_manager.catalog_order:
			if inventory.get_warehouse(product_id) > 0:
				skus.append(product_id)
	if not skus.is_empty():
		return skus
	for key in inventory.state.warehouse_stock.keys():
		var product_id: StringName = key
		if inventory.get_warehouse(product_id) > 0:
			skus.append(product_id)
	return skus


func _assign_unassigned_empties() -> int:
	var skus := _skus_with_warehouse()
	if skus.is_empty() or store_manager == null:
		return 0
	var assigned := 0
	var sku_i := 0
	for fixture_state: FixtureInstanceState in store_manager.runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			if _placement_on_shelf(shelf) != null:
				continue
			var product_id := skus[sku_i % skus.size()]
			if store_manager.assign_product_to_shelf(fixture_state.instance_id, shelf.shelf_index, product_id, 0) == null:
				continue
			assigned += 1
			sku_i += 1
	return assigned


func _scan_auto_empties() -> void:
	if store_manager == null or inventory == null:
		return
	for fixture_state: FixtureInstanceState in store_manager.runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			var placement := _placement_on_shelf(shelf)
			if placement == null:
				continue
			if placement.shelf_stock != 0:
				continue
			if inventory.get_warehouse(placement.product_id) <= 0:
				continue
			_enqueue(fixture_state.instance_id, shelf.shelf_index, placement.product_id, PRIORITY_AUTO)


func _enqueue(instance_id: StringName, shelf_index: int, product_id: StringName, priority: int) -> bool:
	if _busy_keys.has(product_id):
		return false
	var task := ReplenishmentTask.new()
	task.task_id = ids.next(&"replenish")
	task.instance_id = instance_id
	task.shelf_index = shelf_index
	task.product_id = product_id
	task.priority = priority
	_queue.append(task)
	_busy_keys[product_id] = true
	GameLog.info("STAFF", "Queued %s shelf %d pri=%d" % [String(product_id), shelf_index, priority])
	return true


func _pop_next() -> ReplenishmentTask:
	var best_i := 0
	for i in range(1, _queue.size()):
		if _queue[i].priority > _queue[best_i].priority:
			best_i = i
	var task: ReplenishmentTask = _queue[best_i]
	_queue.remove_at(best_i)
	return task


func _execute_task_instant(task: ReplenishmentTask) -> int:
	if inventory == null or store_manager == null:
		return 0
	var product_id := task.product_id
	var want := pick_want(product_id)
	var carry := inventory.take_from_warehouse(product_id, want)
	if carry <= 0:
		return 0
	return run_hop_loop(task, product_id, carry)


func _finish_task(task: ReplenishmentTask) -> void:
	task_finished.emit(task.task_id)
	if inventory != null and sku_room(task.product_id) > 0 and inventory.get_warehouse(task.product_id) > 0:
		_queue.append(task)
		return
	_busy_keys.erase(task.product_id)


func _placement_on_shelf(shelf: ShelfState) -> ProductPlacementState:
	if shelf == null or shelf.placements.is_empty():
		return null
	return shelf.placements[0]


func _shelf_key(instance_id: StringName, shelf_index: int) -> StringName:
	return StringName("%s:%d" % [String(instance_id), shelf_index])
