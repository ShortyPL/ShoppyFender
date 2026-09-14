# ShopyFender — Master Game Design & Cursor Development Spec

> **Status:** Draft v0.1  
> **Project type:** Hobby / solo development  
> **Primary development environment:** Cursor Pro  
> **Game engine:** Godot 4.x  
> **Language:** GDScript  
> **Target platform:** PC first  
> **Working title:** ShopyFender

---

# 1. Purpose of this document

This file is the main source of truth for the ShopyFender project.

Cursor Agent should read this file before making architectural or gameplay decisions.

The project should be developed with the following priorities:

1. Keep costs close to zero.
2. Keep the project technically simple.
3. Prefer data-driven systems over hardcoded content.
4. Build a playable prototype before adding visual polish.
5. Make the game fun before making it realistic.
6. Use Cursor as the primary development environment.
7. Minimize manual work in external tools.
8. Keep the code modular enough to extend later.
9. Prefer procedural/simple/generated assets before paid assets.
10. Never over-engineer an early feature.

---

# 2. Game concept

ShopyFender is a 3D retail management and store optimization game.

The player is the manager of a retail store.

The player's job is to:

- design the store layout,
- place fixtures,
- define product assortment,
- place products on shelves,
- decide product facings,
- manage shelf capacity,
- order stock,
- plan deliveries,
- control costs,
- respond to customer demand,
- optimize customer flow,
- reduce out-of-stock situations,
- improve customer satisfaction,
- earn money,
- expand and improve the store.

The main inspiration is retail category management software, especially concepts similar to:

- macro space planning,
- floor planning,
- space planning,
- planograms,
- assortment planning,
- shelf capacity,
- facings,
- replenishment,
- store flow,
- sales per square meter.

The game must NOT become a realistic enterprise retail software simulator.

The real-world concepts should be simplified into clear and fun gameplay systems.

---

# 3. Core fantasy

The player should feel like:

> "I built this store, optimized it, and now I can watch customers successfully use the system I designed."

The fun should come from:

- planning,
- optimization,
- reacting to problems,
- watching customers interact with the store,
- improving performance,
- turning a bad store into an efficient store.

---

# 4. Main gameplay analogy

The game can feel partially like a tower-defense game.

Customers arrive in waves.

They are not enemies in the story, but mechanically they generate pressure on the player's store.

The player does not build towers.

The player's defensive tools are:

- store layout,
- fixtures,
- assortment,
- product placement,
- number of facings,
- available stock,
- deliveries,
- checkout capacity,
- future staff systems.

The main "health bar" is not a castle.

It is:

- Customer Satisfaction,
- Store Reputation,
- Cash,
- Lost Sales,
- Mission Objectives.

---

# 5. Core gameplay loop

The primary gameplay loop is:

```text
START WITH STORE
    ↓
REVIEW OBJECTIVES
    ↓
BUY FIXTURES
    ↓
PLACE FIXTURES
    ↓
ASSIGN PRODUCTS
    ↓
SET FACINGS
    ↓
ORDER STOCK
    ↓
OPEN STORE
    ↓
CUSTOMER WAVE
    ↓
CUSTOMERS SHOP
    ↓
CHECKOUT
    ↓
RESULTS
    ↓
EARN MONEY
    ↓
ANALYZE PROBLEMS
    ↓
IMPROVE STORE
    ↓
NEXT WAVE / NEXT LEVEL
```

---

# 6. Design principles

## 6.1 Easy to understand, hard to optimize

A new player should understand the basics within a few minutes.

Advanced optimization can become much deeper later.

---

## 6.2 Visual feedback over spreadsheets

Retail planning concepts should be visible in the 3D world.

Examples:

Bad:

```text
ShelfCapacityError = 0.78
```

Good:

- shelf is visibly empty,
- customers cannot find the product,
- warning icon appears,
- lost sales counter increases,
- customer becomes unhappy.

---

## 6.3 Every system should create trade-offs

Examples:

More facings:

- increases shelf capacity,
- reduces stockouts,
- uses more shelf space.

More assortment:

- attracts more customers,
- increases complexity,
- reduces space per SKU.

Large delivery:

- improves availability,
- costs more cash,
- requires storage capacity.

More fixtures:

- increases selling space,
- may reduce aisle width,
- may worsen navigation.

---

## 6.4 Fun before realism

Do not simulate:

- real tax systems,
- complex employment law,
- real supplier contracts,
- thousands of SKUs,
- enterprise-grade replenishment algorithms,

unless they directly improve gameplay.

---

# 7. Visual style

Recommended art direction:

## Stylized 3D / clean low-poly

Avoid photorealism.

Reasons:

- easier to create consistent assets,
- cheaper,
- easier for solo development,
- less demanding performance,
- easier to generate simple models,
- works well with procedural products,
- easier to mix free assets.

Visual direction:

- clean supermarket,
- readable product colors,
- clear aisle structure,
- simple characters,
- slightly exaggerated product scale if needed,
- readable icons,
- soft lighting,
- simple materials.

---

# 8. Camera

Recommended camera:

## 3D management camera

Features:

- perspective camera,
- default angle around 35–50 degrees,
- mouse-wheel zoom,
- pan with middle mouse / WASD,
- rotate around store,
- optional top-down mode later,
- focus on selected fixture,
- close-up mode for shelf editing.

The player should NOT control a walking character in the MVP.

---

# 9. Game modes

Initial development should focus on:

## Campaign / scenario mode

Each level introduces a new concept.

Later possible modes:

- Sandbox,
- Endless,
- Challenge Mode,
- Daily Challenge,
- Scenario Editor.

Do not build these before the main loop works.

---

# 10. Level structure

Every normal level should start from a store room.

A level defines:

- store dimensions,
- entrance,
- exit,
- checkout area,
- starting budget,
- available fixtures,
- available products,
- suppliers,
- customer types,
- customer volume,
- objectives,
- restrictions,
- wave configuration,
- unlocks.

---

# 11. First level concept

Example:

## Level 1 — First Store

Store size:

```text
10 m x 12 m
```

Starting budget:

```text
10,000 credits
```

Starting environment:

- empty sales floor,
- one entrance,
- one exit,
- one checkout,
- optional small backroom.

Available fixtures:

- wall shelf,
- single gondola,
- double-sided gondola,
- basic fridge.

Available products:

Approximately 8–15 simple fictional products.

Example categories:

- Water,
- Soft Drinks,
- Juice,
- Snacks,
- Cereal.

Objectives:

- Serve 30 customers.
- Reach at least 80% satisfaction.
- Keep lost sales below a defined threshold.
- Finish with positive cash.

---

# 12. Build Mode

The player can buy and place fixtures.

Basic controls:

```text
Left Mouse  = select / place
Right Mouse = cancel
R           = rotate
Delete      = remove
Mouse Wheel = zoom
WASD        = move camera
```

Fixtures use a placement grid.

Recommended initial grid:

```text
0.25 m or 0.5 m
```

Placement preview:

- valid placement,
- invalid placement,
- collision feedback.

The game should prevent fixtures from:

- overlapping,
- blocking entrance,
- blocking exit,
- creating impossible navigation.

Do not make aisle regulations overly realistic in the MVP.

---

# 13. Fixture system

Fixtures should be data-driven.

Example fixture types:

- wall shelf,
- gondola,
- endcap,
- refrigerator,
- freezer,
- promotional bin,
- checkout,
- pallet display.

MVP needs only:

- wall shelf,
- gondola,
- checkout.

Each fixture may contain one or more shelf segments.

Example:

```text
Gondola
├── side A
│   ├── shelf 1
│   ├── shelf 2
│   ├── shelf 3
│   └── shelf 4
└── side B
    ├── shelf 1
    ├── shelf 2
    ├── shelf 3
    └── shelf 4
```

---

# 14. Space Planning Mode

Selecting a fixture should allow the player to enter a shelf-editing mode.

The player can assign products to shelf positions.

The system should support:

- product selection,
- shelf selection,
- placement position,
- product width,
- product height,
- product depth,
- number of facings,
- shelf capacity,
- shelf stock.

Do NOT recreate professional space-planning software UI.

Create a simplified gameplay-friendly version.

---

# 15. Product facings

Facings are a key feature.

Definition:

> A facing is the number of units of the same product visible next to one another on a shelf.

Example:

```text
COLA | COLA | COLA | WATER | JUICE
```

Cola has:

```text
3 facings
```

Facings influence:

- visible width,
- shelf capacity,
- availability,
- visual prominence,
- probability of stockout.

Example:

```text
1 facing
Capacity: 6 units

3 facings
Capacity: 18 units
```

The exact formulas can be simplified.

---

# 16. Product system

Products must be data-driven.

Recommended product properties:

```text
id
display_name
brand
category
package_type

width
height
depth

purchase_price
selling_price
margin

base_demand
popularity

units_per_case
shelf_capacity_multiplier

starting_stock
warehouse_stock

texture_id
model_type
```

Future optional properties:

```text
shelf_life
temperature_requirement
brand_loyalty
price_sensitivity
impulse_score
premium_score
substitution_group
```

Do not add future properties until needed.

---

# 17. Product visuals

Do not create a unique 3D mesh for every product.

Use generic product shapes.

Initial package types:

```text
box_small
box_medium
box_large
can
bottle_small
bottle_large
jar
bag
carton
```

A product visual is created from:

```text
base mesh
+
scale
+
material
+
texture
```

This makes it possible to create many fictional SKUs cheaply.

---

# 18. Fictional brands

Use fictional brands.

Reasons:

- no licensing issues,
- easier art direction,
- easier procedural content,
- more creative freedom.

Example placeholder brands:

- FreshPop,
- AquaPure,
- SunnyJuice,
- CrunchBox,
- MorningStar,
- QuickBite.

Names can be changed later.

---

# 19. Inventory

Each product may exist in three states:

```text
Warehouse Stock
Shelf Stock
Ordered Stock
```

For the earliest prototype, warehouse stock may be skipped.

Prototype simplification:

```text
Store Stock
Shelf Capacity
```

Later:

```text
supplier
    ↓
delivery
    ↓
warehouse
    ↓
replenishment
    ↓
shelf
```

---

# 20. Supply and deliveries

Deliveries are an important gameplay system.

The player spends money to order products.

Basic delivery properties:

```text
product
quantity
purchase_cost
delivery_time
```

Initial delivery types:

## Standard

- cheaper,
- delayed.

## Express

- expensive,
- immediate or very fast.

Example:

```text
STANDARD
Cost: 20
Delivery: next day

EXPRESS
Cost: 45
Delivery: now
```

Later possible systems:

- suppliers,
- lead time,
- minimum order quantity,
- case packs,
- delivery windows,
- supplier reliability,
- storage cost,
- warehouse capacity.

---

# 21. Customer system

Customers should be autonomous NPCs.

Basic customer process:

```text
SPAWN
  ↓
ENTER STORE
  ↓
CREATE SHOPPING LIST
  ↓
FIND PRODUCT
  ↓
WALK TO PRODUCT
  ↓
TAKE PRODUCT
  ↓
NEXT PRODUCT
  ↓
CHECKOUT
  ↓
PAY
  ↓
EXIT
```

---

# 22. Customer shopping list

Each customer gets a shopping list.

Example:

```text
Water
Cola
Cereal
```

