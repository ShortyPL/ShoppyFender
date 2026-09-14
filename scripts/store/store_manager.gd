class_name StoreManager
extends Node

const TexLib := preload("res://scripts/store/store_textures.gd")
signal fixture_placed(instance_id: StringName)
signal product_assigned(placement_id: StringName)
signal stock_changed(product_id: StringName, placement_id: StringName, old_value: int, new_value: int)

const DEFAULT_FACINGS := 3
const FALLBACK_PRODUCT_WIDTH_M := 0.065
const FALLBACK_PRODUCT_DEPTH_M := 0.065

var ids: RuntimeIdGenerator = RuntimeIdGenerator.new()
var runtime: Dictionary = {}
var fixture_nodes: Dictionary = {}
var product_catalog: Dictionary = {}
var catalog_order: Array[StringName] = []
var fixture_catalog: Dictionary = {}
var fixture_order: Array[StringName] = []
var staff_manager = null


func setup_for_tests() -> void:
	runtime.clear()
	fixture_nodes.clear()
	add_test_gondola()


func add_test_gondola() -> StringName:
	var fixture := FixtureInstanceState.new()
	fixture.instance_id = ids.next(&"fixture_instance")
	fixture.definition_id = &"gondola_basic_100"
	fixture.position = Vector3.ZERO
	fixture.rotation_y_deg = 0.0
	_add_shelf_states(fixture, 4, 1.0, 0.4)
	runtime[fixture.instance_id] = fixture
	return fixture.instance_id


func register_product(product: ProductDefinition) -> void:
	if product == null:
		push_error("Cannot register null product")
		return
	var errors := product.validate()
	if not errors.is_empty():
		push_error("Invalid product %s: %s" % [String(product.id), ", ".join(errors)])
		return
	if product_catalog.has(product.id):
		push_error("Duplicate product id: %s" % String(product.id))
		return
	product_catalog[product.id] = product
	catalog_order.append(product.id)


func register_fixture(definition: FixtureDefinition) -> void:
	if definition == null:
		push_error("Cannot register null fixture")
		return
	var errors := definition.validate()
	if not errors.is_empty():
		push_error("Invalid fixture %s: %s" % [String(definition.id), ", ".join(errors)])
		return
	if fixture_catalog.has(definition.id):
		push_error("Duplicate fixture id: %s" % String(definition.id))
		return
	fixture_catalog[definition.id] = definition
	fixture_order.append(definition.id)


func get_fixture_definition(definition_id: StringName) -> FixtureDefinition:
	return fixture_catalog.get(definition_id, null)


func list_fixtures() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for definition_id in fixture_order:
		var definition: FixtureDefinition = fixture_catalog.get(definition_id, null)
		if definition == null:
			continue
		rows.append({
			"id": definition.id,
			"display_name": definition.display_name,
			"fixture_type": definition.fixture_type,
			"shelf_count": definition.shelf_count,
			"width_m": definition.width_m,
			"depth_m": definition.depth_m,
			"purchase_cost": definition.purchase_cost,
		})
	return rows


func list_catalog() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for product_id in catalog_order:
		var product: ProductDefinition = product_catalog.get(product_id, null)
		if product == null:
			continue
		rows.append({
			"id": product.id,
			"display_name": product.display_name,
			"selling_price": product.selling_price,
		})
	return rows


func get_product(product_id: StringName) -> ProductDefinition:
	return product_catalog.get(product_id, null)


func get_fixture(instance_id: StringName) -> FixtureInstanceState:
	return runtime.get(instance_id, null)


func export_layout() -> Array:
	var rows: Array = []
	for fixture: FixtureInstanceState in runtime.values():
		var shelves: Array = []
		for shelf: ShelfState in fixture.shelf_states:
			var placement := _placement_on_shelf(shelf)
			if placement == null:
				continue
			shelves.append({
				"index": shelf.shelf_index,
				"product_id": String(placement.product_id),
				"stock": placement.shelf_stock,
				"facings": placement.facings,
			})
		rows.append({
			"definition_id": fixture.definition_id,
			"x": fixture.position.x,
			"z": fixture.position.z,
			"rot": fixture.rotation_y_deg,
			"shelves": shelves,
		})
	return rows


