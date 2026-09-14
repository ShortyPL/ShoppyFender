class_name GameTheme
extends RefCounted

const INK := Color(0.07, 0.09, 0.1, 0.94)
const CREAM := Color(0.96, 0.95, 0.9)
const MUTED := Color(0.78, 0.82, 0.8)
const TEAL := Color(0.16, 0.42, 0.32)
const TEAL_HI := Color(0.22, 0.54, 0.4)
const GOLD := Color(0.98, 0.84, 0.36)
const BORDER := Color(0.42, 0.72, 0.54, 0.7)
const MENU_GREEN := Color(0.298, 0.686, 0.314, 1.0)
const MENU_GREEN_HI := Color(0.36, 0.76, 0.38, 1.0)
const MENU_BLUE := Color(0.102, 0.227, 0.478, 1.0)
const MENU_BLUE_HI := Color(0.14, 0.32, 0.62, 1.0)
const MENU_BLUE_DISABLED := Color(0.12, 0.18, 0.32, 1.0)
const LOGO_SHOPY := Color(0.93, 0.97, 1.0, 1.0)
const LOGO_FENDER := Color(0.976, 0.659, 0.145, 1.0)
const HUD_BLUE := Color(0.18, 0.482, 0.784, 0.94)
const HUD_BLUE_HI := Color(0.24, 0.58, 0.88, 0.98)
const HUD_BLUE_BORDER := Color(0.62, 0.82, 1.0, 0.9)
const HUD_RED_DOT := Color(0.92, 0.18, 0.22, 1.0)


static func make() -> Theme:
	var theme := Theme.new()
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_shadow_color", "Label", Color(0.02, 0.03, 0.03, 0.7))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", Color(1, 1, 1))
	theme.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	theme.set_color("font_disabled_color", "Button", Color(0.55, 0.58, 0.56))
	theme.set_color("font_color", "CheckBox", CREAM)
	theme.set_stylebox("normal", "Button", button_box(Color(0.13, 0.17, 0.19, 0.96), Color(0.3, 0.42, 0.38)))
	theme.set_stylebox("hover", "Button", button_box(Color(0.2, 0.32, 0.28, 0.98), Color(0.5, 0.78, 0.6)))
	theme.set_stylebox("pressed", "Button", button_box(Color(0.1, 0.22, 0.18, 0.98), Color(0.35, 0.62, 0.48)))
	theme.set_stylebox("focus", "Button", button_box(Color(0.16, 0.24, 0.22, 0.98), Color(0.55, 0.84, 0.62)))
	theme.set_stylebox("disabled", "Button", button_box(Color(0.1, 0.12, 0.13, 0.8), Color(0.22, 0.24, 0.24)))
	theme.set_stylebox("panel", "PanelContainer", panel_box(INK, BORDER))
	return theme


static func apply(control: Control) -> void:
	control.theme = make()


static func style_primary(button: Button) -> void:
	button.add_theme_stylebox_override("normal", button_box(Color(0.16, 0.44, 0.3, 0.98), Color(0.5, 0.86, 0.58)))
	button.add_theme_stylebox_override("hover", button_box(Color(0.2, 0.54, 0.36, 0.98), Color(0.62, 0.92, 0.66)))
	button.add_theme_stylebox_override("pressed", button_box(Color(0.12, 0.34, 0.24, 0.98), Color(0.4, 0.7, 0.5)))
	button.add_theme_stylebox_override("focus", button_box(Color(0.18, 0.48, 0.32, 0.98), Color(0.7, 0.95, 0.7)))


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
	button.add_theme_stylebox_override("pressed", menu_button_box(Color(0.08, 0.16, 0.36, 1.0), Color(1, 1, 1, 0.25)))
	button.add_theme_stylebox_override("focus", menu_button_box(MENU_BLUE_HI, Color(1, 1, 1, 0.7)))
	button.add_theme_stylebox_override("disabled", menu_button_box(MENU_BLUE_DISABLED, Color(1, 1, 1, 0.08)))
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.75, 0.8, 0.88, 0.7))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT


static func menu_button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(fill.r, fill.g, fill.b, 1.0)
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(22)
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
		&"cart":
			for x in range(5, 19):
				img.set_pixel(x, 8, white)
			for y in range(8, 16):
				img.set_pixel(5, y, white)
				img.set_pixel(18, y, white)
			for x in range(5, 19):
				img.set_pixel(x, 16, white)
			img.set_pixel(8, 19, white)
			img.set_pixel(16, 19, white)
			img.set_pixel(7, 6, white)
			img.set_pixel(8, 5, white)
		&"hammer":
			for x in range(12, 20):
				for y in range(5, 9):
					img.set_pixel(x, y, white)
			for i in 10:
				img.set_pixel(11 - i, 9 + i, white)
				img.set_pixel(12 - i, 9 + i, white)
		&"chart":
			for y in range(14, 20):
				for x in range(5, 8):
					img.set_pixel(x, y, white)
			for y in range(10, 20):
				for x in range(10, 13):
					img.set_pixel(x, y, white)
			for y in range(6, 20):
				for x in range(15, 18):
					img.set_pixel(x, y, white)
		&"more":
			for cx in [7, 12, 17]:
				for y in range(10, 14):
					for x in range(cx - 1, cx + 2):
						img.set_pixel(x, y, white)
		&"clipboard":
			for y in range(5, 20):
				for x in range(6, 18):
					if y == 5 or y == 19 or x == 6 or x == 17:
						img.set_pixel(x, y, white)
			for x in range(9, 15):
				img.set_pixel(x, 4, white)
			img.set_pixel(10, 10, white)
			img.set_pixel(11, 11, white)
			img.set_pixel(12, 12, white)
		&"star":
			img.set_pixel(11, 5, white)
			for x in range(8, 16):
				img.set_pixel(x, 10, white)
			img.set_pixel(6, 18, white)
			img.set_pixel(16, 18, white)
			img.set_pixel(11, 14, white)
		_:
			pass
	return ImageTexture.create_from_image(img)


static func button_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.shadow_color = Color(0, 0, 0, 0.28)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0, 2)
	return box


static func panel_box(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(14)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 8
	box.shadow_offset = Vector2(0, 3)
	return box


static func chip_box(fill: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(8)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


static func hud_panel_box(fill: Color = HUD_BLUE, radius: int = 20) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = HUD_BLUE_BORDER
	box.set_border_width_all(2)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.shadow_color = Color(0, 0, 0, 0.28)
	box.shadow_size = 6
	box.shadow_offset = Vector2(0, 2)
	return box


static func style_hud_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", hud_panel_box())


static func style_hud_pill(panel: PanelContainer) -> void:
	if panel == null:
		return
	var box := hud_panel_box(HUD_BLUE, 22)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", box)


static func style_hud_action(button: Button, active: bool = false) -> void:
	if button == null:
		return
	var fill := HUD_BLUE_HI if active else Color(0, 0, 0, 0)
	var border := Color(1, 1, 1, 0.0) if not active else HUD_BLUE_BORDER
	var normal := button_box(fill, border)
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := button_box(HUD_BLUE_HI, HUD_BLUE_BORDER)
	hover.set_corner_radius_all(14)
	var pressed := button_box(Color(0.14, 0.4, 0.68, 0.98), HUD_BLUE_BORDER)
	pressed.set_corner_radius_all(14)
	var disabled := button_box(Color(0.12, 0.28, 0.48, 0.55), Color(1, 1, 1, 0.08))
	disabled.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(1, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.82, 0.88, 0.95, 0.55))
	button.add_theme_font_size_override("font_size", 13)
