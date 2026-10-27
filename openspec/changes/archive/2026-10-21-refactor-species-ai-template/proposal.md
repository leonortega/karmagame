## Why

The third-pass review of the AI layer found the same JEV step skeleton copy-pasted across the eight species AI scripts, with near-identical gate and steering blocks, plus a duplicated agent HP-fraction rule in the draw/HUD path. Every species fix had to be re-applied eight times, and the copies had already drifted. This change consolidates the shared skeleton so species-specific behavior stays explicit while the common order is written once.

## What Changes

- Add `KarmaAI.jev_step(state, a, dt, gates, steer, mock)`: one ordered JEV step skeleton (needs update -> base update -> intent tick -> gates -> steering -> live wander fallback -> mock macro), and route all eight species `step_jev` implementations through it.
- Add `KarmaAI.jev_gates_common(state, a, dt)` for the four species whose gate order is byte-identical (raton, topo, sapo, oruga). Zorro, lobo, ardilla and halcon keep species-specific gates.
- Add `KarmaJev.steer_intent(state, a, dt, hunt_kinds, chase_key, flee_moves)` for the generic hunt/chase steering shared by zorro and lobo. The other six species keep their species-specific steering.
- Add `KarmaDraw.hp_frac_for_agent(a)` so the agent HP bar fraction is computed once in the draw layer, used by `main.gd` and `KarmaHud`.
- Replace the remaining per-tick `.filter()` allocations and comparison-only square roots on the agent, hide, distant and respawn paths with plain loops and squared distances.
- No behavior, tuning, save-shape, JEV protocol or public API change: the same decisions run in the same order.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/karma_ai.gd`, `scripts/karma_ai_<species>.gd` (8 files), `scripts/karma_jev.gd`, `scripts/karma_draw.gd`, `scripts/karma_hud.gd`, `scripts/karma_state.gd`, `scripts/main.gd`.
- Affected tests: `tests/test_karma_jev.gd`, `tests/test_karma_jev_lobo.gd`, `tests/test_karma_hot_path_queries.gd`, `tests/test_karma_hot_paths.gd`.
- Systems: species JEV stepping, gate ordering, steering, agent HP bar rendering, per-tick scans. No menu, ranking, protocol or tuning changes.
- Verification: characterization pins for HP fraction, steer intent and the hot-path queries; the full gdUnit4 suite (612 cases) and a headless scene smoke must stay green.
