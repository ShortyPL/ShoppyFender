class_name CustomerController
extends CharacterBody3D

const MOVE_SPEED := 2.5
const STATE_ENTERING := &"entering"
const STATE_MOVING_TO_PRODUCT := &"moving_to_product"
const STATE_PICKING_PRODUCT := &"picking_product"
const STATE_MOVING_TO_CHECKOUT := &"moving_to_checkout"
const STATE_QUEUED := &"queued"
const STATE_PAYING := &"paying"
const STATE_LEAVING := &"leaving"
const STATE_FINISHED := &"finished"
const STATE_FAILED := &"failed"

signal customer_finished(customer_id: StringName, served: bool)
signal customer_paid(customer_id: StringName, revenue: float, cogs: float)

var runtime: CustomerRuntimeState
var store: StoreRoom
var store_manager: StoreManager
var customer_manager: CustomerManager
var checkout_queue: CheckoutQueue
var queue_lane: int = 0
var product_id: StringName = &"freshpop_cola_500"

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var model: CharacterModel = $Model

var _placement: ProductPlacementState
var _debug_paths: bool = false
var _awaiting_arrival: bool = false


func _ready() -> void:
	agent.path_desired_distance = 0.45
	agent.target_desired_distance = 0.7
	agent.avoidance_enabled = false
	agent.debug_enabled = _debug_paths
	_hide_placeholder()
	_apply_character_model()


func set_path_debug(enabled: bool) -> void:
	_debug_paths = enabled
	if agent:
		agent.debug_enabled = enabled


func apply_archetype(type_id: StringName) -> void:
	if runtime == null:
		return
	runtime.customer_type_id = type_id
	match type_id:
		&"impatient_customer":
			runtime.leave_threshold = 60.0
		&"regular_customer":
			runtime.leave_threshold = 100.0
		_:
			runtime.leave_threshold = 100.0
			push_warning("Unhandled customer archetype: %s" % String(type_id))
	_apply_character_model()


func apply_queue_wait_tick() -> bool:
	if runtime == null:
		return false
	var bump := 15.0 if runtime.customer_type_id == &"impatient_customer" else 10.0
	runtime.frustration = minf(100.0, runtime.frustration + bump)
	runtime.satisfaction = clampf(100.0 - runtime.frustration, 0.0, 100.0)
	return runtime.frustration >= runtime.leave_threshold


func retarget_queue_slot() -> void:
	if runtime == null or store == null or checkout_queue == null:
		return
	var raw := checkout_queue.index_of(runtime.runtime_id)
	if raw < 0:
		return
	if runtime.state == STATE_PAYING and raw == 0:
		return
	if runtime.state == STATE_LEAVING or runtime.state == STATE_FINISHED or runtime.state == STATE_FAILED:
		return
	runtime.state = STATE_MOVING_TO_CHECKOUT
	_set_target(store.get_queue_slot_position(queue_lane, checkout_queue.display_index(raw)))


func begin_shopping() -> void:
	runtime.state = STATE_ENTERING
	GameLog.info("CUSTOMER", "%s entered store" % String(runtime.runtime_id))
	_go_to_product.call_deferred()


func _physics_process(_delta: float) -> void:
	if runtime == null or runtime.state == STATE_FINISHED or runtime.state == STATE_FAILED:
		_stop_locomotion()
		return
	if not _awaiting_arrival:
		_stop_locomotion()
		return
	if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
		_stop_locomotion()
		return
	if agent.is_navigation_finished():
		_awaiting_arrival = false
		_stop_locomotion()
		_on_arrived()
		return
	var next_pos := agent.get_next_path_position()
	var direction := global_position.direction_to(next_pos)
	direction.y = 0.0
	if direction.length() < 0.001:
		_stop_locomotion()
		return
	direction = direction.normalized()
	velocity = direction * MOVE_SPEED
	look_at(global_position + direction, Vector3.UP, true)
	move_and_slide()
	_set_locomotion(true)


