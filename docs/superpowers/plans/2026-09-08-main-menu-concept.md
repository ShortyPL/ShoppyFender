# Main Menu Concept Overlay Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the 3D rotating-store main menu with a 2D full-screen concept still plus a Polish overlay that covers the baked-in English UI.

**Architecture:** `MainMenu` becomes a full-rect `Control`. A `TextureRect` draws `res://assets/ui/main_menu_background.jpg` with `stretch_mode = KEEP_ASPECT_COVERED`. Logo, five buttons, version, Settings, and Help sit on top. `Kontynuuj` is disabled. No 3D store, camera, or orbit.

**Tech Stack:** Godot 4.7.2, GDScript, headless `tests/run_tests.gd`.

**Spec:** `docs/superpowers/specs/2026-09-08-main-menu-concept-design.md`

## Global Constraints

- Project root `/Volumes/TimeData/Cursor/ShoppyFender` (never `~/Developer/ShopyFender`).
- Godot 4.7.2, GDScript, Polish UI copy from the spec table (sentence case, not ALL CAPS).
- Tests: `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd` with Shell `required_permissions: ["all"]`. After new `class_name` or new assets, `--import` if types/textures missing.
- Do not commit unless the user asks. Skip every Commit step.
- Do not edit `~/.cursor/plans/`. Do not add MCP servers or paid APIs.
- Do not add save/load, Credits, English labels, or `v1.0.0`.
- Keep Settings (fullscreen, volume, camera sensitivity) and Help body text.
- Cover the still’s English logo/buttons by placing opaque Polish controls in the same left column.
- Imports at top of file.

## File map

Create:

- `assets/ui/main_menu_background.jpg` — copy of the approved concept still

Modify:

- `scenes/ui/MainMenu.tscn` — root `Control`, no Store/camera
- `scripts/ui/main_menu.gd` — `extends Control`, new node paths, Continue disabled
- `scripts/ui/game_theme.gd` — menu green / menu blue styleboxes
- `tests/test_main_menu.gd` — extra contract checks that do not need the scene
- `tests/run_tests.gd` — `_test_main_menu_scene` assertions for 2D overlay
- `assets/LICENSES.md` — user concept still
- `docs/decisions.md` — menu is 2D overlay, Continue disabled

Do not modify: `scenes/main/Main.tscn`, HUD, store, simulation. `run/main_scene` stays `res://scenes/ui/MainMenu.tscn`.

Source still (copy from, do not leave the menu pointing at chat cache):

`/Users/radekwitulski/.cursor/projects/Volumes-TimeData-Cursor-ShoppyFender/assets/image-5a816dfb-41dd-4a2e-9e6b-04ce07e9b941.jpg`

---

### Task 1: Failing 2D menu contract tests

**Files:**

- Modify: `tests/test_main_menu.gd`
- Modify: `tests/run_tests.gd` — `_test_main_menu_scene`

**Interfaces:**

- Consumes: `MainMenu` scene API that Task 2 will expose: `new_game_button`, `continue_button`, `settings_button`, `help_button`, `quit_button`, `settings_panel`, `help_panel`, `version_label`, `background`, `_show_help()`, `_show_settings()`, `_show_root()`
- Produces: failing tests that encode the spec contract

- [ ] **Step 1: Expand unit tests**

Replace `tests/test_main_menu.gd` with:

```gdscript
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
```

- [ ] **Step 2: Expand scene test**

Replace `_test_main_menu_scene` in `tests/run_tests.gd` with:

```gdscript
func _test_main_menu_scene() -> int:
	var menu_scene: PackedScene = load("res://scenes/ui/MainMenu.tscn")
	var menu: MainMenu = menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	await process_frame
	if menu.find_child("Store", true, false) != null:
		print("  FAIL  3D store still in menu")
		menu.queue_free()
		return 1
	if menu.find_child("Camera3D", true, false) != null:
		print("  FAIL  3D camera still in menu")
		menu.queue_free()
		return 1
	if menu.background == null or menu.background.texture == null:
		print("  FAIL  background texture")
		menu.queue_free()
		return 1
	if menu.new_game_button == null or menu.new_game_button.text != "Nowa gra":
		print("  FAIL  new game button")
		menu.queue_free()
		return 1
	if menu.continue_button == null or menu.continue_button.text != "Kontynuuj":
		print("  FAIL  continue label")
		menu.queue_free()
		return 1
	if not menu.continue_button.disabled:
		print("  FAIL  continue should be disabled")
		menu.queue_free()
		return 1
	if menu.continue_button.tooltip_text != "Brak zapisu partii":
		print("  FAIL  continue tooltip")
		menu.queue_free()
		return 1
	if menu.settings_button.text != "Ustawienia" or menu.help_button.text != "Pomoc" or menu.quit_button.text != "Wyjście":
		print("  FAIL  menu button labels")
		menu.queue_free()
		return 1
	if menu.new_game_button.disabled or menu.settings_button.disabled or menu.help_button.disabled or menu.quit_button.disabled:
		print("  FAIL  primary buttons should be enabled")
		menu.queue_free()
		return 1
	if menu.version_label == null or menu.version_label.text != "v0.05":
		print("  FAIL  version label")
		menu.queue_free()
		return 1
	menu._show_help()
	if not menu.help_panel.visible or menu.new_game_button.visible:
		print("  FAIL  help panel opens")
		menu.queue_free()
		return 1
	menu._show_settings()
	if not menu.settings_panel.visible or menu.help_panel.visible:
		print("  FAIL  settings panel opens")
		menu.queue_free()
		return 1
	menu._show_root()
	if menu.settings_panel.visible or not menu.new_game_button.visible:
		print("  FAIL  root menu returns")
		menu.queue_free()
		return 1
	print("  PASS  main menu buttons and panels")
	menu.queue_free()
	return 0
```

Leave the rest of `run_tests.gd` unchanged (banner may stay `Prototype 0.04 tests`).

- [ ] **Step 3: Run tests and confirm they fail**

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

Expected: FAIL on `menu background file exists` and/or `3D store still in menu` / missing `continue_button`. Do not implement the menu yet.

- [ ] **Step 4: Commit**

Skip. User did not ask for a commit.

---

### Task 2: 2D overlay menu (asset, theme, scene, script)

**Files:**

- Create: `assets/ui/main_menu_background.jpg`
- Modify: `assets/LICENSES.md`
- Modify: `scripts/ui/game_theme.gd`
- Modify: `scenes/ui/MainMenu.tscn`
- Modify: `scripts/ui/main_menu.gd`

**Interfaces:**

- Consumes: Task 1 tests; concept jpg at the chat-assets path in the file map
- Produces: `MainMenu` extends `Control` with:
  - `background: TextureRect`
  - `tagline_label: Label`
  - `new_game_button`, `continue_button`, `settings_button`, `help_button`, `quit_button: Button`
  - `version_label: Label`
  - `settings_panel`, `help_panel: PanelContainer`
  - `_show_root()`, `_show_settings()`, `_show_help()`
- Produces: `GameTheme.style_menu_primary(button)`, `GameTheme.style_menu_secondary(button)`
- Produces: `GameTheme.MENU_GREEN`, `MENU_BLUE`, `LOGO_SHOPY`, `LOGO_FENDER`

Godot 4.7 `TextureRect`: `expand_mode = 1` (`EXPAND_IGNORE_SIZE`), `stretch_mode = 6` (`STRETCH_KEEP_ASPECT_COVERED`), full-rect anchors. Background `mouse_filter = 2` (IGNORE).

- [ ] **Step 1: Copy the still and record license**

