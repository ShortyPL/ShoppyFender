# ShopyFender — Game Logic Specification

> **Document type:** Gameplay logic / simulation specification  
> **Project:** ShopyFender  
> **Development environment:** Cursor Pro on macOS  
> **Engine:** Godot 4.x  
> **Language:** GDScript  
> **Status:** v0.1  
> **Purpose:** Source of truth for how the game simulation should behave.

---

# 1. Core idea

ShopyFender is a 3D retail strategy and optimization game.

The player designs a store, configures shelves and products, manages inventory and deliveries, opens the store, then observes how waves of customers interact with that design.

The game loop is:

```text
PLAN
↓
BUILD
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
SALES / OOS / QUEUES / LOST SALES
↓
RESULTS
↓
OPTIMIZE
↓
NEXT WAVE
```

The main challenge is not manual labor.

The main challenge is optimizing:

- store layout,
- product placement,
- shelf capacity,
- facings,
- stock,
- deliveries,
- customer flow,
- checkout capacity.

---

# 2. Main game states

The game should operate using explicit high-level states.

```text
SETUP
BUILD
PLANNING
PRE_WAVE
SIMULATION
RESULTS
PAUSED
LEVEL_COMPLETE
LEVEL_FAILED
```

## SETUP

Used when loading a level.

Responsibilities:

- create store,
- load level definition,
- load products,
- load available fixtures,
- set starting cash,
- place fixed entrance/exit,
- initialize wave data.

Transition:

```text
SETUP -> BUILD
```

---

## BUILD

Player may:

- place fixtures,
- move fixtures,
- rotate fixtures,
- delete fixtures,
- inspect fixture cost,
- inspect free floor space.

Restrictions:

- fixtures cannot overlap,
- entrance cannot be blocked,
- exit cannot be blocked,
- checkout must remain reachable,
- customer paths should remain valid.

Transition:

```text
BUILD -> PLANNING
```

---

## PLANNING

Player may:

- assign products to fixtures,
- change facings,
- inspect shelf capacity,
- inspect stock,
- order products,
- inspect forecast demand,
- inspect expected out-of-stock risk.

Transition:

```text
PLANNING -> PRE_WAVE
```

---

## PRE_WAVE

Short preparation phase.

The game calculates:

- expected demand,
- shelf capacity,
- current available stock,
- active deliveries,
- customer composition,
- obvious warnings.

Example warnings:

```text
WARNING:
FreshPop Cola expected demand: 24
Available stock: 10

High OOS risk
```

Player may still return to planning.

Transition:

```text
PRE_WAVE -> SIMULATION
```

---

## SIMULATION

Store is open.

Major building changes are disabled.

Customers:

- spawn,
- enter,
- search for products,
- move through store,
- take products,
- queue,
- pay,
- exit.

Game tracks:

- sales,
- profit,
- lost sales,
- satisfaction,
- out-of-stock events,
- queue time,
- path distance,
- customer failures.

Transition:

```text
SIMULATION -> RESULTS
```

when the wave is complete.

---

## RESULTS

Show performance.

Player receives:

- revenue,
- profit,
- satisfaction,
- lost sales,
- OOS stats,
- customer flow feedback,
- major problems.

Then player chooses:

```text
NEXT WAVE
RETRY
RETURN TO BUILD
```

---

# 3. Level logic

Every level is data-driven.

A level contains:

```text
level_id
store_width
store_depth
starting_cash

entrance_position
exit_position
checkout_position

available_fixtures
available_products

starting_stock

waves

objectives

star_thresholds

unlocks
```

Example:

```text
level_001

Store:
10m x 12m

Starting cash:
10,000

Available fixture:
gondola_basic_100

Available products:
freshpop_cola_500
aquapure_water_500

Wave 1:
10 customers

Objectives:
Serve 8 customers
Satisfaction >= 70%
```

---

# 4. Store coordinate system

Use world coordinates in meters.

Recommended grid:

```text
0.5 m
```

Fixture placement:

```text
snapped_x = round(world_x / grid_size) * grid_size
snapped_z = round(world_z / grid_size) * grid_size
```

Rotation:

```text
0°
90°
180°
270°
```

---

# 5. Fixture placement logic

A fixture can be placed only if all placement rules pass.

Pseudo logic:

```text
function can_place_fixture(fixture, position, rotation):

    if overlaps_other_fixture:
        return false

    if overlaps_wall:
        return false

    if blocks_entrance:
        return false

    if blocks_exit:
        return false

    if outside_store_bounds:
        return false

    return true
```

Later:

```text
if causes_unreachable_checkout:
    warning or reject
```

For early prototypes, path blocking can be checked after placement rather than before.

---

# 6. Fixture data

Fixture definition:

```text
fixture_id
display_name

width
depth
height

purchase_cost
sell_value

fixture_type

shelf_count

sides
```

Example:

```text
fixture_id:
gondola_basic_100

width:
1.0

depth:
0.5

height:
1.8

cost:
400

shelves:
4

sides:
2
```

---

# 7. Shelf logic

A fixture contains shelves.

Each shelf has:

```text
shelf_id
width
height
depth

assigned_products

used_width
available_width
```

A shelf can contain multiple product placements.

Example:

```text
Shelf 1

[COLA][COLA][COLA][WATER][WATER]
```

---

# 8. Product placement logic

A product placement contains:

```text
product_id
fixture_id
shelf_id

start_position

facings

units_deep

capacity

current_shelf_stock
```

Capacity formula:

```text
capacity =
facings
*
units_deep
*
units_vertical
```

For MVP:

```text
units_vertical = 1
```

Simplified formula:

```text
capacity = facings * units_deep
```

---

# 9. Facings logic

Facings define how much horizontal shelf width a product uses.

Required shelf width:

```text
required_width =
product_width * facings
```

Placement is valid if:

```text
required_width <= available_shelf_width
```

Example:

```text
Product width = 0.07m
Facings = 4

Required width = 0.28m
```

---

# 10. Units deep

Shelf depth controls how many units fit behind one facing.

Formula:

```text
units_deep =
floor(
shelf_depth / product_depth
)
```

Example:

```text
Shelf depth = 0.40
Bottle depth = 0.07

units_deep = 5
```

Capacity:

```text
facings = 3
units_deep = 5

capacity = 15
```

---

# 11. Product data

Each product should contain:

```text
product_id
display_name

brand
category

package_type

width
height
depth

purchase_price
selling_price

base_demand
popularity

units_per_case
```

Possible future fields:

```text
premium_score
impulse_score
substitution_group
temperature_requirement
shelf_life
```

---

# 12. Product stock layers

Long-term system:

```text
ORDERED STOCK
↓
WAREHOUSE STOCK
↓
SHELF STOCK
↓
CUSTOMER PURCHASE
```

Prototype simplification:

```text
STORE STOCK
↓
SHELF STOCK
↓
PURCHASE
```

---

# 13. Shelf stock logic

A shelf placement has:

```text
capacity
current_stock
```

Stock cannot exceed capacity.

```text
current_stock <= capacity
```

When customer takes one unit:

```text
current_stock -= 1
```

If:

```text
current_stock == 0
```

the product is out of stock on shelf.

---

# 14. Inventory logic

Inventory manager tracks:

```text
warehouse_stock
shelf_stock
ordered_stock
```

Total stock:

```text
total_stock =
warehouse_stock
+
sum(all shelf stock)
+
ordered_stock
```

Available stock:

```text
available_stock =
warehouse_stock
+
sum(all shelf stock)
```

---

# 15. Replenishment logic

Later version.

When shelf stock drops below a threshold:

```text
if shelf_stock <= reorder_to_shelf_threshold:
    create_replenishment_task()
```

A worker moves units:

```text
warehouse -> shelf
```

For MVP, shelf stock can be replenished automatically between waves.