func _go_to_product() -> void:
	await get_tree().physics_frame
	var next_id := _next_unfulfilled_product()
	if next_id == &"":
		_go_to_checkout()
		return
	product_id = next_id
	_placement = store_manager.get_first_placement_for_product(product_id)
	if _placement == null:
		GameLog.info("CUSTOMER", "%s searching for product %s — none in stock" % [String(runtime.runtime_id), String(product_id)])
		_fail(&"out_of_stock")
		return
	GameLog.info("CUSTOMER", "%s targeting %s" % [String(runtime.runtime_id), String(product_id)])
	runtime.state = STATE_MOVING_TO_PRODUCT
	var fixture_node := store_manager.get_fixture_node(_placement.fixture_instance_id)
	var target := store.get_entrance_position()
	if fixture_node:
		target = await _first_reachable_approach(fixture_node)
	await _set_target(target)


func _next_unfulfilled_product() -> StringName:
	if runtime == null:
		return product_id
	for item in runtime.shopping_list:
		if item.fulfilled_quantity < maxi(item.requested_quantity, 1):
			return item.product_id
	return &""


func _go_to_checkout() -> void:
	runtime.state = STATE_MOVING_TO_CHECKOUT
	var approach := store.get_checkout_approach_position(0) if store != null else Vector3(3.5, 0.0, 2.8)
	_set_target(approach)


func _on_arrived() -> void:
	match runtime.state:
		STATE_ENTERING:
			pass
		STATE_MOVING_TO_PRODUCT:
			_pick_product()
		STATE_MOVING_TO_CHECKOUT:
			_enter_queued()
		STATE_LEAVING:
			_finish(runtime.fail_reason == &"")
		STATE_QUEUED, STATE_PICKING_PRODUCT, STATE_PAYING, STATE_FINISHED, STATE_FAILED, &"spawning":
			pass
		_:
			push_warning("Unhandled customer state: %s" % String(runtime.state))


func _pick_product() -> void:
	runtime.state = STATE_PICKING_PRODUCT
	_placement = store_manager.get_first_placement_for_product(product_id)
	if _placement == null or not store_manager.take_from_shelf(_placement.placement_id):
		GameLog.info("CUSTOMER", "%s found empty shelf for %s" % [String(runtime.runtime_id), String(product_id)])
		_fail(&"out_of_stock")
		return
	var product := store_manager.get_product(product_id)
	var item := BasketItem.new()
	item.product_id = product_id
	item.quantity = 1
	item.unit_price = product.selling_price if product else 2.50
	item.unit_cost = product.purchase_price if product else 1.20
	runtime.basket.append(item)
	for list_item in runtime.shopping_list:
		if list_item.product_id == product_id and list_item.fulfilled_quantity < maxi(list_item.requested_quantity, 1):
			list_item.fulfilled_quantity += 1
			break
	_show_basket_product()
	if _next_unfulfilled_product() != &"":
		_go_to_product.call_deferred()
		return
	_go_to_checkout()


func _enter_queued() -> void:
	if checkout_queue == null and customer_manager == null:
		runtime.state = STATE_QUEUED
		return
	var raw := -1
	if checkout_queue != null:
		raw = checkout_queue.index_of(runtime.runtime_id)
	if raw < 0:
		var slot := 0
		if customer_manager != null:
			slot = customer_manager.join_shortest_queue(self)
		elif checkout_queue != null:
			slot = checkout_queue.enqueue(runtime.runtime_id)
		if slot != 0:
			runtime.state = STATE_MOVING_TO_CHECKOUT
			_set_target(store.get_queue_slot_position(queue_lane, slot))
			return
		raw = 0
	runtime.state = STATE_QUEUED
	if raw == 0 and checkout_queue != null:
		checkout_queue.start_pay_if_idle()
		runtime.state = STATE_PAYING


func _complete_pay() -> void:
	if runtime == null:
		return
	if runtime.state == STATE_LEAVING or runtime.state == STATE_FINISHED or runtime.state == STATE_FAILED:
		return
	var revenue := 0.0
	var cogs := 0.0
	for item: BasketItem in runtime.basket:
		revenue += item.unit_price * item.quantity
		cogs += item.unit_cost * item.quantity
	runtime.money_spent = revenue
	GameLog.info("SALE", "%s paid %.2f" % [String(runtime.runtime_id), revenue])
	customer_paid.emit(runtime.runtime_id, revenue, cogs)
	if checkout_queue != null:
		checkout_queue.dequeue(runtime.runtime_id)
	runtime.state = STATE_LEAVING
	_set_target(store.get_exit_position())


