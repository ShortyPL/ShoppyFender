# Worker Multi-Rack Restock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One warehouse crate of a SKU can fill several fixtures at random (max 3 units per stop unless it is the last hole), then the worker always walks home to the backroom and idles there.

**Architecture:** `StaffManager` owns eligible-shelf listing, pick amount, DROP_CAP hop loop, and SKU-level queue keys. `WorkerController` keeps carry across shelf hops and adds `to_home`. Instant tests call the same hop helper the worker uses.

**Tech Stack:** Godot 4.7.2, GDScript, headless `tests/run_tests.gd`.

**Spec:** `docs/superpowers/specs/2026-09-08-worker-multi-rack-design.md`

## Global Constraints

- Project root `/Volumes/TimeData/Cursor/ShoppyFender`.
- Godot 4.7.2, GDScript, Polish UI unchanged.
- Tests: `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd` with Shell `required_permissions: ["all"]`.
- Do not commit unless the user asks. Skip every Commit step.
- `CARRY_LIMIT := 6`, `DROP_CAP := 3`.
- Per stop: `min(carry, room, DROP_CAP)` unless this is the last remaining hole this trip (`unvisited` empty after this drop or only one eligible) → then `min(carry, room)`.
- Prefer shelves **not yet visited this trip** when any unvisited eligible remain; otherwise any eligible with room. Pick index 0 in tests (deterministic). Live game: `randi() % n`.
- Always path to `store.get_backroom_pick_position()` after the floor loop; idle only there. Do not `begin_idle` on the sales floor.
- Leftover carry is deposited at home, not at the last aisle stop.
- One queue key per SKU (`product_id`), not per shelf, so one cola trip covers the whole shop.
- Do not call `execute_next_instant` from the playtest bot. Do not skip nav. Do not add workers or mixed-SKU crates.
- Imports at top of file.

## File map

Modify:

- `scripts/store/store_manager.gd` — `add_test_gondola() -> StringName` for two-fixture tests
- `scripts/staff/staff_manager.gd` — DROP_CAP, SKU queue key, `list_eligible_shelves`, `pick_amount`, `deliver_hop`, `run_hop_loop` used by instant + worker
- `scripts/staff/worker_controller.gd` — store-wide pick, hops, `STATE_TO_HOME`
- `tests/test_staff.gd` — split 3+3, last-hole uncapped, SKU swap still returns carry
- `docs/decisions.md`

Do not modify: HUD copy, cashier, customers, playtest bot restock (still wait for idle).

---

### Task 1: Instant hop loop (no nav)

**Files:**

- Modify: `scripts/store/store_manager.gd`
- Modify: `scripts/staff/staff_manager.gd`
- Modify: `tests/test_staff.gd`

**Interfaces:**

- Produces: `StoreManager.add_test_gondola() -> StringName` (same 4-shelf gondola as `setup_for_tests`, new id, does not clear `runtime`)
- Produces: `StaffManager.DROP_CAP := 3`
- Produces: `StaffManager.pick_eligible_index: Callable` default `func(n: int) -> int: return randi() % n` (tests set `func(n: int) -> int: return 0`)
- Produces: `list_eligible_shelves(product_id, visited: Dictionary) -> Array[Dictionary]` each `{ "instance_id": StringName, "shelf_index": int, "placement": ProductPlacementState }`
- Produces: `sku_room(product_id) -> int`
- Produces: `pick_want(product_id) -> int` = `min(CARRY_LIMIT, warehouse, sku_room)`
- Produces: `drop_amount(carry, room, eligible_after_this: int) -> int` — if `eligible_after_this == 0` then `min(carry, room)` else `min(carry, room, DROP_CAP)`
- Produces: `run_hop_loop(task, carry, carry_product) -> int` total shelved; leftover returned to warehouse (instant path deposits leftover immediately because there is no worker to walk home)
- Changes: `_enqueue` busy key is `product_id` (`_sku_key`). `request_restock_fixture` enqueues **once per distinct SKU** on that fixture.
- Changes: `_execute_task_instant` uses `pick_want` + `run_hop_loop`.
- Changes: `_finish_task` re-queues if `sku_room(task.product_id) > 0` and warehouse > 0 (store-wide), else erase `_sku_key`.
- Changes: `execute_next_instant_swap_before_deliver` picks with `pick_want` of original SKU, swaps seed shelf, then `run_hop_loop` (no cola shelves → leftover back).

