# ShopyFender — Texture & Material Specification

> **Project:** ShopyFender  
> **Environment:** Cursor Pro + Godot + Blender on macOS  
> **Purpose:** Source of truth for textures, materials, labels, atlases and visual consistency  
> **Status:** v0.1  
> **Art direction:** Stylized 3D / clean low-poly / readable retail environment

---

# 1. Visual goal

ShopyFender should NOT aim for photorealism.

Target style:

```text
clean
stylized
slightly simplified
bright
readable
consistent
retail-friendly
```

The player must be able to quickly distinguish:

- fixtures,
- product categories,
- product brands,
- empty shelf space,
- warnings,
- entrances/exits,
- refrigerated fixtures,
- checkout zones.

Clarity is more important than realism.

---

# 2. General texture philosophy

Prefer:

```text
simple geometry
+
clean materials
+
small number of reusable textures
+
clear product labels
```

Avoid:

```text
4K textures on small props
unique material for every object
high-frequency noise
heavy grunge
photorealistic dirt
complex procedural shaders without gameplay value
```

The game should look intentional, not dirty or industrial.

---

# 3. Recommended texture resolutions

Use the smallest reasonable texture.

## Environment

```text
Floor: 1024x1024
Walls: 1024x1024
Large signs: 1024x1024
```

## Fixtures

```text
Gondola / shelf: 512x512 or 1024x1024
Checkout: 512x512
Fridge/freezer: 512x512 or 1024x1024
```

## Product packaging

```text
Prototype: 128x128
Playable: 256x256
Hero / close-up: 512x512
```

## Small props

```text
128x128 or 256x256
```

Avoid 2048/4096 textures unless there is a specific visual reason.

---

# 4. Texture format

Preferred source format:

```text
PNG
```

Use:

```text
sRGB for color/albedo
linear data for roughness/metallic/normal
```

Godot should handle imported texture compression.

For source files, keep lossless PNG where practical.

---

# 5. PBR channels

Main materials may use:

```text
Albedo
Roughness
Metallic
Normal
AO
```

Not every asset needs all maps.

For the stylized direction:

## Minimum

```text
Albedo
Roughness
```

## Optional

```text
Normal
AO
Metallic
```

Do not create unnecessary map sets for simple objects.

---

# 6. Channel priority

Use this priority:

```text
1. Albedo
2. Roughness
3. Normal
4. AO
5. Metallic
```

For product packages, often only:

```text
Albedo
Roughness
```

are enough.

---

# 7. Base material library

The project should reuse a small material library.

Recommended:

```text
MAT_Metal_White
MAT_Metal_LightGray
MAT_Metal_DarkGray

MAT_Plastic_White
MAT_Plastic_Black
MAT_Plastic_Red
MAT_Plastic_Blue

MAT_Wood_Light
MAT_Wood_Medium

MAT_Glass_Clear
MAT_Glass_Frosted

MAT_Cardboard
MAT_Rubber_Black

MAT_Floor_LightTile
MAT_Floor_DarkTile

MAT_Wall_White
MAT_Wall_LightGray
```

Do not create duplicate materials that differ only slightly.

---

# 8. Store floor

## Target look

```text
clean commercial floor
neutral
slightly reflective
not glossy like a mirror
```

Recommended variants:

```text
Light Tile
Gray Tile
Polished Concrete
Vinyl
```

MVP:

```text
Light Tile
```

Maps:

```text
Albedo
Roughness
Normal optional
```

Suggested roughness:

```text
0.55–0.75
```

Avoid strong dirt patterns.

---

# 9. Walls

Target:

```text
clean supermarket wall
neutral
very subtle texture
```

Recommended colors:

```text
white
warm white
light gray
```

Maps:

```text
Albedo
Roughness
```

Do not use detailed plaster unless visible.

---

# 10. Ceiling

Target:

```text
simple white commercial ceiling
```

Can use:

```text
plain material
```

No unique texture needed in MVP.

---

# 11. Metal fixtures

Used for:

- gondolas,
- wall shelves,
- racks,
- backroom shelving.

Target:

```text
painted powder-coated steel
```

Main variants:

```text
white
light gray
dark gray
```

Maps:

```text
Albedo
Roughness
Metallic
```

Suggested values:

```text
Metallic: 0.6–0.9
Roughness: 0.35–0.55
```

Keep edges visually clean.

---

# 12. Plastic fixtures

Used for:

- baskets,
- bins,
- trim,
- checkout details.

