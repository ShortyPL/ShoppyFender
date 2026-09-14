# ShopyFender — 3D Asset Generation List

> **Project:** ShopyFender  
> **Environment:** Cursor Pro + Godot + Blender MCP on macOS  
> **Purpose:** Source of truth for 3D assets that should be generated or sourced  
> **Status:** v0.1  
> **Art direction:** Stylized 3D / clean low-poly / readable retail environment

---

# 1. Asset strategy

The project has a small hobby budget.

Therefore the asset strategy is:

```text
1. Primitive placeholders first
2. Blender MCP generated assets second
3. Free commercial-friendly assets third
4. Manual polish only for important hero assets
5. Paid assets only if clearly justified
```

The goal is NOT to create every object manually.

The goal is to create a reusable modular asset library.

---

# 2. Priority system

Each asset has one of these priorities:

```text
P0 = Required for Prototype 0.01
P1 = Required for early playable MVP
P2 = Important for visual variety
P3 = Later / polish
```

Development rule:

> Do not create P2/P3 objects before P0/P1 gameplay works.

---

# 3. General modeling rules

All generated assets should follow:

```text
Units: meters
Origin: logical pivot
Forward: -Z
Up: +Y
Export: GLB / glTF 2.0
Transforms: applied
Scale: 1,1,1
Rotation: 0,0,0
```

Prefer:

- simple topology,
- clean silhouettes,
- reusable materials,
- low-to-medium poly count,
- correct real-world proportions,
- no unnecessary hidden geometry.

---

# 4. Naming convention

Meshes:

```text
SM_<Category>_<Name>_<Variant>
```

Examples:

```text
SM_Fixture_Gondola_100
SM_Fixture_WallShelf_100
SM_Checkout_Basic_01
SM_Product_BottleSmall_01
SM_Prop_CardboardBox_01
```

Scenes or packed Godot scenes can use:

```text
PS_<Name>
```

Examples:

```text
PS_Gondola_Basic
PS_Checkout_Basic
```

---

# 5. Material strategy

Prefer reusable materials.

Base materials:

```text
MAT_Metal_White
MAT_Metal_Gray
MAT_Plastic_White
MAT_Plastic_Black
MAT_Wood_Light
MAT_Wood_Dark
MAT_Glass_Clear
MAT_Rubber_Black
MAT_Cardboard
MAT_Floor_Light
MAT_Wall_White
```

Do not create one unique material per object unless necessary.

---

# 6. P0 — Prototype 0.01 required assets

These are the minimum assets needed to build and test the first full purchase loop.

---

## 6.1 Store floor

**Priority:** P0

Name:

```text
SM_Environment_StoreFloor_10x12
```

Dimensions:

```text
10 m x 12 m
```

Properties:

- simple rectangular floor,
- flat,
- neutral material,
- no detail required.

Recommended implementation:

```text
Godot primitive first
Blender asset later
```

---

## 6.2 Store wall module

**Priority:** P0

Name:

```text
SM_Environment_Wall_100
```

Dimensions:

```text
width: 1.0 m
height: 3.0 m
depth: 0.15 m
```

Variants:

```text
Wall_100
Wall_200
Wall_Corner
```

Prototype can use only:

```text
Wall_100
```

Recommended:

```text
Godot primitive first
```

---

## 6.3 Entrance frame

**Priority:** P0

Name:

```text
SM_Environment_Entrance_Basic
```

Dimensions:

```text
width: 1.6–2.0 m
height: 2.4 m
```

Prototype version:

- simple opening,
- simple frame,
- no animated door required.

Later:

- automatic sliding door.

---

## 6.4 Exit frame

**Priority:** P0

Name:

```text
SM_Environment_Exit_Basic
```

May reuse Entrance asset with different signage/material.

---

## 6.5 Basic gondola

**Priority:** P0

Name:

```text
SM_Fixture_Gondola_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.5 m
height: 1.8 m
```

Required geometry:

```text
base
2 side frames
4 shelves
optional back panel
```

Prototype:

- one-sided or simplified two-sided,
- no tiny bolts,
- no detailed price strips.

This is one of the most important reusable assets in the entire game.

---

## 6.6 Basic checkout

**Priority:** P0

Name:

```text
SM_Checkout_Basic_01
```

Dimensions:

```text
length: 1.8–2.2 m
width: 0.7–0.9 m
height: 0.9 m
```

Required:

```text
counter
scanner area
small customer bagging area
```

No cashier chair required initially.

---

## 6.7 Small product bottle

**Priority:** P0

Name:

```text
SM_Product_BottleSmall_01
```

Approx dimensions:

```text
width: 0.065 m
depth: 0.065 m
height: 0.22 m
```

Used for:

- cola,
- water,
- juice,
- energy drink variants.

One mesh can support many SKUs via material/texture changes.

---

## 6.8 Placeholder customer

**Priority:** P0

Name:

```text
CH_Customer_Placeholder_01
```

Prototype implementation:

```text
capsule / simple low-poly humanoid
```

Required:

- correct character height,
- root transform,
- simple collider.

Approx height:

```text
1.7 m
```

No detailed rig required for the first purchase loop.

---

## 6.9 Checkout marker

**Priority:** P0

Name:

```text
SM_Debug_CheckoutMarker
```

Can be invisible in final game.

Useful during prototype to mark queue/payment location.

---

## 6.10 Entrance spawn marker

**Priority:** P0

Name:

```text
SM_Debug_EntranceMarker
```

Can be Godot-only helper object.

---

## 6.11 Exit marker

**Priority:** P0

Name:

```text
SM_Debug_ExitMarker
```

Can be Godot-only helper object.

---

# 7. P1 — Core fixture library

These assets should be created after Prototype 0.01 works.

---

## 7.1 Wall shelf

**Priority:** P1

Name:

```text
SM_Fixture_WallShelf_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.4 m
height: 2.0 m
```

Shelves:

```text
5
```

Purpose:

- perimeter categories,
- dry groceries,
- personal care,
- household products.

---

## 7.2 Double-sided gondola

**Priority:** P1

Name:

```text
SM_Fixture_GondolaDouble_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.9–1.0 m
height: 1.6–1.8 m
```

Sides:

```text
2
```

This should become a standard main-aisle fixture.

---

## 7.3 Gondola endcap

**Priority:** P1

Name:

```text
SM_Fixture_Endcap_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.5 m
height: 1.6–1.8 m
```

Purpose:

- promotions,
- impulse products,
- high-visibility placement.

---

## 7.4 Small display table

**Priority:** P1

Name:

```text
SM_Fixture_DisplayTable_120
```

Dimensions:

```text
width: 1.2 m
depth: 0.8 m
height: 0.9 m
```

Use:

- bakery,
- seasonal,
- promotional items.

---

## 7.5 Promotional bin

**Priority:** P1

Name:

```text
SM_Fixture_PromoBin_01
```

Dimensions:

```text
width: 0.8 m
depth: 0.8 m
height: 0.8 m
```

---

## 7.6 Basic refrigerator

**Priority:** P1

Name:

```text
SM_Fixture_Fridge_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.7 m
height: 2.0 m
```

Required:

- glass front,
- shelves,
- simple door frame.

No functional door animation initially.

---

## 7.7 Open refrigerator

**Priority:** P1

Name:

```text
SM_Fixture_OpenFridge_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.8 m
height: 2.0 m
```

Use:

- drinks,
- dairy,
- convenience foods.

---

## 7.8 Chest freezer

**Priority:** P1

Name:

```text
SM_Fixture_ChestFreezer_120
```

Dimensions:

```text
width: 1.2 m
depth: 0.8 m
height: 0.9 m
```

---

## 7.9 Upright freezer

**Priority:** P1

Name:

```text
SM_Fixture_UprightFreezer_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.75 m
height: 2.1 m
```

---

# 8. P1 — Product package base meshes

Do NOT create one unique mesh per SKU.

Create reusable package archetypes.

---

## 8.1 Small bottle

```text
SM_Product_BottleSmall_01
```

Use:

- 330–500 ml beverages.

---

## 8.2 Large bottle

```text
SM_Product_BottleLarge_01
```

Approx:

```text
0.09 x 0.09 x 0.32 m
```

Use:

- 1–2 L drinks.

---

## 8.3 Aluminum can

```text
SM_Product_Can_01
```

Approx:

```text
0.066 x 0.066 x 0.115 m
```

---

## 8.4 Small carton

```text
SM_Product_CartonSmall_01
```

