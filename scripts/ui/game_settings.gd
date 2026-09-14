class_name GameSettings
extends RefCounted

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"fullscreen": false,
	"master_volume": 0.85,
	"pan_sensitivity": 0.02,
}


static func load_values() -> Dictionary:
	var values := DEFAULTS.duplicate()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return values
	values["fullscreen"] = bool(cfg.get_value("video", "fullscreen", DEFAULTS["fullscreen"]))
	values["master_volume"] = clampf(float(cfg.get_value("audio", "master_volume", DEFAULTS["master_volume"])), 0.0, 1.0)
	values["pan_sensitivity"] = clampf(float(cfg.get_value("camera", "pan_sensitivity", DEFAULTS["pan_sensitivity"])), 0.005, 0.08)
	return values


static func save_values(values: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "fullscreen", bool(values.get("fullscreen", false)))
	cfg.set_value("audio", "master_volume", clampf(float(values.get("master_volume", 0.85)), 0.0, 1.0))
	cfg.set_value("camera", "pan_sensitivity", clampf(float(values.get("pan_sensitivity", 0.02)), 0.005, 0.08))
	cfg.save(PATH)


static func apply(values: Dictionary) -> void:
	var fullscreen := bool(values.get("fullscreen", false))
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var volume := clampf(float(values.get("master_volume", 0.85)), 0.0, 1.0)
	var db := -80.0 if volume <= 0.001 else linear_to_db(volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)


static func apply_saved() -> Dictionary:
	var values := load_values()
	apply(values)
	return values
