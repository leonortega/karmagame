## Context

See proposal.md Why. Today `main.gd` builds only left/right side panels in one HUD `CanvasLayer`, routes `1-5` vs `1-3` on `shopOpen` in `_unhandled_input`, and runs `KarmaGame.update` every physics tick unless `dead`. `KarmaShop.judge` and `draw_start_form` already decide fate instantly with no presentation. There is no pause flag and no center modal.

## Goals / Non-Goals

**Goals:**
- One modal shell serving shop, birth, judgment, pause with shared freeze + focus behavior.
- Draw-first fate (RNG unchanged) with display-only roulette animation.
- Shop ledger rules byte-identical (`buy_item`, deduct/reject/never-negative/once-per-life).

**Non-Goals:**
- No TUNING rebalance, no new species/verbs/adaptations, no JEV protocol change.
- No save system or run restart beyond fresh-run birth modal.
- No per-popup freeze exceptions; one freeze rule for all modals.

## Decisions

- Single modal manager inside `main.gd` HUD layer (`CenterContainer` + dim `ColorRect` + `PanelContainer`) over four separate scenes. Rationale: HUD already constructs panels this way, keeps one `_unhandled_input` router and one `_refresh_hud` path; alternatives (four scenes, `_draw` text overlay) split focus handling and lose button accessibility.
- Freeze by early-return in `_physics_process` when any modal is open (skip `move_player`, `KarmaGame.update`, JEV poll/flush, timer accrual), while `queue_redraw` and timed HUD refresh continue. Rationale: minimal sim touch, guarantees safe shopping and drama; alternative `get_tree().paused` would require pause-mode audits on every node/timer.
- State flags in the existing state Dictionary (`shopOpen` kept, plus `paused`, birth `introDone`/`introNext`, death `pendingNext`/`pendingPool` kept) drive a priority selector: judgment > birth > pause > shop > play. Rationale: resolves death-while-shop and birth-while-paused races deterministically.
- Roulette is display-only: birth pre-draws via `draw_start_form`, death pre-draws via `judge` at `hp<=0`; modal cycles `highlight_idx` on HUD time and locks to the stored result. Involution pool of one settles instantly. Rationale: preserves seed parity and gdUnit4 testability; animation never consumes RNG.
- Builders stay pure: extend `KarmaHud` row builders for modal content and reuse `KarmaShop.catalog_for`/`buy_item`/`has_adapt`, `KarmaDraw.species_icon`, `SPECIES` names/tiers. Scene-owned `main.gd` keeps all Control creation and input.

## Risks / Trade-offs

- [Risk] `VIEW_W 1280` vs 960x600 window comment → modal mis-centered → Mitigation: anchor center modal to viewport, verify at both sizes before done.
- [Risk] Emoji fallback widths vary (`ardilla`, refuges) → Mitigation: highlight via font/bg color, never via scaling; fixed cell minimums.
- [Risk] JEV in-flight request resolves while frozen → Mitigation: freeze poll/flush issue, still accept `request_completed` and apply on resume; never block modal on network.
- [Risk] Death while shop open loses the shop context → Mitigation: priority selector closes shop and opens judgment; shop `owned`/PA already ledger-consistent.
- [Trade-off] Frozen shopping removes time pressure → accepted: matches JS ceremony intent and prevents shopping deaths.

## Migration Plan

Additive only: new flags default to play-through behavior, no save migration, no spec archive beyond this change. Rollback is deleting the modal layer and restoring the old `shopOpen`-only key branch.

## Open Questions

- Roulette cadence (cycle speed, settle ease, skippable vs fixed ~2s) can be tuned in implementation without changing specs.
- Pause recap depth (show verbs vs controls-only) can be trimmed during build without changing freeze/focus behavior.