---

# 16. Ordering logic

Player chooses:

```text
product
quantity
delivery_type
```

Order cost:

```text
order_cost =
purchase_price
*
quantity
+
delivery_fee
```

Order allowed only if:

```text
cash >= order_cost
```

On order:

```text
cash -= order_cost
ordered_stock += quantity
```

---

# 17. Delivery logic

Delivery object:

```text
delivery_id
product_id
quantity
arrival_time
delivery_type
status
```

Statuses:

```text
ORDERED
IN_TRANSIT
ARRIVED
CANCELLED
```

When delivery arrives:

```text
ordered_stock -= quantity
warehouse_stock += quantity
```

For MVP without warehouse:

```text
ordered_stock -= quantity
store_stock += quantity
```

---

# 18. Delivery types

Example:

## Standard

```text
delivery_fee = low
arrival = next_wave
```

## Express

```text
delivery_fee = high
arrival = immediate
```

---

# 19. Customer generation

Each wave defines:

```text
customer_count
spawn_interval
customer_types
demand_modifiers
```

Example:

```text
Wave 2

Customers:
20

Spawn interval:
1.5 sec

Customer mix:
80% regular
20% impatient
```

---

# 20. Customer data

Customer:

```text
customer_id

customer_type

shopping_list

basket

patience

frustration

satisfaction

money_spent

state
```

---

# 21. Customer state machine

Recommended state machine:

```text
SPAWNING
ENTERING
CHOOSING_NEXT_PRODUCT
SEARCHING_PRODUCT
MOVING_TO_PRODUCT
PICKING_PRODUCT
MOVING_TO_CHECKOUT
WAITING_IN_QUEUE
PAYING
LEAVING
FINISHED
FAILED
```

---

# 22. Customer shopping list generation

Shopping list length may be random.

Example:

```text
min_items = 1
max_items = 4
```

Pseudo:

```text
item_count = random(min_items, max_items)

for i in item_count:
    choose product using demand weights
```

Product weight:

```text
weight =
base_demand
*
wave_modifier
*
customer_type_modifier
```

---

# 23. Demand model

Demand is a probability weight, not exact sales.

Example:

```text
base_demand:
0.8
```

Wave modifiers:

```text
soft_drinks +30%
snacks +20%
```

Effective demand:

```text
effective_demand =
base_demand
*
category_modifier
*
customer_modifier
```

---

# 24. Customer product search

For every requested item:

```text
find all active shelf placements
where product_id == requested_product
and current_stock > 0
```

If none exist:

```text
lost_sale += 1
frustration += unavailable_penalty
```

Customer then:

```text
continue shopping
or
leave
```

depending on frustration.

---

# 25. Selecting a shelf location

If multiple locations sell the same product:

choose based on:

```text
shortest navigation distance
```

Later:

```text
visibility
promotional position
endcap bonus
customer behavior
```

MVP:

```text
nearest reachable placement
```

---

# 26. Navigation logic

Customer path:

```text
Entrance
↓
Product A
↓
Product B
↓
Checkout
↓
Exit
```

Godot NavigationAgent3D handles pathfinding.

If no path:

```text
navigation_failures += 1
customer.frustration += path_failure_penalty
```

Customer may leave.

---

# 27. Product pickup

When customer reaches shelf:

Check again:

```text
current_stock > 0
```

because another customer may have taken the final unit.

If yes:

```text
current_stock -= 1
basket.add(product)
```

If no:

```text
lost_sale += 1
out_of_stock_event += 1
frustration += oos_penalty
```

---

# 28. Race condition logic

Multiple customers may target the same product.

Never reserve stock during search in the MVP.

Instead:

```text
customer finds product
↓
walks toward shelf
↓
stock may change
↓
check stock again on arrival
```

This creates natural OOS pressure.

Later optional:

```text
soft reservation
```

not required.

---

# 29. Out-of-stock event

An OOS event occurs when:

```text
customer wants product
AND
product exists in assortment
AND
no reachable shelf placement has stock
```

Track:

```text
product_id
wave_id
timestamp
customer_id
```

---

# 30. Lost sale

Lost sale occurs when a customer intended to buy an item but did not.

Reasons:

```text
NOT_ASSORTED
OUT_OF_STOCK
UNREACHABLE
CUSTOMER_ABANDONED
QUEUE_ABANDON
```

Lost sale record:

```text
product_id
reason
estimated_revenue
estimated_margin
```

---

# 31. Customer frustration

Start:

```text
frustration = 0
```

Example penalties:

```text
product unavailable +15
out of stock +20
long path +5
queue wait threshold +10
blocked navigation +25
```

Customer leaves if:

```text
frustration >= leave_threshold
```

Example:

```text
leave_threshold = 100
```

---

# 32. Customer satisfaction

Simplified model:

```text
satisfaction =
100
-
frustration
```

Clamp:

```text
0..100
```

Later add positive bonuses:

```text
all items found
short queue
short walking path
promotions
```

---

# 33. Customer completion

Customer is considered served if:

```text
customer reaches checkout
AND
purchases at least one item
AND
exits successfully
```

Optional later:

```text
zero-item customers count as failed
```

---

# 34. Checkout logic

Checkout has:

```text
queue
service_time
```

When customer reaches checkout:

```text
queue.push(customer)
```

First customer:

```text
WAITING
↓
PAYING
↓
LEAVING
```

Service time MVP:

```text
1.5 seconds + 0.3 seconds per item
```

---

# 35. Queue logic

Each checkout tracks:

```text
queue_length
estimated_wait
```

Customer selects checkout:

```text
checkout with shortest queue
```

MVP may have one checkout only.

---

# 36. Payment logic

Basket value:

```text
basket_total =
sum(product.selling_price)
```

Profit:

```text
basket_profit =
sum(product.selling_price - product.purchase_price)
```

On payment:

```text
cash += basket_total
wave_revenue += basket_total
wave_profit += basket_profit
```

Important:

Purchase cost may already have been deducted at ordering time.

For reporting:

```text
gross_profit =
sales_revenue - cost_of_goods_sold
```

---

# 37. Cash logic

Cash changes through:

```text
+ sales
- fixtures
- product orders
- delivery fees
- future salaries
- future upgrades
```

Player cannot buy if:

```text
cash < cost
```

---

# 38. Fixture purchase logic

On fixture placement:

```text
cash -= fixture.purchase_cost
```

If fixture removed:

MVP:

```text
refund = purchase_cost * 0.5
```

Later configurable.

---

# 39. Wave lifecycle

Wave lifecycle:

```text
PREPARE
↓
COUNTDOWN
↓
SPAWNING
↓
ACTIVE
↓
NO_MORE_SPAWNS
↓
WAIT_FOR_CUSTOMERS_TO_EXIT
↓
COMPLETE
```

Wave ends when:

```text
all scheduled customers spawned
AND
active_customer_count == 0
```

---

# 40. Wave difficulty

Difficulty can increase through:

```text
more customers
shorter spawn interval
larger baskets
higher demand concentration
lower patience
more archetypes
higher objectives
```

Do not rely only on increasing customer count.

---

# 41. Wave modifiers

Examples:

```text
SATURDAY_RUSH
PAYDAY
HEATWAVE
HOLIDAY
PROMOTION_DAY
SUPPLIER_DELAY
```

Example:

```text
HEATWAVE

Water demand x1.5
Soft Drink demand x1.4
```

---

# 42. Results calculation

At end of wave calculate:

```text
customers_spawned
customers_served
customers_failed

revenue
profit

items_sold

lost_sales_count
lost_sales_value

oos_events

average_satisfaction

average_queue_time

average_path_length
```

---

# 43. Satisfaction score

Wave satisfaction:

```text
average_satisfaction =
sum(customer.satisfaction)
/
customers_spawned
```

