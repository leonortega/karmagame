## Context

See proposal.md Why. Current state: `KarmaJev` is a facade over per-species bridges (`KarmaJevZorro`, `KarmaJevHalcon`, `KarmaJevRaton`) with shared plumbing (`intent_tick/should_ask/mark_asked/log_decision/parse_answers`, per-species schema/path/flags) and an explicit 3-way scheduler (`pick_batch_species_3`); `KarmaAI` dispatches `ai_step` to per-species strategies with thin private delegates kept for test compatibility. Only `Main` owns I/O (no autoloads); simulation stays pure static funcs on `Dictionary` state. Ardilla diet is patch-and-nut-only (`berries/apples/mushrooms/nuts`); its verbs are tailflick/seedcache-plant/bark/falsecache/groom with the ladder's nut logic driven by `carriedNut` plus slot verbs. Project stance: per-species everything, no generalized scheduler.

## Goals / Non-Goals

**Goals:**
- Ardilla macro intent at player parity through the existing single-batch-per-window path, with the ladder as flag-off fallback.
- Fourth per-species log/schema/flag triple (`jev-ardilla/v1`, `jev_ardilla.log`) reusing the seam with zero changes to other species' output.
- Two-phase carry provably preserved across intent expiry.

**Non-Goals:**
- No conversion of topo/sapo/oruga/lobo in this change; no sidecar protocol change (same `Choice` shape, same evaluate URL).
- No runtime log toggle UI; no log rotation beyond the per-file cap.
- No rebalancing: all numbers stay in `KarmaData.TUNING` / `SPECIES`.

## Decisions

- **Carry/bury as paired candidates, state on the agent.** `build_menu` offers carry-nut (oak with nuts near, hands empty) and bury-nut (`carriedNut` true); `carriedNut` lives on the agent dict so intent expiry or replacement never drops the nut. Hungry carriers eat it via the ladder's exact rule. Alternative (intent-carried nut payload) rejected: a replaced intent would void the pickup and teach the ranker phantom moves.
- **Climbing needs no new code.** No z-axis exists; `climbOnly` refuges resolve through the shared `refuge_fits_size` filter already used by the flee menu. The decision is recorded here so nobody re-solves it for topo/sapo.
- **Explicit 4-way scheduler, no generalization.** `pick_batch_species_4` mirrors `_3` with its own tests; `_3` stays byte-identical for its callers and tests. Alternative (list-based round-robin) rejected per the per-species-everything stance: a topo scheduling bug must never be able to break zorro polling.
- **Mock stays silent, live logs per-species.** Same rule as the three converted species: `mock_macro` applies through player paths and never calls `log_decision`.
- **Flag rotation.** `LOG_JEV_ARDILLA` defaults on, `LOG_JEV_RATON` flips off with this change; zorro/halcon stay off. Only the migrating species is ever noisy.
- **Two files per species, facades stable.** `karma_ai_ardilla.gd` (strategy) + `karma_jev_ardilla.gd` (bridge); `KarmaAI._ai_ardilla*` and `KarmaJev.build_ardilla_*/apply_ardilla_*` stay as one-line delegates so existing tests and `main.gd` call sites keep working.

## Risks / Trade-offs

- [Risk] Ranker ignores bury-nut (never saw carry/bury play) and carriers wander holding nuts → Mitigation: legality-first menus, wander executable, hungry-carrier rule bounds the waste (worst case it eats the nut); log live traffic for the training follow-up.
- [Risk] Four-species batch pressure on sidecar → Mitigation: one HTTP call per window, skip single-candidate menus locally, keep short state text, keep LOD cadence.
- [Trade-off] Duplicated scheduling/menu code across four bridges → Accepted per project stance; ponytail will flag it every time and the answer stays no.
- [Trade-off] Social verbs not rankable in v1 beyond groom-share fallthrough → Accepted; later change can promote more without touching micro.

## Migration Plan

- Additive: new bridge + strategy files, one scheduler function, one flag; existing species' outputs byte-identical.
- Rollback: flip `USE_JEV_ARDILLA` / `LOG_JEV_ARDILLA` off to restore the ladder; delete `jev_ardilla.log` safely (training-only, outside saves).
- No data migration: log files are not read back by the game.
