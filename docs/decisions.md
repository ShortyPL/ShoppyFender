# Decisions

## Decision
Use Godot NavigationRegion3D baking plus NavigationAgent3D for Prototype 0.01 customers.

## Reason
Built into Godot 4.7, no extra plugins, and fixtures become obstacles after a synchronous rebake.

## Alternatives
Custom grid pathfinding; NavigationObstacle3D without rebake.

## Status
Accepted

---

## Decision
Prototype 0.01 does not deduct fixture purchase cost from cash.

## Reason
Starting cash is 100 and gondola cost is 400. Charging the fixture would block the required 100 -> 102.50 sale loop. Cost stays in FixtureDefinition for later prototypes.

## Alternatives
Raise starting cash to 10,000; lower fixture cost to 0.

## Status
Accepted

---

## Decision
Prototype 0.02 starts with a 5-SKU catalog. The single customer buys the first in-stock assigned product. Fixture cost is still not charged.

## Reason
Product assignment and readable shelf visuals are the first 0.02 slice. Extra fixture types, 10-customer waves, facings and charging gondolas come next so the cola 100 → 102.50 loop stays playable.

## Alternatives
Ship all of 0.02 at once.

## Status
Accepted

---

## Decision
Prototype 0.02 adds three fixture types (gondola, wall shelf, endcap). Purchase cost is still not deducted from cash.

## Reason
The player needs more than one furniture silhouette before the 10-customer wave. Charging 400 / 300 / 250 would still wipe the 100 starting cash and break the sale loop.

## Alternatives
Charge fixtures and raise starting cash; keep only gondola until later.

## Status
Accepted

---

## Decision
Prototype 0.02 opens a 10-customer wave. Lists cycle the 5-SKU catalog. RESULTS shows served / 10. Fixture cost is still not charged.

## Reason
The 0.01 loop of one cola sale is covered by the economy unit test. Open Store now has to show a small crowd with different shopping lists before facings and lost-sales metrics.

## Alternatives
Keep a single customer until 0.04 waves; spawn all 10 at once.

## Status
Accepted

---

## Decision
Prototype 0.02 shelf capacity is `facings * units_deep`. Default facings is 3 (clamped to what fits on the shelf). Restock fills to capacity. Fixture cost is still not charged.

## Reason
Hardcoded stock ×5 hid the facing/capacity loop. One SKU per shelf is enough: the player changes facings from the fixture menu, and a deeper gondola holds more than a wall shelf.

## Alternatives
Auto-fill the whole shelf width as facings; wait until 0.04 for facing edits.

## Status
Accepted

---

## Decision
Prototype 0.02 records lost sales and average satisfaction. Out of stock is +20 frustration (satisfaction 80). RESULTS shows served, lost sales count/value, and satisfaction. Fixture cost is still not charged.

## Reason
A silent walk-out hid why a wave scored below 10/10. The player needs the empty-shelf loop before paying for fixtures.

## Alternatives
Only count failed customers; wait until 0.03 for lost-sales value.

## Status
Accepted

---

## Decision
Prototype 0.02 charges fixture purchase cost. Starting cash is 10,000. Deleting a fixture refunds its cost.

## Reason
Gondola 400 / wall shelf 300 / endcap 250 made the old 100 starting cash unplayable. Charging is the last 0.02 budget loop; refunds keep layout experiments cheap.

## Alternatives
Keep free furniture; charge only in 0.03.

## Status
Accepted

---

## Decision
Prototype 0.03 charges product orders (`purchase_price * qty + delivery fee`). Starting warehouse is 12 per SKU. One unpaid warehouse worker carries up to 6 units from the 6×4 backroom. Magic restock is gone.

## Reason
The player needs a real supply loop before wages or trucks. Warehouse stock, paid orders, and a physical worker trip make empty shelves and PPM restock meaningful without adding payroll or crate items.

## Alternatives
Keep magic restock; skip the worker.

## Status
Accepted

---

## Decision
Prototype 0.04 uses a 4-slot queue, 1.8 s pay, 5/5 Regular/Impatient, and independent stars 8 / 80 / 0 lost. The headless bot asserts `stars == 3` plus 10/10, lost 0, sat ≥ 75.

