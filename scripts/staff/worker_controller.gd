class_name WorkerController
extends CharacterBody3D

const MOVE_SPEED := 2.5
const STATE_IDLE := &"idle"
const STATE_TO_PICK := &"to_pick"
const STATE_TO_SHELF := &"to_shelf"
const STATE_TO_HOME := &"to_home"

var store: StoreRoom
var store_manager: StoreManager
var inventory: InventoryManager
var staff_manager: StaffManager
var state: StringName = STATE_IDLE
var current_task: ReplenishmentTask
var current_target: Dictionary = {}
var carry: int = 0
var carry_product: StringName = &""

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var model: CharacterModel = $Model

var _awaiting_arrival: bool = false
var _visited: Dictionary = {}


func _ready() -> void:
	agent.path_desired_distance = 0.45
	agent.target_desired_distance = 0.7
	agent.avoidance_enabled = false
	var visual := get_node_or_null("Visual") as MeshInstance3D
	if visual != null:
		visual.visible = false
	if model != null:
		model.set_kind(&"worker")


func begin_idle() -> void:
	state = STATE_IDLE
	current_task = null
	current_target = {}
	carry = 0
	carry_product = &""
	_visited.clear()
	_awaiting_arrival = false
	_stop_locomotion()
	_sync_carry_visual()


func start_task(task: ReplenishmentTask) -> void:
	current_task = task
	state = STATE_TO_PICK
	GameLog.info("STAFF", "Worker to_pick %s" % String(task.product_id if task else &""))
	_go_to_pick.call_deferred()


func deactivate() -> void:
	_awaiting_arrival = false
	velocity = Vector3.ZERO
	if carry > 0 and inventory != null:
		inventory.add_to_warehouse(carry_product, carry)
		GameLog.info("STAFF", "Returned carry %s x%d" % [String(carry_product), carry])
	carry = 0
	carry_product = &""
	current_task = null
	current_target = {}
	_visited.clear()
	state = STATE_IDLE
	_sync_carry_visual()


func _physics_process(_delta: float) -> void:
	if not _awaiting_arrival or state == STATE_IDLE:
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


func _go_to_pick() -> void:
	var target := global_position
	if store != null:
		target = store.get_backroom_pick_position()
	await _set_target(target)


func _on_arrived() -> void:
	match state:
		STATE_TO_PICK:
			_pick()
		STATE_TO_SHELF:
			_deliver()
		STATE_TO_HOME:
			_arrive_home()
		STATE_IDLE:
			pass
		_:
			push_warning("Unhandled worker state: %s" % String(state))


func _pick() -> void:
	if current_task == null or inventory == null:
		_drop_and_idle()
		return
	_visited.clear()
	current_target = {}
	var product_id := current_task.product_id
	var want := 6
	if staff_manager != null:
		want = staff_manager.pick_want(product_id)
	carry = inventory.take_from_warehouse(product_id, want)
	carry_product = product_id
	if carry <= 0:
		_go_home.call_deferred()
		return
	GameLog.info("STAFF", "Picked %s x%d" % [String(carry_product), carry])
	_sync_carry_visual()
	_choose_next_shelf()
	if current_target.is_empty():
		_go_home.call_deferred()
		return
	state = STATE_TO_SHELF
	_go_to_shelf.call_deferred()


func _go_to_shelf() -> void:
	var target := global_position
	var instance_id := _target_instance_id()
	if instance_id != &"" and store_manager != null:
		var fixture_node := store_manager.get_fixture_node(instance_id)
		if fixture_node != null:
			target = await _first_reachable_approach(fixture_node)
	await _set_target(target)


func _deliver() -> void:
	var placement := _current_placement()
	var others := 0
	if staff_manager != null:
		others = staff_manager.list_eligible_shelves(carry_product, {}).size() - 1
	var room := 0
	if placement != null:
		room = maxi(0, placement.capacity - placement.shelf_stock)
	var drop := carry
	if staff_manager != null:
		drop = staff_manager.drop_amount(carry, room, others)
	var can_shelve := (
		placement != null
		and store_manager != null
		and drop > 0
		and carry_product != &""
		and placement.product_id == carry_product
	)
	if can_shelve:
		var added := store_manager.add_shelf_stock(placement.placement_id, drop)
		carry -= added
		GameLog.info("STAFF", "Shelved %s x%d" % [String(carry_product), added])
	_mark_current_visited()
	_sync_carry_visual()
	if carry > 0:
		_choose_next_shelf()
		if not current_target.is_empty():
			state = STATE_TO_SHELF
			_go_to_shelf.call_deferred()
			return
	_go_home.call_deferred()


