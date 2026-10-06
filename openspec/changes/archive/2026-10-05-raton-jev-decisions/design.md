## Context

See proposal.md Why. Current state: `KarmaJev` is a facade — shared plumbing (`intent_tick/should_ask/mark_asked/log_decision/parse_answers`, per-species schema/path/flags) plus delegates to `KarmaJevZorro` / `KarmaJevHalcon`; `KarmaAI` dispatches `ai_step` to per-species strategies (`KarmaAIZorro`, `KarmaAIHalcon`, `KarmaAIRaton` ladder) with thin private delegates kept for test compatibility. Only `Main` owns I/O (no autoloads); simulation stays pure static funcs on `Dictionary` state. Raton diet is patch-only (`berries/apples/carrots/mushrooms/nuts`, no `insects`/`carrion`); its verbs are alarm/seedcache/groom/scout/share with the ladder's social path driven by `groomT`/`groomCd` plus slot-5 share.

## Goals / Non-Goals

**Goals:**
- Raton macro intent at player parity through the existing single-batch-per-window path, with the ladder as flag-off fallback.
- Third per-species log/scheme/flag triple (`jev-raton/v1`, `jev_raton.log`) reusing the seam with zero changes to zorro/halcon output.
- Social verbs provably preserved in JEV mode.

**Non-Goals:**
- No conversion of ardilla/topo/sapo/oruga/lobo in this change; no sidecar protocol change (same `Choice` shape, same evaluate URL).
- No runtime log toggle UI; no log rotation beyond the per-file cap.
- No rebalancing: all numbers stay in `KarmaData.TUNING`.

## Decisions

- **Grazer-shaped menu, legality-first.** `build_menu` offers eat (contact edible patch via `nearest_edible_patch_for`), seek-food (distant edible patch inside `vision × forageRangeMult`, only when hungry), drink-seek (below `regenSed` with water in forage range), flee-to-refuge (hunted + fitting refuge in `aiCoverRange`), alarm-call (hunter inside `shoutLureRange` with `shoutCd` ready), groom (company mate inside `groomRange`), seed-cache (edible flora with spare fruit in `eatRange`), wander always. No insect/carrion/pounce entries: raton diet has neither, so offering them would teach the ranker dead moves. Verbs were deferred in v1 and are now promoted because wander-only menus starve the log: zorro/halcon always have `dendig`/`bone` available, raton had no always-available entry. Alternative (log wander-only locally) rejected: zero-signal picks would pollute training data; a rankable choice carries real signal.
- **Micro owns survival, macro owns choice.** `_step_jev` ticks needs/cooldowns, runs hide-then-thirst reflexes, then steers intent; contact eat resolves locally without waiting. Wander falls through to `ai_maybe_verb` so groom/share karma survives. Groom-as-intent steers toward the mate and reuses the same 3s `groomT` timer (no instant karma, ladder parity); alarm and seed-cache apply instantly through `cast_verb_for` slots 1–2 with identical costs/cooldowns. Alternative (instant groom karma on apply) rejected: it would bypass the proximity timer and double-pay alongside the fallthrough.
- **Mock stays silent, live logs per-species.** `mock_macro` applies through player paths and never calls `log_decision`; live answers log under `jev-raton/v1` only when the raton flag is on. Mirrors the zorro/halcon rule so training data stays honest.
- **Fair scheduling reuse, no new HTTP path.** Raton due-lists join the existing `pick_batch_species` round-robin; one batch per window, 1s staggered / 3s far LOD, edge-triggered hunger/carrion re-ask. Alternative (raton-only poll) rejected: it would reintroduce the poll-starvation bug fixed for halcon.
- **Two files per species, facades stable.** `karma_ai_raton.gd` (strategy) + `karma_jev_raton.gd` (bridge); `KarmaAI._ai_raton*` and `KarmaJev.build_*/apply_*` stay as one-line delegates so `test_karma_jev.gd` and `main.gd` need no edits.

## Risks / Trade-offs

- [Risk] Stock checkpoint ignores seek-food (never saw grazer play) and wanders hungry → Mitigation: legality-first menus, wander executable, hunger hint unnecessary in v1 (patch proximity is geometric, unlike thermal affordability); log live traffic for the training follow-up.
- [Risk] Wander fallthrough double-counts social karma (macro + micro both trigger share) → Mitigation: share still gated by `verbCds`/cooldowns and mate proximity; tests assert single-grant per window.
- [Risk] Three-species batch pressure on sidecar → Mitigation: one HTTP call per window, skip single-candidate menus locally, keep short state text, keep LOD cadence.
- [Trade-off] Social verbs not rankable in v1 (ranker can't choose groom) → Accepted: preserves behavior; a later change can promote groom/share to menu candidates without touching micro.

## Migration Plan

- Additive: new bridge + strategy files; facade delegates with identical output; new `LOG_JEV_RATON` flag default off.
- Rollback: flip `USE_JEV_RATON` / `LOG_JEV_RATON` off to restore the ladder; delete `jev_raton.log` safely (training-only, outside saves).
- No data migration: log files are not read back by the game.