Clamp:

```text
0..100
```

---

# 44. Service rate

```text
service_rate =
customers_served
/
customers_spawned
```

Example:

```text
27 / 30 = 90%
```

---

# 45. Lost sales value

For each lost product:

```text
lost_revenue += selling_price
lost_margin += selling_price - purchase_price
```

This should be visible to player.

Example:

```text
FreshPop Cola

Lost units:
12

Lost revenue:
30.00

Cause:
Out of stock
```

---

# 46. Product performance

Per product track:

```text
units_requested
units_sold
lost_units

revenue
gross_profit

oos_events
```

Useful ratio:

```text
service_level =
units_sold
/
units_requested
```

---

# 47. Fixture performance

Later:

```text
fixture_revenue
fixture_profit
fixture_units_sold
```

Possible metric:

```text
revenue_per_meter
```

---

# 48. Shelf productivity

Future:

```text
shelf_productivity =
revenue
/
used_shelf_width
```

Example:

```text
Revenue:
120

Used shelf width:
1.5m

Productivity:
80 / m
```

This can become a core optimization KPI later.

---

# 49. Floor productivity

Future:

```text
sales_per_square_meter =
revenue
/
store_sales_area
```

Useful at higher levels.

---

# 50. Store performance score

Optional combined score:

```text
performance_score =
profit_score
+
satisfaction_score
+
service_score
-
lost_sales_penalty
-
oos_penalty
```

Do not make this opaque.

Primary KPIs should still be visible separately.

---

# 51. Objectives

Objectives are data-driven.

Examples:

```text
SERVE_CUSTOMERS
MIN_SATISFACTION
MIN_PROFIT
MAX_LOST_SALES
MAX_OOS
MIN_REVENUE
```

Example:

```text
Serve >= 25 customers
Satisfaction >= 80
Profit >= 300
```

---

# 52. Star logic

Example:

```text
1 star:
complete primary objective

2 stars:
primary + performance threshold

3 stars:
primary + high performance threshold
```

Example:

```text
★ Serve 25 customers

★★ Satisfaction >= 80%

★★★ Profit >= 300
```

---

# 53. Level completion

Level complete if:

```text
mandatory_objectives_met == true
```

Stars are optional performance goals.

---

# 54. Level failure

Possible failure conditions:

```text
cash <= bankruptcy_threshold
mandatory objective impossible
reputation reaches zero
```

Early version:

Prefer soft failure.

Example:

```text
Wave failed
Retry available
```

Avoid harsh permanent punishment.

---

# 55. Customer archetypes

Later.

## Regular

```text
patience = 100
basket_size = normal
```

## Impatient

```text
patience = 60
queue_penalty x1.5
```

## Family

```text
basket_size +2
movement_speed lower
```

## Bargain Hunter

```text
prefers cheaper products
```

## Premium

```text
prefers higher priced products
```

## Impulse

```text
chance to buy additional visible product
```

---

# 56. Product substitution

Later.

If desired product unavailable:

```text
search substitution_group
```

Example:

```text
FreshPop Cola unavailable

Possible substitute:
FizzUp Cola
```

Substitution chance depends on customer type.

MVP:

No substitutions.

---

# 57. Visibility

Later.

Product visibility can influence demand.

Example:

```text
visibility_score =
eye_level_bonus
+
facing_bonus
+
endcap_bonus
```

Do not implement before basic facings work.

---

# 58. Facing demand bonus

Possible later formula:

```text
facing_visibility_bonus =
min(1.0 + facings * 0.05, 1.25)
```

But facings should primarily affect capacity first.

Avoid making them unrealistically increase demand too much.

---

# 59. Adjacency logic

Later.

Product adjacency:

```text
pasta near sauce
chips near soda
cereal near milk
```

Bonus:

```text
cross_sell_probability += adjacency_bonus
```

Not required for MVP.

---

# 60. Impulse buying

Later.

When customer passes promotional or checkout products:

```text
if random() < impulse_probability:
    add product to basket
```

Depends on:

```text
product impulse_score
customer impulse_modifier
placement type
```

---

# 61. Heatmaps

Important future feature.

Track navigation samples.

Each customer periodically reports:

```text
position
timestamp
state
```

Aggregate into grid cells.

Heatmap types:

```text
TRAFFIC
FRUSTRATION
SALES
OOS
QUEUE
```

---

# 62. Traffic heatmap

For each grid cell:

```text
traffic_count += 1
```

Render:

```text
low traffic -> low intensity
high traffic -> high intensity
```

Use this to reveal bottlenecks.

---

# 63. Frustration heatmap

When frustration increases:

```text
frustration_map[cell] += frustration_delta
```

This can reveal:

- hard-to-find items,
- blocked areas,
- queue pressure.

---

# 64. Lost-sales analysis

After wave, group lost sales by:

```text
product
category
reason
location
```

Example:

```text
FreshPop Cola

12 lost units

8 OUT_OF_STOCK
3 UNREACHABLE
1 CUSTOMER_ABANDONED
```

---

# 65. Recommendations system

Game may suggest simple recommendations.

Rules-based only.

Examples:

```text
if product service_level < 70%
and oos_events > threshold:

suggest:
Increase stock or facings
```

Example:

```text
if queue_wait > target:

suggest:
Add checkout capacity
```

No AI API needed.

---

# 66. Product forecast

Before wave:

```text
expected_requests =
customer_count
*
normalized_demand_probability
```

Simple approximation is enough.

Example:

```text
Expected demand:
FreshPop Cola = 18–24 units
```

Show a range rather than fake precision.

---

# 67. OOS risk

Simple forecast:

```text
if available_units >= expected_high:
    LOW

elif available_units >= expected_low:
    MEDIUM

else:
    HIGH
```

---

# 68. Build-to-simulation transition

Before store opens, validate:

```text
entrance exists
exit exists
checkout exists
checkout reachable
at least one product is assigned
```

If not:

prevent opening and show reason.

---

# 69. Customer spawn logic

Spawn location:

```text
entrance_spawn_point
```

Spawn spacing:

avoid spawning multiple NPCs in exactly same position.

Possible:

```text
small random offset
```

---

# 70. Customer movement speed

MVP:

```text
normal speed = 2.5 m/s
```

Later archetypes modify speed.

---

# 71. Customer product ordering

Shopping list order may be:

MVP:

```text
nearest-next-product
```

This avoids stupid backtracking.

Logic:

```text
from current position:
choose remaining requested product
with shortest path
```

Later:

customer preferences may alter route.

---

# 72. Customer basket

Basket is logical data only in MVP.

No need for visible basket model.

Structure:

```text
basket_items = [
product_id,
product_id
]
```

---

# 73. Multiple units

Later shopping list can request:

```text
cola x2
water x3
```

MVP:

Each request = 1 unit.

---

# 74. Time system

Wave simulation runs in real time.

Later:

```text
Pause
1x
2x
4x
```

Simulation logic should use delta time.

Avoid tying logic directly to frame rate.

---

# 75. Randomness

Use seeded random generation when useful.

Benefits:

- easier debugging,
- replay comparisons.

Store:

```text
wave_seed
```

Possible:

```text
same seed = same customer demand pattern
```

Useful for optimization gameplay.

---

# 76. Fairness principle

The game should avoid hidden unfairness.

Before a wave, player should have enough information to make a reasonable decision.

Show:

```text
expected customer count
category demand modifiers
major wave modifier
```

Do not reveal exact future purchases.

---

# 77. Optimization loop

The core learning loop:

```text
Player makes decision
↓
Simulation produces consequences
↓
Game explains consequences
↓
Player changes design
↓
Performance improves or worsens
```

Every major system should support this loop.

---

# 78. Prototype 0.01 logic

Prototype 0.01 needs ONLY:

```text
one store
one shelf
one product
one customer
one checkout
one sale
```

Logic:

```text
START

cash = 100

player places shelf

product assigned:
FreshPop Cola

shelf stock = 5

OPEN STORE

spawn customer

shopping list:
FreshPop Cola

customer enters

customer finds shelf

customer moves to shelf

if shelf_stock > 0:
    shelf_stock -= 1
    basket += cola

customer moves to checkout

basket_total = 2.50

cash += 2.50

customer moves to exit

customer removed

wave complete
```

---

# 79. Prototype 0.02 logic

Add:

```text
5 products
10 customers
multiple shelves
facings
capacity
basic satisfaction
lost sales
```

---

# 80. Prototype 0.03 logic

Add:

```text
orders
stock
deliveries
OOS
lost sales value
```

---

# 81. Prototype 0.04 logic

Add:

```text
waves
queue
customer archetypes
results screen
objectives
stars
```

---

# 82. Data ownership

Recommended ownership:

```text
LevelManager
    owns level definition

StoreManager
    owns store layout

InventoryManager
    owns stock

CustomerManager
    owns customer lifecycle

WaveManager
    owns wave state

EconomyManager
    owns cash/revenue/profit

ResultsManager
    owns wave metrics
```

Do not create managers before needed.

---

# 83. Signal flow

Recommended Godot signals.

Examples:

```text
fixture_placed
product_assigned
stock_changed

customer_spawned
customer_failed_item
customer_paid
customer_exited

wave_started
wave_completed

cash_changed
sale_completed
```

Systems should communicate through signals where it improves decoupling.

---

# 84. Sale event

Sale record:

```text
sale_id
customer_id
wave_id

items
revenue
cost
gross_profit

timestamp
```

Useful for results and future analytics.

---

# 85. Lost sale event

```text
lost_sale_id
customer_id
product_id
wave_id

reason

lost_revenue
lost_margin
```

---

# 86. OOS event

```text
oos_event_id
product_id
fixture_id
shelf_id
wave_id
timestamp
```

---

# 87. Metrics accumulator

During wave:

```text
WaveMetrics

customers_spawned
customers_served

revenue
gross_profit

items_sold

lost_sales

oos_events

total_satisfaction

queue_wait_total
```

Do not repeatedly scan all historic events to render HUD.

Update counters as events happen.

---

# 88. HUD logic

During simulation show only important live metrics:

```text
Cash
Wave progress
Customers active
Sales
Satisfaction
OOS alerts
```

Avoid excessive numbers.

---

# 89. Alerts

Examples:

```text
FreshPop Cola OUT OF STOCK
```

```text
Checkout queue is growing
```

```text
Customer cannot reach product
```

Alerts should not spam continuously.

Use cooldown/grouping.

---

# 90. Path failure logic

If NavigationAgent cannot reach target:

```text
retry alternative target
```

If no alternative:

```text
mark requested item UNREACHABLE
frustration += penalty
continue shopping
```

If checkout unreachable:

```text
customer leaves
failed_customer += 1
```

---

# 91. Invalid product placement

Player cannot assign product if:

```text
product height > shelf clearance
```

or:

```text
product width * facings > free shelf width
```

For MVP, height constraints may be skipped.

Width should be implemented first.

---

# 92. Shelf auto-layout

MVP may visually position products automatically.

Example:

```text
product mesh x position
=
shelf_start
+
used_width
+
product_width / 2
```

Repeat mesh:

```text
for facing in facings:
    for depth in units_deep:
        spawn_visual_instance()
```

For performance, only visible front units may be rendered later.

---

# 93. Product visual stock

Do not necessarily render all physical units.

MVP:

render visible units matching current stock where easy.

Later:

visual representation can be approximate.

Simulation truth = data.

Visuals should never be the authoritative stock state.

---

# 94. Game economy fairness

Player should be able to recover from mistakes.

Avoid early deadlocks such as:

```text
no cash
no stock
cannot make sales
```