`eligible_after_this` = number of other eligible shelves (including visited-with-room if unvisited is empty) **after** removing the current target from the unvisited set. If the unvisited set minus current is empty and no other eligible with room exist, treat as last hole.

Simpler drop rule matching spec:

```gdscript
func drop_amount(carry: int, room: int, others_with_room: int) -> int:
	if others_with_room <= 0:
		return mini(carry, room)
	return mini(carry, mini(room, DROP_CAP))
```

`others_with_room` = eligible count excluding the current target.

Visited: `Dictionary` keys `_shelf_key(instance_id, shelf_index)`. When choosing a target, prefer eligible whose key is not in visited; if none, use all eligible with room.

- [ ] **Step 1: Write failing tests**

Add `StoreManager.add_test_gondola`:

```gdscript
func add_test_gondola() -> StringName:
	var fixture := FixtureInstanceState.new()
	fixture.instance_id = ids.next(&"fixture_instance")
	fixture.definition_id = &"gondola_basic_100"
	fixture.position = Vector3.ZERO
	fixture.rotation_y_deg = 0.0
	_add_shelf_states(fixture, 4, 1.0, 0.4)
	runtime[fixture.instance_id] = fixture
	return fixture.instance_id
```

Replace/extend `tests/test_staff.gd` `run()`:

```gdscript
static func run() -> int:
	var failures := 0
	failures += _assert_eq("instant restock moves 6 from warehouse to shelf", _instant_transfer(), true)
	failures += _assert_eq("empty warehouse queues no restock task", _empty_warehouse_queues_nothing(), true)
	failures += _assert_eq("second instant trip moves remaining 6", _second_trip_moves_six(), true)
	failures += _assert_eq("mid-trip SKU swap returns carry to warehouse", _sku_swap_returns_carry(), true)
	failures += _assert_eq("one crate splits 3 and 3 across two cola fixtures", _split_two_fixtures(), true)
	failures += _assert_eq("last hole takes remainder without DROP_CAP", _last_hole_uncapped(), true)
	return failures
```

Keep existing four tests as written (single fixture still gets 6 in one instant trip because it is the last hole).

New tests:

```gdscript
static func _split_two_fixtures() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var a: StringName = store.runtime.keys()[0]
	var b: StringName = store.add_test_gondola()
	var pa := store.assign_product_to_shelf(a, 1, COLA_ID, 0)
	var pb := store.assign_product_to_shelf(b, 1, COLA_ID, 0)
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 6)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	staff.pick_eligible_index = func(n: int) -> int: return 0
	staff.request_restock_fixture(a)
	staff.execute_next_instant()
	var stocks := [pa.shelf_stock, pb.shelf_stock]
	stocks.sort()
	var ok := (
		inventory.get_warehouse(COLA_ID) == 0
		and stocks[0] == 3
		and stocks[1] == 3
	)
	staff.free()
	inventory.free()
	store.free()
	return ok


static func _last_hole_uncapped() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var a: StringName = store.runtime.keys()[0]
	var b: StringName = store.add_test_gondola()
	var pa := store.assign_product_to_shelf(a, 1, COLA_ID, 0)
	var pb := store.assign_product_to_shelf(b, 1, COLA_ID, 0)
	pb.shelf_stock = pb.capacity - 2
	var inventory := InventoryManager.new()
	inventory.setup(EconomyManager.new())
	inventory.seed_warehouse(COLA_ID, 6)
	var staff := StaffManager.new()
	staff.setup(null, store, inventory, null)
	staff.pick_eligible_index = func(n: int) -> int: return 0
	staff.request_restock_fixture(a)
	staff.execute_next_instant()
	# Prefer unvisited: first target is `a` (index 0), DROP_CAP 3; then only `b` left → uncapped 3? carry 3, room 2 → 2 on b, leftover 1 warehouse.
	# If first target is b (if keys order puts b first): b takes 2 (room 2, others exist so DROP_CAP 3 but room 2), then a last hole takes 4.
	var leftover := inventory.get_warehouse(COLA_ID)
	var total := pa.shelf_stock + pb.shelf_stock
	var ok := total == 6 - leftover and leftover >= 0 and leftover <= 1
	# Stronger: all 6 leave warehouse (last hole uncapped absorbs remainder).
	ok = leftover == 0 and total == 6 and pb.shelf_stock == pb.capacity
	staff.free()
	inventory.free()
	store.free()
	return ok
```

