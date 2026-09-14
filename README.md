# ShopyFender

Gra 3D o zarządzaniu sklepem detalicznym i optymalizacji układu — layout, półki, asortyment, stany magazynowe, klienci i kasa.

> Working title: **ShopyFender** · silnik: **Godot 4.7** · język: **GDScript** · platforma: PC

## Wymagania

- [Godot 4.7+](https://godotengine.org/) (projekt celuje w 4.7 / Forward+)
- opcjonalnie: Node.js (build Godot MCP), Blender + `uvx` (Blender MCP)

## Szybki start

```bash
git clone https://github.com/ShortyPL/ShoppyFender.git
cd ShoppyFender
godot --editor --path .
```

Albo otwórz folder projektu w Godocie (`Project → Import`). Scena startowa: `scenes/ui/MainMenu.tscn`.

## Testy

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

Po dodaniu nowych `class_name` lub assetów czasem trzeba najpierw:

```bash
godot --headless --path . --import
```

## Struktura projektu

| Ścieżka | Opis |
|---|---|
| `scenes/` | Sceny Godot (UI, sklep, klienci, staff) |
| `scripts/` | Logika gry (ekonomia, inventory, store, waves…) |
| `data/` | Dane katalogów (produkty, fixtures) |
| `assets/` | Modele, tekstury, licencje third-party |
| `tests/` | Testy headless |
| `addons/godot_mcp/` | Plugin MCP do edytora |
| `ShopyFender_package/` | Specyfikacje designu i danych |
| `docs/` | Decyzje, MCP, plany / design docs |

## Dokumentacja

Pełny indeks: **[docs/README.md](docs/README.md)**

Najważniejsze:

- [Master spec](ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) — źródło prawdy designu
- [Game logic](ShopyFender_package/SHOPYFENDER_GAME_LOGIC.md)
- [Data model](ShopyFender_package/SHOPYFENDER_DATA_MODEL.md)
- [Decisions](docs/decisions.md)
- [MCP setup](docs/mcp.md)

## MCP (Cursor + Godot / Blender)

Do pracy z agentem w Cursorze:

```bash
./tools/setup_mcp.sh
```

Potem otwórz projekt w Godocie (plugin **Godot MCP** włączony, port `6505`) i ewentualnie Blender MCP (port `9876`). Szczegóły: [docs/mcp.md](docs/mcp.md).

## Licencja

- **Kod projektu:** [MIT](LICENSE)
- **Zewnętrzne assety i narzędzia:** [assets/LICENSES.md](assets/LICENSES.md) (m.in. Kenney / Quaternius CC0, Godot MCP MIT)

## Status

Hobby / solo. Prototyp playable — priorytet: prostota, data-driven content, fun przed realizmem. Szczegóły w master spec.
