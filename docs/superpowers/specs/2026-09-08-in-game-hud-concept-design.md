# In-game HUD — concept chrome (English)

Date: 2026-09-08
Status: Accepted
Godot: 4.7.2, GDScript, project root `/Volumes/TimeData/Cursor/ShoppyFender`

## Goal

Replace the current teal top/bottom HUD bars with a floating casual-game chrome that matches the provided concept: logo top-left, stat pills top-right, goals + queue on the right, action bar bottom-center. English copy. The 3D store stays visible in the center (no full-screen still).

Out of scope: daily-goal logic, XP/level progression, calendar clock, store-rating reviews, Staff/Upgrades screens, new game systems, Polish HUD labels.

## Decisions (locked)

| Topic | Choice |
| --- | --- |
| Construction | Native Godot Controls + `StyleBoxFlat` (not a PNG overlay) |
| Language | English, matching the concept |
| Scope | Look 1:1; dummy Day / XP / goals; live cash, queue, last-wave stars |
| Open Store | Inside **More** (concept has no Open Store slot) |
| Center of screen | Transparent; 3D store shows through |

Reference still (not drawn in-game): keep a copy at `res://assets/ui/hud_concept.png`.

## Scene

`res://scenes/ui/Hud.tscn` stays `CanvasLayer` + `class_name Hud` (`scripts/ui/hud.gd`). Root `Control` remains full-rect, `mouse_filter` ignore except interactive chrome.

```text
HUD (CanvasLayer)
  Root (Control, full rect, mouse ignore)
    LogoBlock (top-left)
      LogoRow: SHOPPY (white) + FENDER (yellow)
      Tagline ribbon: Manage your shop. Grow your story.
    StatsRow (top-right, HBox of pills)
      CashPill
      DayPill          # dummy
      RatingPill       # last-wave stars, else — (0)
      LevelPill        # dummy
    GoalsPanel (mid-right)
      Title: Today's Goals
      three dummy rows
    QueueChip (below goals): "{n} in queue"
    ActionBar (bottom-center, HBox)
      OrderButton ("Order Stock") + red dot in BUILD
      BuildButton ("Build")        # visual mode, not Open Store
      StaffButton ("Staff")        # disabled
      UpgradesButton ("Upgrades")  # disabled
      MoreButton ("More")
    MorePopup (hidden)
      OpenButton ("Open Store")
      ContinueButton ("Back to build")
      MenuButton ("Main Menu")
    ToastLabel           # show_message
    ResultsPanel         # unchanged behavior, restyle to blue chrome
    OrderDimmer / OrderPanel / ContextMenu  # unchanged behavior
```

Keep exported/`@onready` names the bot and tests already use: `cash_label`, `open_button`, `order_button`, `menu_button`, `continue_button`, `results_panel`, `results_label`, `context_menu`, `order_panel`.

`open_button` / `continue_button` / `menu_button` live in `MorePopup`. Headless playtest bot uses API fallback when a HUD button is not visible; do not require VISUAL-mode clicks on More.

## Live vs dummy

| Widget | Data |
| --- | --- |
| Cash | `set_cash` → `$%.2f` (no "Kasa") |
| Queue chip | `set_queue_length`; BUILD/RESULTS show `0 in queue` |
| Rating pill | After `show_results`, `"%.1f (%d)"` with stars as `X.0` and wave count starting at 1; before first wave `"— (0)"` |
| Day pill | Static `Day 1` / `9:00 AM` |
| Level pill | Static `Store Level 1` and `0 / 600 XP` |
| Goals | Static concept rows: Restock dairy `0/1`; Serve 10 customers `0/10`; Keep shelves full `0/50` (not 52/50 — that number is concept art, not live stock) |
| Order Stock | Existing `order_requested`; visible/enabled in BUILD; red notification dot only in BUILD |
| Build | Highlighted in BUILD, idle in SIMULATION/RESULTS; does not open the store |
| Staff / Upgrades | Visible, `disabled`, tooltip `Coming soon` |
| More | Toggles `MorePopup` |
| Open Store | Existing `open_store_pressed`; visible in BUILD |
| Back to build | Existing `continue_pressed`; visible in RESULTS |
| Main Menu | Existing `menu_pressed` |
| Warehouse / in-transit lines | Removed from chrome. `set_warehouse_line` / `set_in_transit_line` stay as no-ops so `main.gd` can keep calling them |
| Hints | `show_message` writes `ToastLabel` above the action bar (no top hint strip) |
| State chip "Budowa/Otwarte" | Removed; Build slot + More actions replace it |

## Copy

| Element | Text |
| --- | --- |
| Logo | SHOPPY + FENDER (two words, two P’s) |
| Tagline | Manage your shop. Grow your story. |
| Order | Order Stock |
| Build | Build |
| Staff | Staff |
| Upgrades | Upgrades |
| More | More |
| Open Store | Open Store |
| Continue | Back to build |
| Menu | Main Menu |
| Goals title | Today's Goals |
| Queue | `%d in queue` |
| Results panel | Keep current English/mixed results body that tests assert (`Stars:`, `☆`) |

Gameplay toasts from `main.gd` / `build_manager` may stay Polish (`Za mało kasy`, open-store fail reasons). HUD chrome is English.

## Visual style

- Medium concept blue panels (~`#2E7BC8`), light-blue border, white bold sans labels, corner radius ~18–22.
- Logo: white SHOPPY, yellow FENDER (`GameTheme.LOGO_*`), dark-blue outline via font shadow; tagline on a blue ribbon.
- Pills: same blue, icons optional (simple `GameTheme` generated textures or Unicode: `$` / calendar / star).
- Action bar: one long stadium capsule, thin vertical separators, icon above label.
- Red dot: small `ColorRect` on Order Stock, BUILD only.
- Completed-goal green is unused this slice (all dummy goals unchecked).
- Do not apply the old teal `ThemeLib.apply($Root)` as the HUD chrome fill; add `GameTheme.style_hud_*` helpers. Order panel and context menu may keep current styling.

## Wiring

- `Hud.set_state` still shows/hides Open Store vs Continue and enables Order in BUILD.
- `MorePopup` closes after a child action, or on click outside.
- `BuildButton` is not connected to `open_store_pressed`.
- Do not call `execute_next_instant` or change staff/customers.

## Tests

Headless `tests/run_tests.gd` (Shell `required_permissions: ["all"]`).

- Keep context-menu and results-stars tests.
- Add HUD chrome asserts after instantiate + two frames: `order_button.text == "Order Stock"`, goals title present, `cash_label.text` begins with `$`, queue chip contains `queue`, `Staff`/`Upgrades` disabled, `open_button.text == "Open Store"`.
- Playtest bot: still `hud.open_button` / `hud.continue_button` / `hud.order_button` node refs. API mode must pass without opening More.

## Non-goals

- Rendering the concept PNG over the 3D view
- Implementing XP, days, or real daily goals
- Translating this HUD to Polish
- Changing PPM context menu copy