Target:

```text
slightly matte colored plastic
```

Suggested roughness:

```text
0.4–0.65
```

Metallic:

```text
0
```

---

# 13. Cardboard

Used for:

- shipping boxes,
- shelf-ready packaging,
- logistics props.

Target:

```text
warm brown cardboard
subtle fiber variation
```

Maps:

```text
Albedo
Roughness
Normal optional
```

Suggested roughness:

```text
0.75–0.9
```

---

# 14. Glass

Used for:

- refrigerators,
- freezers,
- storefronts.

Target:

```text
clear
slightly reflective
subtle tint
```

Avoid overly realistic refraction if it hurts performance.

MVP:

```text
simple transparent material
```

---

# 15. Rubber

Used for:

- wheels,
- bumpers,
- trolley parts.

Target:

```text
dark matte rubber
```

Suggested:

```text
Roughness: 0.8
Metallic: 0
```

---

# 16. Wood

Optional for:

- display tables,
- premium fixtures,
- bakery.

Target:

```text
clean retail laminate
```

Do not use rustic heavy-grain wood unless level design requires it.

---

# 17. Product texture strategy

Products should be differentiated mainly through:

```text
label
brand
category color
product name
small icon
```

Not through unique geometry.

One bottle mesh can become:

```text
FreshPop Cola
FreshPop Zero
AquaPure Water
SunnyJuice Orange
Volt Energy
```

by changing material/texture.

---

# 18. Fictional brand system

All product brands should be fictional.

Recommended naming style:

```text
short
memorable
readable from a distance
```

Examples:

```text
FreshPop
AquaPure
SunnyJuice
CrunchBox
MorningJoy
QuickBite
DailyFresh
FizzUp
HomeCare
PureDay
```

---

# 19. Product label structure

Each product label should follow a reusable layout.

Recommended:

```text
┌────────────────────┐
│ BRAND              │
│                    │
│ PRODUCT NAME       │
│                    │
│ category graphic   │
│                    │
│ size / variant     │
└────────────────────┘
```

At game distance, the most important elements are:

```text
brand color
product category
variant color
```

Text does not need to be fully readable from far away.

---

# 20. Product category color language

Use category families.

Example:

```text
Water            = blue / cyan
Cola             = red / black
Juice            = orange / yellow
Energy Drinks    = neon / dark
Milk             = white / blue
Cereal           = yellow / orange
Snacks           = red / yellow
Coffee           = brown / dark
Cleaning         = blue / green
Personal Care    = purple / teal
Frozen           = light blue
```

These are guidelines, not hard rules.

---

# 21. Product variants

Color should help distinguish variants.

Example:

FreshPop:

```text
Original = red
Zero     = black
Cherry   = dark red
Lime     = green
```

AquaPure:

```text
Still     = blue
Sparkling = cyan
Lemon     = yellow
```

---

# 22. Shelf readability

Products should visually create clear shelf blocks.

Important:

```text
same brand family should look related
different category should look different
```

This makes planograms visually understandable.

---

# 23. Empty shelf readability

The player must immediately see empty spaces.

Therefore shelf interiors should use:

```text
neutral dark/light surface
```

Product textures should be more colorful than shelf materials.

This creates strong contrast.

---

# 24. Product atlases

To reduce material count, use texture atlases later.

Example:

```text
ProductAtlas_Beverages_01.png
```

Contains:

```text
16–32 labels
```

Possible atlas groups:

```text
Beverages
Snacks
Cereal
Dairy
Household
PersonalCare
Frozen
```

Do not build atlas system before multiple products exist.

---

# 25. Prototype product textures

For Prototype 0.01:

Create only:

```text
FreshPop Cola
AquaPure Water
```

Resolution:

```text
256x256
```

Simple flat graphic.

No detailed nutrition text.

---

# 26. Product label detail levels

## L0 Prototype

```text
brand name
product name
2 colors
```

## L1 Playable

```text
brand logo
product name
variant
simple illustration
size text
```

## L2 Polish

```text
small secondary text
better graphic balance
roughness variation
small packaging details
```

Do not create L2 until needed.

---

# 27. Price labels

Shelf price labels should be rendered dynamically where possible.

Do NOT generate a unique texture for every price.

Recommended:

```text
Godot UI / SubViewport / dynamic text
```

Fields:

```text
Product Name
Price
Optional Promo Price
Optional Unit Price
```

---

# 28. Shelf edge strip