Use:

- juice,
- cream,
- small milk.

---

## 8.5 Large carton

```text
SM_Product_CartonLarge_01
```

Use:

- milk,
- juice,
- plant drinks.

---

## 8.6 Small box

```text
SM_Product_BoxSmall_01
```

Use:

- tea,
- medicine-like fictional goods,
- small snacks.

---

## 8.7 Medium box

```text
SM_Product_BoxMedium_01
```

Use:

- cereal,
- pasta,
- household products.

---

## 8.8 Large box

```text
SM_Product_BoxLarge_01
```

Use:

- large cereal,
- detergent,
- bulk goods.

---

## 8.9 Bag / pouch

```text
SM_Product_Bag_01
```

Use:

- chips,
- snacks,
- coffee,
- frozen goods.

---

## 8.10 Jar

```text
SM_Product_Jar_01
```

Use:

- sauces,
- jam,
- spreads.

---

## 8.11 Tin can

```text
SM_Product_TinCan_01
```

Use:

- canned foods.

---

## 8.12 Tub

```text
SM_Product_Tub_01
```

Use:

- yogurt,
- spreads,
- ice cream.

---

## 8.13 Tray

```text
SM_Product_Tray_01
```

Use:

- meat,
- ready meals,
- deli.

---

## 8.14 Multipack

```text
SM_Product_Multipack_01
```

Use:

- beer/soft-drink multipacks,
- household bulk packs.

---

# 9. P1 — Checkout assets

---

## 9.1 Checkout divider

```text
SM_Checkout_Divider_01
```

---

## 9.2 Scanner

```text
SM_Checkout_Scanner_01
```

May be integrated into checkout mesh initially.

---

## 9.3 Card terminal

```text
SM_Checkout_CardTerminal_01
```

Low priority visual detail, but useful later.

---

## 9.4 Shopping bag holder

```text
SM_Checkout_BagHolder_01
```

---

# 10. P1 — Customer support props

---

## 10.1 Shopping basket

```text
SM_Prop_ShoppingBasket_01
```

Dimensions:

```text
approx 0.45 x 0.30 x 0.25 m
```

---

## 10.2 Shopping trolley

```text
SM_Prop_ShoppingCart_01
```

Dimensions:

```text
approx 1.0 x 0.6 x 1.0 m
```

This can wait until customers need carts.

---

## 10.3 Basket stack

```text
SM_Prop_BasketStack_01
```

---

## 10.4 Cart bay

```text
SM_Prop_CartBay_01
```

---

# 11. P1 — Backroom / delivery assets

These become important when delivery planning enters gameplay.

---

## 11.1 Euro pallet

```text
SM_Logistics_EuroPallet_01
```

Dimensions:

```text
1.2 x 0.8 x 0.144 m
```

---

## 11.2 Cardboard box small

```text
SM_Logistics_BoxSmall_01
```

---

## 11.3 Cardboard box medium

```text
SM_Logistics_BoxMedium_01
```

---

## 11.4 Cardboard box large

```text
SM_Logistics_BoxLarge_01
```

---

## 11.5 Roll cage trolley

```text
SM_Logistics_RollCage_01
```

Useful visual for supermarket deliveries.

---

## 11.6 Hand pallet truck

```text
SM_Logistics_PalletJack_01
```

---

## 11.7 Backroom shelving

```text
SM_Logistics_BackroomRack_100
```

Dimensions:

```text
width: 1.0 m
depth: 0.6 m
height: 2.0 m
```

---

## 11.8 Delivery door

```text
SM_Environment_DeliveryDoor_01
```

---

## 11.9 Loading dock marker

```text
SM_Environment_LoadingDock_01
```

Only needed later if deliveries are shown physically.

---

# 12. P2 — Store architecture modular kit

---

## 12.1 Wall 1m

```text
SM_Environment_Wall_100
```

---

## 12.2 Wall 2m

```text
SM_Environment_Wall_200
```

---

## 12.3 Wall corner

```text
SM_Environment_WallCorner_01
```

---

## 12.4 Window module

```text
SM_Environment_Window_200
```

---

## 12.5 Glass storefront

```text
SM_Environment_StorefrontGlass_200
```

---

## 12.6 Automatic sliding door

```text
SM_Environment_AutoDoor_200
```

