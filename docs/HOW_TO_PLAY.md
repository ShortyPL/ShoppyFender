# How to play — ShopyFender

You manage a 3D retail store: design the layout, place shelves, assign products, order deliveries, and open the store for a wave of customers.

Start with **New Game** in the menu (or **Continue** if you have a save). Project overview: [README](../README.md).

## Goal

Earn money and keep customers happy. After each wave you get a **1–3 star** rating:

| Goal | Requirement (prototype) |
|---|---|
| Customers served | ≥ 8 (starting wave is 10 customers) |
| Satisfaction | ≥ 80% |
| Lost sales | 0 |

Wave size grows with the wave number (more customers in later rounds).

## Game loop

1. **BUILD** — place fixtures, assign products, order stock.
2. **Open** — **More → Open store** (or from the context menu).
3. **Wave** — customers enter, pick products, queue at checkout.
4. **RESULTS** — summary; **Next wave** / **Repeat wave** / return to build.

Starting cash: **10,000**.

## Camera

| Control | Action |
|---|---|
| **W A S D** | Move camera |
| **Q / E** | Rotate view |
| **Scroll** | Zoom |
| **Middle mouse + drag** | Pan |
| Settings → **Sensitivity** | Pan sensitivity |

## Build and shelves (BUILD mode)

| Control | Action |
|---|---|
| **RMB** on floor / shelf | Context menu |
| **LMB** | Place ghost (place mode) or select shelf |
| **R** | Rotate preview / ghost by 90° |
| **Esc** | Cancel place mode / close menu |

The **Build** button on the bottom bar also opens the fixture picker.

### Floor context menu (RMB)

- **Place fixture…** — choose fixture type (catalog cost)
- **Rotate preview 90°**
- **Remove all fixtures**
- **Order stock…** / **Open store**

### Shelf context menu (RMB)

- **Place product on shelf…** — assign SKU
- **More / Fewer facings** — display width
- **Restock to capacity** — refill from warehouse
- **Clear product**
- **Rotate / Duplicate / Remove shelf**
- **Open store**

Empty shelves or no warehouse stock = lost sales and a worse rating.

## Action bar (HUD)

| Button | Function |
|---|---|
| **Order** | Order stock into the warehouse |
| **Build** | Choose and place fixtures |
| **Staff** | Workers, auto-fill shelves, restock |
| **Upgrades** | Upgrades (e.g. faster checkout, second lane) |
| **More** | Open store, Menu, Continue (save / leave) |

The HUD also shows cash, day/time, rating, queue, wave goals, wave preview, and delivery status.

### Orders

1. Pick a product.
2. Quantity: **6 / 12 / 24**.
3. Delivery: **Standard** (after the wave) or **Express** (warehouse immediately, more expensive).
4. Confirm **Order** — cost is deducted from cash.

Then use **Restock to capacity** on a shelf, or staff **Auto-fill / Restock empties**.

## Customer wave

- Open the store only when shelves have stock.
- Customers shop from their lists; missing stock / bad pathing / long queues → lost sales.
- The cashier serves the queue; upgrades can speed checkout or add a second lane.

## Game speed

| Shortcut | Action |
|---|---|
| **1 / 2 / 3** | 1× / 2× / 4× |
| **[ ]** or **+ / −** | Cycle speed |
| **Space** | Pause / resume |

## Debug (optional)

| Shortcut | Action |
|---|---|
| **F1 / F2** | Debug overlay |
| **F3** | Playtest bot |

## Main menu

- **New Game** — new session (clears save)
- **Continue** — load last save
- **Settings** — fullscreen, volume, camera sensitivity
- **Help** — short version of this guide
- **Esc** — close Help / Settings

---

Design details: [Master spec](../ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) · [Game logic](../ShopyFender_package/SHOPYFENDER_GAME_LOGIC.md)