Fix `_last_hole_uncapped` so it does not depend on dictionary key order: fill `b` to `capacity - 2` **after** knowing which id is first in `list_eligible`. Easier assertion: `leftover == 0`, `pa.shelf_stock + pb.shelf_stock == 6`, and `pb.shelf_stock == pb.capacity` OR `pa.shelf_stock >= 3`. Simplest robust check:

```gdscript
	var ok := inventory.get_warehouse(COLA_ID) == 0 and pa.shelf_stock + (pb.shelf_stock - (pb.capacity - 2)) == 6
```

Wait, pb started at capacity-2, so added_to_b = pb.shelf_stock - (capacity-2). pa.shelf_stock + added_to_b == 6 and warehouse 0.

- [ ] **Step 2: Run tests, expect FAIL** on the new split test (today all 6 land on one shelf).

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

- [ ] **Step 3: Implement hop helpers + SKU queue key + instant loop**

In `staff_manager.gd` add `DROP_CAP`, `pick_eligible_index`, `list_eligible_shelves`, `sku_room`, `pick_want`, `drop_amount`, `run_hop_loop`.

`run_hop_loop` sketch:

```gdscript
func run_hop_loop(_task: ReplenishmentTask, carry_product: StringName, carry: int) -> int:
	var visited := {}
	var added_total := 0
	while carry > 0:
		var preferred := list_eligible_shelves(carry_product, visited)
		if preferred.is_empty():
			preferred = list_eligible_shelves(carry_product, {})
		if preferred.is_empty():
			break
		var idx := int(pick_eligible_index.call(preferred.size()))
		idx = clampi(idx, 0, preferred.size() - 1)
		var target: Dictionary = preferred[idx]
		var placement: ProductPlacementState = target["placement"]
		var room := maxi(0, placement.capacity - placement.shelf_stock)
		var others := list_eligible_shelves(carry_product, {}).size() - 1
		var drop := drop_amount(carry, room, others)
		if drop <= 0:
			break
		var added := store_manager.add_shelf_stock(placement.placement_id, drop)
		carry -= added
		added_total += added
		visited[_shelf_key(target["instance_id"], int(target["shelf_index"]))] = true
	if carry > 0 and inventory != null:
		inventory.add_to_warehouse(carry_product, carry)
	return added_total
```

`list_eligible_shelves`: iterate `store_manager.runtime.values()`, each shelf’s first placement, `product_id` match and `stock < capacity`; if `visited` non-empty, skip keys in visited **only when building the preferred list** (caller passes visited for preferred, `{}` for fallback).

`_execute_task_instant`:

```gdscript
	var product_id := task.product_id
	var want := pick_want(product_id)
	var carry := inventory.take_from_warehouse(product_id, want)
	if carry <= 0:
		return 0
	return run_hop_loop(task, product_id, carry)
```

`_enqueue`: if `_busy_keys.has(product_id)` return false; store `_busy_keys[product_id] = true`.

`request_restock_fixture`: track SKUs already enqueued this call with a local Dictionary so four cola shelves enqueue cola once.

`_finish_task`:

```gdscript
	task_finished.emit(task.task_id)
	if inventory != null and sku_room(task.product_id) > 0 and inventory.get_warehouse(task.product_id) > 0:
		_queue.append(task)
		return
	_busy_keys.erase(task.product_id)
```

Keep `_shelf_key` for visited maps.

`execute_next_instant_swap_before_deliver`: take `pick_want` of cola, swap seed shelf to water, `run_hop_loop(task, COLA, carry)` — no cola eligible → warehouse restored.

- [ ] **Step 4: Run tests, expect PASS** including old four + split + last hole.

- [ ] **Step 5: Commit** — skip.

---

### Task 2: Worker hops + `to_home`

**Files:**

- Modify: `scripts/staff/worker_controller.gd`
- Modify: `scripts/staff/staff_manager.gd` — `finish_trip` only after home (already called by worker)

**Interfaces:**

