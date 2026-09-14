# In-game HUD Concept Chrome Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the teal in-game HUD with floating English concept chrome (logo, stat pills, dummy goals, live queue, bottom action bar) while keeping order/results/context-menu behavior and bot node names.

**Architecture:** Native Controls in `Hud.tscn` plus `GameTheme.style_hud_*`. Live cash/queue/stars; Day/XP/goals are static dummy copy. Open Store / Continue / Main Menu live in More. Center of the screen stays transparent.

**Tech Stack:** Godot 4.7.2, GDScript, headless `tests/run_tests.gd`.

**Spec:** `docs/superpowers/specs/2026-09-08-in-game-hud-concept-design.md`

## Global Constraints

- Project root `/Volumes/TimeData/Cursor/ShoppyFender`.
- Godot 4.7.2, GDScript. HUD chrome copy is English from the spec table.
- Tests: `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd` with Shell `required_permissions: ["all"]`.
- Do not commit unless the user asks. Skip every Commit step.
- Do not edit `~/.cursor/plans/`.
- Do not overlay the concept PNG on the 3D view. Do not add XP/day/goal systems. Do not change staff, customers, or PPM copy.
- Keep `@onready` names: `cash_label`, `open_button`, `order_button`, `menu_button`, `continue_button`, `results_panel`, `results_label`, `context_menu`, `order_panel`.
- `set_warehouse_line` / `set_in_transit_line` remain as no-ops.
- Imports at top of file.

## File map

Create:

- `assets/ui/hud_concept.png` — reference still only
- `tests/test_hud.gd` — optional unit helpers if needed; chrome asserts live in `run_tests.gd`

Modify:

- `scripts/ui/game_theme.gd` — HUD blue styleboxes + icons
- `scenes/ui/Hud.tscn` — new chrome tree
- `scripts/ui/hud.gd` — wiring, dummy vs live, More popup
- `tests/run_tests.gd` — `_test_hud_chrome`
- `assets/LICENSES.md`
- `docs/decisions.md`

Do not modify: `main.gd` callers except if a renamed node breaks `@onready` (it must not). Playtest bot keeps pressing `open_button` (hidden in More → API fallback).

Source still:

`/Users/radekwitulski/.cursor/projects/Volumes-TimeData-Cursor-ShoppyFender/assets/ChatGPT_Image_8_wrz_2026__21_39_36-6406165e-1c67-451b-a781-6492643206a1.png`

---

### Task 1: Failing HUD chrome tests + reference art

**Files:**

- Create: `assets/ui/hud_concept.png`
- Modify: `tests/run_tests.gd`
- Modify: `assets/LICENSES.md`

- [ ] **Step 1: Copy the concept PNG** into `assets/ui/hud_concept.png`. Append LICENSES like the main-menu still.

- [ ] **Step 2: Add `_test_hud_chrome`** after `_test_results_stars` and call it from `_run`:

```gdscript
	print("HUD chrome")
	failures += await _test_hud_chrome()
```

```gdscript
func _test_hud_chrome() -> int:
	var hud_scene: PackedScene = load("res://scenes/ui/Hud.tscn")
	var hud: Hud = hud_scene.instantiate()
	root.add_child(hud)
	await process_frame
	await process_frame
	if hud.order_button == null or hud.order_button.text != "Order Stock":
		print("  FAIL  Order Stock label")
		hud.queue_free()
		return 1
	if hud.cash_label == null or not hud.cash_label.text.begins_with("$"):
		print("  FAIL  cash uses $")
		hud.queue_free()
		return 1
	var goals := hud.get_node_or_null("Root/GoalsPanel/GoalsTitle") as Label
	if goals == null or goals.text != "Today's Goals":
		print("  FAIL  Today's Goals")
		hud.queue_free()
		return 1
	var queue := hud.get_node_or_null("Root/QueueChip/QueueLabel") as Label
	if queue == null or not queue.text.contains("queue"):
		print("  FAIL  queue chip")
		hud.queue_free()
		return 1
	var staff := hud.get_node_or_null("Root/ActionBar/StaffButton") as Button
	var upgrades := hud.get_node_or_null("Root/ActionBar/UpgradesButton") as Button
	if staff == null or upgrades == null or not staff.disabled or not upgrades.disabled:
		print("  FAIL  Staff/Upgrades disabled")
		hud.queue_free()
		return 1
	if hud.open_button == null or hud.open_button.text != "Open Store":
		print("  FAIL  Open Store label")
		hud.queue_free()
		return 1
	if not ResourceLoader.exists("res://assets/ui/hud_concept.png"):
		print("  FAIL  hud concept file")
		hud.queue_free()
		return 1
	print("  PASS  HUD chrome labels")
	hud.queue_free()
	return 0
```

- [ ] **Step 3: Run tests, expect FAIL** on Order Stock / `$` / Today's Goals.

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

