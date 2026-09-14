# Prototype 0.03 Inventory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Charge product orders, land stock in a 3D backroom, and have one warehouse worker carry units onto shelves so magic restock is gone.

**Architecture:** `InventoryManager` owns warehouse / ordered / Standard deliveries. `StaffManager` + `WorkerController` walk backroom → shelf. `StoreRoom` grows a 6×4 m north backroom. `Hud` adds an order panel. Shelf assign defaults to stock 0; `restock_fixture` only queues the worker.

**Tech Stack:** Godot 4.7.2, GDScript, existing headless `tests/run_tests.gd`.

**Spec:** `docs/superpowers/specs/2026-09-07-prototype-003-inventory-design.md`

## Global Constraints

- Project root is `/Volumes/TimeData/Cursor/ShoppyFender` (never `~/Developer/ShopyFender`).
- Godot 4.7.2, GDScript, answers/UI copy in Polish.
- Tests: `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd` with Shell `required_permissions: ["all"]` (nav fails in sandbox). After new `class_name` files, run `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender --import` once if types are missing.
- Do not commit unless the user explicitly asks. Skip every Commit step.
- Do not edit `~/.cursor/plans/`. Do not call paid generation APIs. Do not add MCP servers.
- Imports at top of file. No 0.04 queues, no wages, no delivery truck, no pickable crates.
- `Uzupełnij` must not set `shelf_stock = capacity` without decreasing warehouse.
- Duplicate fixture copies SKU + facings with **stock 0**.
- Worker carry limit is 6. Standard fee 20, Express fee 45. Start warehouse 12 per catalog SKU.
- Assign with `starting_stock < 0` means **0**, not capacity (tests that pass an explicit count stay valid).

## File map

Create:

- `scripts/inventory/inventory_runtime_state.gd` — warehouse/ordered dictionaries + pending deliveries
- `scripts/inventory/inventory_manager.gd` — quote/order/deliver/take
- `scripts/staff/replenishment_task.gd` — one shelf fill job
- `scripts/staff/staff_manager.gd` — queue, auto-empty in SIMULATION, spawn worker
- `scripts/staff/worker_controller.gd` — nav states idle/to_pick/to_shelf
- `scenes/staff/Worker.tscn` — blue capsule + NavigationAgent3D (clone Customer.tscn)
- `scripts/ui/order_panel.gd` — SKU / qty / Standard|Express / confirm
- `tests/test_inventory.gd` — order + warehouse unit tests

Modify:

- `scripts/store/store_manager.gd` — default assign 0; `add_shelf_stock`; `restock_fixture` queues staff
- `scripts/store/store_room.gd` + `scenes/store/Store.tscn` — backroom floor/walls/door, `BackroomPick`, crate stacks
- `scripts/store/build_manager.gd` — restock → staff; duplicate stock 0; order menu action
- `scripts/ui/context_menu.gd` — floor “Zamów towar…”
- `scripts/ui/hud.gd` + `scenes/ui/Hud.tscn` — warehouse line, Zamów button, order panel
- `scripts/camera/camera_rig.gd` — clamp north to include backroom
- `scripts/core/game_manager.gd` — deliver_pending on Continue; staff active flags
- `scripts/main.gd` + `scenes/main/Main.tscn` — InventoryManager, StaffManager, Workers root
- `scripts/debug/playtest_bot.gd` — assign 0, wait for worker, Standard after wave
- `scripts/debug/debug_overlay.gd` — warehouse + worker state
- `tests/test_shelf_stock.gd` — restock no longer magic-fills
- `tests/run_tests.gd` — banner 0.03, run TestInventory, worker path check
- `docs/decisions.md` — 0.03 charging + worker

---

### Task 1: InventoryManager orders

**Files:**

- Create: `scripts/inventory/inventory_runtime_state.gd`
- Create: `scripts/inventory/inventory_manager.gd`
- Create: `tests/test_inventory.gd`
- Modify: `tests/run_tests.gd` (print `Prototype 0.03 tests`, call `TestInventory.run()` after Economy)