The system chooses products based on:

- level configuration,
- customer archetype,
- product popularity,
- available assortment.

MVP may use simple random weighted selection.

---

# 23. Customer decision logic

Basic state machine:

```text
ENTERING
SEARCHING
MOVING_TO_PRODUCT
PICKING_PRODUCT
MOVING_TO_CHECKOUT
WAITING_IN_QUEUE
PAYING
LEAVING
FAILED
```

Example decision:

```text
Does the store sell Cola?
    ↓
YES

Is Cola reachable?
    ↓
YES

Is shelf stock > 0?
    ↓
YES

Take Cola
```

Failure:

```text
Shelf stock = 0
    ↓
Lost Sale
    ↓
Customer frustration increases
```

---

# 24. Customer frustration

Customers should have a simple frustration value.

Possible reasons for frustration:

- product unavailable,
- product out of stock,
- long walking distance,
- blocked aisle,
- long checkout queue,
- excessive search time.

Frustration can influence:

- satisfaction,
- chance of abandoning shopping,
- store reputation.

Keep formula simple.

---

# 25. Customer waves

Customers arrive in waves.

Example:

```text
Wave 1
Customers: 10

Wave 2
Customers: 20

Wave 3
Rush Hour
Customers: 35
```

Waves can introduce gameplay pressure.

Future wave modifiers:

- payday,
- weekend,
- promotion,
- holiday,
- heatwave,
- viral product,
- supplier delay.

---

# 26. Customer archetypes

Do not implement all archetypes in the MVP.

Possible future archetypes:

## Regular Shopper

Balanced behavior.

## Impatient Shopper

Low tolerance for queues and searching.

## Bargain Hunter

Prefers cheaper products.

## Premium Shopper

Prefers premium brands.

## Family Shopper

Large basket.

## Quick Shopper

Few items, high speed.

## Impulse Shopper

More likely to buy promotional products.

---

# 27. Checkout

MVP:

- one checkout,
- automatic checkout interaction,
- basic queue.

Customer:

```text
arrives
↓
waits
↓
pays
↓
leaves
```

Later:

- multiple checkouts,
- cashiers,
- self-checkout,
- staffing,
- checkout upgrades.

---

# 28. Economy

Core economy:

```text
Cash
Sales
Cost of Goods
Profit
```

Basic transaction:

```text
Revenue = Selling Price
Cost = Purchase Price
Margin = Revenue - Cost
```

Player spends money on:

- fixtures,
- inventory,
- deliveries,
- future upgrades.

Player earns money through customer purchases.

---

# 29. Main KPIs

Start with a small number of readable KPIs.

Recommended MVP:

```text
Cash
Sales
Profit
Customers Served
Customer Satisfaction
Lost Sales
Out of Stock Events
```

Later:

```text
Sales / m²
Sales / fixture
Units sold
Average basket
Conversion rate
Queue time
Stock turn
Waste
Category performance
```

---

# 30. Results screen

After a wave/day:

```text
DAY RESULTS

Customers: 30
Served: 27
Sales: 1,280
Profit: 410

Satisfaction: 84%

Lost Sales: 4
Out of Stocks: 3
```

The game should explain problems.

Example:

```text
PROBLEM

Cola was out of stock for 34% of the wave.

Suggested action:
Increase facings or order more stock.
```

This is an important learning mechanic.

---

# 31. Level rating

Recommended:

```text
0–3 stars
```

Example:

```text
★ Serve 30 customers
★ Satisfaction > 80%
★ Profit > 300
```

Level can be completed with 1 star.

Player can replay to optimize.

---

# 32. Progression

Possible progression:

```text
Small convenience store
↓
Mini market
↓
Neighborhood supermarket
↓
Large supermarket
↓
Hypermarket
```

Progression should introduce complexity gradually.

Possible unlock order:

```text
Level 1 — Fixtures
Level 2 — Product placement
Level 3 — Facings
Level 4 — Deliveries
Level 5 — Customer archetypes
Level 6 — Checkout queues
Level 7 — Promotions
Level 8 — Product adjacency
Level 9 — Refrigerated products
Level 10 — Staff
```

Do not commit to exact level count yet.

---

# 33. Store layouts

Levels should not only become larger.

Interesting level challenges:

- small store with high traffic,
- narrow store,
- L-shaped store,
- two entrances,
- bad starting layout,
- limited fixture budget,
- limited stock budget,
- premium neighborhood,
- discount neighborhood,
- very high-demand category,
- limited delivery frequency.

---

# 34. Product adjacency

Future feature.

Examples:

```text
Pasta near pasta sauce
Cereal near milk
Beer near snacks
```

Good adjacency can:

- increase basket value,
- reduce search time,
- improve sales.

This should be introduced only after the core systems work.

---

# 35. Promotions

Future feature.

Possible promotion mechanics:

- discount,
- endcap promotion,
- featured product,
- temporary demand boost,
- supplier promotion.

Promotions create:

- higher demand,
- stock pressure,
- margin trade-off.

---

# 36. Staff

Not part of the first prototype.

Future staff roles:

- cashier,
- shelf replenisher,
- warehouse worker,
- cleaner,
- manager.

Staff adds cost and efficiency.

---

# 37. First playable prototype

The first prototype must be extremely small.

## Prototype 0.01

Required content:

- one room,
- one entrance,
- one exit,
- one checkout,
- one movable shelf,
- one product,
- one customer,
- one purchase.

Required flow:

```text
PLACE SHELF
    ↓
ASSIGN PRODUCT
    ↓
OPEN STORE
    ↓
CUSTOMER ENTERS
    ↓
CUSTOMER WALKS TO PRODUCT
    ↓
CUSTOMER TAKES PRODUCT
    ↓
CUSTOMER WALKS TO CHECKOUT
    ↓
CUSTOMER PAYS
    ↓
CUSTOMER EXITS
    ↓
PLAYER RECEIVES MONEY
```