Variants:

```text
closed
left
right
double
```

---

## 12.7 Interior door

```text
SM_Environment_DoorInterior_090
```

---

## 12.8 Stockroom door

```text
SM_Environment_DoorStockroom_100
```

---

## 12.9 Ceiling module

```text
SM_Environment_Ceiling_200
```

---

## 12.10 Ceiling light

```text
SM_Environment_CeilingLight_01
```

---

## 12.11 Emergency exit sign

```text
SM_Sign_Exit_01
```

---

# 13. P2 — Signage system

---

## 13.1 Aisle number sign

```text
SM_Sign_AisleNumber_01
```

Text should be handled dynamically in Godot if possible.

---

## 13.2 Category overhead sign

```text
SM_Sign_Category_01
```

Examples:

```text
DRINKS
SNACKS
CEREAL
DAIRY
```

Prefer dynamic texture/text rather than separate mesh per word.

---

## 13.3 Price strip

```text
SM_Sign_PriceStrip_100
```

Can be integrated into fixtures.

---

## 13.4 Promo sign

```text
SM_Sign_Promo_01
```

---

## 13.5 Hanging promo board

```text
SM_Sign_HangingPromo_01
```

---

# 14. P2 — Fresh food fixtures

---

## 14.1 Produce display

```text
SM_Fixture_ProduceTable_120
```

---

## 14.2 Produce crate

```text
SM_Fixture_ProduceCrate_01
```

---

## 14.3 Bakery rack

```text
SM_Fixture_BakeryRack_100
```

---

## 14.4 Bread basket

```text
SM_Fixture_BreadBasket_01
```

---

## 14.5 Deli counter

```text
SM_Fixture_DeliCounter_150
```

---

## 14.6 Meat refrigerator

```text
SM_Fixture_MeatFridge_150
```

---

# 15. P2 — Produce product bases

These can be much simpler than packaged products.

---

## 15.1 Apple

```text
SM_Product_Apple_01
```

---

## 15.2 Banana

```text
SM_Product_Banana_01
```

---

## 15.3 Orange

```text
SM_Product_Orange_01
```

---

## 15.4 Tomato

```text
SM_Product_Tomato_01
```

---

## 15.5 Potato

```text
SM_Product_Potato_01
```

---

## 15.6 Bread loaf

```text
SM_Product_Bread_01
```

---

# 16. P2 — Store office / staff room props

These are visual only at first.

---

## 16.1 Office desk

```text
SM_Prop_OfficeDesk_01
```

---

## 16.2 Office chair

```text
SM_Prop_OfficeChair_01
```

---

## 16.3 Computer monitor

```text
SM_Prop_Monitor_01
```

---

## 16.4 Locker

```text
SM_Prop_Locker_01
```

---

## 16.5 Staff table

```text
SM_Prop_StaffTable_01
```

---

# 17. P2 — Store decoration props

---

## 17.1 Trash bin

```text
SM_Prop_TrashBin_01
```

---

## 17.2 Fire extinguisher

```text
SM_Prop_FireExtinguisher_01
```

---

## 17.3 Security camera

```text
SM_Prop_SecurityCamera_01
```

---

## 17.4 Wall clock

```text
SM_Prop_WallClock_01
```

---

## 17.5 Cleaning bucket

```text
SM_Prop_CleaningBucket_01
```

---

## 17.6 Mop

```text
SM_Prop_Mop_01
```

---

# 18. P2 — Character set

Use Mixamo or another free animation source rather than generating all animations manually.

Create a small reusable customer set.

---

## 18.1 Customer male A

```text
CH_Customer_Male_A
```

---

## 18.2 Customer male B

```text
CH_Customer_Male_B
```

---

## 18.3 Customer female A

```text
CH_Customer_Female_A
```

---

## 18.4 Customer female B

```text
CH_Customer_Female_B
```

---

## 18.5 Senior customer

```text
CH_Customer_Senior_A
```

---

## 18.6 Parent customer

```text
CH_Customer_Parent_A
```

---

## 18.7 Staff placeholder

```text
CH_Staff_Generic_A
```

---

# 19. P2 — Character animation list

Prefer retargeted Mixamo animations.

Minimum:

```text
Idle
Walk
Walk_CarryBasket
TakeItem
PlaceItem
QueueIdle
Pay
Turn
```