**Interfaces:**

- Consumes: `EconomyManager.can_afford`, `spend(amount, reason) -> Dictionary`, `ProductDefinition.purchase_price`
- Produces: `InventoryManager.setup(economy)`, `seed_warehouse(product_id, amount)`, `get_warehouse(product_id) -> int`, `get_ordered(product_id) -> int`, `quote_order(product, qty, delivery_type) -> Dictionary`, `place_order(product, qty, delivery_type) -> Dictionary`, `deliver_pending() -> void`, `take_from_warehouse(product_id, amount) -> int`, `add_to_warehouse(product_id, amount) -> void`, signal `stock_changed`

- [ ] **Step 1: Write the failing tests**

```gdscript
# tests/test_inventory.gd
extends RefCounted
class_name TestInventory

const COLA := preload("res://data/products/freshpop_cola_500.tres")

static func run() -> int:
	var failures := 0
	failures += _assert_eq("express adds warehouse and charges fee", _express_cola_12(), true)
	failures += _assert_eq("standard waits then delivers", _standard_then_deliver(), true)
	failures += _assert_eq("order rejects insufficient cash", _order_rejects_shortfall(), true)
	failures += _assert_eq("take_from_warehouse rejects empty", _take_rejects_empty(), true)
	return failures

static func _express_cola_12() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.seed_warehouse(&"freshpop_cola_500", 12)
	var result: Dictionary = inv.place_order(COLA, 12, &"express")
	var cost := 1.2 * 12.0 + 45.0
	var ok: bool = bool(result.get("ok", false)) and is_equal_approx(economy.get_cash(), 10000.0 - cost) and inv.get_warehouse(&"freshpop_cola_500") == 24
	economy.free()
	inv.free()
	return ok

static func _standard_then_deliver() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.seed_warehouse(&"freshpop_cola_500", 12)
	var result: Dictionary = inv.place_order(COLA, 6, &"standard")
	var cost := 1.2 * 6.0 + 20.0
	var mid: bool = bool(result.get("ok", false)) and inv.get_ordered(&"freshpop_cola_500") == 6 and inv.get_warehouse(&"freshpop_cola_500") == 12 and is_equal_approx(economy.get_cash(), 10000.0 - cost)
	inv.deliver_pending()
	var ok := mid and inv.get_ordered(&"freshpop_cola_500") == 0 and inv.get_warehouse(&"freshpop_cola_500") == 18
	economy.free()
	inv.free()
	return ok

static func _order_rejects_shortfall() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	var result: Dictionary = inv.place_order(COLA, 24, &"express")
	var ok: bool = result.get("ok", true) == false and result.get("reason", &"") == &"insufficient_cash" and inv.get_warehouse(&"freshpop_cola_500") == 0
	economy.free()
	inv.free()
	return ok

static func _take_rejects_empty() -> bool:
	var inv := InventoryManager.new()
	inv.setup(EconomyManager.new())
	var taken := inv.take_from_warehouse(&"freshpop_cola_500", 6)
	var ok := taken == 0
	inv.free()
	return ok

static func _assert_eq(label: String, actual: bool, expected: bool) -> int:
	if actual == expected:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
```

In `tests/run_tests.gd` change the banner to `ShoppyFender Prototype 0.03 tests` and after Economy:

```gdscript
	print("Inventory")
	failures += TestInventory.run()
```

- [ ] **Step 2: Run tests — expect FAIL** (`InventoryManager` missing / parse error)

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender --import
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

- [ ] **Step 3: Implement InventoryManager**

```gdscript
# scripts/inventory/inventory_runtime_state.gd
class_name InventoryRuntimeState
extends RefCounted

var warehouse_stock: Dictionary = {} # StringName -> int
var ordered_stock: Dictionary = {}
var pending_deliveries: Array[Dictionary] = []
```

