class_name StoreLayout
extends RefCounted

## Small grocery layout for the 10×12 sales floor:
## wall fixtures on the perimeter, gondolas in north–south aisle runs,
## endcaps on the south ends facing the front power aisle.
const GRID := 0.5
const WALL_X_WEST := -4.0
const WALL_X_EAST := 4.0
const WALL_Z_NORTH := -5.0
const AISLE_X_WEST_OUTER := -2.0
const AISLE_X_WEST := -1.5
const AISLE_X_EAST := 1.5
const AISLE_X_EAST_OUTER := 2.0
const ROT_NORTH := 0.0
const ROT_WEST := 90.0
const ROT_SOUTH := 180.0
const ROT_EAST := 270.0


static func slots_for(definition: FixtureDefinition) -> Array[Dictionary]:
	if definition == null:
		return []
	match definition.fixture_type:
		&"wall_shelf":
			return _wall_slots()
		&"gondola":
			return _gondola_slots()
		&"endcap":
			return _endcap_slots()
		_:
			push_warning("Unhandled fixture type for layout: %s" % String(definition.fixture_type))
			return _gondola_slots()


static func plan_for(store_manager: StoreManager) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	if store_manager == null:
		return plan
	for kind: StringName in [&"wall_shelf", &"gondola", &"endcap"]:
		var definition := definition_of_type(store_manager, kind)
		if definition == null:
			continue
		for slot in slots_for(definition):
			var row: Dictionary = slot.duplicate()
			row["definition"] = definition
			plan.append(row)
	return plan


static func definition_of_type(store_manager: StoreManager, kind: StringName) -> FixtureDefinition:
	if store_manager == null:
		return null
	for definition_id in store_manager.fixture_order:
		var definition: FixtureDefinition = store_manager.get_fixture_definition(definition_id)
		if definition != null and definition.fixture_type == kind:
			return definition
	return null


static func snap(definition: FixtureDefinition, raw: Vector3, rotation_y_deg: float) -> Dictionary:
	if definition == null:
		return {"pos": _grid(raw), "rot": rotation_y_deg}
	match definition.fixture_type:
		&"wall_shelf":
			return _snap_wall(raw)
		&"gondola":
			return _snap_gondola(raw, rotation_y_deg)
		&"endcap":
			return _snap_endcap(raw, rotation_y_deg)
		_:
			return {"pos": _grid(raw), "rot": rotation_y_deg}


static func duplicate_offsets(rotation_y_deg: float, definition: FixtureDefinition) -> Array[Vector3]:
	var along := _run_step(rotation_y_deg, definition)
	var across := Vector3(along.z, 0.0, along.x)
	if across.length() < 0.01:
		across = Vector3(GRID, 0.0, 0.0)
	return [
		along,
		-along,
		across,
		-across,
		along + across,
		along - across,
		-along + across,
		-along - across,
	]


static func _wall_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for z in [-4.0, -2.5, -1.0, 0.5]:
		slots.append(_slot(Vector3(WALL_X_WEST, 0.0, z), ROT_EAST))
	slots.append(_slot(Vector3(-3.5, 0.0, WALL_Z_NORTH), ROT_SOUTH))
	slots.append(_slot(Vector3(3.5, 0.0, WALL_Z_NORTH), ROT_SOUTH))
	for z in [-4.0, -2.5, -1.0, 0.5]:
		slots.append(_slot(Vector3(WALL_X_EAST, 0.0, z), ROT_WEST))
	return slots


static func _gondola_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for z in [-3.5, -2.5, -1.5, -0.5]:
		slots.append(_slot(Vector3(AISLE_X_WEST_OUTER, 0.0, z), ROT_WEST))
		slots.append(_slot(Vector3(AISLE_X_WEST, 0.0, z), ROT_EAST))
		slots.append(_slot(Vector3(AISLE_X_EAST, 0.0, z), ROT_WEST))
		slots.append(_slot(Vector3(AISLE_X_EAST_OUTER, 0.0, z), ROT_EAST))
	return slots


static func _endcap_slots() -> Array[Dictionary]:
	return [
		_slot(Vector3(AISLE_X_WEST, 0.0, 0.8), ROT_SOUTH),
		_slot(Vector3(AISLE_X_EAST, 0.0, 0.8), ROT_SOUTH),
	]


static func _snap_wall(raw: Vector3) -> Dictionary:
	var west := absf(raw.x - WALL_X_WEST)
	var east := absf(raw.x - WALL_X_EAST)
	var north := absf(raw.z - WALL_Z_NORTH)
	if north <= west and north <= east:
		var x := clampf(_grid_axis(raw.x), -3.5, 3.5)
		if absf(x) < 1.5:
			x = -3.5 if raw.x < 0.0 else 3.5
		return _slot(Vector3(x, 0.0, WALL_Z_NORTH), ROT_SOUTH)
	if east < west:
		var z_east := clampf(_grid_axis(raw.z), -4.5, 0.5)
		return _slot(Vector3(WALL_X_EAST, 0.0, z_east), ROT_WEST)
	var z_west := clampf(_grid_axis(raw.z), -4.5, 1.0)
	return _slot(Vector3(WALL_X_WEST, 0.0, z_west), ROT_EAST)


static func _snap_gondola(raw: Vector3, rotation_y_deg: float) -> Dictionary:
	var aisle_x := _nearest_aisle_x(raw.x)
	var rot := rotation_y_deg
	var yaw := fmod(rotation_y_deg + 360.0, 180.0)
	if not (is_equal_approx(yaw, 90.0) or is_equal_approx(yaw, -90.0)):
		rot = _aisle_facing(aisle_x)
	var z := clampf(_grid_axis(raw.z), -4.5, 0.5)
	return _slot(Vector3(aisle_x, 0.0, z), rot)


static func _snap_endcap(raw: Vector3, _rotation_y_deg: float) -> Dictionary:
	var aisle_x := AISLE_X_WEST if raw.x < 0.0 else AISLE_X_EAST
	return _slot(Vector3(aisle_x, 0.0, 0.8), ROT_SOUTH)


static func _nearest_aisle_x(x: float) -> float:
	var best := AISLE_X_WEST
	var best_d := absf(x - best)
	for aisle_x in [AISLE_X_WEST_OUTER, AISLE_X_WEST, AISLE_X_EAST, AISLE_X_EAST_OUTER]:
		var distance := absf(x - aisle_x)
		if distance < best_d:
			best_d = distance
			best = aisle_x
	return best


static func _aisle_facing(aisle_x: float) -> float:
	if is_equal_approx(aisle_x, AISLE_X_WEST_OUTER) or is_equal_approx(aisle_x, AISLE_X_EAST):
		return ROT_WEST
	return ROT_EAST


static func _run_step(rotation_y_deg: float, definition: FixtureDefinition) -> Vector3:
	var length := 1.0
	if definition != null:
		length = definition.width_m
	var step := snappedf(length + GRID, GRID)
	var yaw := fmod(rotation_y_deg, 180.0)
	if is_equal_approx(yaw, 90.0) or is_equal_approx(yaw, -90.0):
		return Vector3(0.0, 0.0, step)
	return Vector3(step, 0.0, 0.0)


static func _slot(pos: Vector3, rot: float) -> Dictionary:
	return {"pos": pos, "rot": rot}


static func _grid(point: Vector3) -> Vector3:
	return Vector3(_grid_axis(point.x), 0.0, _grid_axis(point.z))


static func _grid_axis(value: float) -> float:
	return round(value / GRID) * GRID
