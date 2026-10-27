## Context

See `proposal.md` for motivation. The simulation is a pure static-function pipeline over Dictionary state. `KarmaGame.update` and `main.gd::_physics_process` run every physics tick; `KarmaAI` delegates species work to `KarmaAI*` classes; `KarmaJev` builds batches from the same state. Distance helpers and roster filters are shared by AI, predators, JEV snapshots, and HUD paths, so changes must preserve the exact selected object and tie-break order.

## Goals / Non-Goals

**Goals:**

- Remove dead code and duplicate rules without changing any observable result.
- Remove avoidable allocations and square roots from per-tick query paths.
- Keep the change reviewable in small, behavior-preserving steps with characterization tests first.

**Non-Goals:**

- No spatial index, quadtree, or cross-tick cache.
- No AI, tuning, JEV cadence, save-format, or rendering behavior changes.
- No public API removals beyond confirmed unused helpers.
- No rebalancing or new magic thresholds.

## Decisions

- **Delete only confirmed dead symbols.** Remove the six unused `KarmaAI` wrappers and the three unused `*_definition` builders found with a project-wide reference scan. Keep the `_ai_*` wrappers that tests use as seams and keep definitions referenced by the facade. Alternative: remove all wrappers and update tests; rejected because it adds churn unrelated to the performance goal.
- **One max-HP rule.** Make `KarmaAI.ai_max_hp` delegate to `KarmaState.eff_max_hp_for`; `KarmaJevBridge.max_hp` continues delegating through that path. Alternative: rewrite every call site to `KarmaState.eff_max_hp_for`; rejected for a larger diff with the same result.
- **Remove the constant age multiplier.** Delete `KarmaUtils.eff_age_mult()` and its multiplication in `update_needs`. The function is a `1.0` stub already documented as dead in the senescence design.
- **Squared distances for comparisons.** In `nearest_from`, `nearest_hunter_in_fears`, `_nearest_zorro_hunter`, `nearest_victim_karma_aware`, `inside_water`, `los_blocked`, and `resolve_collisions`, compare squared distances. Keep the same strict `<` and iteration order, so equal-distance ties select the same first candidate. Compute `sqrt` only when movement normalization or an actual collision response needs the real distance. For `nearest_water_for`, compare against `(best_surface_distance + radius)^2` and update the best surface distance only on improvement. Alternative: leave `distance_to` everywhere; rejected because these helpers dominate per-tick math.
- **Hoist invariants out of loops.** Move `KarmaState.all_hunters(state)` above the `wander_mates` loop; the loop only moves company agents and does not mutate the hunter set. Alternative: cache hunters on state; rejected because it risks stale data across ticks.
- **Iterate flora categories directly.** Add one ordered key list next to `KarmaState.FLORA_KIND` and use it in `nearest_edible_patch_for`, `nearest_spare_flora_for`, `diet_hint_if_near`, and `collect_solids`. Preserve the current concatenation order (`bushes`, `shrubs`, `patches`, `clusters`, `clumps`, `oaks`) and skip `clumps` where the current code does. Alternative: keep concatenating arrays; rejected because it allocates a large temporary array per query.
- **Reuse the camera Dictionary in place.** Keep `state["cam"]` as `{x, y}` so save shape and tests stay stable, but initialize it once and mutate its fields during the tick. In `_draw`, read it once instead of building default dictionaries twice. Alternative: switch to `Vector2`; rejected because it changes the state shape for no behavior gain.
- **Cache the JEV view diagonal.** Compute `Vector2(VIEW_W, VIEW_H).length()` once as a member and have `_jev_view_diag()` return it. Alternative: keep recomputing; rejected because the value depends only on constants.
- **Shared cooldown and verb-cast cores.** Add `KarmaUtils.tick_cooldowns`/`tick_verb_cds` for the repeated decrement loops, and one `_cast_verb_core(state, actor, slot)` shared by `cast_verb` and `cast_verb_for`, with `actor == null` meaning the player state. Preserve both current lookup paths, defaults, and return values. Alternative: leave the duplicates; rejected because they make future cooldown changes easy to split.

## Risks / Trade-offs

- [Risk] Squared comparisons change a boundary or tie result through floating-point rounding → Mitigation: characterization tests pin nearest selection, equal-distance order, water range, LOS, and collision positions; use the same `<` direction and keep `sqrt` for movement.
- [Risk] Hoisting hunters observes a different set if the loop mutates agents → Mitigation: `wander_mates` only updates positions; add a test with multiple mates and hunters and verify identical movement.
- [Risk] In-place camera mutation aliases a shared Dictionary → Mitigation: `blank_state` creates a fresh dictionary per run; add a test that two states do not share camera data.
- [Risk] The verb-cast core changes player/agent default handling → Mitigation: tests for player cast, agent cast, cooldown rejection, and insufficient PA before and after extraction.
- [Risk] Flora key iteration changes plant order → Mitigation: keep the exact concatenation order and test an equal-distance flora pair.
- [Risk] Dead-code deletion removes a dynamic API → Mitigation: project-wide reference scan plus the full suite; no dynamic call sites found.

## Migration Plan

Refactor only. Rollback is the touched helper bodies and the deleted wrappers/builders; no save or data migration is needed.