- [ ] **Step 4: Commit** — skip.

---

### Task 2: Theme helpers + HUD scene + script

**Files:**

- Modify: `scripts/ui/game_theme.gd`
- Modify: `scenes/ui/Hud.tscn`
- Modify: `scripts/ui/hud.gd`

**Interfaces:**

- Produces: `GameTheme.HUD_BLUE`, `HUD_BLUE_HI`, `HUD_BLUE_BORDER`, `style_hud_panel`, `style_hud_pill`, `style_hud_action`, `style_hud_action_on`, `hud_icon(kind)`
- Produces: HUD node paths from the spec tree
- Produces: `Hud.set_cash` → `$%.2f`; `set_queue_length` → `%d in queue`; `show_results` updates rating `"%.1f (%d)"`; warehouse setters no-op; `show_message` → `ToastLabel`

Theme constants:

```gdscript
const HUD_BLUE := Color(0.18, 0.482, 0.784, 0.94)
const HUD_BLUE_HI := Color(0.24, 0.58, 0.88, 0.98)
const HUD_BLUE_BORDER := Color(0.62, 0.82, 1.0, 0.9)
```

`style_hud_panel` / `style_hud_pill`: `StyleBoxFlat`, radius 20, border 2, `HUD_BLUE` / `HUD_BLUE_BORDER`, light shadow.

`style_hud_action`: same fill, radius 8 (inner slots). `style_hud_action_on`: `HUD_BLUE_HI`.

`hud_icon`: extend `menu_icon` kinds with `&"cart"`, `&"hammer"`, `&"chart"`, `&"more"`, `&"clipboard"`, `&"star"`.

Scene: keep ResultsPanel, OrderDimmer, OrderPanel, ContextMenu. Replace TopPanel/BottomPanel with LogoBlock, StatsRow (CashPill/CashLabel, DayPill, RatingPill/RatingLabel, LevelPill), GoalsPanel, QueueChip/QueueLabel, ActionBar (OrderButton, BuildButton, StaffButton, UpgradesButton, MoreButton), MoreDimmer, MorePopup (OpenButton, ContinueButton, MenuButton), ToastLabel.

`OrderDot` ColorRect on OrderButton (red, top-right).

Hud script sketch:

```gdscript
func set_cash(amount: float) -> void:
	cash_label.text = "$%.2f" % amount

func set_warehouse_line(_text: String) -> void:
	pass

func set_in_transit_line(_text: String) -> void:
	pass

func set_queue_length(n: int) -> void:
	_queue_length = n
	if queue_label != null:
		queue_label.text = "%d in queue" % n

func set_state(state_name: String) -> void:
	_state_name = state_name
	var is_build := state_name == "BUILD"
	var is_results := state_name == "RESULTS"
	order_button.disabled = not is_build
	if order_dot != null:
		order_dot.visible = is_build
	open_button.visible = is_build
	continue_button.visible = is_results
	results_panel.visible = is_results
	_paint_build_slot(is_build)
	if not is_build:
		_hide_more()
```

`show_results` keeps the existing results body (tests assert `Stars:` and `☆`) and sets `rating_label.text = "%.1f (%d)" % [float(stars), _waves_seen]` after incrementing `_waves_seen`.

More: `more_button` toggles `MoreDimmer` + `MorePopup`. Dimmer click or child press closes it. Do not connect `BuildButton` to `open_store_pressed`. Staff/Upgrades `disabled = true`, tooltip `Coming soon`.

Do not call `ThemeLib.apply($Root)` for chrome fill; style chrome nodes with `style_hud_*`. Order panel / context menu may keep `ThemeLib.apply` on themselves as today.

- [ ] **Step 1: Implement theme + scene + script**
- [ ] **Step 2: Run full tests, expect PASS** including HUD chrome and playtest bot
- [ ] **Step 3: Commit** — skip

---

### Task 3: Decision log

- [ ] **Step 1: Append `docs/decisions.md`**

```markdown
## Decision
In-game HUD is floating English concept chrome (native Controls). Cash, queue, and last-wave stars are live; day/XP/goals are dummy. Open Store lives under More.

## Reason
The concept cannot sit as a full-screen still over the 3D store. Prototype 0.05 has no XP or daily-goal systems.

## Alternatives
PNG overlay; implement XP/goals now; keep Polish teal bars.

## Status
Accepted
```

- [ ] **Step 2: Full tests again.** Expected: `All tests passed.`
- [ ] **Step 3: Commit** — skip.

## Spec coverage

| Spec | Task |
| --- | --- |
| Native Controls, English copy | 2 |
| Reference PNG not drawn | 1 |
| Live cash/queue/stars | 2 |
| Dummy day/XP/goals | 2 |
| Open Store in More | 2 |
| Bot node names + API fallback | 2 |
| Chrome tests | 1–2 |
| Decision log | 3 |
