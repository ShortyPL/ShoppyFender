# Retail balance fixes — implementation plan

See Cursor plan `retail_balance_fixes` and design spec `docs/superpowers/specs/2026-09-13-retail-balance-fixes-design.md`.

## Tasks

1. Enqueue on arrival + tests
2. Second checkout upgrade + dual lanes
3. Auto-fill preference in SIM
4. Multi-SKU shopping lists 2–3
5. Lost-sale breakdown in RESULTS
6. RunSave meta fields
7. HUD Avg ★ / Cash Δ / live goals
8. Spec, decisions, regression

## Verification

```bash
godot --headless --path /Volumes/TimeData/Cursor/ShoppyFender -s res://tests/run_tests.gd
```

Expect: All tests passed (including playtest bot 10/10, stars 3).
