# Prototype 0.04 Store Pressure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Visible 4-slot checkout queue, Regular vs Impatient customers, and 0–3 independent stars on RESULTS.

**Architecture:** `CheckoutQueue` (RefCounted, customer ids only) owned by `CustomerManager`. Customers walk to slot markers, pay 1.8 s at slot 0, compact on leave. Stars are three boolean checks on existing wave metrics.

**Tech Stack:** Godot 4.7.2, GDScript, headless `tests/run_tests.gd`.

**Spec:** `docs/superpowers/specs/2026-09-07-prototype-004-store-pressure-design.md`

## Global Constraints

- Project root `/Volumes/TimeData/Cursor/ShoppyFender` (never `~/Developer/ShopyFender`).
- Godot 4.7.2, GDScript, Polish UI copy.
- Tests: `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd` with Shell `required_permissions: ["all"]`. After new `class_name`, `--import` if types missing.
- Do not commit unless the user asks. There is no git repo. Skip every Commit step.
- Do not edit `~/.cursor/plans/`. Do not add MCP servers or paid APIs.
- Do not type-hint `StaffManager` from new customer scripts (GDScript class cycles). `BuildManager` must not read `store_manager.staff_manager`.
- Queue: 4 slots at `(3.5,0,2.8)`, `(2.6,0,2.8)`, `(1.7,0,2.8)`, `(0.8,0,2.8)`. Pay **1.8 s**. Tick every **3.0 s** on slots ≥ 1: Regular **+10**, Impatient **+15**. Leave at **100** / **60**.
- Spawn even = Regular, odd = Impatient. Spawn interval stays 1.25 s. Wave size 10.
- Stars: served ≥ 8, sat ≥ 80, lost == 0. Independent. Continue never locked.
- Bot must not skip the queue or set pay time to 0. Do not call `execute_next_instant` for restock.
- Imports at top of file.

## File map

Create:

- `scripts/customers/checkout_queue.gd` — FIFO ids, slot index, pay timer, wait ticks
- `tests/test_checkout_queue.gd` — FIFO, compact, stars, impatient threshold helper

Modify:

- `scripts/store/store_room.gd` — `get_queue_slot_position(index) -> Vector3`
- `scripts/customers/customer_runtime_state.gd` — `leave_threshold`, already has `customer_type_id`
- `scripts/customers/customer_controller.gd` — `queued` state, pay wait, queue ticks, tint, abandon to exit
- `scripts/customers/customer_manager.gd` — own queue, even/odd spawn, tick in `_process`
- `scripts/waves/wave_runtime_state.gd` — `count_stars(served, sat, lost) -> int` + line helpers
- `scripts/ui/hud.gd` — queue line, RESULTS stars
- `scripts/main.gd` — pass stars into `show_results`; log `Prototype 0.04 queue ready`
- `scripts/debug/debug_overlay.gd` — queue length + first archetype
- `scripts/debug/playtest_bot.gd` + `tests/run_tests.gd` — assert `stars == 3` (or 2 with a logged decision if 3★ is impossible)
- `docs/decisions.md`

---

### Task 1: CheckoutQueue + stars (unit, no nav)

**Files:**

- Create: `scripts/customers/checkout_queue.gd`
- Create: `tests/test_checkout_queue.gd`
- Modify: `scripts/waves/wave_runtime_state.gd`
- Modify: `tests/run_tests.gd` — banner `Prototype 0.04 tests`, run `TestCheckoutQueue` after Wave lists

**Interfaces:**

- Produces: `CheckoutQueue.enqueue(id) -> int` (slot index, extras clamp to 3 for *display index* but list can grow), `dequeue(id)`, `index_of(id) -> int` (-1 if missing), `size() -> int`, `front() -> StringName`, `advance_pay(delta) -> bool` (true when slot-0 pay of 1.8 s finished), `start_pay_if_idle()`, `wait_tick_due(delta) -> bool` (true every 3.0 s if size>1), `SLOT_COUNT := 4`, `PAY_SEC := 1.8`, `WAIT_TICK_SEC := 3.0`
- Produces: `WaveRuntimeState.count_stars(served: int, satisfaction: float, lost_sales_count: int) -> int` using served≥8, sat≥80, lost==0