func export_stock_snapshot() -> Array:
	var rows: Array = []
	for fixture: FixtureInstanceState in runtime.values():
		for shelf: ShelfState in fixture.shelf_states:
			var placement := _placement_on_shelf(shelf)
			if placement == null:
				continue
			rows.append({
				"instance_id": fixture.instance_id,
				"shelf_index": shelf.shelf_index,
				"product_id": placement.product_id,
				"stock": placement.shelf_stock,
				"facings": placement.facings,
			})
	return rows


func apply_stock_snapshot(rows: Array) -> void:
	for row in rows:
		assign_product_to_shelf(
			row.get("instance_id", &""),
			int(row.get("shelf_index", 0)),
			row.get("product_id", &""),
			int(row.get("stock", 0)),
			int(row.get("facings", -1))
		)


func get_placement(placement_id: StringName) -> ProductPlacementState:
	for fixture_state: FixtureInstanceState in runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			for placement: ProductPlacementState in shelf.placements:
				if placement.placement_id == placement_id:
					return placement
	return null


func get_first_placement_for_product(product_id: StringName) -> ProductPlacementState:
	for fixture_state: FixtureInstanceState in runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			for placement: ProductPlacementState in shelf.placements:
				if placement.product_id == product_id and placement.shelf_stock > 0:
					return placement
	return null


func get_total_shelf_stock(product_id: StringName) -> int:
	var total := 0
	for fixture_state: FixtureInstanceState in runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			for placement: ProductPlacementState in shelf.placements:
				if placement.product_id == product_id:
					total += placement.shelf_stock
	return total


func get_total_any_shelf_stock() -> int:
	var total := 0
	for fixture_state: FixtureInstanceState in runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			for placement: ProductPlacementState in shelf.placements:
				total += placement.shelf_stock
	return total


func get_first_stocked_product_id() -> StringName:
	for fixture_state: FixtureInstanceState in runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			for placement: ProductPlacementState in shelf.placements:
				if placement.shelf_stock > 0:
					return placement.product_id
	return &""


func has_assigned_product() -> bool:
	for fixture_state: FixtureInstanceState in runtime.values():
		for shelf: ShelfState in fixture_state.shelf_states:
			if not shelf.placements.is_empty():
				return true
	return false


func register_placed_fixture(definition: FixtureDefinition, node: Node3D, world_pos: Vector3, rotation_y_deg: float, announce: bool = true) -> FixtureInstanceState:
	var fixture := FixtureInstanceState.new()
	fixture.instance_id = ids.next(&"fixture_instance")
	fixture.definition_id = definition.id
	fixture.position = world_pos
	fixture.rotation_y_deg = rotation_y_deg
	var count := maxi(definition.shelf_count, 1)
	_add_shelf_states(fixture, count, definition.width_m, definition.depth_m)
	runtime[fixture.instance_id] = fixture
	fixture_nodes[fixture.instance_id] = node
	if node.has_method("bind_state"):
		node.bind_state(fixture)
	fixture_placed.emit(fixture.instance_id)
	if announce:
		GameLog.info("STORE", "Placed %s at %s rot %.0f" % [String(definition.id), str(world_pos), rotation_y_deg])
	return fixture


func assign_product_to_fixture(instance_id: StringName, product_id: StringName, starting_stock: int = -1) -> ProductPlacementState:
	var fixture: FixtureInstanceState = get_fixture(instance_id)
	if fixture == null:
		push_warning("Missing fixture %s" % String(instance_id))
		return null
	var existing := _first_placement(fixture)
	if existing != null:
		return assign_product_to_shelf(instance_id, existing.shelf_index, product_id, starting_stock)
	var shelf: ShelfState = _default_assign_shelf(fixture)
	return assign_product_to_shelf(instance_id, shelf.shelf_index, product_id, starting_stock)