```bash
mkdir -p /Volumes/TimeData/Cursor/ShoppyFender/assets/ui
cp "/Users/radekwitulski/.cursor/projects/Volumes-TimeData-Cursor-ShoppyFender/assets/image-5a816dfb-41dd-4a2e-9e6b-04ce07e9b941.jpg" /Volumes/TimeData/Cursor/ShoppyFender/assets/ui/main_menu_background.jpg
```

If the source is missing, search the workspace for the jpg from this chat and copy that file instead. Do not generate a new image. Do not call paid APIs.

Append to `assets/LICENSES.md`:

```markdown
## Main menu concept still

- **Name:** ShoppyFender main menu concept
- **Source:** User-provided concept still (chat attachment)
- **License:** Project art, not redistributable as a third-party pack
- **Local path:** `assets/ui/main_menu_background.jpg`
- **Added:** 2026-09-08
```

- [ ] **Step 2: Add menu styleboxes to `game_theme.gd`**

Keep existing HUD helpers. Add constants and two functions (do not change `style_primary` used by HUD):

```gdscript
const MENU_GREEN := Color(0.298, 0.686, 0.314, 1.0)
const MENU_GREEN_HI := Color(0.36, 0.76, 0.38, 1.0)
const MENU_BLUE := Color(0.102, 0.227, 0.478, 0.96)
const MENU_BLUE_HI := Color(0.14, 0.32, 0.62, 0.98)
const MENU_BLUE_DISABLED := Color(0.12, 0.18, 0.32, 0.72)
const LOGO_SHOPY := Color(0.93, 0.97, 1.0, 1.0)
const LOGO_FENDER := Color(0.976, 0.659, 0.145, 1.0)
```

```gdscript
static func style_menu_primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", menu_button_box(MENU_GREEN, Color(1, 1, 1, 0.35)))
	button.add_theme_stylebox_override("hover", menu_button_box(MENU_GREEN_HI, Color(1, 1, 1, 0.55)))
	button.add_theme_stylebox_override("pressed", menu_button_box(Color(0.22, 0.55, 0.24, 1.0), Color(1, 1, 1, 0.4)))
	button.add_theme_stylebox_override("focus", menu_button_box(MENU_GREEN_HI, Color(1, 1, 1, 0.8)))
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT


static func style_menu_secondary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", menu_button_box(MENU_BLUE, Color(1, 1, 1, 0.18)))
	button.add_theme_stylebox_override("hover", menu_button_box(MENU_BLUE_HI, Color(1, 1, 1, 0.35)))
	button.add_theme_stylebox_override("pressed", menu_button_box(Color(0.08, 0.16, 0.36, 0.98), Color(1, 1, 1, 0.25)))
	button.add_theme_stylebox_override("focus", menu_button_box(MENU_BLUE_HI, Color(1, 1, 1, 0.7)))
	button.add_theme_stylebox_override("disabled", menu_button_box(MENU_BLUE_DISABLED, Color(1, 1, 1, 0.08)))
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.8, 0.88, 0.7))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT


static func menu_button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(16)
	box.content_margin_left = 22
	box.content_margin_right = 18
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 3)
	return box


static func menu_icon(kind: StringName) -> Texture2D:
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var white := Color(1, 1, 1, 1)
	match kind:
		&"play":
			for y in range(6, 18):
				var w := int((y - 6) * 0.7) if y < 12 else int((18 - y) * 0.7)
				for x in range(8, 8 + max(w, 1) + 4):
					if x < 20:
						img.set_pixel(x, y, white)
		&"save":
			for y in range(5, 19):
				for x in range(6, 18):
					if y == 5 or y == 18 or x == 6 or x == 17 or (y >= 5 and y <= 10 and x >= 8 and x <= 15):
						img.set_pixel(x, y, white)
		&"gear":
			for y in range(8, 16):
				for x in range(8, 16):
					if (x - 11) * (x - 11) + (y - 11) * (y - 11) <= 16:
						img.set_pixel(x, y, white)
			img.set_pixel(11, 5, white)
			img.set_pixel(11, 18, white)
			img.set_pixel(5, 11, white)
			img.set_pixel(18, 11, white)
		&"people":
			img.set_pixel(9, 7, white)
			img.set_pixel(10, 7, white)
			img.set_pixel(14, 7, white)
			img.set_pixel(15, 7, white)
			for y in range(12, 19):
				for x in range(6, 12):
					img.set_pixel(x, y, white)
				for x in range(13, 19):
					img.set_pixel(x, y, white)
		&"door":
			for y in range(4, 20):
				for x in range(8, 17):
					if y == 4 or x == 8 or x == 16 or y == 19:
						img.set_pixel(x, y, white)
			img.set_pixel(14, 12, white)
		_:
			pass
	return ImageTexture.create_from_image(img)
```