Display index: `mini(queue_index, 3)` so a 5th customer reports slot 3.

- [ ] **Step 1: Write failing tests**

```gdscript
# tests/test_checkout_queue.gd
extends RefCounted
class_name TestCheckoutQueue

static func run() -> int:
	var failures := 0
	failures += _assert("fifo pay order", _fifo())
	failures += _assert("compact after front leaves", _compact())
	failures += _assert("stars 10/100/0 is 3", WaveRuntimeState.count_stars(10, 100.0, 0) == 3)
	failures += _assert("stars 10/100/1 is 2", WaveRuntimeState.count_stars(10, 100.0, 1) == 2)
	failures += _assert("stars 7/100/0 is 2", WaveRuntimeState.count_stars(7, 100.0, 0) == 2)
	failures += _assert("pay completes after 1.8s", _pay_timer())
	return failures

static func _fifo() -> bool:
	var q := CheckoutQueue.new()
	q.enqueue(&"a")
	q.enqueue(&"b")
	q.enqueue(&"c")
	return q.front() == &"a" and q.index_of(&"c") == 2 and q.size() == 3

static func _compact() -> bool:
	var q := CheckoutQueue.new()
	q.enqueue(&"a")
	q.enqueue(&"b")
	q.dequeue(&"a")
	return q.front() == &"b" and q.index_of(&"b") == 0

static func _pay_timer() -> bool:
	var q := CheckoutQueue.new()
	q.enqueue(&"a")
	q.start_pay_if_idle()
	var done_early := q.advance_pay(1.0)
	var done := q.advance_pay(1.0)
	return (not done_early) and done

static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
```

Add `WaveRuntimeState.count_stars` as a **static** func so tests can call it without an instance.

- [ ] **Step 2: Run suite — FAIL** (missing class / missing count_stars)

```
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender --import
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

- [ ] **Step 3: Implement CheckoutQueue + count_stars**

```gdscript
# scripts/customers/checkout_queue.gd
class_name CheckoutQueue
extends RefCounted

const SLOT_COUNT := 4
const PAY_SEC := 1.8
const WAIT_TICK_SEC := 3.0

var _ids: Array[StringName] = []
var _pay_left: float = 0.0
var _paying: bool = false
var _wait_acc: float = 0.0

func enqueue(customer_id: StringName) -> int:
	_ids.append(customer_id)
	return display_index(_ids.size() - 1)

func dequeue(customer_id: StringName) -> void:
	var i := _ids.find(customer_id)
	if i < 0:
		return
	_ids.remove_at(i)
	if i == 0:
		_paying = false
		_pay_left = 0.0

func index_of(customer_id: StringName) -> int:
	return _ids.find(customer_id)

func display_index(raw: int) -> int:
	return mini(raw, SLOT_COUNT - 1)

func size() -> int:
	return _ids.size()

func front() -> StringName:
	return _ids[0] if not _ids.is_empty() else &""

func start_pay_if_idle() -> void:
	if _ids.is_empty() or _paying:
		return
	_paying = true
	_pay_left = PAY_SEC

func advance_pay(delta: float) -> bool:
	if not _paying:
		return false
	_pay_left -= delta
	if _pay_left > 0.0:
		return false
	_paying = false
	_pay_left = 0.0
	return true

func wait_tick_due(delta: float) -> bool:
	if _ids.size() <= 1:
		_wait_acc = 0.0
		return false
	_wait_acc += delta
	if _wait_acc < WAIT_TICK_SEC:
		return false
	_wait_acc = 0.0
	return true
```

```gdscript
static func count_stars(served: int, satisfaction: float, lost_sales_count: int) -> int:
	var n := 0
	if served >= 8:
		n += 1
	if satisfaction + 0.0001 >= 80.0:
		n += 1
	if lost_sales_count == 0:
		n += 1
	return n