Create generic strip material:

```text
MAT_Shelf_PriceStrip
```

Color:

```text
white / transparent
```

Price labels are placed on top.

---

# 29. Aisle signs

Sign body can use one reusable material.

Text should be dynamic.

Examples:

```text
1
2
3
DRINKS
SNACKS
DAIRY
```

Do not create separate 3D textures for every sign.

---

# 30. Promotional signs

Create a small set of reusable templates.

Examples:

```text
SALE
NEW
BEST VALUE
PROMO
2 FOR 1
```

Use fictional branding only.

Resolution:

```text
256x256 or 512x512
```

---

# 31. Warning and gameplay textures

Gameplay feedback should use UI/material overlays rather than permanent textures.

Examples:

```text
Placement Valid
Placement Invalid
Selected
OOS Warning
Low Stock
Blocked
```

Recommended:

```text
shader/material color overlay
```

not duplicate textures.

---

# 32. Placement ghost material

Use one transparent material.

Example:

```text
MAT_PlacementGhost
```

States:

```text
valid
invalid
```

Implement through color parameter.

---

# 33. Selection highlight

Prefer:

```text
outline shader
or
emissive material overlay
```

Do not create unique highlighted textures.

---

# 34. Fridge/freezer surfaces

Recommended:

```text
white/gray painted metal
black trim
clear glass
subtle interior light
```

Use small reusable texture set.

---

# 35. Checkout materials

Recommended:

```text
gray plastic
black rubber belt
white painted metal
small accent color
```

Checkout should be visually distinct from regular shelves.

---

# 36. Shopping basket material

Recommended colors:

```text
red
blue
green
black
```

Use material parameter/color variation.

Do not use separate texture files for each color.

---

# 37. Shopping cart materials

Use:

```text
metal frame
plastic handle
rubber wheels
```

No complex textures required.

---

# 38. Backroom textures

Backroom should visually differ from sales floor.

Use:

```text
gray concrete
cardboard
industrial metal
neutral lighting
```

Still stylized, not dirty.

---

# 39. Pallet texture

Simple wood material.

Suggested:

```text
512x512
```

Can be reused across all pallets.

---

# 40. Box markings

Shipping boxes may use generic markings:

```text
UP
FRAGILE
CATEGORY CODE
fictional supplier logo
```

Avoid real shipping brands.

---

# 41. Character texture strategy

For early game:

```text
small number of body meshes
+
material color variations
```

Clothing can use:

```text
base clothing texture
color parameter
```

Avoid unique 2K textures per customer.

---

# 42. Character texture resolution

Recommended:

```text
512x512
```

Potential later hero characters:

```text
1024x1024
```

Most customers do not need more.

---

# 43. Staff clothing

Staff should be easy to distinguish.

Recommended:

```text
solid branded shirt
dark pants
small ShopyFender/store logo
```

Use one or two staff material variants.

---

# 44. Decals

Use decals sparingly.

Possible:

```text
floor arrows
queue markings
delivery zone
staff-only sign
promo floor graphic
```

Avoid excessive decorative decals.

---

# 45. Floor navigation markings

Potential later textures:

```text
ENTRY
EXIT
QUEUE
STAFF ONLY
DELIVERY
```

Can help gameplay readability.

---

# 46. Texture tiling

For large surfaces:

```text
floor
walls
ceiling
```

use tileable textures.

Avoid stretching one texture across entire store.

---

# 47. UV strategy

Fixtures:

```text
simple box UVs
consistent texel density
```

Products:

```text
simple predictable UV layouts
```

Package base meshes should use reusable UV templates.

---

# 48. Product UV templates

Create standard UV layouts for:

```text
Bottle
Can
Box
Carton
Bag
Jar
Tub
Tray
```

This allows Cursor/Blender automation to swap labels easily.

---

# 49. Texture naming convention

Use:

```text
T_<Category>_<Name>_<Map>
```

Examples:

```text
T_Floor_LightTile_Albedo
T_Floor_LightTile_Roughness
T_Metal_White_Albedo
T_Product_FreshPopCola_Albedo
```

Maps:

```text
_Albedo
_Normal
_Roughness
_Metallic
_AO
_Emission
```

---

# 50. Material naming convention

Use:

```text
MAT_<Category>_<Name>
```

Examples:

```text
MAT_Floor_LightTile
MAT_Metal_White
MAT_Product_FreshPopCola
MAT_Glass_Clear
```

---

# 51. Product material naming