```gdscript
# scripts/inventory/inventory_manager.gd
class_name InventoryManager
extends Node

signal stock_changed(product_id: StringName, warehouse: int, ordered: int)

const FEE_STANDARD := 20.0
const FEE_EXPRESS := 45.0

var economy: EconomyManager
var state := InventoryRuntimeState.new()
var ids := RuntimeIdGenerator.new()

func setup(p_economy: EconomyManager) -> void:
	economy = p_economy

func seed_warehouse(product_id: StringName, amount: int) -> void:
	state.warehouse_stock[product_id] = maxi(0, amount)
	_emit(product_id)

func get_warehouse(product_id: StringName) -> int:
	return int(state.warehouse_stock.get(product_id, 0))

func get_ordered(product_id: StringName) -> int:
	return int(state.ordered_stock.get(product_id, 0))

func quote_order(product: ProductDefinition, quantity: int, delivery_type: StringName) -> Dictionary:
	if product == null or quantity <= 0:
		return {"ok": false, "reason": &"invalid_order", "cost": 0.0}
	var fee := FEE_EXPRESS if delivery_type == &"express" else FEE_STANDARD
	var cost := product.purchase_price * float(quantity) + fee
	if economy == null or not economy.can_afford(cost):
		return {"ok": false, "reason": &"insufficient_cash", "cost": cost}
	return {"ok": true, "reason": &"ok", "cost": cost}

func place_order(product: ProductDefinition, quantity: int, delivery_type: StringName) -> Dictionary:
	var quoted := quote_order(product, quantity, delivery_type)
	if not bool(quoted.get("ok", false)):
		return quoted
	var spend: Dictionary = economy.spend(float(quoted["cost"]), &"order")
	if not bool(spend.get("ok", false)):
		return spend
	if delivery_type == &"express":
		add_to_warehouse(product.id, quantity)
	else:
		state.ordered_stock[product.id] = get_ordered(product.id) + quantity
		state.pending_deliveries.append({
			"id": ids.next(&"delivery"),
			"product_id": product.id,
			"quantity": quantity,
			"delivery_type": &"standard",
		})
		_emit(product.id)
	GameLog.info("INVENTORY", "Order %s x%d %s cost=%.2f" % [String(product.id), quantity, String(delivery_type), float(quoted["cost"])])
	return quoted

func deliver_pending() -> void:
	var pending: Array[Dictionary] = state.pending_deliveries.duplicate()
	state.pending_deliveries.clear()
	for row in pending:
		var product_id: StringName = row.get("product_id", &"")
		var qty := int(row.get("quantity", 0))
		state.ordered_stock[product_id] = maxi(0, get_ordered(product_id) - qty)
		add_to_warehouse(product_id, qty)
		GameLog.info("INVENTORY", "Delivered %s x%d" % [String(product_id), qty])

func take_from_warehouse(product_id: StringName, amount: int) -> int:
	var have := get_warehouse(product_id)
	var take := mini(maxi(amount, 0), have)
	if take <= 0:
		return 0
	state.warehouse_stock[product_id] = have - take
	_emit(product_id)
	return take

func add_to_warehouse(product_id: StringName, amount: int) -> void:
	if amount <= 0:
		return
	state.warehouse_stock[product_id] = get_warehouse(product_id) + amount
	_emit(product_id)

func _emit(product_id: StringName) -> void:
	stock_changed.emit(product_id, get_warehouse(product_id), get_ordered(product_id))
```

- [ ] **Step 4: Run tests — Inventory four PASS, rest of suite still green**

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

Expected: `Inventory` all PASS. Bot still passes because this task does not change restock yet.

- [ ] **Step 5: Commit** — skip unless the user asks.

---

### Task 2: Shelves start empty; restock no longer magically fills

**Files:**

- Modify: `scripts/store/store_manager.gd` (`_apply_product_to_placement`, `restock_fixture`, add `add_shelf_stock`)
- Modify: `scripts/store/build_manager.gd` (duplicate: pass `0` as stock, keep facings)
- Modify: `tests/test_shelf_stock.gd`

**Interfaces:**

- Consumes: none from Task 1 yet (`restock_fixture` returns 0 until StaffManager exists)
- Produces: `StoreManager.add_shelf_stock(placement_id, amount) -> int` (clamped to remaining capacity); assign `starting_stock < 0` → 0; `restock_fixture` does **not** write shelf stock

