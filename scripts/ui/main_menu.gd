class_name MainMenu
extends Control

const GAME_SCENE := "res://scenes/main/Main.tscn"
const Settings := preload("res://scripts/ui/game_settings.gd")
const ThemeLib := preload("res://scripts/ui/game_theme.gd")

@onready var background: TextureRect = $Background
@onready var shopy_label: Label = $LogoBlock/LogoRow/ShopyLabel
@onready var fender_label: Label = $LogoBlock/LogoRow/FenderLabel
@onready var tagline_label: Label = $LogoBlock/Tagline
@onready var new_game_button: Button = $MenuColumn/NewGameButton
@onready var continue_button: Button = $MenuColumn/ContinueButton
@onready var settings_button: Button = $MenuColumn/SettingsButton
@onready var help_button: Button = $MenuColumn/HelpButton
@onready var quit_button: Button = $MenuColumn/QuitButton
@onready var version_label: Label = $Version
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var help_panel: PanelContainer = $HelpPanel
@onready var fullscreen_check: CheckBox = $SettingsPanel/SettingsBox/FullscreenCheck
@onready var volume_slider: HSlider = $SettingsPanel/SettingsBox/VolumeSlider
@onready var sensitivity_slider: HSlider = $SettingsPanel/SettingsBox/SensitivitySlider
@onready var settings_back: Button = $SettingsPanel/SettingsBox/SettingsBack
@onready var help_back: Button = $HelpPanel/HelpBox/HelpBack

var _settings: Dictionary = {}


func _ready() -> void:
	_settings = Settings.apply_saved()
	_apply_theme()
	new_game_button.pressed.connect(_on_new_game)
	settings_button.pressed.connect(_show_settings)
	help_button.pressed.connect(_show_help)
	quit_button.pressed.connect(_on_quit)
	settings_back.pressed.connect(_show_root)
	help_back.pressed.connect(_show_root)
	fullscreen_check.toggled.connect(_on_fullscreen)
	volume_slider.value_changed.connect(_on_volume)
	sensitivity_slider.value_changed.connect(_on_sensitivity)
	continue_button.pressed.connect(_on_continue)
	_refresh_continue()
	_sync_settings_controls()
	_show_root()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible or help_panel.visible:
			_show_root()
			get_viewport().set_input_as_handled()


func _on_new_game() -> void:
	Settings.save_values(_settings)
	Settings.apply(_settings)
	RunSave.clear()
	RunSave.load_on_next_main = false
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_continue() -> void:
	if not RunSave.exists():
		return
	Settings.save_values(_settings)
	Settings.apply(_settings)
	RunSave.load_on_next_main = true
	get_tree().change_scene_to_file(GAME_SCENE)


func _refresh_continue() -> void:
	var has_save := RunSave.exists()
	continue_button.disabled = not has_save
	continue_button.tooltip_text = "Resume last save" if has_save else "No saved game"


func _on_quit() -> void:
	Settings.save_values(_settings)
	get_tree().quit()


func _show_root() -> void:
	settings_panel.visible = false
	help_panel.visible = false
	$MenuColumn.visible = true
	$MenuColumnBacking.visible = true
	new_game_button.grab_focus()


func _show_settings() -> void:
	settings_panel.visible = true
	help_panel.visible = false
	$MenuColumn.visible = false
	$MenuColumnBacking.visible = false
	fullscreen_check.grab_focus()


func _show_help() -> void:
	help_panel.visible = true
	settings_panel.visible = false
	$MenuColumn.visible = false
	$MenuColumnBacking.visible = false
	help_back.grab_focus()


func _on_fullscreen(pressed: bool) -> void:
	_settings["fullscreen"] = pressed
	Settings.apply(_settings)
	Settings.save_values(_settings)


func _on_volume(value: float) -> void:
	_settings["master_volume"] = value / 100.0
	Settings.apply(_settings)
	Settings.save_values(_settings)


func _on_sensitivity(value: float) -> void:
	_settings["pan_sensitivity"] = value
	Settings.save_values(_settings)


func _sync_settings_controls() -> void:
	fullscreen_check.set_pressed_no_signal(bool(_settings.get("fullscreen", false)))
	volume_slider.set_value_no_signal(clampf(float(_settings.get("master_volume", 0.85)) * 100.0, 0.0, 100.0))
	sensitivity_slider.set_value_no_signal(float(_settings.get("pan_sensitivity", 0.02)))


func _apply_theme() -> void:
	ThemeLib.apply(self)
	ThemeLib.style_menu_primary(new_game_button)
	ThemeLib.style_menu_secondary(continue_button)
	ThemeLib.style_menu_secondary(settings_button)
	ThemeLib.style_menu_secondary(help_button)
	ThemeLib.style_menu_secondary(quit_button)
	settings_panel.add_theme_stylebox_override("panel", ThemeLib.menu_button_box(ThemeLib.MENU_BLUE, ThemeLib.MENU_GREEN))
	help_panel.add_theme_stylebox_override("panel", ThemeLib.menu_button_box(ThemeLib.MENU_BLUE, ThemeLib.MENU_GREEN))
	ThemeLib.style_menu_secondary(settings_back)
	ThemeLib.style_menu_secondary(help_back)
	new_game_button.icon = ThemeLib.menu_icon(&"play")
	continue_button.icon = ThemeLib.menu_icon(&"save")
	settings_button.icon = ThemeLib.menu_icon(&"gear")
	help_button.icon = ThemeLib.menu_icon(&"people")
	quit_button.icon = ThemeLib.menu_icon(&"door")
	var cart_label: Label = $LogoBlock/LogoRow/CartLabel
	cart_label.add_theme_font_size_override("font_size", 40)
	shopy_label.add_theme_font_size_override("font_size", 72)
	shopy_label.add_theme_color_override("font_color", ThemeLib.LOGO_SHOPY)
	shopy_label.add_theme_color_override("font_outline_color", Color(0.12, 0.28, 0.55, 1.0))
	shopy_label.add_theme_constant_override("outline_size", 14)
	fender_label.add_theme_font_size_override("font_size", 72)
	fender_label.add_theme_color_override("font_color", ThemeLib.LOGO_FENDER)
	fender_label.add_theme_color_override("font_outline_color", Color(0.55, 0.22, 0.05, 1.0))
	fender_label.add_theme_constant_override("outline_size", 14)
	tagline_label.add_theme_font_size_override("font_size", 18)
	tagline_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.96))
	tagline_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.92))
	tagline_label.add_theme_constant_override("outline_size", 8)
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	version_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.8))
	version_label.add_theme_constant_override("outline_size", 3)