Possible protections:

- cheap emergency delivery,
- partial fixture refund,
- retry wave,
- restart level.

---

# 95. Difficulty scaling

Prefer complexity scaling over stat inflation.

Good:

```text
new customer type
new category
new delivery constraint
new layout problem
```

Less good:

```text
same customers x10
```

---

# 96. Tutorial logic

Teach one mechanic at a time.

Example:

```text
Level 1:
place shelf

Level 2:
assign product

Level 3:
facings

Level 4:
stock

Level 5:
deliveries
```

Do not introduce every mechanic on first level.

---

# 97. Save logic

Later.

Save only outside active wave if possible.

Save:

```text
level progress
cash
store layout
fixtures
product assignments
facings
inventory
deliveries
```

Do not save transient navigation state.

---

# 98. Deterministic testing mode

Add debug option later:

```text
fixed_seed = true
```

Then:

```text
same wave
same shopping lists
same spawn schedule
```

This allows meaningful layout comparisons.

---

# 99. Replay comparison

Future differentiator.

Player could compare:

```text
Layout A
Revenue 1200
Satisfaction 76
Lost Sales 180
```

versus:

```text
Layout B
Revenue 1380
Satisfaction 88
Lost Sales 60
```

This directly reinforces optimization gameplay.

---

# 100. Critical rule for Cursor

The simulation should be built in this order:

```text
1. one customer completes one purchase
2. multiple customers
3. stock
4. lost sales
5. facings
6. waves
7. queue
8. deliveries
9. metrics
10. optimization feedback
```

Do not skip directly to advanced systems.

---

# 101. Cursor implementation rule

Before implementing any game-logic feature:

1. Read this document.
2. Read SHOPYFENDER_MASTER_SPEC.md.
3. Inspect existing code.
4. Implement the smallest working version.
5. Do not invent unrelated scope.
6. Keep logic data-driven.
7. Add debug output for important state changes.
8. Keep the project runnable.

---

# 102. First Cursor prompt for game logic

Use this prompt when beginning implementation:

```text
Read SHOPYFENDER_GAME_LOGIC.md and SHOPYFENDER_MASTER_SPEC.md completely.

Treat both files as project sources of truth.

Implement only the minimum game logic needed for Prototype 0.01.

Required simulation:

1. One product definition.
2. One shelf with stock.
3. One customer with a one-item shopping list.
4. Customer enters the store.
5. Customer finds the shelf containing the required product.
6. Customer navigates to the shelf.
7. Customer checks stock on arrival.
8. If stock exists:
   - decrease shelf stock by 1,
   - add product to basket.
9. Customer navigates to checkout.
10. Customer pays.
11. Economy cash increases by product selling price.
12. Customer navigates to exit.
13. Customer is removed.
14. Wave completes.

Use placeholder geometry only.

Do not implement:
- multiple products,
- facings,
- deliveries,
- advanced inventory,
- multiple customer types,
- heatmaps,
- save system,
- advanced UI.

Use clear state transitions and logs.

Example logs:

[CUSTOMER] Customer_001 entered store
[CUSTOMER] Customer_001 targeting freshpop_cola_500
[INVENTORY] freshpop_cola_500 shelf stock 5 -> 4
[SALE] Customer_001 paid 2.50
[ECONOMY] cash 100.00 -> 102.50
[CUSTOMER] Customer_001 exited store

At the end report:

Implemented:
Files changed:
How to test:
Known limitations:

Do not continue to additional gameplay systems automatically.
```

---

# 103. Final design principle

The core of ShopyFender is:

```text
DECISION
↓
SIMULATION
↓
VISIBLE CONSEQUENCE
↓
ANALYSIS
↓
BETTER DECISION
```

If a feature does not meaningfully support this loop, it should not be prioritized.

The game should reward understanding of:

```text
space
demand
capacity
stock
flow
```

The player should win because the store is better designed, not because the player manually performs repetitive tasks faster.

