# ShopyFender documentation

Index of project materials. Design specs and this index are in English.

## Game specs (`ShopyFender_package/`)

| Document | Topic |
|---|---|
| [SHOPYFENDER_MASTER_SPEC.md](../ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) | Design source of truth (priorities + systems) |
| [SHOPYFENDER_GAME_LOGIC.md](../ShopyFender_package/SHOPYFENDER_GAME_LOGIC.md) | Gameplay logic |
| [SHOPYFENDER_DATA_MODEL.md](../ShopyFender_package/SHOPYFENDER_DATA_MODEL.md) | Data model |
| [SHOPYFENDER_3D_ASSET_LIST.md](../ShopyFender_package/SHOPYFENDER_3D_ASSET_LIST.md) | 3D asset list |
| [SHOPYFENDER_TEXTURE_SPEC.md](../ShopyFender_package/SHOPYFENDER_TEXTURE_SPEC.md) | Texture spec |
| [SHOPYFENDER_MCP_SETUP.md](../ShopyFender_package/SHOPYFENDER_MCP_SETUP.md) | MCP setup (starter package) |

## Project notes (`docs/`)

| Document | Topic |
|---|---|
| [HOW_TO_PLAY.md](HOW_TO_PLAY.md) | Player guide (controls, HUD, waves) |
| [decisions.md](decisions.md) | Accepted technical / product decisions |
| [mcp.md](mcp.md) | Current MCP setup in this repo (Godot / Blender / Context7) |

## Plans and designs (superpowers)

Detailed specs and implementation plans live in:

- [`docs/superpowers/specs/`](superpowers/specs/)
- [`docs/superpowers/plans/`](superpowers/plans/)

Examples: menu, HUD, inventory, store pressure, retail balance.

## Licenses and assets

- Code: [../LICENSE](../LICENSE) (MIT)
- Third-party: [../assets/LICENSES.md](../assets/LICENSES.md)
- Characters: [../assets/characters/README.md](../assets/characters/README.md)

## Quick commands

```bash
# Editor
godot --editor --path .

# Tests
godot --headless --path . -s res://tests/run_tests.gd

# Godot MCP (server + addon)
./tools/setup_mcp.sh
```
