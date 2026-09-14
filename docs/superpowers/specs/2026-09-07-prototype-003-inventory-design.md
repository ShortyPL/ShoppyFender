# Prototype 0.03 — Inventory, orders, backroom, worker

Date: 2026-09-07
Status: Draft pending user review
Godot: 4.7.2, GDScript, project root `/Volumes/TimeData/Cursor/ShoppyFender`

## Goal

The player pays for stock, receives it in a 3D backroom, and a warehouse worker carries units onto shelves. Magic restock from 0.02 is gone. Lost sales / satisfaction from 0.02 stay.

## Loop

```text
BUILD: place fixtures → assign SKU (shelf stock 0)
     → order Standard/Express
     → PPM Restock and/or wait for worker
     → Open Store only if some shelf has stock
SIMULATION: customers buy from shelves; worker auto-fills shelves at 0
RESULTS: Continue
BUILD: pending Standard deliveries arrive in warehouse
```

## Architecture

New nodes under Main, same pattern as EconomyManager:

| Owner | Owns |
| --- | --- |
| `InventoryManager` | `warehouse_stock`, `ordered_stock`, pending Standard deliveries |
| `StaffManager` | one worker, replenishment task queue |
| `StoreRoom` | sales floor 10×12 plus backroom 6×4 attached north |
| `StoreManager` | layout, shelf stock, facings (unchanged ownership) |
| `EconomyManager` | cash; `spend` for orders |
| `Hud` | warehouse line, order panel |

`StoreManager.restock_fixture` does not write shelf stock. If `StaffManager` is set, it enqueues fill-to-capacity tasks for occupied shelves on that fixture and returns the number of tasks. Without staff it returns 0.

Unit tests that need a full shelf call `InventoryManager.take_from_warehouse` then a store helper `add_shelf_stock` (test/API only). The playtest bot does **not** use that helper: it enqueues restock and waits for the worker.

Signals:

- `InventoryManager.stock_changed(product_id, warehouse, ordered)`
- `InventoryManager.delivery_arrived(delivery_id)`
- `StaffManager.task_started` / `task_finished`

## Store and navigation

- Sales floor stays 10×12 m. Fixtures may be placed only on the sales floor (`contains_point` unchanged).
- Backroom: 6×4 m, centered on the north wall (`z < -6`), darker floor, door in the middle of the north wall (~2 m wide).
- Five crate stacks in the backroom, one per catalog SKU, tinted with `preview_color`, label = warehouse count.
- Marker `BackroomPick` at the pick face of the stacks.
- Navigation: one bake covering sales floor + backroom + door. Customers never set a backroom target. Worker does (`BackroomPick` ↔ shelf). A clogged shop may let a customer shortcut through the backroom — accepted in 0.03 (no second nav region).
- Camera clamp extends north so the backroom is visible.
- Customer entrance→checkout path must still exist after backroom walls.

## Inventory numbers

Starting warehouse: **12 units of each of the 5 SKUs**. Starting ordered: 0.

Shelf after `assign_product_*`: **stock = 0**, facings default 3, capacity unchanged (`facings * units_deep`).

Order quantities: **6 / 12 / 24**.

```text
order_cost = product.purchase_price * quantity + delivery_fee
```

| Type | Fee | Arrival |
| --- | --- | --- |
| Standard | 20 | on RESULTS → BUILD (`GameManager.return_to_build`) |
| Express | 45 | immediately into `warehouse_stock` |

Purchase prices already on resources: cola 1.20, water 0.60, juice 0.90, cereal 1.80, chips 0.70.

Rules:

- Reject order if `not economy.can_afford(order_cost)` — HUD hint `Za mało kasy (X)`.
- On accept: `economy.spend(order_cost, &"order")`. Express: `warehouse_stock[sku] += qty`. Standard: `ordered_stock[sku] += qty` and append a pending delivery `{id, product_id, quantity, type: standard}`.
- Several Standard orders may wait. All of them arrive together on Continue.
- Express does not create a waiting delivery.
- No cancel, no supplier reliability, no case packs, no warehouse capacity cap.

