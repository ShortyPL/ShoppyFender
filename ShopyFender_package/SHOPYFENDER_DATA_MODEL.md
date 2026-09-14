# ShopyFender — Data Model Specification

> **Project:** ShopyFender  
> **Environment:** Cursor Pro + Godot 4.x + GDScript on macOS  
> **Purpose:** Source of truth for gameplay data structures, ownership, serialization and persistence  
> **Status:** v0.1  
> **Related docs:**  
> - `SHOPYFENDER_MASTER_SPEC.md`  
> - `SHOPYFENDER_GAME_LOGIC.md`  
> - `SHOPYFENDER_3D_ASSET_LIST.md`  
> - `SHOPYFENDER_TEXTURE_SPEC.md`

---

# 1. Purpose

This document defines the core data model for ShopyFender.

Cursor must use this document when creating or modifying:

- product data,
- fixtures,
- shelf placements,
- inventory,
- customer data,
- waves,
- levels,
- deliveries,
- economy events,
- objectives,
- save data,
- analytics data.

The goal is to avoid duplicated state and contradictory representations.

---

# 2. Core principle

Each piece of gameplay data must have one authoritative owner.

Do not store the same authoritative value in several systems.

Examples:

```text
GOOD

InventoryManager
owns stock truth

Shelf visuals
read stock from InventoryManager / ShelfPlacement
```

```text
BAD

Shelf script stock = 8
InventoryManager stock = 7
Product node stock = 6
```

Single source of truth is mandatory.

---

# 3. Data categories

ShopyFender data is divided into four categories:

```text
STATIC DEFINITIONS
RUNTIME STATE
EVENT RECORDS
SAVE DATA
```

---

# 4. Static definitions

Static definitions describe content that usually does not change during play.

Examples:

```text
ProductDefinition
FixtureDefinition
CustomerTypeDefinition
WaveDefinition
LevelDefinition
SupplierDefinition
ObjectiveDefinition
```

Recommended Godot implementation:

```text
Resource
```

Stored as:

```text
.tres
```

or generated from data files if needed later.

---

# 5. Runtime state

Runtime state describes what is currently happening in a loaded level.

Examples:

```text
ShelfPlacementState
InventoryState
CustomerRuntimeState
WaveRuntimeState
DeliveryRuntimeState
StoreRuntimeState
EconomyRuntimeState
```

Recommended implementation:

```text
RefCounted
Node
or lightweight custom classes
```

Do not automatically use `Resource` for every runtime object.

---

# 6. Event records

Event records describe something that already happened.

Examples:

```text
SaleEvent
LostSaleEvent
OutOfStockEvent
CustomerExitEvent
StockChangeEvent
```

These records support:

- results,
- analytics,
- debugging,
- replay,
- heatmaps.

Keep them immutable after creation where practical.

---

# 7. Save data

Save data is a serializable snapshot of long-lived state.

Examples:

```text
PlayerProgressSave
StoreSaveData
FixtureSaveData
InventorySaveData
DeliverySaveData
```

Save data should NOT directly serialize entire live scene trees.

---

# 8. ID philosophy

Every static definition should have a stable string ID.

Examples:

```text
freshpop_cola_500
aquapure_water_500
gondola_basic_100
checkout_basic_01
regular_customer
level_001
supplier_basic
```

IDs:

```text
lowercase_snake_case
```

Never use display names as IDs.

Display names may change.

IDs should remain stable after release.

---

# 9. Runtime IDs

Runtime entities should have unique runtime IDs.

Examples:

```text
customer_000001
fixture_instance_000012
delivery_000004
sale_000221
```

Runtime IDs are not content-definition IDs.

Example:

```text
fixture_definition_id = gondola_basic_100
fixture_instance_id   = fixture_instance_000012
```

---

# 10. Recommended static Resource base

Optional base class:

```gdscript
class_name DefinitionResource
extends Resource

@export var id: StringName
@export var display_name: String
```

Use only if it improves consistency.

Do not create inheritance layers without a clear benefit.

---

# 11. ProductDefinition

Recommended file:

```text
scripts/products/product_definition.gd
```

Class:

```gdscript
class_name ProductDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName
@export var display_name: String

@export var brand_id: StringName
@export var category_id: StringName

@export var package_type: StringName

@export var width_m: float
@export var height_m: float
@export var depth_m: float

@export var purchase_price: float
@export var selling_price: float

@export var base_demand: float

@export var units_per_case: int = 1

@export var model_id: StringName
@export var material_id: StringName
```

---

# 12. ProductDefinition validation

Required rules:

```text
id not empty
display_name not empty

width > 0
height > 0
depth > 0

purchase_price >= 0
selling_price >= 0

base_demand >= 0
units_per_case >= 1
```

Optional warning:

```text
selling_price < purchase_price
```

This can be valid, but should be intentional.

---

# 13. ProductDefinition example

```text
id:
freshpop_cola_500

display_name:
FreshPop Cola 500 ml

brand_id:
freshpop

category_id:
soft_drinks

package_type:
bottle_small

width_m:
0.065

height_m:
0.22

depth_m:
0.065

purchase_price:
1.20

selling_price:
2.50

base_demand:
0.80

units_per_case:
12

model_id:
bottle_small_01

material_id:
freshpop_cola_original
```

---

# 14. ProductCategoryDefinition

Recommended class:

```gdscript
class_name ProductCategoryDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName
@export var display_name: String
@export var parent_category_id: StringName
@export var color_hint: Color
```

Examples:

```text
beverages
soft_drinks
water
snacks
cereal
dairy
household
```

Do not overbuild category hierarchy early.

---

# 15. BrandDefinition

Recommended class:

```gdscript
class_name BrandDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName
@export var display_name: String
@export var primary_color: Color
@export var secondary_color: Color
@export var logo_texture: Texture2D
```

Examples:

```text
freshpop
aquapure
sunnyjuice
crunchbox
```

---

# 16. FixtureDefinition

Recommended file:

```text
scripts/fixtures/fixture_definition.gd
```

Class:

```gdscript
class_name FixtureDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName
@export var display_name: String

@export var fixture_type: StringName

@export var width_m: float
@export var depth_m: float
@export var height_m: float

@export var purchase_cost: float
@export var sell_value_ratio: float = 0.5

@export var shelf_count: int
@export var side_count: int = 1

@export var packed_scene: PackedScene
```

---

# 17. Fixture types

Initial fixture type IDs:

```text
gondola
wall_shelf
checkout
fridge
freezer
promo_bin
display_table
backroom_rack
```

Use strings/`StringName` initially.

Do not create large enum hierarchies unless needed.

---

# 18. FixtureDefinition example

```text
id:
gondola_basic_100

display_name:
Basic Gondola 1m

fixture_type:
gondola

width_m:
1.0

depth_m:
0.5

height_m:
1.8

purchase_cost:
400

sell_value_ratio:
0.5

shelf_count:
4

side_count:
2
```

---

# 19. ShelfDefinition

A fixture may have predefined shelf geometry.

Recommended:

```gdscript
class_name ShelfDefinition
extends Resource
```

Fields:

```gdscript
@export var shelf_index: int
@export var side_index: int

@export var width_m: float
@export var depth_m: float
@export var clearance_height_m: float

@export var local_position: Vector3
```

FixtureDefinition may contain:

```gdscript
@export var shelves: Array[ShelfDefinition]
```

---

# 20. FixtureInstanceState

Represents one placed fixture.

Recommended runtime class:

```gdscript
class_name FixtureInstanceState
extends RefCounted
```

Fields:

```gdscript
var instance_id: StringName
var definition_id: StringName

var position: Vector3
var rotation_y_deg: float

var is_active: bool = true

var shelf_states: Array[ShelfState]
```

The scene node references this state.

---

# 21. ShelfState

Represents one physical shelf on one placed fixture.

Fields:

```gdscript
class_name ShelfState
extends RefCounted

var fixture_instance_id: StringName
var shelf_index: int
var side_index: int

var width_m: float
var depth_m: float
var clearance_height_m: float

var placements: Array[ProductPlacementState]
```

---

# 22. ProductPlacementState

One assigned product block on a shelf.

Fields:

```gdscript
class_name ProductPlacementState
extends RefCounted

var placement_id: StringName

var product_id: StringName

var fixture_instance_id: StringName
var shelf_index: int
var side_index: int

var horizontal_start_m: float

var facings: int = 1
var units_deep: int = 1

var capacity: int = 1
var shelf_stock: int = 0
```

---

# 23. Placement derived fields

These values should be calculated, not stored permanently when avoidable:

```text
required_width
available_width
units_deep
capacity
```

Example:

```gdscript
func get_required_width(product: ProductDefinition) -> float:
    return product.width_m * facings
```

---

# 24. Shelf capacity formula

Initial formula:

```text
units_deep =
floor(shelf_depth / product_depth)

capacity =
facings * units_deep
```

Future:

```text
capacity =
facings
* units_deep
* units_vertical
```

Do not add vertical stacking in MVP.

---

# 25. ShelfState ownership

Authoritative owner:

```text
StoreManager / StoreRuntimeState
```

Inventory system may reference placement state.

Do not keep a separate duplicate shelf-stock dictionary unless required for performance.

---

# 26. StoreDefinition

Static level store geometry data.

Recommended fields:

```gdscript
class_name StoreDefinition
extends Resource

@export var width_m: float
@export var depth_m: float

@export var entrance_position: Vector3
@export var exit_position: Vector3
@export var checkout_spawn_position: Vector3
```

For early levels, store geometry can be embedded in LevelDefinition.

---

# 27. StoreRuntimeState

Fields:

```gdscript
class_name StoreRuntimeState
extends RefCounted

var fixture_instances: Dictionary
var current_level_id: StringName
```

Dictionary:

```text
fixture_instance_id -> FixtureInstanceState
```

---

# 28. InventoryState

Recommended authoritative stock model:

```gdscript
class_name InventoryState
extends RefCounted
```

Fields:

```gdscript
var warehouse_stock: Dictionary
var ordered_stock: Dictionary
```

Format:

```text
product_id -> quantity
```

Shelf stock lives inside `ProductPlacementState`.

---

# 29. Inventory totals

Functions:

```gdscript
func get_warehouse_stock(product_id) -> int
func get_ordered_stock(product_id) -> int
func get_total_shelf_stock(product_id) -> int
func get_available_stock(product_id) -> int
func get_total_stock(product_id) -> int
```

Definitions:

```text
available_stock =
warehouse + shelf stock

total_stock =
warehouse + shelf stock + ordered
```

---

# 30. Prototype 0.01 inventory simplification

For 0.01, allowed temporary simplification:

```text
shelf_stock only
```

No warehouse.

No ordered stock.

But code should not make later inventory expansion impossible.

---

# 31. Stock mutation rule

Never directly modify stock from random systems.

Use inventory/store methods such as:

```gdscript
take_from_shelf(...)
add_to_shelf(...)
add_to_warehouse(...)
reserve_delivery(...)
receive_delivery(...)
```

This makes logging and metrics reliable.

---

# 32. StockChangeEvent

Fields:

```text
event_id
product_id
source_type
source_id
delta
old_value
new_value
reason
timestamp
```

Reasons:

```text
CUSTOMER_PURCHASE
REPLENISHMENT
DELIVERY
DEBUG
LEVEL_SETUP
```

---

# 33. SupplierDefinition

Future/static.

Fields:

```gdscript
class_name SupplierDefinition
extends Resource

@export var id: StringName
@export var display_name: String

@export var delivery_fee: float
@export var lead_time_waves: int

@export var available_product_ids: Array[StringName]
```

MVP can use one implicit supplier.

---

# 34. DeliveryDefinition vs DeliveryRuntimeState

Static delivery types:

```text
standard
express
```

Runtime delivery:

```gdscript
class_name DeliveryRuntimeState
extends RefCounted
```

Fields:

```gdscript
var delivery_id: StringName
var supplier_id: StringName
var product_id: StringName

var quantity: int
var unit_cost: float
var delivery_fee: float

var created_wave_index: int
var arrival_wave_index: int

var status: StringName
```

---

# 35. Delivery status IDs

```text
ordered
in_transit
arrived
cancelled
```

Prefer constants:

```gdscript
const DELIVERY_ORDERED := &"ordered"
```

rather than free-form strings everywhere.

---

# 36. OrderRequest

Temporary command-style data object.

Fields:

```text
product_id
quantity
delivery_type
supplier_id
```

EconomyManager validates affordability.

Inventory/Delivery system creates delivery state.

---

# 37. CustomerTypeDefinition

Recommended class:

```gdscript
class_name CustomerTypeDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName
@export var display_name: String

@export var move_speed_mps: float = 2.5
@export var max_frustration: float = 100.0

@export var min_basket_items: int = 1
@export var max_basket_items: int = 3

@export var queue_penalty_multiplier: float = 1.0
@export var oos_penalty_multiplier: float = 1.0
```

---

# 38. CustomerTypeDefinition future fields

Later:

```text
price_sensitivity
premium_preference
impulse_modifier
substitution_probability
category_preferences
```

Do not add until needed.

---

# 39. ShoppingListItem

Recommended:

```gdscript
class_name ShoppingListItem
extends RefCounted

var product_id: StringName
var requested_quantity: int = 1
var fulfilled_quantity: int = 0
```

MVP:

```text
requested_quantity = 1
```

---

# 40. BasketItem

Fields:

```text
product_id
quantity
unit_price
unit_cost
```

Store price-at-purchase if dynamic pricing is later introduced.

---

# 41. CustomerRuntimeState

Fields:

```gdscript
class_name CustomerRuntimeState
extends RefCounted

var runtime_id: StringName
var customer_type_id: StringName

var state: StringName

var shopping_list: Array[ShoppingListItem]
var basket: Array[BasketItem]

var frustration: float = 0.0
var satisfaction: float = 100.0

var total_queue_wait_sec: float = 0.0
var total_path_distance_m: float = 0.0

var money_spent: float = 0.0
```

---

# 42. Customer state IDs

```text
spawning
entering
choosing_next_product
searching_product
moving_to_product
picking_product
moving_to_checkout
waiting_in_queue
paying
leaving
finished
failed
```

Keep state data separate from animation state where possible.

---

# 43. Customer scene node

Recommended scene:

```text
Customer.tscn
```

Contains:

```text
Customer
├── NavigationAgent3D
├── VisualRoot
├── CollisionShape3D
└── CustomerController
```

Controller owns the runtime state reference.

Visual does not own shopping logic.

---

# 44. WaveDefinition

Recommended:

```gdscript
class_name WaveDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName

@export var customer_count: int
@export var spawn_interval_sec: float

@export var customer_type_weights: Dictionary
@export var category_demand_modifiers: Dictionary

@export var seed: int = 0
```

---

# 45. WaveDefinition example

```text
id:
level_001_wave_01

customer_count:
10

spawn_interval_sec:
1.5

customer_type_weights:
regular_customer = 1.0

category_demand_modifiers:
soft_drinks = 1.0
water = 1.0
```

---

# 46. WaveRuntimeState

Fields:

```gdscript
class_name WaveRuntimeState
extends RefCounted

var wave_id: StringName

var state: StringName

var total_to_spawn: int
var spawned_count: int
var active_customer_count: int
var completed_customer_count: int

var elapsed_sec: float
```

---

# 47. Wave state IDs

```text
prepare
countdown
spawning
active
waiting_for_exit
complete
```

---

# 48. LevelDefinition

Recommended class:

```gdscript
class_name LevelDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName
@export var display_name: String

@export var store_width_m: float
@export var store_depth_m: float

@export var starting_cash: float

@export var available_fixture_ids: Array[StringName]
@export var available_product_ids: Array[StringName]

@export var starting_inventory: Dictionary

@export var waves: Array[WaveDefinition]
@export var objectives: Array[ObjectiveDefinition]
```

---

# 49. LevelDefinition additional fields

Optional:

```text
entrance_position
exit_position
fixed_checkout_position
tutorial_steps
unlocks
```

Use only when needed.

---

# 50. ObjectiveDefinition

Recommended:

```gdscript
class_name ObjectiveDefinition
extends Resource
```

Fields:

```gdscript
@export var id: StringName
@export var objective_type: StringName

@export var target_value: float

@export var is_mandatory: bool = true
@export var star_value: int = 0
```

---

# 51. Objective type IDs

Initial:

```text
serve_customers
min_satisfaction
min_profit
min_revenue
max_lost_sales
max_oos_events
```

Example:

```text
objective_type = min_satisfaction
target_value = 80
```

---

# 52. ObjectiveRuntimeState

Fields:

```text
objective_id
current_value
is_complete
```

Usually calculated from wave metrics.

Do not duplicate source metrics.

---

# 53. EconomyRuntimeState

Recommended:

```gdscript
class_name EconomyRuntimeState
extends RefCounted
```

Fields:

```gdscript
var cash: float

var lifetime_revenue: float
var lifetime_cogs: float
var lifetime_gross_profit: float
```

For current level only initially.

---

# 54. Economy mutation rule

All cash changes go through EconomyManager.

Methods:

```gdscript
can_afford(amount)
spend(amount, reason)
add_revenue(amount, reason)
```

Never:

```gdscript
economy.cash += 50
```

from random scripts.

---

# 55. Money precision

For hobby prototype:

```text
float
```

is acceptable.

Later if needed:

```text
store integer cents
```

Do not overcomplicate MVP.

---

# 56. SaleEvent

Recommended immutable record:

```gdscript
class_name SaleEvent
extends RefCounted
```

Fields:

```text
sale_id
wave_id
customer_id

items
revenue
cost
gross_profit

timestamp_sec
```

---

# 57. SaleLineItem

Fields:

```text
product_id
quantity
unit_price
unit_cost
line_revenue
line_cost
line_profit
```

---

# 58. LostSaleEvent

Fields:

```text
event_id
wave_id
customer_id
product_id

reason

quantity
lost_revenue
lost_margin

timestamp_sec
```

---

# 59. Lost sale reason IDs

```text
not_assorted
out_of_stock
unreachable
customer_abandoned
queue_abandon
```

---

# 60. OutOfStockEvent

Fields:

```text
event_id
wave_id
customer_id

product_id
fixture_instance_id
shelf_index

timestamp_sec
```

---

# 61. CustomerExitEvent

Fields:

```text
customer_id
wave_id

served
basket_value
satisfaction
frustration

timestamp_sec
```

---

# 62. WaveMetrics

Recommended runtime accumulator:

```gdscript
class_name WaveMetrics
extends RefCounted
```

Fields:

```gdscript
var customers_spawned: int = 0
var customers_served: int = 0
var customers_failed: int = 0

var revenue: float = 0.0
var cost_of_goods: float = 0.0
var gross_profit: float = 0.0

var items_sold: int = 0

var lost_sales_count: int = 0
var lost_sales_value: float = 0.0

var oos_events: int = 0

var satisfaction_total: float = 0.0
var queue_wait_total_sec: float = 0.0
```

---

# 63. Derived WaveMetrics

Do not store if easy to derive:

```text
average_satisfaction
service_rate
average_queue_time
```

Functions:

```gdscript
func get_average_satisfaction() -> float
func get_service_rate() -> float
func get_average_queue_time() -> float
```

---

# 64. ProductWaveMetrics

Per-product metrics:

```gdscript
class_name ProductWaveMetrics
extends RefCounted
```

Fields:

```text
product_id
units_requested
units_sold
lost_units

revenue
gross_profit

oos_events
```

---

# 65. Product service level

Derived:

```text
units_sold / units_requested
```

Handle zero requests safely.

---

# 66. CheckoutDefinition

Static data:

```gdscript
class_name CheckoutDefinition
extends Resource
```

Fields:

```text
service_base_sec
service_per_item_sec
queue_capacity
```

Can be part of FixtureDefinition later.

MVP may hardcode one checkout behavior.

---

# 67. CheckoutRuntimeState

Fields:

```text
fixture_instance_id
queue_customer_ids
current_customer_id
service_time_remaining
```

The checkout scene node owns this runtime state.

---

# 68. Queue state

Store customer IDs, not direct scene references in persistent data.

Runtime code can maintain node references separately.

---

# 69. HeatmapCellState

Future.

Fields:

```text
grid_x
grid_z

traffic_count
frustration_sum
sales_value
oos_count
```

Do not implement before metrics need it.

---

# 70. HeatmapRuntimeState

Dictionary:

```text
Vector2i -> HeatmapCellState
```

Separate maps may be simpler initially.

---

# 71. DemandProfile

Optional static/runtime helper.

Fields:

```text
product_id
base_weight
effective_weight
expected_low
expected_high
```

This can be calculated per wave.

---

# 72. Shopping list generation input

Required inputs:

```text
available product definitions
wave modifiers
customer type
random seed
```

Shopping list output:

```text
Array[ShoppingListItem]
```

Do not store a separate duplicated demand table after generation unless needed.

---

# 73. ProductRegistry

Recommended singleton/service:

```text
ProductRegistry
```

Responsibilities:

```text
load ProductDefinition resources
lookup by product_id
validate duplicate IDs
```

API:

```gdscript
get_product(id)
has_product(id)
get_all_products()
```

---

# 74. FixtureRegistry

Responsibilities:

```text
fixture definition lookup
duplicate ID validation
scene lookup
```

---

# 75. LevelRegistry

Responsibilities:

```text
level lookup
available level list
```

---

# 76. Registry rule

Registries contain definitions.

They do NOT own runtime gameplay state.

---

# 77. Manager ownership map

Recommended ownership:

```text
LevelManager
    -> current level definition

StoreManager
    -> fixture runtime state
    -> shelf runtime state
    -> product placements

InventoryManager
    -> warehouse stock
    -> ordered stock
    -> stock mutation API

CustomerManager
    -> live customer lifecycle

WaveManager
    -> current wave state

EconomyManager
    -> cash
    -> purchase/revenue mutations

ResultsManager
    -> wave metrics
    -> event accumulation

DeliveryManager
    -> delivery runtime state
```

---

# 78. Ownership matrix

| Data | Owner |
|---|---|
| ProductDefinition | ProductRegistry |
| FixtureDefinition | FixtureRegistry |
| LevelDefinition | LevelRegistry / LevelManager |
| FixtureInstanceState | StoreManager |
| ShelfState | StoreManager |
| ProductPlacementState | StoreManager |
| Warehouse stock | InventoryManager |
| Ordered stock | InventoryManager |
| CustomerRuntimeState | CustomerManager |
| WaveRuntimeState | WaveManager |
| Cash | EconomyManager |
| Deliveries | DeliveryManager |
| WaveMetrics | ResultsManager |

---

# 79. Runtime scene references

Runtime scene nodes may reference state objects.

Example:

```text
FixtureNode
    -> FixtureInstanceState

CustomerNode
    -> CustomerRuntimeState
```

State objects should not depend on visual nodes unless necessary.

---

# 80. Signal contract

Recommended cross-system signals:

```text
fixture_placed(instance_id)
fixture_removed(instance_id)

product_assigned(placement_id)
product_placement_changed(placement_id)

stock_changed(product_id, source_id, old_value, new_value)

customer_spawned(customer_id)
customer_item_failed(customer_id, product_id, reason)
customer_paid(customer_id, sale_event)
customer_exited(customer_id)

delivery_created(delivery_id)
delivery_arrived(delivery_id)

wave_started(wave_id)
wave_completed(wave_id)

cash_changed(old_cash, new_cash, reason)
```

---

# 81. Event direction rule

Prefer:

```text
Manager mutates authoritative state
↓
Manager emits signal
↓
UI/metrics/visuals react
```

Avoid UI mutating core state directly.

---

# 82. UI data rule

UI should read from managers/state.

UI should issue commands such as:

```text
place_fixture(...)
set_facings(...)
order_product(...)
open_store()
```

UI should not directly edit arrays/dictionaries.

---

# 83. Save system scope

Do not implement save/load in Prototype 0.01.

When added, save:

```text
version
current level
cash
fixture placements
product placements
facings
shelf stock
warehouse stock
ordered deliveries
progress/unlocks
```

Do not save:

```text
active NavigationAgent path
live animation state
temporary scene references
debug state
```

---

# 84. Save root schema

Recommended conceptual schema:

```json
{
  "save_version": 1,
  "current_level_id": "level_001",
  "cash": 1234.5,
  "store": {},
  "inventory": {},
  "deliveries": [],
  "progress": {}
}
```

---

# 85. StoreSaveData

Fields:

```text
fixtures[]
```

Each fixture:

```text
instance_id
definition_id
position
rotation_y
shelves[]
```

---

# 86. FixtureSaveData

Example:

```json
{
  "instance_id": "fixture_instance_000012",
  "definition_id": "gondola_basic_100",
  "position": [4.0, 0.0, 3.5],
  "rotation_y_deg": 90.0,
  "shelves": []
}
```

---

# 87. ShelfSaveData

Fields:

```text
shelf_index
side_index
placements[]
```

---

# 88. ProductPlacementSaveData

Fields:

```text
placement_id
product_id
horizontal_start_m
facings
shelf_stock
```

Do not save derived capacity if it can be recalculated.

---

# 89. InventorySaveData

Example:

```json
{
  "warehouse_stock": {
    "freshpop_cola_500": 24,
    "aquapure_water_500": 12
  },
  "ordered_stock": {
    "freshpop_cola_500": 12
  }
}
```

---

# 90. DeliverySaveData

Fields:

```text
delivery_id
supplier_id
product_id
quantity
arrival_wave_index
status
```

---

# 91. PlayerProgressSave

Fields:

```text
unlocked_level_ids
completed_level_ids
best_stars_by_level
unlocked_fixture_ids
unlocked_product_ids
```

Campaign progression only.

---

# 92. Save versioning

Every save contains:

```text
save_version
```

When schema changes:

```text
v1 -> v2 migration
```

Do not silently assume old saves match new schema.

---

# 93. Save serialization format

Recommended initial format:

```text
JSON
```

Advantages:

- inspectable,
- easy to debug,
- easy to version,
- simple for Cursor.

Later binary format is optional.

---

# 94. Resource vs JSON rule

Use `.tres` Resources for static definitions.

Use JSON for player save data.

This separation is recommended.

---

# 95. Static file layout

Recommended:

```text
data/
├── products/
│   ├── freshpop_cola_500.tres
│   └── aquapure_water_500.tres
├── fixtures/
│   └── gondola_basic_100.tres
├── customers/
│   └── regular_customer.tres
├── levels/
│   └── level_001.tres
└── suppliers/
```

---

# 96. Runtime script layout

Recommended:

