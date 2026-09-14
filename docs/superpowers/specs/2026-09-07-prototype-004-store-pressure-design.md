# Prototype 0.04 — Store pressure (queue, archetypes, stars)

Date: 2026-09-07
Status: Draft pending user review
Godot: 4.7.2, GDScript, project root `/Volumes/TimeData/Cursor/ShoppyFender`

## Goal

One checkout queue you can see, two customer types, and a 0–3 star RESULTS score. Inventory / worker / orders from 0.03 stay. No second checkout, no cashier hire, no mission meta, no 0.05 polish.

## Loop (unchanged except SIMULATION and RESULTS)

```text
BUILD: layout, assign, order, worker restock
SIMULATION: 10 customers, 5 Regular + 5 Impatient, checkout queue
RESULTS: served / lost / sat / cash / 0–3 stars
Continue: Standard deliveries, back to BUILD
```

## Architecture

Keep ownership in `CustomerManager`. Add a `CheckoutQueue` (`RefCounted` or small Node under CustomerManager) — not a new ResultsManager.

| Owner | Owns |
| --- | --- |
| `CheckoutQueue` | FIFO of customer ids, slot index, pay timer |
| `CustomerController` | states `queued` / `paying`; archetype; queue wait |
| `WaveRuntimeState` | existing metrics + `star_count` helper |
| `Hud` | queue length in SIMULATION; star lines in RESULTS |
| `StoreRoom` | 4 queue `Marker3D`s (or code-built like walls) |

Do not type-hint `StaffManager` from new customer scripts (avoid GDScript class cycles). BuildManager already talks to staff only through `StoreManager`.

Signals: reuse `customer_exited`, `sale_completed`. Queue does not need a global signal for 0.04.

## Queue

Four slots in front of checkout, toward store center, step **0.9 m** along −X from `CheckoutPay` `(3.5, 0, 2.8)`:

| Slot | Position |
| --- | --- |
| 0 (paying) | `(3.5, 0, 2.8)` |
| 1 | `(2.6, 0, 2.8)` |
| 2 | `(1.7, 0, 2.8)` |
| 3 | `(0.8, 0, 2.8)` |

If more than 4 wait, extras stand at slot 3 until a gap opens.

Flow:

1. After pickup, customer paths to the assigned slot (index = current queue length).
2. Only index 0 may pay. Pay duration **1.8 s**, then leave to exit.
3. On leave/abandon, compact: each remaining customer’s index -= 1 and they walk to the new slot.
4. Slot 0 does **not** tick queue frustration. Slots ≥ 1 tick every **3.0 s**: Regular **+10**, Impatient **+15**.
5. Spawn interval stays **1.25 s** so a short line forms.

Abandon (frustration ≥ leave threshold while queued): walk to exit, no pay, `record_customer_exit(false, satisfaction, selling_price)` — same lost-sale path as OOS.

Fixtures still must not block the south doors. Queue slots are not placeable furniture.

## Archetypes

Spawn index even → Regular, odd → Impatient (5/5 in a wave of 10).

| | Regular | Impatient |
| --- | --- | --- |
| `leave_threshold` | 100 | 60 |
| Queue tick (slot ≥ 1) | +10 / 3 s | +15 / 3 s |
| Speed | 2.5 (current) | 2.5 (same; pressure is patience, not sprint) |
| Basket | 1 SKU (current lists) | 1 SKU |

OOS / no_path penalties stay +20 / +25. Impatient can therefore leave after OOS+queue; Regular almost never from queue alone in a 10-customer wave.

Capsule tint: Regular keep current blue-grey; Impatient a warmer color (e.g. `Color(0.78, 0.38, 0.22)`).

## Stars

Computed when the wave completes. Three independent checks; star count is how many passed:

1. `last_served >= 8`
2. `get_average_satisfaction() >= 80`
3. `lost_sales_count == 0`

Show each line on RESULTS with filled/empty star. Level is always “complete” enough to Continue (no lock). Replay is already Continue → BUILD.

## UI

- SIMULATION hint or stock row: `Kolejka: n`
- RESULTS after existing served/lost/sat/cash:

```text
★ Served ≥ 8
★ Sat ≥ 80%
★ Lost sales = 0
Stars: 2/3
```

Use `★` when passed, `☆` when failed.

Debug overlay (F2): archetype of first customer + queue length + paying id.

## Bot and tests

Headless: `godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd` with Shell permissions `all`.

Unit:

- FIFO: join A,B,C → pay order A then B then C
- Compact: A paying, B slot 1; A leaves → B becomes slot 0
- Stars: served 10, sat 100, lost 0 → 3; served 10, sat 100, lost 1 → 2; served 7, sat 100, lost 0 → 2
- Impatient leave_threshold 60 vs Regular 100

Bot (F3 / `drive_mode = 2`): same 0.03 happy path (3 fixtures, worker stock, no Express). Assert wave **10/10**, lost **0**, sat **100**, **stars == 3**. If Impatient walk-outs make 3★ impossible without cheating the queue, drop the bot star assert to 2 and record a decision — do **not** make pay time 0 or skip the queue in the bot.

Do not call `execute_next_instant` for restock.

## Out of scope

Second checkout, cashier NPC, mission objectives, multiple waves per Open Store, Bargain/Family/Premium archetypes, 0.05 visuals.

## Decisions to record after implementation

- 0.04 uses a 4-slot checkout queue and 1.8 s service
- Wave mix 5 Regular / 5 Impatient
- Stars are three independent checks on a 10-customer wave (8 served / 80 sat / 0 lost)