Later:

```text
PushCart
InspectShelf
Frustrated
Happy
StaffRestock
StaffCarryBox
```

---

# 20. P3 — Staff gameplay assets

Only when staff system is implemented.

---

## 20.1 Cashier station details

```text
SM_Staff_CashierChair_01
```

---

## 20.2 Restocking cart

```text
SM_Staff_RestockCart_01
```

---

## 20.3 Staff box

```text
SM_Staff_CarryBox_01
```

---

## 20.4 Cleaning cart

```text
SM_Staff_CleaningCart_01
```

---

# 21. P3 — Advanced checkout assets

---

## 21.1 Self checkout

```text
SM_Checkout_Self_01
```

---

## 21.2 Self-checkout gate

```text
SM_Checkout_Gate_01
```

---

## 21.3 Queue barrier

```text
SM_Checkout_QueueBarrier_01
```

---

# 22. P3 — Advanced store fixtures

---

## 22.1 Island freezer

```text
SM_Fixture_IslandFreezer_150
```

---

## 22.2 Wine rack

```text
SM_Fixture_WineRack_100
```

---

## 22.3 Bottle rack

```text
SM_Fixture_BottleRack_100
```

---

## 22.4 Pharmacy cabinet

```text
SM_Fixture_Cabinet_100
```

---

## 22.5 Pegboard display

```text
SM_Fixture_Pegboard_100
```

---

## 22.6 Hanging display

```text
SM_Fixture_HangingDisplay_01
```

---

# 23. P3 — Exterior environment

Only needed when the game shows outside the store.

---

## 23.1 Store facade

```text
SM_Exterior_StoreFacade_01
```

---

## 23.2 Parking space module

```text
SM_Exterior_ParkingSpace_01
```

---

## 23.3 Parking curb

```text
SM_Exterior_Curb_100
```

---

## 23.4 Shopping cart shelter

```text
SM_Exterior_CartShelter_01
```

---

## 23.5 Delivery truck

```text
VEH_DeliveryTruck_01
```

---

## 23.6 Small customer car

```text
VEH_Car_Generic_01
```

---

# 24. P3 — Advanced logistics

---

## 24.1 Delivery truck interior

```text
SM_Logistics_TruckInterior_01
```

---

## 24.2 Dock leveler

```text
SM_Logistics_DockLeveler_01
```

---

## 24.3 Larger pallet rack

```text
SM_Logistics_PalletRack_200
```

---

## 24.4 Plastic delivery crate

```text
SM_Logistics_PlasticCrate_01
```

---

# 25. Modular gondola system

Instead of modeling every shelf separately, create modular components.

Recommended components:

```text
SM_Gondola_FrameSide_01
SM_Gondola_Base_100
SM_Gondola_Shelf_100
SM_Gondola_BackPanel_100
SM_Gondola_PriceStrip_100
SM_Gondola_EndPanel_01
```

Then build:

```text
1m gondola
1.25m gondola
1.33m gondola
2m gondola
```

from reusable parts.

This is strongly recommended.

---

# 26. Shelf width variants

Later useful fixture module widths:

```text
0.50 m
0.75 m
1.00 m
1.25 m
1.33 m
2.00 m
```

For MVP:

```text
1.00 m only
```

---

# 27. Fixture height variants

Possible:

```text
1.2 m
1.4 m
1.6 m
1.8 m
2.0 m
2.2 m
```

For MVP:

```text
1.8 m gondola
2.0 m wall shelf
```

---

# 28. Product package generation strategy

Cursor + Blender MCP should create generic base packages.

For example:

```text
BottleSmall
BottleLarge
Can
BoxSmall
BoxMedium
BoxLarge
Bag
Jar
Carton
Tray
Tub
Multipack
```

Then SKU differentiation should primarily happen through:

```text
material
texture
scale
label
color
```

Do not create hundreds of unique meshes.

---

# 29. Product visual quality levels

## Level 0 — Prototype

```text
solid color
basic geometry
no label
```

## Level 1 — Playable

```text
simple fictional label
2–3 colors
brand name
product name
```

## Level 2 — Polish

```text
better texture
roughness
normal details
small packaging variation
```

Do not start at Level 2.

---

# 30. Asset generation order

Recommended order:

```text
01 Store Floor
02 Wall
03 Entrance
04 Exit
05 Gondola
06 Checkout
07 Bottle Small
08 Placeholder Customer

09 Wall Shelf
10 Double Gondola
11 Endcap

12 Can
13 Bottle Large
14 Box Small
15 Box Medium
16 Bag
17 Jar

18 Refrigerator
19 Freezer

20 Shopping Basket
21 Shopping Cart

22 Cardboard Box
23 Euro Pallet
24 Backroom Rack
```

This order supports gameplay development.

---

# 31. Suggested first Blender MCP batch

Cursor prompt:

```text
Read SHOPYFENDER_3D_ASSET_LIST.md.

Use Blender MCP.

Create only these prototype assets:

1. SM_Fixture_Gondola_100
2. SM_Checkout_Basic_01
3. SM_Product_BottleSmall_01

Follow the dimensions and naming conventions from the asset list.

Style:
- simple
- low-poly
- clean
- no detailed textures
- game-ready placeholder

Use meters.

Apply transforms.

Set logical origins.

Do not create additional objects.

Export each asset as GLB into:

assets/models/prototype/

Report:
- objects created
- dimensions
- filenames
- export result
```

---

# 32. Suggested second Blender MCP batch

After Prototype 0.01:

```text
Read SHOPYFENDER_3D_ASSET_LIST.md.

Create:

1. SM_Fixture_WallShelf_100
2. SM_Fixture_GondolaDouble_100
3. SM_Fixture_Endcap_100
4. SM_Product_Can_01
5. SM_Product_BottleLarge_01
6. SM_Product_BoxSmall_01
7. SM_Product_BoxMedium_01
8. SM_Product_Bag_01
9. SM_Product_Jar_01

Use the project's low-poly stylized direction.

Reuse materials where possible.

Do not add unnecessary geometry.

Export as GLB.
```

---

# 33. Objects that should NOT be generated early

Do not spend time on:

```text
detailed cash register internals
realistic screws
individual shelf brackets
complex labels
fully modeled electronics
decorative ceiling infrastructure
complex exterior
delivery truck engine/interior
high-poly food
tiny props
```

These do not improve the core gameplay loop.

---

# 34. Objects better sourced than generated

Prefer free assets when quality matters and licensing is safe.

Possible candidates:

```text
humanoid characters
animations
shopping carts
office props
generic cars
small decoration props
audio-related decorative objects
```

Always record license in:

```text
assets/LICENSES.md
```

---

# 35. Objects better generated with Blender MCP

Strong candidates:

```text
gondolas
wall shelving
endcaps
checkout counters
backroom racks
product package bases
promo bins
simple refrigerators
simple freezers
pallets
cardboard boxes
sign frames
```

They are geometric and repetitive.

---

# 36. Objects better created directly in Godot

Do not use Blender for objects that are only gameplay/debug helpers.

Examples:

```text
spawn markers
navigation markers
queue points
interaction zones
placement ghosts
grid visualizations
debug heatmap cells
trigger volumes
```

---

# 37. LOD strategy

Not needed initially.

Later:

```text
LOD0
full fixture

LOD1
reduced geometry

LOD2
simple silhouette
```

Products may use:

```text
distance-based hiding
or
GPU instancing
```

Do not implement LOD until performance requires it.

---

# 38. Collision strategy

Fixtures:

```text
simple box collisions
```

Do not use mesh collision unless necessary.

Characters:

```text
capsule collision
```

Products:

Usually:

```text
no collision
```

unless directly interacted with physically.

---

# 39. Product rendering strategy

Products on shelves may become numerous.

Avoid:

```text
one complex Node3D per visible unit forever
```

Future optimization:

```text
MultiMeshInstance3D
GPU instancing
reduced back-row rendering
```

MVP can remain simple.

---

# 40. Shelf visualization rule

Only render enough products to communicate stock state.

Example:

```text
full shelf
partially empty shelf
empty shelf
```

Simulation data is authoritative.

Visual count does not need to perfectly equal every physical unit later.

---

# 41. Fixture visual states

Useful later:

```text
NORMAL
SELECTED
PLACEMENT_VALID
PLACEMENT_INVALID
OOS_WARNING
```

These states should use materials/outlines, not duplicate meshes.

