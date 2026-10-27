## 1. Pin current behavior first

- [x] 1.1 Add a characterization pin for the agent HP fraction used by the draw and HUD paths.
- [x] 1.2 Add pins for the zorro and lobo steer-intent decisions that the shared steering helper must reproduce.
- [x] 1.3 Add pins for the hot-path agent queries (nearest target, cooldown ticking, cast-verb parity) before touching the per-tick paths.
- [x] 1.4 Run the focused tests and confirm they pass before refactoring.

## 2. Consolidate the shared rules

- [x] 2.1 Add `KarmaDraw.hp_frac_for_agent(a)` and route `main.gd` and `KarmaHud` through it.
- [x] 2.2 Add `KarmaJev.steer_intent(state, a, dt, hunt_kinds, chase_key, flee_moves)` and give zorro and lobo thin wrappers.
- [x] 2.3 Add `KarmaAI.jev_step(state, a, dt, gates, steer, mock)` with the shared JEV step order.
- [x] 2.4 Add `KarmaAI.jev_gates_common(state, a, dt)` for the four species whose gate order is identical.

## 3. Adopt the template per species

- [x] 3.1 Route zorro and lobo `step_jev` through the template, keeping their species gates.
- [x] 3.2 Route raton, ardilla and topo through the template, keeping the ardilla `carriedNut` gate rule.
- [x] 3.3 Route sapo, oruga and halcon through the template, keeping the halcon strike/thirst/grounded gate order and `mock_halcon_macro`.
- [x] 3.4 Point raton, topo, sapo and oruga at `jev_gates_common` and delete the four duplicated gate copies.

## 4. Reduce per-tick allocations

- [x] 4.1 Replace the remaining `.filter()` allocations on the agent, hide, distant and respawn paths with plain loops.
- [x] 4.2 Replace comparison-only square roots on the hide and respawn paths with squared distances.

## 5. Verification and review

- [x] 5.1 Run the full gdUnit4 suite and confirm all project tests are green (612 cases).
- [x] 5.2 Run GDScript diagnostics on every touched script, run the project-wide compile check, and run the headless scene smoke.
- [x] 5.3 Run a `ponytail-review` pass over the diff and fix or explicitly defer each finding.
- [x] 5.4 Run a `ponytail-audit` over the changed files and record which findings were applied and which were rejected.