Use:

```text
MAT_Product_<Brand><Product><Variant>
```

Examples:

```text
MAT_Product_FreshPopColaOriginal
MAT_Product_FreshPopColaZero
MAT_Product_AquaPureStill
```

---

# 52. Folder structure

Recommended:

```text
assets/
└── textures/
    ├── environment/
    ├── fixtures/
    ├── products/
    ├── characters/
    ├── signage/
    ├── decals/
    └── ui/
```

Materials:

```text
assets/
└── materials/
    ├── environment/
    ├── fixtures/
    ├── products/
    └── shared/
```

---

# 53. Source files

Keep editable source files separate.

Example:

```text
assets_source/
└── textures/
    ├── products/
    ├── labels/
    ├── signage/
    └── atlases/
```

Do not store only flattened game-ready files.

---

# 54. Procedural texture opportunities

Cursor may generate simple assets procedurally.

Good candidates:

```text
product labels
price labels
category signs
promo signs
cardboard markings
simple iconography
```

Use scripts when repetition is high.

---

# 55. Product label generator

Recommended future tool:

```text
tools/generators/product_label_generator.py
```

Input:

```text
brand
product_name
variant
primary_color
secondary_color
category_icon
package_type
```

Output:

```text
PNG texture
```

Example:

```text
FreshPop
Cola
Zero
black
red
soft_drink_icon
bottle
```

---

# 56. Sign generator

Recommended:

```text
tools/generators/sign_generator.py
```

Input:

```text
text
icon
background_color
text_color
size
```

Output:

```text
PNG
```

Useful for:

```text
aisle signs
category signs
promo signs
```

---

# 57. Brand consistency

Each fictional brand should define:

```text
logo style
primary color
secondary color
font style
category
```

Example:

```text
FreshPop
Primary: red
Secondary: white
Style: bold rounded
Category: soft drinks
```

This lets many SKUs look like the same brand family.

---

# 58. Texture variation

Do not add random dirt/noise to every asset.

Variation should come from:

```text
color
brand
package shape
material
minor hue shifts
```

Keep store visually clean.

---

# 59. Roughness variation

Use roughness to distinguish materials.

Examples:

```text
Glass: low
Plastic: medium
Painted metal: medium
Cardboard: high
Rubber: high
Floor: medium-high
```

This gives depth without heavy texture detail.

---

# 60. Normal maps

Use only where visible.

Good candidates:

```text
tile floor
cardboard
wood
metal embossing
```

Skip normal maps for:

```text
tiny product labels
flat signage
simple plastic props
```

---

# 61. Metallic maps

Use only for actual metal surfaces.

Do NOT mark:

```text
plastic
cardboard
paper labels
wood
```

as metallic.

---

# 62. Emission

Use carefully.

Good uses:

```text
fridge interior lights
exit signs
small electronic displays
selected/alert effects
```

Avoid glowing supermarket everywhere.

---

# 63. Texture memory goal

Early game should stay lightweight.

General rule:

```text
many small reused textures
>
many unique large textures
```

Texture atlases and reusable materials should reduce draw calls and memory.

---

# 64. Product category atlas plan

Potential future atlases:

```text
Atlas_Beverages_01
Atlas_Snacks_01
Atlas_Breakfast_01
Atlas_Dairy_01
Atlas_Household_01
Atlas_PersonalCare_01
```

Each atlas can contain:

```text
16–32 product labels
```

---

# 65. Prototype texture set

Prototype 0.01 should need only:

```text
1. Floor
2. Wall
3. White Metal
4. Dark Plastic
5. Glass
6. FreshPop Cola label
7. AquaPure Water label
8. Entrance sign
9. Exit sign
```

Do not create more before needed.

---

# 66. MVP texture set

Recommended MVP library:

```text
Environment:
- Floor Light
- Floor Dark
- Wall White
- Wall Gray
- Ceiling White

Fixtures:
- Metal White
- Metal Gray
- Plastic Black
- Plastic Red
- Glass
- Rubber
- Cardboard
- Wood Light

Product:
- 20–40 fictional label textures

Signage:
- Entrance
- Exit
- Category signs
- Promo signs
```

---

# 67. Texture creation order

Recommended:

```text
01 Floor
02 Wall
03 White Metal
04 Gray Metal
05 Black Plastic
06 Glass
07 Cardboard
08 FreshPop Cola
09 AquaPure Water
10 Exit / Entrance signs
```

Then only create new textures as gameplay requires them.