## Worker

One `WorkerController` (`CharacterBody3D` + `NavigationAgent3D`), capsule mesh distinct color (blue), spawn at `BackroomPick`.

Carry size: **up to 6** units of the task SKU per trip.

States: `idle` → `to_pick` → `to_shelf` → `idle`.

Task sources:

1. **PPM „Uzupełnij do pojemności”** (BUILD and SIMULATION): priority queue. Fill that fixture’s occupied shelves toward capacity, SKU already on the shelf. If warehouse is 0 for those SKUs: hint `Magazyn pusty.` and no task.
2. **Auto in SIMULATION only:** if a shelf has an assigned product, `shelf_stock == 0`, and `warehouse_stock[sku] > 0`, enqueue a fill-to-capacity task (dedupe per shelf).

Idle in RESULTS (stop moving, keep current carry or return it to warehouse — **return unused carry to warehouse** when entering RESULTS so stock cannot vanish).

Transfer:

```text
take = min(6, warehouse_stock[sku], capacity - shelf_stock)
warehouse_stock -= take
walk to shelf
shelf_stock += take
```

If the shelf was cleared or the fixture deleted while walking, return `take` to warehouse.

Worker has no wage in 0.03. No hiring. No second worker.

Worker runs in BUILD (so the player can stock before Open Store) and SIMULATION.

## UI

BUILD HUD under cash:

- `Magazyn: Cola 12 · Woda 12 · Sok 12 · Płatki 12 · Chipsy 12`
- `W drodze: …` only when `ordered_stock` > 0

Button **Zamów** opens order panel: SKU list, qty 6/12/24, Standard/Express, live cost, confirm/cancel. PPM floor also has **Zamów towar…** (same panel).

PPM fixture **Uzupełnij do pojemności** stays, meaning enqueue worker task.

Hint when Open Store and shelves empty: keep existing `Półka jest pusta.` (`GameManager.can_open_store` unchanged).

Debug overlay (F1): worker state + current task + warehouse totals.

## Breaking change vs 0.02

`restock_fixture` must not set `shelf_stock = capacity` without decreasing warehouse. Duplicate fixture copies product id + facings, **stock 0** (must not clone shelf units). Assigning a product does not spawn free units.

Open Store still requires `get_total_any_shelf_stock() > 0`, so the worker (or a test helper that simulates a finished trip) must have stocked at least one unit.

## Tests

Headless, `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd`, permissions `all`.

New `tests/test_inventory.gd`:

- Express 12 cola: cash `10000 - 1.20*12 - 45`, warehouse cola 12+12
- Standard 6 cola: cash `10000 - 1.20*6 - 20`, ordered 6; after `deliver_pending()` warehouse +6, ordered 0
- Cannot order when cash < cost
- `take_from_warehouse` rejects when empty

Update shelf-stock tests: filling a shelf requires warehouse units; restock with warehouse 0 leaves stock unchanged.

Nav test: entrance→checkout still paths; worker pick marker → gondola at origin paths.

Bot F3 / `drive_mode = 2`:

1. Place 3 fixture types, pay 950
2. Assign 5 SKUs (shelves at 0)
3. Do not Express-order on the happy path. Enqueue restock on assigned fixtures; wait until each assigned SKU has shelf stock > 0 (one trip of 6 is enough; do not wait for full capacity)
4. Wave 10/10, lost sales 0, sat 100%, cash = after fixtures − 0 orders + wave revenue
5. Standard 6 cola, Continue, warehouse cola increased by 6

Do not assert duplicate-fixture cash in 0.03 unless duplicate still costs the fixture.

## Out of scope

Worker wage, hiring, cashier, delivery truck mesh, pickable crates, case packs, MOQ, supplier failure, warehouse area cap, 0.04 queues/archetypes, 0.05 polish.

## Decisions to record after implementation

- 0.03 charges product orders (purchase_price + delivery fee)
- 0.03 adds a 6×4 backroom and one unpaid warehouse worker
- Shelf restock is a physical worker trip from warehouse stock