func assign_product_to_shelf(instance_id: StringName, shelf_index: int, product_id: StringName, starting_stock: int = -1, facings: int = -1) -> ProductPlacementState:
	var fixture: FixtureInstanceState = get_fixture(instance_id)
	if fixture == null:
		push_warning("Missing fixture %s" % String(instance_id))
		return null
	if not product_catalog.has(product_id) and not product_catalog.is_empty():
		push_warning("Unknown product %s" % String(product_id))
		return null
	var shelf := _shelf_at(fixture, shelf_index)
	if shelf == null:
		push_warning("Fixture %s has no shelf %d" % [String(instance_id), shelf_index])
		return null
	var existing := _placement_on_shelf(shelf)
	if existing != null:
		_apply_product_to_placement(existing, product_id, starting_stock, shelf, facings)
		product_assigned.emit(existing.placement_id)
		_refresh_fixture_visual(instance_id)
		GameLog.info("STORE", "Assigned %s to %s shelf %d stock=%d/%d facings=%d" % [String(product_id), String(instance_id), shelf_index, existing.shelf_stock, existing.capacity, existing.facings])
		return existing
	var placement := ProductPlacementState.new()
	placement.placement_id = ids.next(&"placement")
	placement.fixture_instance_id = instance_id
	placement.shelf_index = shelf.shelf_index
	_apply_product_to_placement(placement, product_id, starting_stock, shelf, facings)
	shelf.placements.append(placement)
	product_assigned.emit(placement.placement_id)
	_refresh_fixture_visual(instance_id)
	GameLog.info("STORE", "Assigned %s to %s shelf %d stock=%d/%d facings=%d" % [String(product_id), String(instance_id), shelf.shelf_index, placement.shelf_stock, placement.capacity, placement.facings])
	return placement


func describe_fixture_shelves(instance_id: StringName) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var fixture := get_fixture(instance_id)
	if fixture == null:
		return lines
	for shelf: ShelfState in fixture.shelf_states:
		var placement := _placement_on_shelf(shelf)
		var row := {
			"shelf_index": shelf.shelf_index,
			"stock": 0,
			"product_id": &"",
			"occupied": false,
		}
		if placement != null:
			row["stock"] = placement.shelf_stock
			row["capacity"] = placement.capacity
			row["facings"] = placement.facings
			row["units_deep"] = placement.units_deep
			row["product_id"] = placement.product_id
			row["display_name"] = placement.display_name if not placement.display_name.is_empty() else String(placement.product_id)
			row["occupied"] = true
		lines.append(row)
	return lines


func restock_fixture(instance_id: StringName) -> int:
	if staff_manager != null and staff_manager.has_method("request_restock_fixture"):
		return staff_manager.request_restock_fixture(instance_id)
	return 0


func restock_fail_reason(instance_id: StringName) -> StringName:
	if staff_manager != null and staff_manager.has_method("restock_fail_reason"):
		return staff_manager.restock_fail_reason(instance_id)
	return &"warehouse_empty"


func add_shelf_stock(placement_id: StringName, amount: int) -> int:
	var placement := _find_placement(placement_id)
	if placement == null or amount <= 0:
		return 0
	var room := maxi(0, placement.capacity - placement.shelf_stock)
	var add := mini(amount, room)
	if add <= 0:
		return 0
	var old_value := placement.shelf_stock
	placement.shelf_stock += add
	stock_changed.emit(placement.product_id, placement.placement_id, old_value, placement.shelf_stock)
	_refresh_fixture_visual(_fixture_id_for_placement(placement))
	return add


