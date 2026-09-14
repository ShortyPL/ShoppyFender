# Contributing — ShopyFender

Hobby / solo project. This file explains how to add changes safely (humans and agents).

## Before you start

1. Read [SHOPYFENDER_MASTER_SPEC.md](ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) for architecture or gameplay changes.
2. Check [docs/decisions.md](docs/decisions.md) — do not reverse accepted decisions without a new entry.
3. Prefer simple, data-driven solutions (`data/`) over hardcoding in scripts.

## Environment

- Godot **4.7+**
- Project root: the folder that contains `project.godot` (do not use the old `~/Developer/ShopyFender` path)

```bash
godot --editor --path .
```

## Tests

Every logic change should pass the headless suite:

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

New behavior: add asserts in `tests/` or `tests/run_tests.gd`. Do not commit with failing tests.

## Code conventions

- GDScript, clear names, small single-responsibility scripts
- Scenes in `scenes/`, logic in `scripts/`, content definitions in `data/`
- Comments only where logic is non-obvious
- No over-engineering on early prototypes
- Game runtime must stay independent of MCP

## MCP / editor tools

Godot MCP and Blender MCP are for editing and inspection — not part of the game build.

- Setup: `./tools/setup_mcp.sh`
- Notes: [docs/mcp.md](docs/mcp.md)
- Do not commit secrets, tokens, or local venvs (`.tools/`)

## Commits and PRs

- Small, focused changes with a clear “why”
- In the PR: what gameplay / API changes, how it was tested
- Do not force-push `main` without agreement

## Asset licenses

Record new third-party assets in [assets/LICENSES.md](assets/LICENSES.md) (source, author, license, date, local path).