---

# 42. Asset folder structure

Recommended:

```text
assets/
└── models/
    ├── prototype/
    ├── environment/
    ├── fixtures/
    ├── products/
    ├── logistics/
    ├── checkout/
    ├── characters/
    ├── props/
    └── exterior/
```

---

# 43. Blender source folder

Keep editable Blender sources separate:

```text
assets_source/
└── blender/
    ├── fixtures/
    ├── products/
    ├── environment/
    └── props/
```

Do not treat exported GLB files as the only source.

---

# 44. Reusable generation scripts

Useful Blender scripts:

```text
tools/blender/create_gondola.py
tools/blender/create_wall_shelf.py
tools/blender/create_checkout.py
tools/blender/create_product_package.py
tools/blender/create_pallet.py
tools/blender/create_box.py
```

Prefer parameterized generation.

Example:

```text
create_gondola(
    width=1.0,
    depth=0.5,
    height=1.8,
    shelves=4
)
```

---

# 45. Parameterized fixture generation

Cursor should prefer one generator over many copy-pasted models.

Example:

```text
Gondola Generator

width
depth
height
shelf_count
side_count
material
```

Output:

```text
SM_Fixture_Gondola_100
SM_Fixture_Gondola_125
SM_Fixture_Gondola_200
```

This is ideal for ShopyFender.

---

# 46. Parameterized product package generation

Example:

```text
Package Generator

package_type
width
depth
height
label_texture
body_color
cap_color
```

Then generate many SKU visuals cheaply.

---

# 47. Recommended initial asset count

For Prototype 0.01:

```text
8–10 assets maximum
```

For Prototype 0.02:

```text
20–30 reusable assets
```

For MVP:

```text
50–80 reusable assets
```

Do NOT target hundreds of unique models.

---

# 48. MVP fixture target

Recommended MVP fixture set:

```text
1. Wall Shelf
2. Gondola Single
3. Gondola Double
4. Endcap
5. Refrigerator
6. Freezer
7. Promo Bin
8. Display Table
9. Checkout
10. Backroom Rack
```

This is enough for significant layout variety.

---

# 49. MVP package target

Recommended:

```text
1. Bottle Small
2. Bottle Large
3. Can
4. Carton Small
5. Carton Large
6. Box Small
7. Box Medium
8. Box Large
9. Bag
10. Jar
11. Tin Can
12. Tub
13. Tray
14. Multipack
```

These can represent hundreds of fictional products.

---

# 50. MVP customer target

Recommended:

```text
4–6 body variants
```

With material/clothing variations:

```text
10–20 visible customer variants
```

No need for 20 unique character meshes.

---

# 51. Character variation strategy

Use:

```text
same skeleton
same animation set
different:
- body mesh
- hair
- clothing colors
- accessories
```

This reduces animation work.

---

# 52. Customer scale variation

Later:

```text
height variation ±5%
body variation
walk speed variation
```

Avoid extreme random scaling that looks unrealistic.

---

# 53. Asset QA checklist

Every generated asset should be checked for:

```text
[ ] correct name
[ ] correct dimensions
[ ] correct scale
[ ] applied transforms
[ ] logical origin
[ ] reasonable poly count
[ ] reusable material
[ ] simple collision possible
[ ] exports correctly as GLB
[ ] imports in Godot
[ ] no broken normals
[ ] no unexpected hidden objects
```

---

# 54. First asset acceptance test

For a gondola:

```text
1. Import into Godot.
2. Place on 0.5m build grid.
3. Rotate 90 degrees.
4. Confirm visual size feels correct.
5. Add simple collision.
6. Confirm customer navigation can route around it.
7. Confirm product shelf positions align with geometry.
```

If this works, the asset is valid.

---

# 55. Final recommendation

Generate first:

```text
P0
Store floor
Wall
Entrance
Exit
Basic Gondola
Basic Checkout
Bottle Small
Placeholder Customer
```

Then:

```text
P1
Wall Shelf
Double Gondola
Endcap
Package archetypes
Fridge
Freezer
Basket
Cart
Pallet
Boxes
Backroom Rack
```

Do not create the full supermarket asset library before the core gameplay loop is working.

The first important visual milestone is:

> A small store that clearly reads as a supermarket and supports the complete ShopyFender simulation loop.