func set_shelf_facings(instance_id: StringName, shelf_index: int, facings: int) -> bool:
	var fixture := get_fixture(instance_id)
	if fixture == null:
		return false
	var shelf := _shelf_at(fixture, shelf_index)
	if shelf == null:
		return false
	var placement := _placement_on_shelf(shelf)
	if placement == null:
		return false
	_apply_product_to_placement(placement, placement.product_id, placement.shelf_stock, shelf, facings)
	_refresh_fixture_visual(instance_id)
	GameLog.info("STORE", "Facings %s shelf %d → %d cap=%d" % [String(instance_id), shelf_index, placement.facings, placement.capacity])
	return true


func adjust_facings(instance_id: StringName, delta: int) -> int:
	var fixture := get_fixture(instance_id)
	if fixture == null:
		return 0
	var updated := 0
	for shelf: ShelfState in fixture.shelf_states:
		var placement := _placement_on_shelf(shelf)
		if placement == null:
			continue
		if set_shelf_facings(instance_id, shelf.shelf_index, placement.facings + delta):
			updated += 1
	return updated


func clear_fixture_products(instance_id: StringName) -> bool:
	var fixture := get_fixture(instance_id)
	if fixture == null:
		return false
	var had_any := false
	for shelf: ShelfState in fixture.shelf_states:
		if not shelf.placements.is_empty():
			had_any = true
		shelf.placements.clear()
	_refresh_fixture_visual(instance_id)
	if had_any:
		GameLog.info("STORE", "Cleared products on %s" % String(instance_id))
	return had_any


func assign_product_to_first_shelf(product_id: StringName, starting_stock: int) -> ProductPlacementState:
	if runtime.is_empty():
		return null
	var first_id: StringName = runtime.keys()[0]
	return assign_product_to_fixture(first_id, product_id, starting_stock)


func take_from_shelf(placement_id: StringName) -> bool:
	var placement := get_placement(placement_id)
	if placement == null:
		return false
	if placement.shelf_stock <= 0:
		return false
	var old_value := placement.shelf_stock
	placement.shelf_stock -= 1
	stock_changed.emit(placement.product_id, placement.placement_id, old_value, placement.shelf_stock)
	GameLog.info("INVENTORY", "%s shelf stock: %d -> %d" % [String(placement.product_id), old_value, placement.shelf_stock])
	_refresh_fixture_visual(placement.fixture_instance_id)
	return true


func find_fixture_id_for_node(node: Node) -> StringName:
	for instance_id: StringName in fixture_nodes.keys():
		if fixture_nodes[instance_id] == node:
			return instance_id
	return &""


func get_fixture_node(instance_id: StringName) -> Node3D:
	return fixture_nodes.get(instance_id, null)


func rotate_fixture(instance_id: StringName, delta_deg: float) -> bool:
	var fixture := get_fixture(instance_id)
	var node := get_fixture_node(instance_id)
	if fixture == null or node == null:
		return false
	fixture.rotation_y_deg = fmod(fixture.rotation_y_deg + delta_deg + 360.0, 360.0)
	node.rotation.y = deg_to_rad(fixture.rotation_y_deg)
	GameLog.info("STORE", "Rotated %s to %.0f" % [String(instance_id), fixture.rotation_y_deg])
	return true


func remove_fixture(instance_id: StringName) -> bool:
	if not runtime.has(instance_id):
		return false
	runtime.erase(instance_id)
	var node: Node = fixture_nodes.get(instance_id)
	fixture_nodes.erase(instance_id)
	if node != null:
		node.queue_free()
	GameLog.info("STORE", "Removed %s" % String(instance_id))
	return true


func _refresh_fixture_visual(instance_id: StringName) -> void:
	var node: Node = fixture_nodes.get(instance_id, null)
	if node != null and node.has_method("refresh_product_visual"):
		node.refresh_product_visual()


func _add_shelf_states(fixture: FixtureInstanceState, count: int, width_m: float, depth_m: float) -> void:
	for i in count:
		var shelf := ShelfState.new()
		shelf.fixture_instance_id = fixture.instance_id
		shelf.shelf_index = i
		shelf.side_index = 0
		shelf.width_m = width_m
		shelf.depth_m = depth_m
		fixture.shelf_states.append(shelf)


