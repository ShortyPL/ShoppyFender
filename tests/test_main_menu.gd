extends RefCounted
class_name TestMainMenu

const Settings := preload("res://scripts/ui/game_settings.gd")
const BG_PATH := "res://assets/ui/main_menu_background.jpg"


static func run() -> int:
	var failures := 0
	failures += _assert("settings have volume and camera keys", _defaults_complete())
	failures += _assert("volume applies without crash", _apply_volume())
	failures += _assert("menu background file exists", ResourceLoader.exists(BG_PATH))
	return failures


static func _defaults_complete() -> bool:
	var values := Settings.load_values()
	return values.has("fullscreen") and values.has("master_volume") and values.has("pan_sensitivity")


static func _apply_volume() -> bool:
	Settings.apply({
		"fullscreen": false,
		"master_volume": 0.4,
		"pan_sensitivity": 0.02,
	})
	return true


static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