func _go_home() -> void:
	state = STATE_TO_HOME
	GameLog.info("STAFF", "Worker to_home")
	var target := global_position
	if store != null:
		target = store.get_backroom_pick_position()
	await _set_target(target)


func _arrive_home() -> void:
	if carry > 0 and inventory != null:
		inventory.add_to_warehouse(carry_product, carry)
		GameLog.info("STAFF", "Returned leftover %s x%d" % [String(carry_product), carry])
	carry = 0
	carry_product = &""
	_sync_carry_visual()
	var done := current_task
	begin_idle()
	if staff_manager != null:
		staff_manager.finish_trip(done)


func _drop_and_idle() -> void:
	if carry > 0 and inventory != null:
		inventory.add_to_warehouse(carry_product, carry)
	carry = 0
	carry_product = &""
	_sync_carry_visual()
	var done := current_task
	begin_idle()
	if staff_manager != null:
		staff_manager.finish_trip(done)


func _choose_next_shelf() -> void:
	current_target = {}
	if staff_manager == null or carry <= 0 or carry_product == &"":
		return
	var preferred := staff_manager.list_eligible_shelves(carry_product, _visited)
	if preferred.is_empty():
		preferred = staff_manager.list_eligible_shelves(carry_product, {})
	if preferred.is_empty():
		return
	var idx := int(staff_manager.pick_eligible_index.call(preferred.size()))
	idx = clampi(idx, 0, preferred.size() - 1)
	current_target = preferred[idx]


func _mark_current_visited() -> void:
	var instance_id := _target_instance_id()
	if instance_id == &"":
		return
	var shelf_index := _target_shelf_index()
	_visited[StringName("%s:%d" % [String(instance_id), shelf_index])] = true


func _current_placement() -> ProductPlacementState:
	var instance_id := _target_instance_id()
	var shelf_index := _target_shelf_index()
	if instance_id == &"" or store_manager == null:
		return null
	var fixture := store_manager.get_fixture(instance_id)
	if fixture == null:
		return null
	for shelf: ShelfState in fixture.shelf_states:
		if shelf.shelf_index != shelf_index:
			continue
		if shelf.placements.is_empty():
			return null
		return shelf.placements[0]
	return null


func _target_instance_id() -> StringName:
	if current_target.has("instance_id"):
		return current_target["instance_id"]
	if current_task != null:
		return current_task.instance_id
	return &""


func _target_shelf_index() -> int:
	if current_target.has("shelf_index"):
		return int(current_target["shelf_index"])
	if current_task != null:
		return current_task.shelf_index
	return 0


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
		origin,
	]
	for candidate in candidates:
		if await _is_reachable(candidate):
			return candidate
	return origin


func _is_reachable(world_pos: Vector3) -> bool:
	agent.target_position = Vector3(world_pos.x, 0.0, world_pos.z)
	for _i in 4:
		await get_tree().physics_frame
		if NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) == 0:
			continue
		return agent.is_target_reachable()
	return agent.is_target_reachable()


func _stop_locomotion() -> void:
	velocity = Vector3.ZERO
	_set_locomotion(false)


func _sync_carry_visual() -> void:
	var visual := model if model != null else get_node_or_null("Model") as CharacterModel
	if visual == null:
		return
	if carry <= 0:
		visual.clear_carry_goods()
		return
	var product: ProductDefinition = null
	if store_manager != null:
		product = store_manager.get_product(carry_product)
	visual.set_carry_goods(product, carry)


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
	if state == STATE_IDLE:
		return
	if not agent.is_target_reachable():
		GameLog.info("STAFF", "Worker no path to target")
		if state == STATE_TO_HOME:
			_drop_and_idle()
		elif carry > 0:
			_go_home.call_deferred()
		else:
			_drop_and_idle()
		return
	_awaiting_arrival = true
	if agent.is_navigation_finished():
		_awaiting_arrival = false
		_on_arrived()