```text
scripts/
├── products/
│   ├── product_definition.gd
│   └── product_registry.gd
├── fixtures/
│   ├── fixture_definition.gd
│   ├── fixture_instance_state.gd
│   ├── shelf_state.gd
│   └── product_placement_state.gd
├── customers/
│   ├── customer_type_definition.gd
│   ├── customer_runtime_state.gd
│   ├── shopping_list_item.gd
│   └── basket_item.gd
├── inventory/
│   ├── inventory_state.gd
│   └── inventory_manager.gd
├── economy/
│   ├── economy_runtime_state.gd
│   └── economy_manager.gd
├── waves/
│   ├── wave_definition.gd
│   ├── wave_runtime_state.gd
│   └── wave_manager.gd
├── levels/
│   ├── level_definition.gd
│   └── level_manager.gd
└── analytics/
    ├── wave_metrics.gd
    ├── sale_event.gd
    ├── lost_sale_event.gd
    └── results_manager.gd
```

---

# 97. Prototype 0.01 minimum data model

Do NOT implement every type from this document immediately.

Prototype 0.01 needs only:

```text
ProductDefinition
FixtureDefinition
FixtureInstanceState
ShelfState
ProductPlacementState

CustomerRuntimeState
ShoppingListItem
BasketItem

EconomyRuntimeState
WaveRuntimeState
```

Plus minimal managers.

---

# 98. Prototype 0.01 minimum ProductDefinition

Fields:

```text
id
display_name
width
height
depth
purchase_price
selling_price
```

Everything else can wait.

---

# 99. Prototype 0.01 minimum FixtureDefinition

Fields:

```text
id
display_name
width
depth
height
purchase_cost
```

---

# 100. Prototype 0.01 minimum ProductPlacementState

Fields:

```text
product_id
shelf_stock
```

Facings can be added in Prototype 0.02.

---

# 101. Prototype 0.01 minimum CustomerRuntimeState

Fields:

```text
runtime_id
state
shopping_list
basket
```

No archetype system required yet.

---

# 102. Prototype 0.01 minimum EconomyRuntimeState

Fields:

```text
cash
```

---

# 103. Prototype 0.01 minimum WaveRuntimeState

Fields:

```text
spawned
active_customers
completed
```

Only one customer is necessary.

---

# 104. Data validation strategy

Add validation where failure would be confusing.

Examples:

```text
duplicate definition ID
negative price
fixture dimensions <= 0
missing product reference
missing fixture definition
invalid shelf index
negative stock
facings <= 0
```

In debug:

```text
push_error
push_warning
```

Do not crash release builds for recoverable data errors.

---

# 105. Duplicate ID validation

Registries must detect duplicate IDs during initialization.

Example:

```gdscript
if definitions.has(definition.id):
    push_error("Duplicate product id: %s" % definition.id)
```

---

# 106. Missing reference behavior

If a saved product ID no longer exists:

```text
log warning
skip invalid placement
continue loading where possible
```

Do not hard crash entire save load.

---

# 107. Null-safety rule

Before using registry lookups:

```gdscript
var product := ProductRegistry.get_product(product_id)

if product == null:
    ...
```

Do not assume all external data is perfect.

---

# 108. Derived-data rule

Prefer calculating data instead of storing duplicate derived values.

Examples:

Do not store:

```text
margin
```

if:

```text
margin = selling_price - purchase_price
```

Do not store:

```text
service_rate
```

if derived from:

```text
units_sold / units_requested
```

Store only when needed for historical snapshots.

---

# 109. Historical snapshot rule

Events must capture values that may later change.

Example sale line should store:

```text
unit_price at purchase time
unit_cost at purchase time
```

because ProductDefinition may later change.

---

# 110. Product price rule

Current product price may initially live in ProductDefinition.

Later store-specific pricing should use:

```text
StoreProductState
```

Do not mutate the base ProductDefinition if prices become dynamic.

---

# 111. Future StoreProductState

Potential future class:

```text
product_id
current_selling_price
is_active
promotion_id
```

Not required now.

---

# 112. Assortment model

Initial assortment is derived from:

```text
products assigned to shelves
```

Later:

```text
StoreProductState.is_active
```

can separate assortment from placement.

MVP does not need that distinction.

---

# 113. Facings ownership

Facings belong to:

```text
ProductPlacementState
```

Not ProductDefinition.

The same product can have different facings in different fixtures.

---

# 114. Shelf stock ownership

Shelf stock belongs to:

```text
ProductPlacementState
```

because different locations can have different stock.

---

# 115. Warehouse stock ownership

Warehouse stock belongs to:

```text
InventoryState
```

indexed by product ID.

---

# 116. Customer basket ownership

Basket belongs to:

```text
CustomerRuntimeState
```

until checkout completes.

After payment:

```text
SaleEvent
```

becomes historical record.

---

# 117. Checkout authority

Checkout should NOT decrement stock.

Stock is decremented during pickup.

Checkout only:

```text
calculates basket value
creates sale
adds revenue
```

This prevents double stock mutations.

---

# 118. Lost sale authority

ResultsManager or CustomerManager may create LostSaleEvent.

Recommended:

```text
CustomerManager determines failure
ResultsManager records it
```

---

# 119. Event bus

Do not create a giant generic EventBus immediately.

Use direct manager signals first.

If signal routing becomes difficult later, introduce event aggregation carefully.

---

# 120. Autoload recommendations

Potential autoloads:

```text
ProductRegistry
FixtureRegistry
LevelRegistry
```

Maybe:

```text
GameManager
```

Avoid putting every manager in autoload.

Level-specific managers can live in Main scene.

---

# 121. Scene-bound manager recommendations

Prefer scene-bound:

```text
StoreManager
CustomerManager
WaveManager
InventoryManager
EconomyManager
ResultsManager
DeliveryManager
```