```

- [ ] **Step 4: Queue + star tests PASS.** Bot still 0.03-green (no customer-state change yet).
- [ ] **Step 5: Commit** — skip.

---

### Task 2: Slot positions on StoreRoom

**Files:** Modify `scripts/store/store_room.gd`. Optional Marker3Ds in `scenes/store/Store.tscn` named `QueueSlot0`…`3`; if missing, `get_queue_slot_position` uses the constants.

**Interfaces:**

- Produces: `StoreRoom.get_queue_slot_position(index: int) -> Vector3` with index clamped 0..3 to spec coordinates.

- [ ] **Step 1: Extend nav test** in `tests/run_tests.gd` `_test_store_navigation`: path from `get_queue_slot_position(3)` to `get_checkout_position()` size ≥ 2 (or from slot 3 to slot 0).

- [ ] **Step 2: FAIL** if method missing.

- [ ] **Step 3: Implement.** Do not block south doors. Slots are markers only (no collision).

```gdscript
func get_queue_slot_position(index: int) -> Vector3:
	var i := clampi(index, 0, 3)
	return Vector3(3.5 - 0.9 * float(i), 0.0, 2.8)
```

If Marker3D children exist, prefer their `global_position`.

- [ ] **Step 4: Nav tests PASS.**
- [ ] **Step 5: Commit** — skip.

---

### Task 3: Customer queued / paying / archetypes

**Files:**

- Modify: `scripts/customers/customer_runtime_state.gd` — `leave_threshold: float = 100.0`
- Modify: `scripts/customers/customer_controller.gd`
- Modify: `scripts/customers/customer_manager.gd`
- Modify: `scenes/customers/Customer.tscn` only if tint is set in script (prefer script `MeshInstance3D` override)

**Interfaces:**

- Consumes: `CheckoutQueue`, `StoreRoom.get_queue_slot_position`
- Produces: `CustomerController.checkout_queue` (typed `CheckoutQueue` is OK — queue does not type the controller), `apply_archetype(type_id)`, `STATE_QUEUED := &"queued"`
- CustomerManager: `var checkout_queue := CheckoutQueue.new()`, spawn sets type even/odd, after pickup customer **joins queue** instead of `_pay()` immediately

Behavior:

1. `_pick_product` success → `checkout_queue.enqueue(id)` → `STATE_MOVING_TO_CHECKOUT` → `_set_target(slot pos)`.
2. Arrive: `STATE_QUEUED`. If `index_of == 0`: `start_pay_if_idle()`, `STATE_PAYING`. Else wait.
3. CustomerManager `_process` while wave running: `advance_pay`; if true, tell front customer `_complete_pay()` (emit `customer_paid`, dequeue, leave to exit). Then `wait_tick_due`: for each id with `display_index >= 1`, add frustration (Regular 10 / Impatient 15), update satisfaction, if `frustration >= leave_threshold` → abandon (`fail_reason = &"queue"`, dequeue, path to exit, `served=false` on finish). After dequeue, remaining customers `_set_target` their new slot.
4. `_fail(&"queue")` must **walk to exit** then `_finish(false)`. OOS/no_path may keep instant `_finish(false)`.
5. `_physics_process` must also run while `STATE_QUEUED`/`STATE_PAYING` if they still need to walk after compact (they will be `MOVING_TO_CHECKOUT` again) OR keep queued and walk: simplest is after compact set state `MOVING_TO_CHECKOUT` and `_set_target`.
6. Tint: Regular leave mesh as-is; Impatient set albedo `Color(0.78, 0.38, 0.22)`.
7. `leave_threshold` Regular 100, Impatient 60.
8. Match in `_on_arrived` includes `STATE_QUEUED` (no-op) and does not instant-pay on first checkout arrival — go queued first.

Do not reference `StaffManager` in these files.

- [ ] **Step 1: Add a unit test** that enqueue + simulated 1.8 s `advance_pay` still works (already Task 1). Add `TestCheckoutQueue` case: wait_tick_due false before 3 s with 2 people, true after.

- [ ] **Step 2: FAIL** if wait_tick not implemented.

- [ ] **Step 3: Wire customers.** Headless bot may start failing (pay delay / impatient). That is expected until Task 5.

- [ ] **Step 4: Unit queue tests PASS.** Note bot result in the report.
- [ ] **Step 5: Commit** — skip.

---

### Task 4: HUD queue + RESULTS stars

**Files:** `scripts/ui/hud.gd`, `scripts/main.gd`, `scripts/debug/debug_overlay.gd`

**Interfaces:**

- `Hud.set_queue_length(n: int)` — SIMULATION hint or stock-row suffix `Kolejka: n`; hide/empty in BUILD.
- `Hud.show_results(..., stars: int, served_ok: bool, sat_ok: bool, lost_ok: bool)`
- Star glyphs: `★` passed, `☆` failed. Footer `Stars: %d/3`.
- `main.gd` `_on_results_ready`: compute via `WaveRuntimeState.count_stars(...)`.
- Overlay: `Queue: n` and first customer `customer_type_id`.
- Log line: `Prototype 0.04 queue ready`.
- SIMULATION hint can stay; queue length still shown (`set_queue_length` every frame from overlay or Main `_process` — prefer CustomerManager signal-free: Hud updated from DebugOverlay `_process` **or** Main `_process` when SIMULATION). Simplest: `debug_overlay` already ticks; also call `hud.set_queue_length` from `CustomerManager._process` via a new signal `queue_changed` **or** GameManager. Add `CustomerManager.get_queue_length() -> int` and have DebugOverlay/Hud poll. Polling in DebugOverlay + Hud from Main `_process` is enough:

```gdscript
# main.gd _process
if game_manager.current_state == GameManager.STATE_SIMULATION:
	hud.set_queue_length(customer_manager.checkout_queue.size())
