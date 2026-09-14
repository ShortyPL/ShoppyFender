# ShopyFender

A 3D retail management and store-layout optimization game — fixtures, assortment, inventory, customers, and checkout.

> Working title: **ShopyFender** · engine: **Godot 4.7** · language: **GDScript** · platform: PC

## Requirements

- [Godot 4.7+](https://godotengine.org/) (project targets 4.7 / Forward+)
- optional: Node.js (Godot MCP build), Blender + `uvx` (Blender MCP)

## Quick start

```bash
git clone https://github.com/ShortyPL/ShoppyFender.git
cd ShoppyFender
godot --editor --path .
```

Or open the project folder in Godot (`Project → Import`). Main scene: `scenes/ui/MainMenu.tscn`.

## Tests

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

After adding new `class_name` types or assets you may need:

```bash
godot --headless --path . --import
```

## Project layout

| Path | Description |
|---|---|
| `scenes/` | Godot scenes (UI, store, customers, staff) |
| `scripts/` | Game logic (economy, inventory, store, waves…) |
| `data/` | Catalog data (products, fixtures) |
| `assets/` | Models, textures, third-party licenses |
| `tests/` | Headless tests |
| `addons/godot_mcp/` | Editor MCP plugin |
| `ShopyFender_package/` | Design and data specs |
| `docs/` | Decisions, MCP notes, plans / design docs |

## Documentation

Full index: **[docs/README.md](docs/README.md)**

Highlights:

- [**How to play**](docs/HOW_TO_PLAY.md) — controls, HUD, waves
- [Master spec](ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) — design source of truth
- [Game logic](ShopyFender_package/SHOPYFENDER_GAME_LOGIC.md)
- [Data model](ShopyFender_package/SHOPYFENDER_DATA_MODEL.md)
- [Decisions](docs/decisions.md)
- [MCP setup](docs/mcp.md)

## MCP (Cursor + Godot / Blender)

For agent-assisted editing in Cursor:

```bash
./tools/setup_mcp.sh
```

Then open the project in Godot (**Godot MCP** plugin enabled, port `6505`) and optionally Blender MCP (port `9876`). Details: [docs/mcp.md](docs/mcp.md).

## License

- **Project code:** [MIT](LICENSE)
- **Third-party assets and tools:** [assets/LICENSES.md](assets/LICENSES.md) (e.g. Kenney / Quaternius CC0, Godot MCP MIT)

## Status

Hobby / solo. Playable prototype — prioritize simplicity, data-driven content, and fun over realism. See the master spec for details.