This simplifies level resets.

---

# 122. Level reset behavior

On level restart:

```text
destroy runtime state
reload LevelDefinition
reinitialize managers
```

Static registries persist.

---

# 123. Runtime ID generator

Create one simple service/helper.

Example:

```gdscript
RuntimeIdGenerator.next(&"customer")
```

Output:

```text
customer_000001
```

Do not use UUID unless needed.

Readable IDs help debugging.

---

# 124. Time representation

For active wave:

```text
float seconds since wave start
```

For save/progression:

use:

```text
wave index
level ID
```

Avoid real-world timestamps unless necessary.

---

# 125. Random seed storage

WaveRuntimeState should know:

```text
seed
```

Shopping list generation should use seeded RNG.

This enables:

```text
same wave comparison
debugging
replay
```

---

# 126. RandomNumberGenerator rule

Use a dedicated Godot `RandomNumberGenerator`.

Do not use global random calls if deterministic comparison matters.

---

# 127. Data equality rule

Definition equality:

```text
compare IDs
```

Runtime entity equality:

```text
compare runtime instance IDs
```

Do not compare entire Resources by object identity for gameplay logic.

---

# 128. Currency display

Store numeric data:

```text
float
```

UI formats:

```text
1,234.50
```

Currency symbol should be presentation-level data, not embedded in prices.

---

# 129. Unit system

Internal dimensions:

```text
meters
```

Display may later show:

```text
cm
m
```

Do not mix centimeters internally.

---

# 130. Coordinates

World position:

```text
Vector3
```

Build grid:

```text
Vector2i
```

Conversion handled by BuildManager.

---

# 131. Grid occupancy data

Future optimization:

```text
Dictionary[Vector2i, fixture_instance_id]
```

Do not rely on physics alone if placement becomes complex.

MVP can use physics overlap.

---

# 132. Navigation references

Do not serialize:

```text
NavigationAgent3D
RID
NavigationRegion IDs
```

These are runtime-only.

---

# 133. Visual asset references

Static definitions may reference:

```text
PackedScene
Texture2D
Material
```

For save data, store IDs/paths, not raw Resource objects.

---

# 134. Resource loading strategy

Initial:

```text
preload explicit .tres resources
or scan known directories
```

Prefer simple explicit registries first.

Do not build dynamic mod loading early.

---

# 135. Registry initialization order

Recommended:

```text
ProductRegistry
FixtureRegistry
CustomerTypeRegistry
LevelRegistry
```

Then level loading.

---

# 136. Dependency direction

Preferred:

```text
Definitions
    ↓
Managers
    ↓
Runtime State
    ↓
Scenes/UI
```

Avoid:

```text
ProductDefinition
depending on Customer scene
```

Static data should stay independent.

---

# 137. Circular dependency rule

Do not let managers depend on each other bidirectionally without need.

Example preferred:

```text
CustomerManager asks InventoryManager
CustomerManager emits sale-ready event
Checkout/Economy resolves sale
```

Avoid hidden mutual mutation.

---

# 138. Command methods

Recommended manager APIs:

StoreManager:

```text
place_fixture
remove_fixture
assign_product
set_facings
```

InventoryManager:

```text
take_from_shelf
add_to_shelf
add_to_warehouse
```

EconomyManager:

```text
spend
add_revenue
can_afford
```

WaveManager:

```text
prepare_wave
start_wave
complete_wave
```

---

# 139. Read methods

Examples:

```text
get_product_stock
get_fixture
get_placement
get_cash
get_current_wave
```

Keep reads side-effect free.

---

# 140. Result return pattern

For operations that can fail, return structured result.

Possible simple approach:

```gdscript
{
    "ok": false,
    "reason": "insufficient_cash"
}
```

Later create typed Result class only if useful.

---

# 141. Error reason IDs

Examples:

```text
insufficient_cash
invalid_position
overlap
blocked_entrance
missing_product
no_stock
invalid_facings
```

Use stable IDs, UI converts them to readable text.

---

# 142. Localization readiness

Do not hardcode UI text into data IDs.

Definitions should contain:

```text
display_name
```

For future localization:

```text
display_name_key
```

No localization system needed yet.

---

# 143. Metrics retention

For current wave:

store detailed events.

After level completion:

keep summary metrics unless replay requires full history.

Do not keep unlimited event history forever.

---

# 144. Replay readiness

If replay becomes important later, retain:

```text
seed
layout snapshot
wave definition
player pre-wave inventory
```

Not required now.

---

# 145. Testing fixtures

Create dedicated test definitions:

```text
test_product_01
test_fixture_01
test_customer_regular
```

Only if automated tests need them.

Do not pollute production data.

---

# 146. Test data folder

Recommended:

```text
tests/data/
```

---

# 147. Save location on macOS

Use Godot user path:

```text
user://
```

Example:

```text
user://savegame_v1.json
```

Do not hardcode macOS absolute save paths.

---

# 148. Debug dump

Useful command:

```text
dump_runtime_state()
```

Output:

```text
cash
fixtures
stock
active customers
wave state
```

Can write JSON to:

```text
user://debug_state.json
```

Only in debug builds.

---

# 149. Data audit tool

Later create:

```text
tools/validators/validate_game_data.gd
```

Checks:

```text
duplicate IDs
missing references
invalid prices
invalid dimensions
invalid level product references
invalid fixture references
```

---

# 150. Definition file naming

Match file name to ID where practical.

Examples:

```text
freshpop_cola_500.tres
gondola_basic_100.tres
regular_customer.tres
level_001.tres
```

