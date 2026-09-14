# Dokumentacja ShopyFender

Indeks materiałów projektowych. Specyfikacje designu są po angielsku; ten indeks i README repo — po polsku.

## Specyfikacje gry (`ShopyFender_package/`)

| Dokument | Temat |
|---|---|
| [SHOPYFENDER_MASTER_SPEC.md](../ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) | Główne źródło prawdy (design + priorytety rozwoju) |
| [SHOPYFENDER_GAME_LOGIC.md](../ShopyFender_package/SHOPYFENDER_GAME_LOGIC.md) | Logika rozgrywki |
| [SHOPYFENDER_DATA_MODEL.md](../ShopyFender_package/SHOPYFENDER_DATA_MODEL.md) | Model danych |
| [SHOPYFENDER_3D_ASSET_LIST.md](../ShopyFender_package/SHOPYFENDER_3D_ASSET_LIST.md) | Lista assetów 3D |
| [SHOPYFENDER_TEXTURE_SPEC.md](../ShopyFender_package/SHOPYFENDER_TEXTURE_SPEC.md) | Spec tekstur |
| [SHOPYFENDER_MCP_SETUP.md](../ShopyFender_package/SHOPYFENDER_MCP_SETUP.md) | Setup MCP (pakiet startowy) |

## Notatki projektu (`docs/`)

| Dokument | Temat |
|---|---|
| [INSTRUKCJA.md](INSTRUKCJA.md) | Instrukcja gry dla gracza (sterowanie, HUD, fale) |
| [decisions.md](decisions.md) | Zaakceptowane decyzje techniczne / produktowe |
| [mcp.md](mcp.md) | Aktualny stan MCP w tym repo (Godot / Blender / Context7) |

## Plany i designy (superpowers)

Szczegółowe specyfikacje i plany implementacji leżą w:

- [`docs/superpowers/specs/`](superpowers/specs/)
- [`docs/superpowers/plans/`](superpowers/plans/)

Przykłady: menu, HUD, inventory, store pressure, retail balance.

## Licencje i assety

- Kod: [../LICENSE](../LICENSE) (MIT)
- Third-party: [../assets/LICENSES.md](../assets/LICENSES.md)
- Postacie: [../assets/characters/README.md](../assets/characters/README.md)

## Szybkie komendy

```bash
# Edytor
godot --editor --path .

# Testy
godot --headless --path . -s res://tests/run_tests.gd

# Godot MCP (serwer + addon)
./tools/setup_mcp.sh
```