---

# 68. What NOT to texture early

Do not spend time on:

```text
tiny screws
barcode text
nutrition panels
fine legal text
individual shelf brackets
complex dust
scratches on every object
high-resolution logos
realistic fingerprints
```

These do not improve gameplay.

---

# 69. Product texture readability test

A product texture is successful if:

```text
player can identify category from normal gameplay camera distance
player can distinguish neighboring SKUs
brand families look related
shelves do not become visual noise
```

Full text readability is not required.

---

# 70. Color-blind accessibility

Do not communicate gameplay state through color alone.

For:

```text
OOS
invalid placement
warnings
```

also use:

```text
icons
patterns
text
shape
```

---

# 71. Godot material rules

Prefer StandardMaterial3D initially.

Use custom shaders only when needed.

Good early uses:

```text
selection outline
placement ghost
heatmap overlay
transparent glass
```

Avoid custom shader proliferation.

---

# 72. Godot import rules

When importing:

```text
verify sRGB for albedo
verify normal map import
enable mipmaps where useful
use texture compression
```

Do not disable mipmaps for ordinary 3D world textures.

---

# 73. Alpha usage

Use alpha only when needed.

Examples:

```text
glass
decals
labels with cutout
```

Avoid unnecessary transparent materials because they are more expensive.

---

# 74. Price label rendering

Price labels should preferably be generated dynamically in Godot.

Format example:

```text
FreshPop Cola
2.49
```

Promo:

```text
3.29
2.49
PROMO
```

No unique textures per shelf price.

---

# 75. Digital displays

Later refrigerators/checkouts may use:

```text
dynamic SubViewport textures
```

Do not bake text into object textures if data changes at runtime.

---

# 76. Product label source format

Prefer source labels in:

```text
SVG
or
editable layered format
```

Then export PNG for game use.

This allows fast scaling and modifications.

---

# 77. Cursor rules for texture generation

Cursor should:

1. reuse existing materials first,
2. create new textures only when visually necessary,
3. use project naming conventions,
4. avoid large texture resolutions,
5. keep fictional branding consistent,
6. never use copyrighted brand packaging,
7. document external texture licenses.

---

# 78. External texture sources

Preferred license types:

```text
CC0
public domain
commercial-friendly
```

Good use:

```text
generic floor
generic concrete
generic wood
generic cardboard
```

Product labels should preferably be created specifically for ShopyFender.

---

# 79. License tracking

Record external assets in:

```text
assets/LICENSES.md
```

Include:

```text
asset name
source
author
license
download date
```

---

# 80. First texture generation prompt for Cursor

```text
Read SHOPYFENDER_TEXTURE_SPEC.md and SHOPYFENDER_3D_ASSET_LIST.md.

Create only the minimum Prototype 0.01 texture/material set.

Required:

1. MAT_Floor_LightTile
2. MAT_Wall_White
3. MAT_Metal_White
4. MAT_Plastic_Black
5. MAT_Glass_Clear
6. MAT_Product_FreshPopColaOriginal
7. MAT_Product_AquaPureStill

Product labels should be fictional and simple.

Target style:
- stylized
- clean
- readable
- low visual noise

Use 256x256 textures for product labels.

Do not create detailed PBR maps unless necessary.

Use reusable Godot StandardMaterial3D materials where practical.

Report:
- files created
- materials created
- texture resolutions
- where each material is used
```

---

# 81. Product label prompt template

```text
Create a fictional supermarket product label.

Brand:
{brand}

Product:
{product}

Variant:
{variant}

Category:
{category}

Primary color:
{primary_color}

Secondary color:
{secondary_color}

Style:
clean stylized retail packaging

Requirements:
- readable from medium distance
- simple logo
- clear product name
- no real brands
- no copyrighted characters
- minimal small text
- no photorealistic packaging
```

---

# 82. Texture quality checklist

Every texture/material should pass:

```text
[ ] correct name
[ ] correct resolution
[ ] correct color space
[ ] no copyrighted branding
[ ] consistent style
[ ] reasonable file size
[ ] readable at gameplay distance
[ ] reusable where possible
[ ] correct roughness/metallic behavior
[ ] imports correctly into Godot
```

---

# 83. Final rule

The visual hierarchy should always be:

```text
GAMEPLAY INFORMATION
>
READABILITY
>
STYLE
>
DETAIL
```

ShopyFender should look clean and coherent, but texture detail must never make store optimization harder to read.