If this is not working, do not implement more features.

---

# 38. Prototype roadmap

## Prototype 0.01 — Core Interaction

- room,
- camera,
- placement grid,
- fixture placement,
- one product,
- one NPC,
- navigation,
- purchase loop.

---

## Prototype 0.02 — Small Store

Add:

- 5 products,
- 2–3 fixture types,
- 10 customers,
- basic budget,
- facings,
- shelf capacity,
- satisfaction.

---

## Prototype 0.03 — Inventory

Add:

- stock,
- orders,
- deliveries,
- out of stock,
- lost sales.

---

## Prototype 0.04 — Store Pressure

Add:

- waves,
- queues,
- customer types,
- results screen.

---

## Prototype 0.05 — Visual Polish

Add:

- better fixtures,
- character animations,
- product textures,
- sound,
- lighting,
- VFX,
- UI polish.

Only after Prototype 0.04 works.

---

# 39. Technology stack

Primary stack:

```text
macOS
Cursor Pro
Godot 4.x
GDScript
Git
GitHub
Blender
Homebrew
```

The project is developed primarily on macOS.

Cursor Agent should prefer macOS-compatible commands and paths.

Optional free tools/assets:

```text
Mixamo
Kenney
Poly Haven
Audacity
```

Avoid paid subscriptions at the beginning.

---


# 39A. macOS development environment

The main development machine uses macOS.

All development instructions generated by Cursor should assume macOS unless explicitly stated otherwise.

Preferred command-line conventions:

```text
Shell:
zsh

Package manager:
Homebrew

Repository paths:
Unix-style paths

Example:
~/Developer/ShopyFender
```

Do not generate Windows-specific commands such as:

```text
dir
copy
del
set VAR=value
C:\...
PowerShell-only commands
```

unless explicitly requested.

Prefer:

```bash
ls
cp
mv
rm
export VAR=value
chmod
find
grep
sed
```

Use portable shell commands where practical.

---

# 39B. Recommended macOS tools

Recommended free tools:

```text
Cursor
Godot 4.x
Blender
Git
GitHub
Homebrew
```

Optional:

```text
ffmpeg
ImageMagick
Audacity
```

Cursor should not install extra software unless it is necessary for the current task.

---

# 39C. Homebrew

If command-line tooling is required, prefer Homebrew.

Example checks:

```bash
brew --version
git --version
```

Do not automatically install packages without first explaining why they are required.

---

# 39D. Godot on macOS

Godot is the runtime and editor for the project.

The game should be launchable from Cursor's terminal when practical.

Possible Godot application path:

```text
/Applications/Godot.app
```

Possible CLI executable:

```text
/Applications/Godot.app/Contents/MacOS/Godot
```

Cursor must verify the actual installation path before relying on it.

Example:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --version
```

For launching the current project:

```bash
"/Applications/Godot.app/Contents/MacOS/Godot" --path .
```

If the `godot` command is available in PATH, prefer:

```bash
godot --path .
```

Do not hardcode a path before checking what exists on the user's Mac.

---

# 39E. Blender on macOS

Blender may be used later for procedural asset generation.

Typical application path:

```text
/Applications/Blender.app
```

Typical CLI executable:

```text
/Applications/Blender.app/Contents/MacOS/Blender
```

Example:

```bash
"/Applications/Blender.app/Contents/MacOS/Blender" --background --python tools/blender/create_shelf.py
```

Cursor must verify the installed Blender path first.

Blender is not required for Prototype 0.01 if primitive Godot geometry is sufficient.

---

# 39F. macOS project paths

Prefer keeping the repository somewhere simple, for example:

```text
~/Developer/ShopyFender
```

Avoid storing the active repository inside:

```text
Desktop
Documents synced by cloud storage
iCloud Drive
```

if that causes file synchronization or permission problems.

Recommended example:

```bash
mkdir -p ~/Developer
cd ~/Developer
```

---

# 39G. Apple Silicon

Assume Apple Silicon may be used.

Cursor should prefer native ARM64 versions of applications and command-line tools when available.

Avoid adding x86_64-only dependencies unless necessary.

Do not require Rosetta unless no native alternative exists.

---

# 39H. macOS permissions

If Godot, Blender, Cursor, or terminal tooling is blocked by macOS permissions, diagnose the actual error before suggesting changes.

Possible relevant macOS settings include:

```text
System Settings
→ Privacy & Security
```

Do not recommend disabling macOS security globally.

---

# 39I. Development target versus development OS

Development OS:

```text
macOS
```

This does not mean the game must be macOS-only.

Initial development should prioritize running the game locally on the developer's Mac.

Later export targets may include:

```text
macOS
Windows
Linux
```

Cross-platform export should not be worked on during Prototype 0.01 unless required.


# 40. Cursor-first workflow

Cursor is the primary environment.

The preferred workflow is:

```text
Developer
    ↓
Cursor Agent
    ↓
creates / edits:
    GDScript
    Godot scenes
    resources
    JSON
    shaders
    tests
    Blender scripts
    documentation
    ↓
Cursor terminal
    ↓