Assign icons in `MainMenu._apply_theme` (Task 2 Step 4), not in HUD `style_primary`. Button `.text` stays exactly as in the spec table.

- [ ] **Step 3: Rewrite `scenes/ui/MainMenu.tscn`**

Replace the whole file. Root is `Control`. No `Store`, `WorldEnvironment`, `DirectionalLight3D`, `Pivot`, or `Camera3D`. Keep Help body text identical to the current scene.

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://scripts/ui/main_menu.gd" id="1_menu"]
[ext_resource type="Texture2D" path="res://assets/ui/main_menu_background.jpg" id="2_bg"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_menu")

[node name="Background" type="TextureRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
texture = ExtResource("2_bg")
expand_mode = 1
stretch_mode = 6

[node name="LogoBlock" type="VBoxContainer" parent="."]
layout_mode = 0
offset_left = 48.0
offset_top = 28.0
offset_right = 520.0
offset_bottom = 168.0
theme_override_constants/separation = 4
mouse_filter = 2

[node name="LogoRow" type="HBoxContainer" parent="LogoBlock"]
layout_mode = 2
theme_override_constants/separation = 6

[node name="ShopyLabel" type="Label" parent="LogoBlock/LogoRow"]
layout_mode = 2
text = "SHOPY"

[node name="FenderLabel" type="Label" parent="LogoBlock/LogoRow"]
layout_mode = 2
text = "FENDER"

[node name="Tagline" type="Label" parent="LogoBlock"]
layout_mode = 2
text = "Zarządzaj sklepem. Rozwijaj historię."

[node name="MenuColumn" type="VBoxContainer" parent="."]
layout_mode = 0
offset_left = 48.0
offset_top = 200.0
offset_right = 368.0
offset_bottom = 560.0
theme_override_constants/separation = 12

[node name="NewGameButton" type="Button" parent="MenuColumn"]
custom_minimum_size = Vector2(320, 56)
layout_mode = 2
text = "Nowa gra"

[node name="ContinueButton" type="Button" parent="MenuColumn"]
custom_minimum_size = Vector2(320, 56)
layout_mode = 2
disabled = true
text = "Kontynuuj"
tooltip_text = "Brak zapisu partii"

[node name="SettingsButton" type="Button" parent="MenuColumn"]
custom_minimum_size = Vector2(320, 56)
layout_mode = 2
text = "Ustawienia"

[node name="HelpButton" type="Button" parent="MenuColumn"]
custom_minimum_size = Vector2(320, 56)
layout_mode = 2
text = "Pomoc"

[node name="QuitButton" type="Button" parent="MenuColumn"]
custom_minimum_size = Vector2(320, 56)
layout_mode = 2
text = "Wyjście"

[node name="Version" type="Label" parent="."]
layout_mode = 1
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -120.0
offset_top = -40.0
offset_right = -24.0
offset_bottom = -16.0
text = "v0.05"
horizontal_alignment = 2

[node name="SettingsPanel" type="PanelContainer" parent="."]
visible = false
layout_mode = 0
offset_left = 48.0
offset_top = 200.0
offset_right = 430.0
offset_bottom = 520.0

[node name="SettingsBox" type="VBoxContainer" parent="SettingsPanel"]
layout_mode = 2
theme_override_constants/separation = 10

[node name="SettingsTitle" type="Label" parent="SettingsPanel/SettingsBox"]
layout_mode = 2
text = "Ustawienia"

[node name="FullscreenCheck" type="CheckBox" parent="SettingsPanel/SettingsBox"]
layout_mode = 2
text = "Pełny ekran"

[node name="VolumeLabel" type="Label" parent="SettingsPanel/SettingsBox"]
layout_mode = 2
text = "Głośność"

[node name="VolumeSlider" type="HSlider" parent="SettingsPanel/SettingsBox"]
layout_mode = 2
max_value = 100.0
value = 85.0

[node name="SensitivityLabel" type="Label" parent="SettingsPanel/SettingsBox"]
layout_mode = 2
text = "Czułość kamery"

[node name="SensitivitySlider" type="HSlider" parent="SettingsPanel/SettingsBox"]
layout_mode = 2
min_value = 0.005
max_value = 0.06
step = 0.001
value = 0.02

[node name="SettingsBack" type="Button" parent="SettingsPanel/SettingsBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "Wstecz"

[node name="HelpPanel" type="PanelContainer" parent="."]
visible = false
layout_mode = 0
offset_left = 48.0
offset_top = 170.0
offset_right = 520.0
offset_bottom = 620.0

[node name="HelpBox" type="VBoxContainer" parent="HelpPanel"]
layout_mode = 2
theme_override_constants/separation = 12

[node name="HelpTitle" type="Label" parent="HelpPanel/HelpBox"]
layout_mode = 2
text = "Jak grać"

[node name="HelpText" type="Label" parent="HelpPanel/HelpBox"]
layout_mode = 2
autowrap_mode = 3
text = "Cel: postaw regały, przypisz towar, zamów dostawy i otwórz sklep na falę 10 klientów.

Budowa
WASD — kamera   Q/E — obrót widoku
Kółko — zoom   Środek myszy — przesuwanie
LPM — stawianie mebla   R — obrót ducha
PPM — SKU, facings, zamówienie

Fala
Otwórz sklep, gdy na półce jest towar. Klienci ustawiają się w kolejce. Trzy gwiazdki: obsłużeni ≥ 8, satysfakcja ≥ 80%, zero utraconych sprzedaży.

F3 — bot playtestu
Esc — powrót z tego ekranu"

[node name="HelpBack" type="Button" parent="HelpPanel/HelpBox"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2
text = "Wstecz"
```

- [ ] **Step 4: Rewrite `scripts/ui/main_menu.gd`**

```gdscript
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
	continue_button.disabled = true
	continue_button.tooltip_text = "Brak zapisu partii"
	_sync_settings_controls()
	_show_root()
	new_game_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel.visible or help_panel.visible:
			_show_root()
			get_viewport().set_input_as_handled()


func _on_new_game() -> void:
	Settings.save_values(_settings)
	Settings.apply(_settings)
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit() -> void:
	Settings.save_values(_settings)
	get_tree().quit()


func _show_root() -> void:
	settings_panel.visible = false
	help_panel.visible = false
	$MenuColumn.visible = true
	new_game_button.grab_focus()


func _show_settings() -> void:
	settings_panel.visible = true
	help_panel.visible = false
	$MenuColumn.visible = false
	fullscreen_check.grab_focus()


func _show_help() -> void:
	help_panel.visible = true
	settings_panel.visible = false
	$MenuColumn.visible = false
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
	new_game_button.icon = ThemeLib.menu_icon(&"play")
	continue_button.icon = ThemeLib.menu_icon(&"save")
	settings_button.icon = ThemeLib.menu_icon(&"gear")
	help_button.icon = ThemeLib.menu_icon(&"people")
	quit_button.icon = ThemeLib.menu_icon(&"door")
	shopy_label.add_theme_font_size_override("font_size", 56)
	shopy_label.add_theme_color_override("font_color", ThemeLib.LOGO_SHOPY)
	shopy_label.add_theme_color_override("font_outline_color", Color(0.12, 0.28, 0.55, 1.0))
	shopy_label.add_theme_constant_override("outline_size", 10)
	fender_label.add_theme_font_size_override("font_size", 56)
	fender_label.add_theme_color_override("font_color", ThemeLib.LOGO_FENDER)
	fender_label.add_theme_color_override("font_outline_color", Color(0.55, 0.22, 0.05, 1.0))
	fender_label.add_theme_constant_override("outline_size", 10)
	tagline_label.add_theme_font_size_override("font_size", 16)
	tagline_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	tagline_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.85))
	tagline_label.add_theme_constant_override("outline_size", 4)
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	version_label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 0.8))
	version_label.add_theme_constant_override("outline_size", 3)
