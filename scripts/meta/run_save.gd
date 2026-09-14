class_name RunSave
extends RefCounted

const PATH := "user://shoppy_run.cfg"

static var load_on_next_main: bool = false


static func _ensure_user_dir() -> void:
	var abs_dir := ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(abs_dir)


static func exists() -> bool:
	return FileAccess.file_exists(PATH)


static func clear() -> void:
	_ensure_user_dir()
	var abs_path := ProjectSettings.globalize_path(PATH)
	if FileAccess.file_exists(PATH) or FileAccess.file_exists(abs_path):
		DirAccess.remove_absolute(abs_path)


static func write_snapshot(data: Dictionary) -> void:
	_ensure_user_dir()
	var cfg := ConfigFile.new()
	cfg.set_value("economy", "cash", float(data.get("cash", 0.0)))
	cfg.set_value("economy", "start_cash", float(data.get("start_cash", 10000.0)))
	cfg.set_value("staff", "auto_fill", bool(data.get("auto_fill", false)))
	cfg.set_value("upgrades", "owned", data.get("owned", PackedStringArray()))
	cfg.set_value("meta", "wave_number", int(data.get("wave_number", 1)))
	cfg.set_value("meta", "clock_minutes", int(data.get("clock_minutes", StoreClock.OPEN_MINUTES)))
	var stars: Array = data.get("stars_history", [])
	cfg.set_value("meta", "stars_history", stars)
	var warehouse: Dictionary = data.get("warehouse", {})
	for key in warehouse.keys():
		cfg.set_value("warehouse", String(key), int(warehouse[key]))
	var ordered: Dictionary = data.get("ordered", {})
	for key in ordered.keys():
		cfg.set_value("ordered", String(key), int(ordered[key]))
	var pending: Array = data.get("pending", [])
	cfg.set_value("pending", "count", pending.size())
	for i in pending.size():
		var row: Dictionary = pending[i]
		var section := "pending_%d" % i
		cfg.set_value(section, "id", String(row.get("id", "")))
		cfg.set_value(section, "product_id", String(row.get("product_id", "")))
		cfg.set_value(section, "quantity", int(row.get("quantity", 0)))
		cfg.set_value(section, "delivery_type", String(row.get("delivery_type", "standard")))
		cfg.set_value(section, "eta_minutes", int(row.get("eta_minutes", -1)))
	var fixtures: Array = data.get("fixtures", [])
	cfg.set_value("fixtures", "count", fixtures.size())
	for i in fixtures.size():
		var row: Dictionary = fixtures[i]
		var section := "fixture_%d" % i
		cfg.set_value(section, "definition_id", String(row.get("definition_id", "")))
		cfg.set_value(section, "x", float(row.get("x", 0.0)))
		cfg.set_value(section, "z", float(row.get("z", 0.0)))
		cfg.set_value(section, "rot", float(row.get("rot", 0.0)))
		cfg.set_value(section, "shelves", row.get("shelves", []))
	cfg.save(PATH)


static func read_snapshot() -> Dictionary:
	_ensure_user_dir()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return {}
	var warehouse := {}
	if cfg.has_section("warehouse"):
		for key in cfg.get_section_keys("warehouse"):
			warehouse[StringName(key)] = int(cfg.get_value("warehouse", key, 0))
	var ordered := {}
	if cfg.has_section("ordered"):
		for key in cfg.get_section_keys("ordered"):
			ordered[StringName(key)] = int(cfg.get_value("ordered", key, 0))
	var pending: Array = []
	var pending_count := int(cfg.get_value("pending", "count", 0))
	for i in pending_count:
		var section := "pending_%d" % i
		pending.append({
			"id": StringName(str(cfg.get_value(section, "id", ""))),
			"product_id": StringName(str(cfg.get_value(section, "product_id", ""))),
			"quantity": int(cfg.get_value(section, "quantity", 0)),
			"delivery_type": StringName(str(cfg.get_value(section, "delivery_type", "standard"))),
			"eta_minutes": int(cfg.get_value(section, "eta_minutes", -1)),
		})
	var owned: PackedStringArray = cfg.get_value("upgrades", "owned", PackedStringArray())
	var fixtures: Array = []
	var count := int(cfg.get_value("fixtures", "count", 0))
	for i in count:
		var section := "fixture_%d" % i
		fixtures.append({
			"definition_id": StringName(str(cfg.get_value(section, "definition_id", ""))),
			"x": float(cfg.get_value(section, "x", 0.0)),
			"z": float(cfg.get_value(section, "z", 0.0)),
			"rot": float(cfg.get_value(section, "rot", 0.0)),
			"shelves": cfg.get_value(section, "shelves", []),
		})
	var stars_raw = cfg.get_value("meta", "stars_history", [])
	var stars_history: Array = []
	if stars_raw is Array:
		for value in stars_raw:
			stars_history.append(int(value))
	return {
		"cash": float(cfg.get_value("economy", "cash", 0.0)),
		"start_cash": float(cfg.get_value("economy", "start_cash", 10000.0)),
		"auto_fill": bool(cfg.get_value("staff", "auto_fill", false)),
		"owned": owned,
		"warehouse": warehouse,
		"ordered": ordered,
		"pending": pending,
		"fixtures": fixtures,
		"wave_number": int(cfg.get_value("meta", "wave_number", 1)),
		"clock_minutes": int(cfg.get_value("meta", "clock_minutes", StoreClock.OPEN_MINUTES)),
		"stars_history": stars_history,
	}