---

# 151. Product data example in GDScript

Conceptual:

```gdscript
var cola := ProductDefinition.new()

cola.id = &"freshpop_cola_500"
cola.display_name = "FreshPop Cola 500 ml"

cola.width_m = 0.065
cola.height_m = 0.22
cola.depth_m = 0.065

cola.purchase_price = 1.20
cola.selling_price = 2.50
cola.base_demand = 0.8
```

Prefer `.tres` content assets over creating every product in code.

---

# 152. Fixture runtime example

```text
FixtureInstanceState

instance_id:
fixture_instance_000012

definition_id:
gondola_basic_100

position:
(4.0, 0.0, 3.5)

rotation_y_deg:
90

shelves:
8 runtime shelf states
```

---

# 153. Placement runtime example

```text
placement_id:
placement_000033

product_id:
freshpop_cola_500

fixture:
fixture_instance_000012

side:
0

shelf:
2

facings:
3

units_deep:
5

capacity:
15

shelf_stock:
12
```

---

# 154. Customer runtime example

```text
customer_id:
customer_000014

type:
regular_customer

state:
moving_to_product

shopping_list:
FreshPop Cola x1
AquaPure Water x1

basket:
FreshPop Cola x1

frustration:
10

satisfaction:
90
```

---

# 155. Wave runtime example

```text
wave:
level_001_wave_02

spawned:
15 / 20

active:
7

completed:
8

elapsed:
44.2 sec
```

---

# 156. Economy example

Before:

```text
cash = 100.00
```

Sale:

```text
FreshPop Cola
price = 2.50
cost = 1.20
```

After:

```text
cash = 102.50

wave revenue += 2.50
wave COGS += 1.20
wave gross profit += 1.30
```

---

# 157. Price vs purchase cost timing

When ordering stock:

```text
cash decreases by purchase cost
```

When reporting gross profit:

```text
revenue - COGS sold
```

Do not subtract purchase cost twice.

---

# 158. Inventory accounting note

For MVP, precise accounting is less important than consistent gameplay.

Document the chosen rule in code comments.

Recommended:

```text
cash cost recognized at order time
gross profit report uses product cost for sold units
```

This may mean cash flow and profit differ, which is acceptable.

---

# 159. Delivery example

```text
delivery_id:
delivery_000004

product:
freshpop_cola_500

quantity:
24

status:
in_transit

arrival_wave:
3
```

---

# 160. Level 1 example model

```text
level_001

Store:
10 x 12

Starting cash:
10,000

Available fixtures:
gondola_basic_100
checkout_basic_01

Products:
freshpop_cola_500
aquapure_water_500

Wave 1:
10 customers

Objective:
serve 8 customers
```

---

# 161. Data evolution roadmap

Prototype 0.01:

```text
minimal product
minimal fixture
minimal shelf
minimal customer
minimal economy
minimal wave
```

Prototype 0.02:

```text
facings
multiple products
customer satisfaction
lost sales
product metrics
```

Prototype 0.03:

```text
warehouse
orders
deliveries
OOS event history
```

Prototype 0.04:

```text
customer types
objectives
star ratings
queue metrics
```

---

# 162. Anti-patterns

Do NOT do this:

```text
Product.gd stores current shelf stock
Shelf.gd stores its own ProductDefinition copy
Customer.gd changes cash directly
UI directly edits warehouse dictionary
Level code hardcodes all product prices
```

---

# 163. Preferred pattern

```text
ProductDefinition = static product data

ProductPlacementState = shelf assignment + shelf stock

InventoryManager = warehouse/ordered stock

CustomerManager = customer lifecycle

EconomyManager = money

ResultsManager = metrics/events
```

---

# 164. Cursor rules

Cursor must:

1. read this document before adding new gameplay state,
2. use existing owners instead of inventing duplicates,
3. prefer stable IDs,
4. separate definitions from runtime state,
5. keep save data separate from scene nodes,
6. avoid speculative future fields,
7. implement only fields needed by current prototype,
8. document any deliberate deviation.

---

# 165. Cursor implementation prompt

Use this when implementing the first data layer:

```text
Read SHOPYFENDER_DATA_MODEL.md, SHOPYFENDER_GAME_LOGIC.md and SHOPYFENDER_MASTER_SPEC.md completely.

Implement only the minimum data model required for Prototype 0.01.

Create:

1. ProductDefinition
2. FixtureDefinition
3. FixtureInstanceState
4. ShelfState
5. ProductPlacementState
6. ShoppingListItem
7. BasketItem
8. CustomerRuntimeState
9. EconomyRuntimeState
10. WaveRuntimeState

Do NOT implement:
- suppliers,
- deliveries,
- save/load,
- customer archetypes,
- heatmaps,
- advanced metrics,
- promotions.

Requirements:
- use stable StringName IDs,
- keep static definitions separate from runtime state,
- avoid duplicated authoritative stock,
- keep code small and explicit,
- use typed GDScript where practical,
- add lightweight validation for invalid IDs and negative values.

Create two example data assets:
- freshpop_cola_500
- gondola_basic_100

At the end report:
- files created,
- files changed,
- data ownership decisions,
- how to test,
- known limitations.

Do not continue to other systems automatically.
```

---

# 166. Final data-model rule

Every gameplay value should answer this question:

> Who owns the authoritative version of this data?

If that answer is unclear, the model is not ready.

The ShopyFender data model should remain:

```text
simple
explicit
data-driven
debuggable
serializable
```

rather than academically perfect.