```

- [ ] **Step 1: Extend `_test_context_menu`** is the wrong place. Add a Hud instantiate check in run_tests: `show_results` text contains `Stars:` — small `_test_results_stars` in `run_tests.gd`.

- [ ] **Step 2: FAIL** missing Stars.
- [ ] **Step 3: Implement copy.**
- [ ] **Step 4: New HUD test PASS.**
- [ ] **Step 5: Commit** — skip.

---

### Task 5: Bot asserts 3 stars

**Files:** `scripts/debug/playtest_bot.gd`, `tests/run_tests.gd`

**Interfaces:** Report key `stars`. After wave: `stars == WaveRuntimeState.count_stars(served, sat, lost)`. Assert `stars == 3` together with 10/10, lost 0, sat 100.

If the bot **fails** because Impatient abandon the queue: first check slots are reachable (Task 2 path). Do **not** zero `PAY_SEC` or skip enqueue. Allowed last resort (record in `docs/decisions.md` in Task 6): assert `stars >= 2` and log why. Prefer keeping 3★.

CUSTOMER_TIMEOUT_SEC 90 may need +30 because 10 × 1.8 s pay plus walks. Raise to **120** if the wave times out while still serving.

- [ ] **Step 1: Add stars to bot report + run_tests assert.**
- [ ] **Step 2: Run full suite `all` permissions.**
- [ ] **Step 3: Fix path/timeout until `All tests passed.`**
- [ ] **Step 4: Confirm 10/10, lost 0, sat 100, stars 3 (or documented ≥2).**
- [ ] **Step 5: Commit** — skip.

---

### Task 6: Decision log

**Files:** `docs/decisions.md`

Append Accepted: 4-slot queue, 1.8 s pay, 5/5 Regular/Impatient, independent stars 8 / 80 / 0 lost. Alternatives: instant pay; one archetype.

- [ ] **Step 1: Write the paragraph.** Leave 0.03 history untouched.
- [ ] **Step 2: Re-run full headless suite once.**
- [ ] **Step 3: Confirm log `Prototype 0.04 queue ready`.**
- [ ] **Step 4: Commit** — skip.

---

## Self-review

| Spec | Task |
| --- | --- |
| 4 slots, coordinates, extras at slot 3 | 1–2 |
| Pay 1.8 s, tick 3 s, +10/+15, leave 100/60 | 1, 3 |
| Even Regular / odd Impatient | 3 |
| Queue abandon = lost sale, walk to exit | 3 |
| Stars 8 / 80 / 0 lost | 1, 4 |
| HUD Kolejka + RESULTS glyphs | 4 |
| Bot 3★ without skipping queue | 5 |
| No second checkout / cashier / missions | global |
| No `store_manager.staff_manager` from BuildManager | global |
