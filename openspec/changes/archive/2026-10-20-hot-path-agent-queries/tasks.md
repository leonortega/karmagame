## 1. Pin query outcomes first (characterization)

- [x] 1.1 Add gdUnit4 tests that pin `is_hunted` true/false outcomes for in-range, out-of-range, hidden, and non-edible candidates.
- [x] 1.2 Add tests that pin the predator victim selected for multi-candidate and equal-distance cases.
- [x] 1.3 Add tests that pin a predator tick where one of several victims is killed, so list reuse cannot hide a newly eligible victim.
- [x] 1.4 Add a test that pins `_jev_poll` busy-skip telemetry and the due-set for a multi-species tick.
- [x] 1.5 Run the focused tests and confirm they pass on the current implementation.

## 2. Replace hot-path filters with loops

- [x] 2.1 Rewrite `is_hunted` as a loop with early exit and confirm the pinned outcomes.
- [x] 2.2 Rewrite the `ai_hide_tick` danger scan and the repeated inline predator queries as direct loops with the same predicate.
- [x] 2.3 Build `stalk_victims` once per predator pass and rebuild it after any kill or agent-set mutation, then confirm the victim tests.
- [x] 2.4 Run the focused tests and confirm no outcome changed.

## 3. Trim JEV poll work

- [x] 3.1 Hoist `_jev_view_diag()` and any other invariant per-poll value out of the per-agent loop.
- [x] 3.2 Skip species with no agents before running cadence checks, keeping busy-skip and sent counters identical.
- [x] 3.3 Run the focused cadence and telemetry tests and confirm they pass unchanged.

## 4. Verification and cleanup

- [x] 4.1 Run the full gdUnit4 suite and confirm AI, predator, JEV, and simulation tests are green.
- [x] 4.2 Run GDScript diagnostics on every touched script and confirm no parse or type errors.
- [x] 4.3 Boot the main scene once and confirm a normal multi-species run with no behavior change.
- [x] 4.4 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