func _finish(served: bool) -> void:
	runtime.state = STATE_FINISHED if served else STATE_FAILED
	if served:
		GameLog.info("CUSTOMER", "%s exited store" % String(runtime.runtime_id))
	else:
		GameLog.info("CUSTOMER", "%s failed and left" % String(runtime.runtime_id))
	customer_finished.emit(runtime.runtime_id, served)
	queue_free()


func _fail(reason: StringName = &"out_of_stock") -> void:
	if runtime == null:
		return
	if reason == &"queue":
		runtime.fail_reason = &"queue"
		if checkout_queue != null:
			checkout_queue.dequeue(runtime.runtime_id)
		if store_manager != null:
			for basket_item: BasketItem in runtime.basket:
				var placement := store_manager.get_first_placement_for_product(basket_item.product_id)
				if placement != null:
					store_manager.add_shelf_stock(placement.placement_id, basket_item.quantity)
		runtime.basket.clear()
		_hide_basket_product()
		GameLog.info("CUSTOMER", "%s abandoned queue" % String(runtime.runtime_id))
		runtime.state = STATE_LEAVING
		_set_target(store.get_exit_position())
		return
	var penalty := 15.0
	match reason:
		&"out_of_stock":
			penalty = 20.0
		&"no_path":
			penalty = 25.0
		&"unavailable":
			penalty = 15.0
		_:
			push_warning("Unhandled fail reason: %s" % String(reason))
			penalty = 15.0
	runtime.fail_reason = reason
	runtime.frustration = minf(100.0, runtime.frustration + penalty)
	runtime.satisfaction = clampf(100.0 - runtime.frustration, 0.0, 100.0)
	runtime.state = STATE_FAILED
	_finish(false)


func _first_reachable_approach(fixture_node: Node3D) -> Vector3:
	var origin := fixture_node.global_position
	var forward := -fixture_node.global_transform.basis.z
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var right := fixture_node.global_transform.basis.x
	if right.length() < 0.001:
		right = Vector3.RIGHT
	right = right.normalized()
	var candidates: Array[Vector3] = [
		origin + forward * 0.9,
		origin - forward * 0.9,
		origin + right * 1.1,
		origin - right * 1.1,
	]
	for candidate in candidates:
		if await _is_reachable(candidate):
			return candidate
	return candidates[0]


func _is_reachable(world_pos: Vector3) -> bool:
	agent.target_position = Vector3(world_pos.x, 0.0, world_pos.z)
	for _i in 4:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
			continue
		return agent.is_target_reachable()
	return agent.is_target_reachable()


func _hide_placeholder() -> void:
	var visual := get_node_or_null("Visual") as MeshInstance3D
	if visual != null:
		visual.visible = false


func _apply_character_model() -> void:
	if not is_inside_tree():
		return
	var visual := get_node_or_null("Model") as CharacterModel
	if visual == null:
		return
	var kind := &"regular"
	if runtime != null and runtime.customer_type_id == &"impatient_customer":
		kind = &"impatient"
	var variety := 0
	if runtime != null:
		if kind == &"impatient":
			variety = absi(String(runtime.runtime_id).hash()) % 2
		else:
			variety = absi(String(runtime.runtime_id).hash()) % 9
	visual.set_kind(kind, variety)


func _show_basket_product() -> void:
	var visual := model if model != null else get_node_or_null("Model") as CharacterModel
	if visual == null or store_manager == null:
		return
	visual.set_basket_product(store_manager.get_product(product_id))


func _hide_basket_product() -> void:
	var visual := model if model != null else get_node_or_null("Model") as CharacterModel
	if visual != null:
		visual.clear_basket_product()


func _stop_locomotion() -> void:
	velocity = Vector3.ZERO
	_set_locomotion(false)


func _set_locomotion(moving: bool) -> void:
	var visual := model if model != null else get_node_or_null("Model") as CharacterModel
	if visual != null:
		visual.set_moving(moving)


func _set_target(world_pos: Vector3) -> void:
	_awaiting_arrival = false
	agent.target_position = Vector3(world_pos.x, 0.0, world_pos.z)
	for _i in 4:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) != 0:
			break
	if runtime == null or runtime.state == STATE_FINISHED or runtime.state == STATE_FAILED:
		return
	if not agent.is_target_reachable():
		GameLog.info("CUSTOMER", "%s no path to target" % String(runtime.runtime_id))
		_fail(&"no_path")
		return
	_awaiting_arrival = true
	if agent.is_navigation_finished():
		_awaiting_arrival = false
		_on_arrived()
