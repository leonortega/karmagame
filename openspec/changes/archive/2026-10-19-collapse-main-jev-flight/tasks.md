## 1. Baseline the flight behavior (characterization)

- [x] 1.1 Add gdUnit4 coverage that pins fair-share selection across two or more due species using the existing picker and last-served record.
- [x] 1.2 Add coverage that pins busy-skip telemetry, `mark_served`, per-species `sent`, and `_jev_flushed` behavior before the refactor.
- [x] 1.3 Add coverage that pins timeout, error, and success clear paths so `_jev_busy` returns to false and the flight record empties.
- [x] 1.4 Run the focused tests and confirm they pass on the current duplicated implementation.

## 2. Collapse the flight state

- [x] 2.1 Replace the eight `_agents` / `_menus` / `_snaps` field groups with one `_jev_flight` record while keeping `_jev_busy` and `_jev_last_species`.
- [x] 2.2 Replace the eight send functions with one `_send_batch(species, due)` that dispatches to the existing per-species body builders and preserves `jev_live`, `poll_note`, `mark_served`, and `mark_asked` calls.
- [x] 2.3 Route `_on_jev_done` and the timeout/error paths through one apply and one clear function keyed off the flight record.
- [x] 2.4 Run the focused tests and confirm they pass unchanged.

## 3. Verification and cleanup

- [x] 3.1 Run the full gdUnit4 suite and confirm JEV cadence, fairness, logging, and menu tests are green.
- [x] 3.2 Run GDScript diagnostics on `main.gd` and confirm no parse or type errors.
- [x] 3.3 Boot the main scene once and confirm JEV batches still resolve for at least two species with no stuck-busy state.
- [x] 3.4 Run `ponytail-review` over the diff and fix or explicitly defer every finding.