func _default_assign_shelf(fixture: FixtureInstanceState) -> ShelfState:
	var preferred := mini(1, fixture.shelf_states.size() - 1)
	return fixture.shelf_states[preferred]


func _apply_product_to_placement(
	placement: ProductPlacementState,
	product_id: StringName,
	starting_stock: int,
	shelf: ShelfState,
	facings_request: int = -1
) -> void:
	placement.product_id = product_id
	var product := get_product(product_id)
	var product_width := product.width_m if product != null else FALLBACK_PRODUCT_WIDTH_M
	var product_depth := product.depth_m if product != null else FALLBACK_PRODUCT_DEPTH_M
	var shelf_width := shelf.width_m if shelf != null else 1.0
	var shelf_depth := shelf.depth_m if shelf != null else 0.4
	var max_facings := max_facings_from(shelf_width, product_width)
	var deep := units_deep_from(shelf_depth, product_depth)
	var facings := DEFAULT_FACINGS if facings_request < 0 else facings_request
	placement.facings = clampi(facings, 1, max_facings)
	placement.units_deep = deep
	placement.capacity = maxi(1, placement.facings * placement.units_deep)
	if starting_stock < 0:
		placement.shelf_stock = 0
		_seed_stock_from_warehouse(placement)
	else:
		placement.shelf_stock = clampi(starting_stock, 0, placement.capacity)
	if product != null:
		placement.display_name = product.display_name
		placement.preview_color = product.preview_color
		placement.package_type = product.package_type
		placement.preview_texture = TexLib.product(product.id)
	else:
		placement.display_name = String(product_id)
		placement.preview_color = Color(0.78, 0.12, 0.16)
		placement.package_type = &"bottle_small"
		placement.preview_texture = null


func _seed_stock_from_warehouse(placement: ProductPlacementState) -> void:
	if placement == null or staff_manager == null:
		return
	var inv: InventoryManager = staff_manager.inventory
	if inv == null:
		return
	var room := maxi(0, placement.capacity - placement.shelf_stock)
	if room <= 0:
		return
	var took := inv.take_from_warehouse(placement.product_id, room)
	if took <= 0:
		return
	var old_value := placement.shelf_stock
	placement.shelf_stock += took
	stock_changed.emit(placement.product_id, placement.placement_id, old_value, placement.shelf_stock)


static func max_facings_from(shelf_width_m: float, product_width_m: float) -> int:
	if product_width_m <= 0.0:
		return 1
	return maxi(1, int(floor(shelf_width_m / product_width_m)))


static func units_deep_from(shelf_depth_m: float, product_depth_m: float) -> int:
	if product_depth_m <= 0.0:
		return 1
	return maxi(1, int(floor(shelf_depth_m / product_depth_m)))


func _shelf_at(fixture: FixtureInstanceState, shelf_index: int) -> ShelfState:
	for shelf: ShelfState in fixture.shelf_states:
		if shelf.shelf_index == shelf_index:
			return shelf
	if shelf_index >= 0 and shelf_index < fixture.shelf_states.size():
		return fixture.shelf_states[shelf_index]
	return null


func _find_placement(placement_id: StringName) -> ProductPlacementState:
	return get_placement(placement_id)


func _fixture_id_for_placement(placement: ProductPlacementState) -> StringName:
	if placement == null:
		return &""
	return placement.fixture_instance_id


func _placement_on_shelf(shelf: ShelfState) -> ProductPlacementState:
	if shelf.placements.is_empty():
		return null
	return shelf.placements[0]


func _first_placement(fixture: FixtureInstanceState) -> ProductPlacementState:
	for shelf: ShelfState in fixture.shelf_states:
		if not shelf.placements.is_empty():
			return shelf.placements[0]
	return null