- [ ] **Step 1: Change shelf tests that assumed magic restock**

Replace `_restock_fixture` with warehouse-free behavior: restock does not fill. Add `add_shelf_stock` coverage:

```gdscript
	failures += _assert_eq("assign default stock is zero", _assign_default_empty(), true)
	failures += _assert_eq("restock_fixture does not spawn stock", _restock_fixture(), true)
	failures += _assert_eq("add_shelf_stock fills toward capacity", _add_shelf_stock(), true)
```

```gdscript
static func _assign_default_empty() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var placement := store.assign_product_to_first_shelf(&"freshpop_cola_500", -1)
	var passed := placement != null and placement.shelf_stock == 0 and placement.capacity > 0
	store.free()
	return passed

static func _restock_fixture() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var instance_id: StringName = store.runtime.keys()[0]
	var placement := store.assign_product_to_shelf(instance_id, 1, &"freshpop_cola_500", 1)
	store.restock_fixture(instance_id)
	var passed := placement != null and placement.shelf_stock == 1
	store.free()
	return passed

static func _add_shelf_stock() -> bool:
	var store := StoreManager.new()
	store.setup_for_tests()
	var placement := store.assign_product_to_first_shelf(&"freshpop_cola_500", 0)
	var added := store.add_shelf_stock(placement.placement_id, 6)
	var passed := added == 6 and placement.shelf_stock == 6
	store.free()
	return passed
```

In `_stock_clamped_to_capacity`, remove `store.restock_fixture(instance_id, 999)` (assign with 999 already clamps). Keep the assign assertion.

- [ ] **Step 2: Run tests — expect FAIL** on default-empty / restock-does-not-spawn / add_shelf_stock.

- [ ] **Step 3: Implement**

In `_apply_product_to_placement`:

```gdscript
	if starting_stock < 0:
		placement.shelf_stock = 0
	else:
		placement.shelf_stock = clampi(starting_stock, 0, placement.capacity)
```

Replace `restock_fixture` body so it never assigns capacity. If `staff_manager != null` and `staff_manager.has_method("request_restock_fixture")`, return `staff_manager.request_restock_fixture(instance_id)`. Otherwise return 0. Add `var staff_manager: StaffManager` (leave null until Task 4).

Add:

```gdscript
func add_shelf_stock(placement_id: StringName, amount: int) -> int:
	var placement := _find_placement(placement_id)
	if placement == null or amount <= 0:
		return 0
	var room := maxi(0, placement.capacity - placement.shelf_stock)
	var add := mini(amount, room)
	if add <= 0:
		return 0
	var old_value := placement.shelf_stock
	placement.shelf_stock += add
	stock_changed.emit(placement.product_id, placement.placement_id, old_value, placement.shelf_stock)
	_refresh_fixture_visual(_fixture_id_for_placement(placement))
	return add
```

Reuse existing private lookup if a `_find_placement` already exists; otherwise scan `runtime` shelves.

Duplicate in `build_manager.gd`: pass `0` instead of `int(row.get("stock", 0))`.

- [ ] **Step 4: Run tests**

Shelf tests PASS. Playtest bot **will FAIL** (`Stock X = 0, pojemność …`) until Task 7. That is expected after this task. Do not “fix” it by restoring magic restock.

If you need a green suite before Task 7 is done, keep going — do not skip the bot rewrite.

- [ ] **Step 5: Commit** — skip unless asked.

---

### Task 3: 3D backroom

**Files:**

- Modify: `scripts/store/store_room.gd`
- Modify: `scenes/store/Store.tscn` (add Marker3D `BackroomPick`, optional `Backroom` node; floor can stay code-built)
- Modify: `scripts/camera/camera_rig.gd` (`store_half_extents` z min must reach ~-10)
- Modify: `tests/run_tests.gd` nav section

**Interfaces:**