- Consumes: `StaffManager.pick_want`, `list_eligible_shelves`, `drop_amount`, `pick_eligible_index`
- Produces: `WorkerController.STATE_TO_HOME := &"to_home"`
- Produces: `current_target: Dictionary` (instance_id, shelf_index) while hopping
- Produces: `_visited: Dictionary` cleared at pick
- `_pick` uses `staff_manager.pick_want(current_task.product_id)` not seed-shelf room
- `_deliver` applies one hop via `drop_amount`; if `carry > 0` and eligible remain → `_go_to_shelf` again; else `_go_home` (do not idle, do not `finish_trip` yet)
- `_go_home` targets `store.get_backroom_pick_position()`
- On `STATE_TO_HOME` arrive: deposit leftover, `begin_idle`, `staff_manager.finish_trip(done)`
- `_drop_and_idle` used only when pick fails or nav fails **before** leaving the backroom; if already on the floor with carry, `_go_home` instead of idling in the aisle
- `_current_placement` reads `current_target` if set, else seed task shelf

- [ ] **Step 1: Failing scene-level assert in `tests/run_tests.gd` is optional.** Prefer a small unit-style check without nav: after implementing, `STATE_TO_HOME` exists and `_deliver` does not call `finish_trip`. If you add a test, assert `WorkerController.STATE_TO_HOME == &"to_home"`. Do not instantiate Worker in headless unless already done elsewhere.

Add to `test_staff.gd`:

```gdscript
	failures += _assert_eq("worker has to_home state", WorkerController.STATE_TO_HOME == &"to_home", true)
```

This fails until the const exists.

- [ ] **Step 2: Run tests, expect FAIL** (`to_home` missing).

- [ ] **Step 3: Implement worker**

`_on_arrived` add `STATE_TO_HOME: _arrive_home()`.

`_pick`:

```gdscript
	_visited.clear()
	current_target = {}
	var product_id := current_task.product_id
	var want := 6
	if staff_manager != null:
		want = staff_manager.pick_want(product_id)
	carry = inventory.take_from_warehouse(product_id, want)
	carry_product = product_id
	if carry <= 0:
		_go_home()
		return
	_choose_next_shelf()
	if current_target.is_empty():
		_go_home()
		return
	state = STATE_TO_SHELF
	_go_to_shelf.call_deferred()
```

`_choose_next_shelf` uses staff_manager lists + pick_eligible_index, sets `current_target` and `_visited` on choose (mark visited when delivering, not when choosing — mark in `_deliver` after drop).

`_go_to_shelf` uses `current_target.instance_id` for `get_fixture_node`.

`_deliver`:

```gdscript
	var placement := _current_placement()
	var others := 0
	if staff_manager != null:
		others = staff_manager.list_eligible_shelves(carry_product, {}).size() - 1
	var room := 0
	if placement != null:
		room = maxi(0, placement.capacity - placement.shelf_stock)
	var drop := carry
	if staff_manager != null:
		drop = staff_manager.drop_amount(carry, room, others)
	# add_shelf_stock, subtract carry, log, mark visited
	_choose_next_shelf()
	if carry > 0 and not current_target.is_empty():
		_go_to_shelf.call_deferred()
		return
	_go_home()
```

Do not return leftover in `_deliver`. `_arrive_home` returns leftover then `finish_trip`.

`_go_home`: `state = STATE_TO_HOME`; `_set_target(backroom)`.

If `store == null` (unit tests never spawn worker), skip.

- [ ] **Step 4: Run full suite, expect PASS.** Bot still waits for worker idle; extra hops + home walk are allowed.

- [ ] **Step 5: Commit** — skip.

---

### Task 3: Decision log

**Files:**

- Modify: `docs/decisions.md`
- Modify: spec status → `Accepted`

- [ ] **Step 1: Append**

```markdown
---

## Decision
Worker restock is one SKU crate hopped across random store shelves (DROP_CAP 3, last hole uncapped), then always returns to the backroom pick point to idle.

## Reason
Players expect one trip to feed several racks. Idling in the aisle blocked customers.

## Alternatives
Nearest-shelf routing; one shelf per trip; idle at last rack.

## Status
Accepted
```

Set spec `Status: Accepted`.

- [ ] **Step 2: Full tests again.** Expected: `All tests passed.`

- [ ] **Step 3: Commit** — skip.

---

## Spec coverage

| Spec | Task |
| --- | --- |
| PPM trigger, unique SKU enqueue | 1 |
| Store-wide eligible, random / test index 0 | 1–2 |
| DROP_CAP 3, last hole uncapped | 1 |
| Pick want store-wide | 1–2 |
| Hop while carry > 0 | 2 |
| Always home, leftover at warehouse | 2 |
| finish_trip requeue store-wide | 1 |
| Auto-fill uses same hop loop | 2 |
| Tests split 3+3, swap, last hole | 1 |
| Bot still waits idle | 2 (no bot edit) |