```

Do not connect `continue_button.pressed`. Do not restore `_process` orbit. Logo and version stay visible while Settings/Help are open (`MenuColumn` hides as a whole, which also hides Continue).

- [ ] **Step 5: Import and run tests**

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender --import
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

Expected: `All tests passed.` including `PASS  menu background file exists` and `PASS  main menu buttons and panels`.

If `continue_button` is null: `@onready` path mismatch — names must be `MenuColumn/ContinueButton`.
If texture is null: import did not pick up the jpg — rerun `--import`.
If Store still found: old `MainMenu.tscn` not fully replaced.

- [ ] **Step 6: Commit**

Skip. User did not ask for a commit.

---

### Task 3: Decision log + visual sanity

**Files:**

- Modify: `docs/decisions.md`
- Modify: `docs/superpowers/specs/2026-09-08-main-menu-concept-design.md` — set Status to `Accepted`

**Interfaces:**

- Consumes: Task 2 menu
- Produces: documented decision; spec status Accepted

- [ ] **Step 1: Append to `docs/decisions.md`**

```markdown
---

## Decision
Main menu is a 2D overlay on the user concept still (`assets/ui/main_menu_background.jpg`). Continue is visible and disabled until a save-game exists. Help stays instead of Credits. Copy is Polish.