- Produces: `StoreRoom.get_backroom_pick_position() -> Vector3`, `StoreRoom.is_sales_floor(world_xz) -> bool` (current `contains_point`), `StoreRoom.refresh_warehouse_visuals(counts: Dictionary) -> void`

Layout (sales floor unchanged, origin center):

- Sales: 10×12, z ∈ [-6, 6]
- Punch a 2 m door in `WallNorth` at x ∈ [-1, 1] (split wall like the south wall)
- Backroom floor: 6×4×0.1 at `(0, -0.05, -8)`, color `Color(0.62, 0.58, 0.52)`
- Backroom walls: west/east/north of that box, collision layer 4
- `BackroomPick` at `(0, 0, -7.2)`
- Five crate `MeshInstance3D` boxes along x = -2,-1,0,1,2 at z = -8.6, one per later SKU tint; `refresh_warehouse_visuals` updates a Label3D or scale.y from count
- `blocks_doorway`: also reject fixtures overlapping north door AABB `(-1.2, 1.2)` × `(-6.6, -5.4)`
- Camera: `store_half_extents = Vector2(5.0, 10.0)` is wrong on x; keep x=5, change clamp to independent min/max **or** `Vector2(5, 6)` plus extra north: implement `_clamp_to_store` as `z ∈ [-10.5, 6.0]`, `x ∈ [-5, 5]`

- [ ] **Step 1: Extend nav test** in `_test_store_navigation` after gondola path:

```gdscript
	var pick := store.get_backroom_pick_position()
	var worker_path := await _wait_nav_path(nav_map, pick, Vector3(0.0, 0.0, 0.0))
	if worker_path.size() < 2:
		print("  FAIL  path from backroom to gondola")
		store.queue_free()
		return 1
	print("  PASS  path from backroom to gondola (%d points)" % worker_path.size())
```

- [ ] **Step 2: Run — expect FAIL** (`get_backroom_pick_position` missing or path < 2 because north wall is solid)

- [ ] **Step 3: Implement room + door + marker + clamp**

Keep `_build_room` as the single builder. Split `WallNorth` into west / door gap / east. Add backroom floor as `StaticBody3D` collision layer 1 so the same `PARSED_GEOMETRY_STATIC_COLLIDERS` bake includes it.

- [ ] **Step 4: Run nav tests PASS** (entrance→checkout still ≥2 points)

- [ ] **Step 5: Commit** — skip unless asked.

---

### Task 4: Worker + StaffManager

**Files:**

- Create: `scripts/staff/replenishment_task.gd`
- Create: `scripts/staff/staff_manager.gd`
- Create: `scripts/staff/worker_controller.gd`
- Create: `scenes/staff/Worker.tscn` (copy `scenes/customers/Customer.tscn`, blue `Color(0.18, 0.42, 0.78)`, script `worker_controller.gd`, collision_layer keep 8 or use 8)
- Modify: `scenes/main/Main.tscn` — nodes `InventoryManager`, `StaffManager`, `Workers` (Node3D)
- Modify: `scripts/main.gd` — setup inventory seed 12 per catalog product, staff spawn, connect `stock_changed` → backroom visuals
- Modify: `scripts/store/store_manager.gd` — `staff_manager` assigned in main
- Modify: `scripts/store/build_manager.gd` — ACTION_RESTOCK uses staff; hint `Magazyn pusty.`
- Modify: `scripts/core/game_manager.gd` — `set_auto_enabled` / `set_active` around states
- Modify: `scripts/debug/debug_overlay.gd`
- Add unit-level task tests in `tests/test_inventory.gd` **or** new `tests/test_staff.gd` that do not need nav: `request_restock_fixture` with warehouse 12 and empty shelf creates a task whose `execute_instant()` (test helper on StaffManager) moves 6 units.

**Interfaces:**

- Consumes: `InventoryManager.take_from_warehouse`, `StoreManager.add_shelf_stock`, `StoreRoom.get_backroom_pick_position`, `StoreManager.get_fixture_node`
- Produces: `StaffManager.request_restock_fixture(instance_id) -> int`, `StaffManager.set_auto_fill_empties(enabled: bool)`, `StaffManager.set_worker_active(active: bool)`, `StaffManager.get_worker_state() -> StringName`, `WorkerController` states `&"idle"`, `&"to_pick"`, `&"to_shelf"`