Godot CLI / Blender CLI / tests
```

The project should minimize manual editing in Godot.

Manual editor use is allowed only when it is significantly faster or required.

---

# 41. Godot project philosophy

Prefer:

- text-based scenes,
- reusable components,
- resource-driven configuration,
- small scripts,
- composition,
- signals,
- clear naming.

Avoid:

- giant scripts,
- hardcoded product lists,
- hardcoded levels,
- duplicated scenes,
- premature optimization,
- complex dependency injection,
- unnecessary plugins.

---

# 42. Suggested folder structure

```text
ShopyFender/
│
├── README.md
├── SHOPYFENDER_MASTER_SPEC.md
├── project.godot
│
├── docs/
│   ├── architecture.md
│   ├── gameplay.md
│   ├── roadmap.md
│   └── decisions.md
│
├── scenes/
│   ├── main/
│   ├── store/
│   ├── fixtures/
│   ├── products/
│   ├── customers/
│   ├── ui/
│   └── levels/
│
├── scripts/
│   ├── core/
│   ├── store/
│   ├── fixtures/
│   ├── products/
│   ├── customers/
│   ├── economy/
│   ├── inventory/
│   ├── delivery/
│   ├── ui/
│   └── debug/
│
├── data/
│   ├── products/
│   ├── fixtures/
│   ├── customers/
│   ├── levels/
│   └── suppliers/
│
├── assets/
│   ├── models/
│   │   ├── environment/
│   │   ├── fixtures/
│   │   ├── products/
│   │   └── characters/
│   │
│   ├── textures/
│   ├── materials/
│   ├── animations/
│   ├── audio/
│   ├── icons/
│   └── fonts/
│
├── tools/
│   ├── blender/
│   ├── generators/
│   ├── validators/
│   └── importers/
│
└── tests/
```

---

# 43. Core architecture

Recommended major systems:

```text
GameManager
StoreManager
BuildManager
ProductManager
InventoryManager
CustomerManager
EconomyManager
WaveManager
NavigationManager
UIManager
LevelManager
```

Do not create all managers immediately.

Create them only when required.

---

# 44. Suggested early scene tree

Example:

```text
Main
├── GameManager
├── Store
│   ├── Floor
│   ├── Walls
│   ├── Entrance
│   ├── Exit
│   ├── Fixtures
│   └── NavigationRegion3D
│
├── Customers
├── CameraRig
├── UI
└── Debug
```

---

# 45. Fixture architecture

Suggested structure:

```text
Fixture
├── Mesh
├── Collision
├── PlacementArea
├── NavigationObstacle
└── ShelfSlots
```

Fixture script responsibilities:

- placement,
- rotation,
- cost,
- fixture ID,
- shelf capacity,
- assigned products.

---

# 46. Product architecture

Products should NOT exist as unique scripts.

Use a shared product definition.

Recommended:

```text
ProductDefinition
```

Example fields:

```gdscript
id
display_name
category
package_type
size
purchase_price
selling_price
base_demand
```

A visual product instance references a ProductDefinition.

---

# 47. Customer architecture

Customer behavior should use a state machine.

Example:

```text
Customer
├── NavigationAgent3D
├── Visual
├── Collision
└── CustomerController
```

State machine:

```text
ENTER
PLAN
SEARCH
MOVE
PICK
CHECKOUT
PAY
EXIT
```

Do not use advanced AI/ML for customer AI.

Simple deterministic or probabilistic game AI is preferred.

---

# 48. Navigation

Use Godot navigation.

Customers must be able to navigate around fixtures.

When a fixture is placed:

- navigation must update,
- blocked paths should be detected if practical,
- entrance and checkout should remain reachable.

The first version can use simple NavigationRegion3D baking or runtime navigation approaches supported by the selected Godot version.

Cursor should select the simplest stable approach.

---

# 49. Grid placement

Build Mode should use a grid.

Suggested first implementation:

```text
cell size = 0.5 m
```

Fixture transform:

```text
position snapped to grid
rotation = multiples of 90 degrees
```

Later support:

```text
0.25 m grid
free placement
```

only if needed.

---

# 50. Interaction system

Use raycasts from the mouse camera.

Basic interactions:

```text
hover
select
place
rotate
delete
inspect
```

A selected object should be clearly highlighted.

---

# 51. UI

Early UI must prioritize functionality.

Suggested HUD:

```text
┌────────────────────────────────────────────┐
│ Cash   Sales   Satisfaction   Wave         │
├────────────────────────────────────────────┤
│                                            │
│                 GAME VIEW                  │
│                                            │
├────────────────────────────────────────────┤
│ Build | Products | Supply | Open Store     │
└────────────────────────────────────────────┘
```

Do not spend large amounts of development time on UI polish before gameplay works.

---

# 52. Build menu

Example:

```text
BUILD

Wall Shelf
Price: 300

Gondola
Price: 400

Checkout
Price: 1,500
```

---

# 53. Product menu

Example:

```text
PRODUCTS

FreshPop Cola
Demand: ★★★★★
Margin: 0.70
Stock: 40

AquaPure Water
Demand: ★★★★
Margin: 0.30
Stock: 80
```

---

# 54. Shelf editing UI

Example:

```text
SELECTED PRODUCT

FreshPop Cola

Facings
[-] 3 [+]

Capacity: 18
Current Stock: 14
```

---

# 55. Supply UI

Example:

```text
FreshPop Cola

Stock: 10

Order:
[-] 40 [+]

Cost: 20

