## 1. Pin current behavior first

- [x] 1.1 Add gdUnit4 characterization tests for `nearest_from` and `nearest_hunter_in_fears`: in-range, out-of-range, and equal-distance first-match order.
- [x] 1.2 Add tests for `nearest_water_for` surface range and `inside_water` boundary, plus blocked/unblocked `los_blocked` samples.
- [x] 1.3 Add a collision test that pins `resolve_collisions` output for a solid hit and a near-miss.
- [x] 1.4 Add a `wander_mates` test with multiple company agents and hunters that pins mate movement.
- [x] 1.5 Add cooldown parity tests for player and AI dictionary cooldowns plus `verbCds` array ticking.
- [x] 1.6 Add player/agent `cast_verb`/`cast_verb_for` tests covering success, cooldown rejection, and insufficient PA.
- [x] 1.7 Add tests pinning max-HP with and without `stomach`, equal-distance flora selection order, and fresh camera data per state.
- [x] 1.8 Run the focused tests and confirm they pass before refactoring.

## 2. Remove dead code and constant rules

- [x] 2.1 Delete the six unused `KarmaAI` wrappers and run diagnostics on `scripts/karma_ai.gd`.
- [x] 2.2 Delete `sapo_definition`, `topo_definition`, and `zorro_definition`; re-run the project-wide reference scan and diagnostics.
- [x] 2.3 Remove `KarmaUtils.eff_age_mult()` and its multiplication in `update_needs`; run the needs/senescence tests.
- [x] 2.4 Make `KarmaAI.ai_max_hp` delegate to `KarmaState.eff_max_hp_for`; run the max-HP and JEV bridge tests.

## 3. Consolidate duplicated rules

- [x] 3.1 Add `KarmaUtils.tick_cooldowns` and `tick_verb_cds`; use them in `KarmaGame.update`, `KarmaAI.ai_base`, and `KarmaPredators.step_predator`.
- [x] 3.2 Extract `KarmaGame._cast_verb_core` and route `cast_verb`/`cast_verb_for` through it; run the cast parity tests.
- [x] 3.3 Add one ordered flora key list and use it in `nearest_edible_patch_for`, `nearest_spare_flora_for`, `diet_hint_if_near`, and `collect_solids`; run the flora-order tests.

## 4. Replace comparison-only square roots

- [x] 4.1 Convert `nearest_from`, `nearest_hunter_in_fears`, `_nearest_zorro_hunter`, and `nearest_victim_karma_aware` to squared comparisons while keeping the same strict tie order.
- [x] 4.2 Convert `inside_water`, `los_blocked`, and the collision early-out to squared comparisons; keep `sqrt` only for collision response and movement normalization.
- [x] 4.3 Convert `nearest_water_for` to radius-adjusted squared comparisons; run the water and nearest-target tests.

## 5. Remove per-tick allocations

- [x] 5.1 Hoist `KarmaState.all_hunters(state)` above the `wander_mates` loop and run the mate-movement test.
- [x] 5.2 Initialize `state["cam"]` once, mutate its fields in place during the tick, and read the dictionary once in `_draw`; run the camera tests.
- [x] 5.3 Cache the JEV view diagonal as a member and use it in `_jev_view_diag`.

## 6. Verification and cleanup

- [x] 6.1 Run the full gdUnit4 suite and confirm all project tests are green.
- [x] 6.2 Run GDScript diagnostics on every touched script and confirm no parse or type errors.
- [x] 6.3 Boot the main scene once and confirm normal multi-species play with no visible behavior change.
- [x] 6.4 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
  - Fixed: `main.gd` lazy `_jev_view_diag_len` cache replaced by `const VIEW_DIAG := sqrt(VIEW_W * VIEW_W + VIEW_H * VIEW_H)`.
  - Deferred: the three flora scans in `karma_eat.gd` (`diet_hint_if_near`, `nearest_edible_patch_for`, `nearest_spare_flora_for`) share a shape but differ in filters; extracting one helper needs a mode flag or three near-duplicates, which trades ~20 lines for a worse interface. Revisit only if a fourth scan appears.