ReplenishmentTask fields: `task_id`, `instance_id`, `shelf_index`, `product_id`, `priority` (PPM=1, auto=0).

Worker loop (mirror `CustomerController` move code, speed 2.5):

1. Idle in backroom. If queue non-empty, pop highest priority.
2. `to_pick`: path to `get_backroom_pick_position`. On arrive: `carry = inventory.take_from_warehouse(sku, mini(6, capacity - shelf_stock))`. If carry=0, drop task, idle.
3. `to_shelf`: path to fixture node (reuse customer side-offset candidates if you want; origin of fixture is enough). On arrive: `store_manager.add_shelf_stock(placement_id, carry)`; leftover carry (fixture gone) → `add_to_warehouse`. If shelf still below capacity and warehouse remains, **requeue same shelf** (PPM fill-to-capacity). Auto tasks stop after the trip that made stock > 0 **or** fill toward capacity while auto — spec says auto when stock==0, fill toward capacity. Implement auto as fill-to-capacity too, but only *enqueue* when stock==0 (dedupe key `instance_id:shelf_index`).
4. `set_worker_active(false)` on RESULTS: if carrying, `add_to_warehouse(carry)` then idle.

GameManager:

- `open_store`: `staff.set_auto_fill_empties(true)`, `set_worker_active(true)`
- `_set_state(RESULTS)`: `set_auto_fill_empties(false)`, `set_worker_active(false)`
- `return_to_build`: `inventory.deliver_pending()`, `set_worker_active(true)`, auto false

Main `_ready` after registering products:

```gdscript
	inventory.setup(economy)
	for product in [COLA, WATER, JUICE, CEREAL, CHIPS]:
		inventory.seed_warehouse(product.id, 12)
	store_manager.staff_manager = staff_manager
	staff_manager.setup(store, store_manager, inventory, $Workers)
	staff_manager.spawn_worker(preload("res://scenes/staff/Worker.tscn"))
	inventory.stock_changed.connect(func(pid, w, _o): store.refresh_warehouse_visuals(inventory.state.warehouse_stock))
	store.refresh_warehouse_visuals(inventory.state.warehouse_stock)
```

CHANGE log line to `Prototype 0.03 inventory ready`.

PPM restock in `_on_context_action ACTION_RESTOCK`:

```gdscript
		BuildContextMenu.ACTION_RESTOCK:
			if _menu_target_id != &"":
				var queued := store_manager.restock_fixture(_menu_target_id)
				if queued <= 0:
					hint_requested.emit("Magazyn pusty.")
```

- [ ] **Step 1: Write `TestStaff` instant transfer** (no scene): seed warehouse 12, assign stock 0, `request_restock_fixture`, `staff.execute_next_instant()` takes 6 from warehouse and `add_shelf_stock` 6. `execute_next_instant` is allowed as a test/API helper on StaffManager; the bot in Task 7 must **not** call it.

- [ ] **Step 2: Run — FAIL** missing classes

- [ ] **Step 3: Implement worker scene + managers + Main wiring + GameManager hooks**

Keep `Worker.tscn` NavigationAgent3D settings identical to Customer (`path_desired_distance` 0.45, `target_desired_distance` 0.7, avoidance off).

- [ ] **Step 4: Run unit tests PASS.** Headless bot still fails until Task 7. Optionally F5-play the scene: worker should spawn in the backroom.

- [ ] **Step 5: Commit** — skip unless asked.

---

### Task 5: Order UI

**Files:**

- Create: `scripts/ui/order_panel.gd`
- Modify: `scenes/ui/Hud.tscn` — `StockLabel` under TopBar (or second row), `OrderButton` in BottomBar, `OrderPanel` PanelContainer
- Modify: `scripts/ui/hud.gd`
- Modify: `scripts/ui/context_menu.gd` — `ACTION_ORDER := 15`, floor action `Zamów towar…`
- Modify: `scripts/store/build_manager.gd` — ACTION_ORDER opens hud order panel
- Modify: `scripts/main.gd` — connect confirm → `inventory.place_order`; refresh labels on `cash_changed` and `stock_changed`