Delivery:
Standard
```

---

# 56. Debug systems

Debugging is important for a simulation game.

Add debug views early.

Useful toggles:

```text
F1 = navigation paths
F2 = customer states
F3 = fixture IDs
F4 = shelf stock
F5 = demand
```

Debug panel should show:

```text
Customers alive
Customers served
Customers failed
Cash
Current wave
Navigation errors
```

---

# 57. Logging

Use readable logs.

Examples:

```text
[CUSTOMER] Customer_004 entered store
[CUSTOMER] Customer_004 searching for product cola_500
[INVENTORY] cola_500 shelf stock: 5 -> 4
[SALE] Customer_004 bought cola_500 for 2.50
[ECONOMY] Cash: 100.00 -> 102.50
```

Avoid excessive logging in release builds.

---

# 58. Saving

Do not implement save/load in Prototype 0.01.

Later save:

- player progression,
- cash,
- unlocked fixtures,
- unlocked products,
- store layout,
- stock,
- active deliveries.

Use simple structured serialization.

---

# 59. Data-driven levels

Levels should be defined by data.

Example structure:

```text
LevelDefinition
├── store_size
├── starting_cash
├── products
├── fixtures
├── objectives
├── waves
└── unlocks
```

Do not create a unique code file for every level.

---

# 60. Procedural asset strategy

Because the project has a very small budget:

1. Use simple placeholder geometry first.
2. Use free assets second.
3. Generate repetitive assets with Blender Python.
4. Replace important assets manually only when needed.
5. Do not buy art before gameplay works.

---

# 61. Blender automation

Blender should be scriptable from Cursor.

Possible workflow:

```text
Cursor
    ↓
writes Python script
    ↓
Blender CLI
    ↓
creates model
    ↓
exports .glb
    ↓
Godot imports model
```

Example generated assets:

- gondola,
- shelf,
- checkout,
- pallet,
- box,
- bottle,
- can,
- simple fridge.

---

# 62. Asset rules

Every external asset should have license information.

Create:

```text
assets/LICENSES.md
```

For each external asset record:

```text
name
source
author
license
download date
```

Prefer:

```text
CC0
MIT
commercial-friendly licenses
```

---

# 63. AI usage

AI should assist development, not become a gameplay dependency.

Recommended AI use:

- Cursor coding,
- architecture,
- refactoring,
- bug fixing,
- test generation,
- documentation,
- procedural data creation,
- placeholder text,
- product names,
- generating Blender scripts.

Do not require paid AI APIs for the running game.

---

# 64. Out of scope for MVP

Do NOT implement initially:

- multiplayer,
- online services,
- cloud saves,
- mobile version,
- console version,
- mod support,
- workshop support,
- real brands,
- advanced employees,
- advanced warehouse simulation,
- realistic accounting,
- realistic weather,
- day/night cycle,
- complex character customization,
- advanced marketing,
- machine learning customer behavior,
- thousands of products.

---

# 65. Definition of MVP

MVP is reached when the player can:

1. Start a small store.
2. Place fixtures.
3. Assign products to shelves.
4. Change facings.
5. Buy or order products.
6. Open the store.
7. Watch customers shop.
8. Experience out-of-stock situations.
9. Make sales.
10. Earn or lose money.
11. Receive performance feedback.
12. Improve the store.

This is enough for an MVP.

---

# 66. Definition of fun test

Before expanding the game, ask:

> Is it satisfying to redesign the store and then watch customer behavior improve?

If the answer is no:

Do not add more systems.

Improve:

- feedback,
- customer flow,
- building,
- shelf interaction,
- economy,
- objectives.

---

# 67. Cursor coding rules

Cursor Agent must follow these rules.

## General

- Prefer small files.
- Prefer explicit code.
- Prefer readable code.
- Avoid unnecessary abstractions.
- Avoid speculative systems.
- Avoid premature optimization.
- Do not add dependencies unless necessary.
- Do not introduce plugins without explaining why.
- Keep the project runnable after each task.

---

## Before coding

For every meaningful feature:

1. Read this file.
2. Inspect the existing project.
3. Identify affected systems.
4. Make the smallest viable plan.
5. Implement only what is required.
6. Run available checks.
7. Report what changed.

---

## After coding

Agent should report:

```text
Implemented:
- ...

Files changed:
- ...

How to test:
1. ...
2. ...

Known limitations:
- ...
```

---

# 68. Git workflow

Use Git from the start.

Suggested branch strategy for solo development:

```text
main
```

Optional short-lived branches for major work:

```text
feature/build-mode
feature/customers
feature/inventory
```

Commit frequently.

Suggested commit style:

```text
feat: add fixture placement
fix: prevent blocked entrance
feat: add basic customer shopping
refactor: split product data from shelf instance
```

---

# 69. Documentation rules

Keep documentation close to code.

Important architectural decisions should be stored in:

```text
docs/decisions.md
```

Format:

```text
## Decision
Use Godot NavigationAgent3D for customers.

## Reason
Simple and built into engine.

## Alternatives
Custom pathfinding.

