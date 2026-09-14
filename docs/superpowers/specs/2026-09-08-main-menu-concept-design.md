# Main menu — concept overlay (2D)

Date: 2026-09-08
Status: Accepted
Godot: 4.7, GDScript, project root `/Volumes/TimeData/Cursor/ShoppyFender`

## Goal

Replace the current 3D rotating-store main menu with a 16:9 2D screen that matches the provided concept: full-bleed store illustration, left-side logo and button column, version in the bottom-right. Overlay language is Polish. Existing Settings and Help behavior stays.

Out of scope: save/load, credits screen, 3D menu restage, English labels, v1.0.0 branding.

## Decisions (locked)

| Topic | Choice |
| --- | --- |
| Background | User concept image as full-screen 2D texture |
| Language | Polish |
| Continue | Visible, disabled, no action until a save exists |
| Fourth slot | Help (not Credits) |
| Composition | Overlay 1:1 on the full image so Polish UI covers baked-in English logo/buttons |

## Scene

`res://scenes/ui/MainMenu.tscn` becomes a root `Control` (not `Node3D`). Script stays `res://scripts/ui/main_menu.gd` (`class_name MainMenu`).

Remove from this scene: `WorldEnvironment`, `DirectionalLight3D`, instanced `Store`, `Pivot` / `Camera3D`, and the `_process` camera orbit.

Node tree:

```text
MainMenu (Control, full rect)
  Background (TextureRect, full rect, stretch cover)
  UI (full rect)
    LogoBlock (VBox, top-left)
      LogoRow (HBox: SHOPY + cart + FENDER)
      Tagline
    MenuColumn (VBox, left, under logo)
      NewGameButton
      ContinueButton
      SettingsButton
      HelpButton
      QuitButton
    Version (Label, bottom-right)
    SettingsPanel (hidden)
    HelpPanel (hidden)
```

`project.godot` `run/main_scene` stays `res://scenes/ui/MainMenu.tscn`. Esc from `Main.tscn` still loads this scene.

## Art

Copy the approved concept still into `res://assets/ui/main_menu_background.jpg` (project asset, not a chat cache path). Assign it to `Background`. Stretch mode covers the viewport (1280×720 native, 16:9). Do not letterbox with empty bars.

Logo is Godot labels/icons drawn on top of the image at the concept positions, not a separate logo PNG. That covering is required: the still already contains English “SHOPYFENDER” and English buttons.

## Copy

| Element | Text |
| --- | --- |
| Logo | SHOPY + FENDER |
| Tagline | Zarządzaj sklepem. Rozwijaj historię. |
| New game | Nowa gra |
| Continue | Kontynuuj |
| Settings | Ustawienia |
| Help | Pomoc |
| Quit | Wyjście |
| Continue tooltip | Brak zapisu partii |
| Version | `v0.05` (prototype, not v1.0.0) |

Help body text stays the current Polish how-to from `MainMenu.tscn`. Settings labels stay: Pełny ekran, Głośność, Czułość kamery, Wstecz.

## Visual style

- **Nowa gra**: action green (~`#4CAF50`), play icon, selected/primary.
- **Other buttons**: deep menu blue (~`#1A3A7A`), white bold sentence-case Polish labels (not ALL CAPS), matching concept icons (floppy, gear, people, door).
- Rounded rectangles, hover/focus lightens the fill. Focus starts on Nowa gra.
- Version: small white label, bottom-right, covering the still’s `v1.0.0`.
- Settings/Help panels: same left-side overlay region as today, restyled to the blue/green palette. They hide the button column only; background and logo stay visible.

Extend `scripts/ui/game_theme.gd` with menu-specific styleboxes (green primary, blue secondary, disabled blue-grey) rather than inventing a second theme system. In-game HUD theme is unchanged unless a shared helper is reused.

## Behavior

| Control | Action |
| --- | --- |
| Nowa gra | Save settings, `change_scene_to_file("res://scenes/main/Main.tscn")` |
| Kontynuuj | Disabled; tooltip only |
| Ustawienia | Show SettingsPanel, hide button column, focus first setting |
| Pomoc | Show HelpPanel, hide button column, focus Wstecz |
| Wyjście | Save settings, `get_tree().quit()` |
| Esc | If a panel is open, return to root list |

Keyboard/gamepad: `ui_up` / `ui_down` through the five buttons. Disabled Continue is skipped by Godot focus if `disabled` is set (desired).

No save-game API in this change. Continue stays disabled even if settings.cfg exists.

## Tests

`tests/run_tests.gd` `_test_main_menu_scene` and `tests/test_main_menu.gd` must assert:

- Menu instantiates without a `Store` child or 3D camera
- Background texture is set
- Button texts match the Polish copy above
- Continue is disabled; the other four buttons are enabled
- Settings and Help panels open/close; Esc returns to root
- Version label is visible and is not `v1.0.0`

Do not test scene change on Nowa gra.

## Non-goals

- Persist or load a play session
- Credits screen
- Recreating the grocery still in 3D
- Changing HUD, store, or simulation