**Interfaces:**

- Produces: `Hud.set_warehouse_line(text)`, `Hud.set_in_transit_line(text)`, `Hud.open_order_panel(catalog, quote_cb)`, signal `order_confirmed(product_id, qty, delivery_type)`

Order panel:

- SKU buttons from `store_manager.list_catalog()`
- Qty 6 / 12 / 24
- Standard / Express
- Live cost via `inventory.quote_order`
- Confirm disabled when quote not ok; hint uses `Za mało kasy (%.0f).`
- Polish labels: `Standard (+20)`, `Express (+45)`

HUD BUILD hint: `LPM mebel · PPM SKU/facings/zamów · F3 bot`

Stock line example: `Magazyn: Cola 12 · Woda 12 · Sok 12 · Płatki 12 · Chipsy 12`

In-transit hidden when all ordered are 0.

- [ ] **Step 1: Extend `_test_context_menu`** to open floor menu and assert a button whose text contains `Zamów`

- [ ] **Step 2: Run — FAIL** missing action

- [ ] **Step 3: Implement panel + wiring.** `quote_order` / `place_order` already exist.

- [ ] **Step 4: Context menu test PASS**

- [ ] **Step 5: Commit** — skip unless asked.

---

### Task 6: Continue delivers Standard

**Files:**

- Modify: `scripts/core/game_manager.gd` (`return_to_build` calls `inventory.deliver_pending()`)
- Modify: `tests/test_inventory.gd` — already unit-tested; add a GameManager hook test if inventory is injected:

```gdscript
static func _continue_delivers_standard() -> bool:
	var economy := EconomyManager.new()
	economy.setup(10000.0)
	var inv := InventoryManager.new()
	inv.setup(economy)
	inv.place_order(COLA, 6, &"standard")
	var game := GameManager.new()
	game.inventory = inv
	game.return_to_build()
	var ok := inv.get_warehouse(&"freshpop_cola_500") == 6 and inv.get_ordered(&"freshpop_cola_500") == 0
	game.free()
	inv.free()
	economy.free()
	return ok
```

`return_to_build` currently touches `customer_manager` — null-guard `customer_manager` and `build_manager` so the unit test can call it, **or** extract `func deliver_arrivals() -> void` and call that from both `return_to_build` and the test. Prefer `deliver_arrivals()` on GameManager:

```gdscript
func deliver_arrivals() -> void:
	if inventory != null:
		inventory.deliver_pending()

func return_to_build() -> void:
	deliver_arrivals()
	...
```

- [ ] **Step 1: Add `_continue_delivers_standard` test**
- [ ] **Step 2: FAIL** (`inventory` missing on GameManager)
- [ ] **Step 3: Wire `game_manager.inventory` in `main.gd` `game_manager.setup(...)` — extend setup signature rather than assigning fields ad hoc. Keep old args and add inventory + staff at the end.**
- [ ] **Step 4: PASS**
- [ ] **Step 5: Commit** — skip unless asked.

---

### Task 7: Playtest bot covers 0.03

**Files:**

- Modify: `scripts/debug/playtest_bot.gd`
- Modify: `tests/run_tests.gd` bot assertions (cash after fixtures still 950; after wave = that + 23; after Standard 6 cola warehouse +6 — expose in bot report)

**Interfaces:**

- Consumes: `build_manager` restock enqueue, worker walks in API mode (real nav, same as customers)
- Produces: report keys `warehouse_cola`, `ordered_cola` optional

Bot `_execute` changes:

1. After `_step_fill_catalog`: assign may leave stock 0. **Remove** the check `placed.shelf_stock != placed.capacity`. Require only `placed != null`.
2. Replace `_step_restock` magic fill with `_step_wait_worker_stock(catalog, token)`: for each assigned fixture call `store_manager.restock_fixture(id)`; wait up to 45s until every catalog SKU has `get_total_shelf_stock(id) > 0`. Log worker state on timeout.
3. `_step_restock` capacity test: take one unit, enqueue restock, wait until stock == previous (worker brings 6 but shelf may already be 6 from first trip with warehouse 12 / cap ~21 → after take, wait until stock > after-take). Simpler: **drop the old take-then-refill-to-capacity assertion.** After wait-for-stock, take 1, restock, wait until `shelf_stock >= after_take + 1` (worker brought something). Do not require full capacity (warehouse 12 < cap 21).
4. `_step_facings`: remove `store_manager.restock_fixture` as a stock cheat. Facings-only assertion.
5. After successful wave / back to BUILD: `inventory.place_order(COLA, 6, &"standard")`; `game_manager.return_to_build()` already delivers — **order BEFORE continue** while still RESULTS? Continue already called in `_step_back_to_build`. Order Standard in RESULTS or BUILD after continue, then if ordered in BUILD it arrives next Continue — spec bot: “Standard 6 cola → Continue → warehouse +6”. Sequence: after wave in RESULTS, place Standard 6, then Continue (`return_to_build` delivers). Then assert `inventory.get_warehouse(cola) == before + 6`.
6. Happy path: **no Express**. Cash after fixtures 9050; after wave 9073; Standard costs `1.2*6+20=27.2` so cash 9045.80 then deliver does not change cash. Update bot cash checks: after wave still `cash_before + revenue`; after order, cash dropped by 27.2. Do not require exact 8673 duplicate math unless duplicate still runs — duplicate still costs gondola 400.

Extend `PlaytestBot.setup` with `inventory` and `staff_manager`.

Timeout: keep `CUSTOMER_TIMEOUT_SEC := 90`; add `WORKER_TIMEOUT_SEC := 45`.

- [ ] **Step 1: Rewrite bot steps as above (will fail until worker paths work in the test Main scene)**
- [ ] **Step 2: Run full suite with `all` permissions**
- [ ] **Step 3: Fix nav/timeout/door until bot PASS.** Common failures: north wall not open, pick marker inside collider, worker spawned before nav bake (`await` physics + `map_force_update` like nav tests), Open Store clicked before stock > 0.
- [ ] **Step 4: Full suite `All tests passed.`**
- [ ] **Step 5: Commit** — skip unless asked.

---

### Task 8: Decisions + HUD copy

**Files:**

- Modify: `docs/decisions.md` — append 0.03 decision (orders charged, start warehouse 12, worker unpaid, magic restock removed). Leave 0.02 “fixture cost still not charged” history as-is; later 0.02 fixture-charge decision already exists.
- Modify: `scripts/ui/hud.gd` BUILD hint if not done in Task 5.

- [ ] **Step 1: Write the decision paragraph** (Accepted, alternatives: magic restock / skip worker)
- [ ] **Step 2: No extra test**
- [ ] **Step 3: Re-run full headless suite once**
- [ ] **Step 4: Confirm log `Prototype 0.03 inventory ready`**
- [ ] **Step 5: Commit** — skip unless asked.

---

## Self-review

| Spec item | Task |
| --- | --- |
| Express immediate warehouse + fee 45 | 1 |
| Standard after Continue + fee 20 | 1, 6 |
| Start 12 / SKU | 4 (main seed) |
| Assign stock 0 | 2 |
| Restock is worker trip, carry 6 | 4, 7 |
| PPM restock + auto when shelf=0 in SIM | 4 |
| 6×4 backroom north + crates | 3 |
| Order UI + PPM Zamów | 5 |
| Bot 10/10 no Express on happy path | 7 |
| Duplicate stock 0 | 2 |
| No wages / truck / crates-as-items | global out of scope |

No TBD/TODO placeholders in tasks. Signatures: `place_order(product, qty, delivery_type)`, `deliver_pending()`, `request_restock_fixture(instance_id)`, `add_shelf_stock(placement_id, amount)`.
