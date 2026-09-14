# Contributing — ShopyFender

Projekt hobby / solo. Ten plik opisuje, jak bezpiecznie dokładać zmiany (ludzie i agenty).

## Zanim zaczniesz

1. Przeczytaj [SHOPYFENDER_MASTER_SPEC.md](ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) przy zmianach architektury lub gameplayu.
2. Sprawdź [docs/decisions.md](docs/decisions.md) — nie odwracaj zaakceptowanych decyzji bez wpisu.
3. Preferuj rozwiązania proste i data-driven (`data/`) zamiast hardcodu w skryptach.

## Środowisko

- Godot **4.7+**
- Root projektu: katalog z `project.godot` (nie używaj starej ścieżki `~/Developer/ShopyFender`)

```bash
godot --editor --path .
```

## Testy

Każda zmiana logiki powinna przejść headless suite:

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

Nowe zachowania: dodaj asercje w `tests/` albo w `tests/run_tests.gd`. Nie commituj z czerwonymi testami.

## Konwencje kodu

- GDScript, czytelne nazwy, małe skrypty z jedną odpowiedzialnością
- Sceny w `scenes/`, logika w `scripts/`, definicje treści w `data/`
- Komentarze tylko tam, gdzie logika nie jest oczywista
- Bez over-engineeringu na wczesne prototypy
- Runtime gry ma być niezależny od MCP

## MCP / narzędzia edytora

Godot MCP i Blender MCP służą do edycji i inspekcji — nie są częścią buildu gry.

- Setup: `./tools/setup_mcp.sh`
- Notatki: [docs/mcp.md](docs/mcp.md)
- Nie commituj sekretów, tokenów ani lokalnych venv (`.tools/`)

## Commity i PR

- Małe, fokusowane zmiany z jasnym „dlaczego”
- Opisz w PR: co zmienia gameplay / API, jak przetestowano
- Nie force-pushuj na `main` bez uzgodnienia

## Licencje assetów

Nowe zewnętrzne assety zapisz w [assets/LICENSES.md](assets/LICENSES.md) (źródło, autor, licencja, data, ścieżka lokalna).