## Status
Accepted.
```

---

# 70. Performance philosophy

Do not optimize early.

First target:

```text
30–50 customers
```

Later:

```text
100+
```

Only optimize after measuring.

Potential later optimization:

- object pooling,
- reduced animation complexity,
- lower pathfinding frequency,
- simplified customer LOD,
- batched product rendering.

---

# 71. Prototype 0.01 implementation checklist

Cursor should implement Prototype 0.01 in small stages.

## Stage 1 — Project

- create Godot project,
- create folders,
- create main scene,
- create basic room.

## Stage 2 — Camera

- pan,
- zoom,
- rotate if easy,
- mouse raycast.

## Stage 3 — Fixture

- simple box shelf,
- grid placement,
- rotation,
- collision.

## Stage 4 — Product

- one product definition,
- one shelf slot,
- assign product.

## Stage 5 — Customer

- spawn,
- navigate to shelf,
- take product,
- navigate to checkout,
- exit.

## Stage 6 — Economy

- sale price,
- cash,
- HUD.

## Stage 7 — Game state

- Build Mode,
- Open Store,
- one customer wave.

## Stage 8 — Debugging

- logs,
- simple debug panel,
- path visualization if useful.

---

# 72. Success criteria for Prototype 0.01

Prototype 0.01 is complete only if:

```text
1. Project launches without errors.
2. Camera can inspect the room.
3. Player can place at least one shelf.
4. Product can be assigned.
5. Store can be opened.
6. Customer enters through entrance.
7. Customer reaches the product.
8. Product stock decreases.
9. Customer reaches checkout.
10. Sale increases cash.
11. Customer exits the store.
12. The whole loop can repeat reliably.
```

---

# 73. Do not add before Prototype 0.01 works

Do not add:

- animations,
- detailed graphics,
- multiple customer types,
- complex UI,
- suppliers,
- employees,
- promotions,
- campaign map,
- achievements,
- sound system,
- save system.

---

# 74. Prototype 0.02 planned features

Only after 0.01:

```text
5 products
2–3 fixture types
10 customers
multiple shopping lists
facings
shelf capacity
basic satisfaction
lost sales
basic results screen
```

---

# 75. Prototype 0.03 planned features

```text
stock
orders
deliveries
standard delivery
express delivery
out-of-stock events
simple backroom
```

---

# 76. Prototype 0.04 planned features

```text
customer waves
checkout queues
customer archetypes
mission objectives
3-star rating
```

---

# 77. Prototype 0.05 planned features

```text
better characters
animations
better models
lighting
sounds
UI polish
product textures
```

---

# 78. Long-term feature ideas

These are ideas only.

Do NOT treat them as current requirements.

Possible future systems:

- employees,
- theft,
- cleaning,
- store maintenance,
- seasonal demand,
- competitor stores,
- store chains,
- pricing,
- promotions,
- loyalty system,
- private label,
- category reviews,
- supplier negotiations,
- product discontinuation,
- planogram compliance,
- waste,
- expiration dates,
- cold chain,
- regional demand,
- store classes,
- heatmaps,
- queue optimization,
- online orders,
- click & collect.

---

# 79. Possible unique ShopyFender features

Potential differentiators:

## Customer Flow Heatmap

Shows where customers move.

## Lost Sales Heatmap

Shows where unavailable products cause lost revenue.

## Shelf Productivity View

Shows revenue generated by shelf area.

## Customer Frustration View

Shows bottlenecks.

## Replay

Replay the last wave at high speed.

## Before / After Comparison

Compare two layouts.

These features fit the game's identity better than generic supermarket simulator mechanics.

---

# 80. Heatmaps

Future useful heatmaps:

```text
traffic
sales
profit
frustration
queue
out of stock
product interaction
```

Heatmaps should be visual overlays in the store.

---

# 81. Game speed

Simulation controls should eventually support:

```text
Pause
1x
2x
4x
```

This is useful for management gameplay.

Not required in the first build unless trivial to add.

---

# 82. Store opening cycle

Recommended cycle:

```text
PLANNING MODE

Player can:
- build,
- move,
- change assortment,
- change facings,
- order products.

↓ OPEN STORE

SIMULATION MODE

Customers arrive.

Major layout editing disabled.

↓ END WAVE

RESULTS

↓ PLANNING MODE
```

This is preferred over allowing unrestricted construction during the customer wave in the first versions.

---

# 83. Store state machine

Suggested high-level states:

```text
SETUP
BUILD
OPENING
SIMULATION
RESULTS
PAUSED
```

---

# 84. First data examples

Example product:

```text
ID: freshpop_cola_500
Name: FreshPop Cola 500 ml
Category: Soft Drinks
Package: bottle_small

Width: 0.065
Height: 0.22
Depth: 0.065

Purchase Price: 1.20
Selling Price: 2.50

Base Demand: 0.8
```

Example water:

```text
ID: aquapure_water_500
Name: AquaPure Water 500 ml
Category: Water
Package: bottle_small

Purchase Price: 0.60
Selling Price: 1.50

Base Demand: 0.7
```

---

# 85. First customer example

```text
Customer ID: customer_001

Shopping List:
- freshpop_cola_500

Patience: 100

States:
ENTER
MOVE_TO_PRODUCT
PICK_PRODUCT
MOVE_TO_CHECKOUT
PAY
EXIT
```

---

# 86. First fixture example

```text
Fixture ID: gondola_basic_100

Name:
Basic Gondola 1m

Cost:
400

Width:
1.0 m

Depth:
0.5 m

Height:
1.8 m

Shelf count:
4
```

---

# 87. First store example

```text
Store:
Prototype Store

Width:
10 m

Depth:
12 m

Starting Cash:
10,000

Entrance:
south-west

Exit:
south-east

Checkout:
south-east
```

---

# 88. First gameplay balance

All numbers are temporary.

Use placeholder balance.

Example:

```text
Shelf: 400
Checkout: 1,500

Cola Buy: 1.20
Cola Sell: 2.50

