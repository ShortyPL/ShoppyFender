# Retail balance fixes — design

Date: 2026-09-13
Status: Approved
Godot: 4.7, GDScript, `/Volumes/TimeData/Cursor/ShoppyFender`

## Goal

Fix unfair checkout reservation, scale the till bottleneck, restore stock pressure in SIM, deepen shopping lists, persist a real run, and replace dummy HUD XP/goals with live metrics.

## Decisions (locked)

1. **Enqueue on arrival** — after all picks, walk to checkout approach; `enqueue` in `_enter_queued`. Pay only when front is present and queued/paying.
2. **Second checkout upgrade** — `&"second_checkout"` cost 400; dual `CheckoutQueue`; shorter-line join; second cashier stand.
3. **Auto-fill** — SIM uses `auto_fill_preference` (default false); no force-on in `_begin_wave`.
4. **Lists** — 2–3 unique SKUs, deterministic from spawn index; first OOS fails (no partial basket).
5. **Save** — wave, clock, pending, ordered, stars_history, start_cash.
6. **HUD** — Avg ★, Cash Δ, live wave goals; RESULTS lost breakdown oos/queue/path.

## Out of scope

Customer RVO, MCP strip for release, wages/rent, partial baskets.
