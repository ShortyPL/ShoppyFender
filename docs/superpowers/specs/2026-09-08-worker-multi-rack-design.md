# Worker multi-rack restock + return home

Date: 2026-09-08
Status: Accepted
Godot: 4.7.2, GDScript, project root `/Volumes/TimeData/Cursor/ShoppyFender`

## Goal

One warehouse trip can put the same SKU on several fixtures. After the crate is empty (or there is no target), the worker always walks back to the backroom pick point and idles there so they do not block aisle customers.

Out of scope: extra workers, mixed SKUs in one crate, auto-fill changes, wages, new HUD.

## Locked choices

| Topic | Choice |
| --- | --- |
| Trigger | PPM **Uzupełnij** on one fixture |
| Destinations | Every shelf in the store with that SKU and free room |
| Order | Random among remaining eligible shelves |
| Per-stop cap | 3 units (or less if the shelf cannot take 3) |
| After the trip | Always path to `StoreRoom.get_backroom_pick_position()`, then idle |
| Auto-fill | Unchanged (empty shelves only, still one task at a time unless this trip logic also applies when those tasks run — see Worker loop) |

Auto-fill still enqueues per empty shelf. When the worker runs a task, the **same hop loop** applies: pick that task’s SKU, then randomly feed every matching shelf in the store, then go home. Do not add a second restock code path.

## Trigger

`request_restock_fixture(instance_id)` stays the player entry. It still scans that fixture’s shelves and enqueues work for each SKU on that fixture that has room and warehouse stock.

The queue item is still `ReplenishmentTask` with `product_id` (the SKU to fetch). `instance_id` / `shelf_index` are the seed shelf (used if it is still eligible). They do not pin the whole crate to one fixture.

Cola and water on the same clicked gondola remain **two warehouse trips** (two tasks).

## Pick

At the backroom:

```text
eligible_room = sum of (capacity - stock) for every shelf in the store
                whose assigned product_id == task.product_id and stock < capacity
want = min(CARRY_LIMIT 6, warehouse of that SKU, eligible_room)
```

If `want == 0`, skip the floor loop and still go home (then finish the task).

## Floor loop (while carry > 0)

1. Build the eligible list: same SKU, `stock < capacity`.
2. If empty: break (carry leftover goes home).
3. Pick uniformly at random. Prefer the seed shelf only if it is the sole eligible; otherwise all eligible are equal, including the seed.
4. Walk to that fixture’s existing approach point (`_first_reachable_approach`).
5. Deliver `min(carry, room, DROP_CAP)` where `DROP_CAP := 3`. If this is the **last** eligible shelf, deliver `min(carry, room)` (no cap), so leftover does not bounce home when only one hole remains.
6. Repeat.

SKU swap or fixture removal mid-hop: that shelf drops out of the next eligible list. If the list is empty, go home with leftover.

Do not return leftover at the last sales-floor stop. Carry leftover until home.

## Home

New worker state `to_home`:

- Target: `store.get_backroom_pick_position()`.
- On arrive: `inventory.add_to_warehouse(carry_product, carry)` if carry > 0; clear carry; `begin_idle`; `staff_manager.finish_trip(task)`.

Idle pose is always in the backroom, never in a sales-floor aisle.

`finish_trip` may re-queue the same SKU if any matching shelf still has room and warehouse stock > 0 (same idea as today, but store-wide, not only the seed shelf). The worker is already at the pick point, so the next dispatch is a new pick without crossing the floor first.

`deactivate()` (Open Store / interrupt) still dumps carry to warehouse immediately; no home walk required.

## Constants

- `StaffManager.CARRY_LIMIT := 6` (unchanged)
- `StaffManager.DROP_CAP := 3` (new)
- Random: `randi() % list.size()` (Godot RNG; tests inject a fake picker or seed)

## Tests

`tests/test_staff.gd` (instant path, no nav):

- Two fixtures, both cola, both empty, warehouse 6: one `execute_next_instant` (updated to run the hop loop) leaves stock on **both** fixtures, neither gets all 6 if both had room ≥ 3 (expect 3 and 3 when DROP_CAP is 3 and both remain eligible).
- One fixture cola room 2, second cola room 10, warehouse 6: first stop can take at most 2; remainder (capped at 3 on the second if another eligible existed… if only two and first took 2, last eligible takes remaining 4). Spell this as: last eligible shelf is uncapped.
- SKU swap after pick, no remaining cola shelf: all carry returns to warehouse, shelves unchanged.
- After instant hop loop the worker is not required to simulate `to_home` in unit tests; a separate test or scene assert: `WorkerController` after `finish_trip` from a real trip ends in `idle` at backroom. If too heavy for unit tests, assert the state machine: `_deliver` does not idle on the floor — it enters `to_home`.

Playtest bot: still enqueue restock and wait until worker `idle`; do not call `execute_next_instant` for restock. Bot may take longer because of extra hops + home walk. Do not skip nav.

## Non-goals

- Nearest-shelf heuristic
- Carrying two SKUs at once
- New player UI
- Changing cashier or customers