Water Buy: 0.60
Water Sell: 1.50
```

Do not spend time balancing before the simulation loop is playable.

---

# 89. Error-handling philosophy

If a gameplay configuration is invalid:

- fail safely,
- log the issue,
- show debug feedback,
- avoid crashing.

Examples:

```text
Product missing → log warning.
Shelf missing → customer fails gracefully.
No path → customer exits unhappy.
Invalid level data → show clear error.
```

---

# 90. Testing philosophy

For simulation logic, prefer deterministic tests where practical.

Useful test areas:

- inventory reduction,
- sale calculations,
- shelf capacity,
- facings,
- objective completion,
- customer shopping-list completion.

Do not try to fully automate visual testing early.

---

# 91. Naming conventions

GDScript files:

```text
snake_case.gd
```

Scenes:

```text
PascalCase.tscn
```

Classes:

```text
PascalCase
```

Variables:

```text
snake_case
```

Signals:

```text
snake_case
```

IDs:

```text
lowercase_snake_case
```

Example:

```text
freshpop_cola_500
gondola_basic_100
level_001
```

---

# 92. Cursor task size

Cursor should work in small tasks.

Good task:

> Implement grid snapping for fixture placement.

Bad task:

> Build the entire game.

Every task should ideally result in something testable.

---

# 93. Cursor should not invent scope

Cursor must not automatically add:

- new game modes,
- networking,
- plugins,
- ECS frameworks,
- DI frameworks,
- paid APIs,
- analytics SDKs,
- ads,
- monetization,

unless explicitly requested.

---

# 94. Cursor source-of-truth hierarchy

When there is uncertainty:

1. User's latest instruction.
2. This master specification.
3. Existing project architecture.
4. docs/decisions.md.
5. Cursor's own suggestion.

Cursor should ask only when a decision materially changes the project.

For small implementation details, choose the simplest reasonable solution.

---

# 95. Project goal

The goal is NOT to build a perfect retail simulator.

The goal is:

> Build a fun, visually understandable 3D store optimization game where the player can design a store, configure shelves and inventory, and then watch customer behavior validate or punish those decisions.

---

# 96. First development instruction for Cursor

Use the following instruction after placing this file in the repository.

---

## MASTER CURSOR PROMPT

```text
You are the lead developer for the ShopyFender project.

Before doing anything, read SHOPYFENDER_MASTER_SPEC.md completely.

This document is the main product and architecture specification.

We are building ShopyFender as a low-budget hobby project.

Technology:
- macOS as the primary development OS
- Cursor Pro as the primary development environment
- Godot 4.x
- GDScript
- Git
- Homebrew for macOS command-line dependencies when needed
- Blender only when useful
- no paid runtime APIs

Environment rules:
- assume zsh/macOS terminal,
- use Unix-style paths,
- do not use Windows commands,
- verify Godot and Blender executable paths before using them,
- prefer Apple Silicon-native tooling when available.

Development philosophy:
- simplest working solution first,
- data-driven systems,
- no unnecessary plugins,
- no premature optimization,
- no over-engineering,
- keep the project runnable after every meaningful step.

Your immediate objective is NOT to build the full game.

Your objective is to build Prototype 0.01.

Prototype 0.01 must contain:

1. One simple rectangular 3D store room.
2. One entrance.
3. One exit.
4. One checkout.
5. A management-style 3D camera.
6. A simple build mode.
7. Grid-based shelf placement.
8. One basic shelf fixture.
9. One product definition.
10. Ability to assign that product to the shelf.
11. One customer NPC.
12. Customer navigation.
13. Customer enters the store.
14. Customer walks to the assigned product.
15. Product stock decreases.
16. Customer walks to checkout.
17. Customer pays.
18. Player cash increases.
19. Customer exits.
20. The cycle can be repeated.

For the first version use placeholder geometry only.

Do not use downloaded art assets yet.

Do not implement:
- advanced UI,
- animations,
- employees,
- deliveries,
- suppliers,
- multiple customer types,
- promotions,
- campaign system,
- save system,
- sound,
- achievements.

First inspect the repository.

If the Godot project does not exist, create the minimum project structure described in SHOPYFENDER_MASTER_SPEC.md.

Then create a short implementation plan for Prototype 0.01.

Break the work into small stages.

Implement only Stage 1 first.

After implementation:

1. Run any available validation or project checks.
2. Tell me exactly what files were created or modified.
3. Tell me exactly how I can test the result.
4. List known limitations.
5. Do not automatically continue to the next stage until I ask.

Use clear code and comments only where useful.

Avoid giant scripts.

Prefer reusable components and signals.

Treat SHOPYFENDER_MASTER_SPEC.md as the source of truth.
```

---

# 97. Suggested first Cursor task

After Cursor reads the master prompt, the first actual implementation should be:

```text
Implement Stage 1 of Prototype 0.01 only.

Create the initial Godot project structure and a Main scene containing:

- a simple 10m x 12m store floor,
- basic surrounding walls,
- one clearly marked entrance,
- one clearly marked exit,
- placeholder checkout location,
- basic lighting,
- WorldEnvironment if useful.

Use only primitive geometry.

Do not implement the camera controller or gameplay systems yet.

Make sure the project launches successfully.

At the end provide:
- changed files,
- how to run,
- how to test,
- known limitations.
```

---

# 98. Suggested second Cursor task

```text
Implement Stage 2 of Prototype 0.01.

Add a management camera.

Requirements:
- perspective 3D camera,
- WASD movement,
- mouse wheel zoom,
- optional middle-mouse drag if simple,
- camera remains focused on the store area,
- reasonable movement speed,
- no player character.

Keep the implementation simple.

Do not add fixture placement yet.

Test the project and report:
- files changed,
- controls,
- how to test,
- limitations.
```

---

# 99. Suggested third Cursor task

```text
Implement Stage 3 of Prototype 0.01.

Add the first fixture placement system.

Requirements:
- Build Mode,
- one placeholder shelf fixture,
- mouse raycast to store floor,
- placement preview,
- 0.5m grid snapping,
- R rotates fixture by 90 degrees,
- left mouse confirms placement,
- right mouse cancels,
- placement collision prevents overlapping existing fixtures,
- fixture cost exists in data but does not need full economy yet.

Use primitive geometry.

Do not implement products or customers yet.

Test the project and report:
- files changed,
- controls,
- how to test,
- limitations.
```

---

# 100. Development mantra

Whenever unsure:

```text
MAKE IT PLAYABLE
BEFORE
MAKING IT COMPLEX
```

And:

```text
FUN
>
REALISM
>
VISUAL POLISH
```

for the early development phase.

---

# 101. End of specification

This document should evolve with the project.

When a major design decision changes:

1. update this file,
2. update docs/decisions.md,
3. keep code consistent with the latest agreed design.

Do not silently change the core direction of the project.