## Reason
Wait ticks only when `STATE_QUEUED` on slots ≥ 1 (Regular +10 / Impatient +15 every 3.0 s) raised average sat to ~83–85 with spawn 1.25 s vs pay 1.8 s — enough for 3★. Walking `MOVING_TO_CHECKOUT` no longer eats ticks. Impatient did not abandon. Do not zero `PAY_SEC` or skip the queue.

## Alternatives
Instant pay; one archetype.

## Status
Accepted

---

## Decision
Main menu is a 2D overlay on the user concept still (`assets/ui/main_menu_background.jpg`). Continue is visible and disabled until a save-game exists. Help stays instead of Credits. Copy is Polish.

## Reason
The concept look cannot be matched by the current prototype store mesh. Overlaying Polish controls on the still covers the baked-in English UI without a 3D restage.

## Alternatives
Keep the rotating 3D store; dim the left 40% of the still; crop the still to the shop only.

## Status
Accepted

---

## Decision
In-game HUD is floating English concept chrome (native Controls). Cash, queue, and last-wave stars are live; day/XP/goals are dummy. Open Store lives under More.

## Reason
The concept cannot sit as a full-screen still over the 3D store. Prototype 0.05 has no XP or daily-goal systems.

## Alternatives
PNG overlay; implement XP/goals now; keep Polish teal bars.

## Status
Accepted

---

## Decision
Worker restock is one SKU crate hopped across random store shelves (DROP_CAP 3, last hole uncapped), then always returns to the backroom pick point to idle.

## Reason
Players expect one trip to feed several racks. Idling in the aisle blocked customers.

## Alternatives
Nearest-shelf routing; one shelf per trip; idle at last rack.

## Status
Accepted

---

## Decision
HUD action bar is live: Build opens the fixture picker (RESULTS returns to build, SIM toasts), Staff manages workers/auto-fill/restock, Upgrades sell extra worker ($250) and faster checkout ($200, pay_sec 1.2). Continue uses a thin `user://shoppy_run.cfg` snapshot. Playtest bot does not buy upgrades.

## Reason
Every HUD button needed a real loop. XP/goals/day/wages stay dummy. SIM still forces auto-fill on; preference restores in BUILD.

## Alternatives
Keep Staff/Upgrades disabled; full day/XP systems; bot buys upgrades.

## Status
Accepted

---

## Decision
Wave RESULTS panel has Continue (back to BUILD), Next wave (another 10 from current stock), and Repeat (restore cash/warehouse/shelf stock from that wave's opening snapshot, then replay immediately). Playtest still uses More → Back to build.

## Reason
The results card had no actions. Repeat needs a start-of-wave snapshot because SIM spends cash and shelf stock; Next wave does not roll back.

## Alternatives
OK-only close; Repeat as a full day/level reset.

## Status
Accepted

## Decision
Customers enqueue only after arriving at the checkout approach; walking shoppers do not reserve a lane slot.

## Reason
Enqueue-at-pick let a distant front block pay while others ticked frustration.

## Alternatives
Start pay for whoever is physically at slot 0 even if another id is FIFO front.

## Status
Accepted

---

## Decision
Upgrade `second_checkout` ($400) adds a second independent queue lane and cashier stand. Customers join the shorter lane. `faster_checkout` applies pay_sec to all lanes.

## Reason
Wave growth to 24 outpaced a single 1.8 s till; a visible second till matches retail fantasy.

## Alternatives
Hire cashier as pay multiplier only; hard-cap wave size.

## Status
Accepted

---

## Decision
SIM no longer forces auto-fill. Open Store uses `StaffManager.auto_fill_preference` (default false).

## Reason
Forced fill hid empty-shelf pressure during the wave.

## Alternatives
Hard-disable auto-fill in SIM; paid Floor Restock upgrade.

## Status
Accepted

---

## Decision
Shopping lists are 2-3 unique catalog SKUs (deterministic from spawn index). First OOS fails the customer (no partial basket).

## Reason
One-SKU baskets were too thin for a supermarket fantasy.

## Alternatives
Partial basket; random list length.

## Status
Accepted

---

## Decision
RunSave persists wave_number, clock, pending deliveries, ordered stock, stars_history, and start_cash. HUD Level/XP show Avg stars and Cash delta; Goals track live wave star criteria. RESULTS shows lost-sale breakdown (oos/queue/path).

## Reason
Dummy XP/goals lied; Continue needed real run continuity.

## Alternatives
Hide Level/XP; keep thin save.

## Status
Accepted
