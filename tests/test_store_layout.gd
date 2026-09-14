extends RefCounted
class_name TestStoreLayout


static func run() -> int:
	var failures := 0
	var wall := _def(&"wall_shelf", 1.5, 0.3)
	var gondola := _def(&"gondola", 1.0, 0.5)
	var endcap := _def(&"endcap", 0.8, 0.6)
	var wall_slots := StoreLayout.slots_for(wall)
	failures += _assert("wall slots exist", wall_slots.size() >= 3)
	failures += _assert("wall shelves hug perimeter", _all_walls_on_perimeter(wall_slots))
	failures += _assert("wall shelves face inward", _all_rots_in(wall_slots, [90.0, 180.0, 270.0]))
	var gondola_slots := StoreLayout.slots_for(gondola)
	failures += _assert("gondolas sit in center aisles", _all_gondolas_in_aisles(gondola_slots))
	failures += _assert("gondolas run north-south", _all_rots_in(gondola_slots, [90.0, 270.0]))
	var endcap_slots := StoreLayout.slots_for(endcap)
	failures += _assert("endcaps sit on aisle ends", endcap_slots.size() >= 2)
	failures += _assert("front endcaps face the power aisle", float(endcap_slots[0].get("rot", -1.0)) == 180.0)
	failures += _assert("full shop has many slots", wall_slots.size() + gondola_slots.size() + endcap_slots.size() >= 24)
	var snapped_wall := StoreLayout.snap(wall, Vector3(-3.2, 0.0, -1.0), 0.0)
	failures += _assert("near west wall snaps onto west wall", is_equal_approx(float((snapped_wall.get("pos", Vector3.ZERO) as Vector3).x), -4.0))
	failures += _assert("west wall faces east", is_equal_approx(float(snapped_wall.get("rot", 0.0)), 270.0))
	var snapped_gondola := StoreLayout.snap(gondola, Vector3(-0.4, 0.0, -2.1), 0.0)
	failures += _assert("gondola snaps to west aisle", is_equal_approx(float((snapped_gondola.get("pos", Vector3.ZERO) as Vector3).x), -1.5))
	return failures


static func _def(kind: StringName, width_m: float, depth_m: float) -> FixtureDefinition:
	var definition := FixtureDefinition.new()
	definition.fixture_type = kind
	definition.width_m = width_m
	definition.depth_m = depth_m
	definition.height_m = 1.6
	return definition


static func _all_walls_on_perimeter(slots: Array[Dictionary]) -> bool:
	for slot in slots:
		var pos: Vector3 = slot.get("pos", Vector3.ZERO)
		var on_west := is_equal_approx(pos.x, -4.0)
		var on_east := is_equal_approx(pos.x, 4.0)
		var on_north := is_equal_approx(pos.z, -5.0)
		if not (on_west or on_east or on_north):
			return false
	return true


static func _all_gondolas_in_aisles(slots: Array[Dictionary]) -> bool:
	for slot in slots:
		var pos: Vector3 = slot.get("pos", Vector3.ZERO)
		if not (
			is_equal_approx(pos.x, -2.0)
			or is_equal_approx(pos.x, -1.5)
			or is_equal_approx(pos.x, 1.5)
			or is_equal_approx(pos.x, 2.0)
		):
			return false
		if pos.z > 1.0:
			return false
	return true


static func _all_rots_in(slots: Array[Dictionary], allowed: Array) -> bool:
	for slot in slots:
		var rot := float(slot.get("rot", -1.0))
		var ok := false
		for value in allowed:
			if is_equal_approx(rot, float(value)):
				ok = true
				break
		if not ok:
			return false
	return true


static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