## Reason
The concept look cannot be matched by the current prototype store mesh. Overlaying Polish controls on the still covers the baked-in English UI without a 3D restage.

## Alternatives
Keep the rotating 3D store; dim the left 40% of the still; crop the still to the shop only.

## Status
Accepted
```

Set spec header `Status: Accepted`.

- [ ] **Step 2: Re-run full tests**

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

Expected: `All tests passed.`

- [ ] **Step 3: Visual check (editor or MCP)**

Play `res://scenes/ui/MainMenu.tscn` at 1280×720. Confirm: still fills the screen, Polish logo/buttons sit on the left covering English text, Continue is greyed, version `v0.05` bottom-right, Nowa gra starts `Main.tscn`, Esc closes Help/Settings. If Godot MCP is connected (port 6505), `play_scene` + `get_game_screenshot` is enough; otherwise run the editor.

- [ ] **Step 4: Commit**

Skip. User did not ask for a commit.

---

## Spec coverage

| Spec section | Task |
| --- | --- |
| Control root, remove 3D store/camera | 2 |
| Background jpg cover stretch | 2 |
| Polish copy table | 2 |
| Continue disabled + tooltip | 1, 2 |
| Help not Credits | 1, 2 |
| Settings/Help panels, Esc | 1, 2 |
| Version `v0.05` | 1, 2 |
| Theme green/blue | 2 |
| Tests | 1, 2, 3 |
| Non-goals (no save, no 3D restage) | 2 (omitted) |
| License + decision | 2, 3 |
