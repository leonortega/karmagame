## Context

See proposal.md (Why). The lobo bridge already builds snapshots (`hp_frac`, `hambre`, `sed`, `hungry`, …), appraises `emocion` locally with a fixed rule (fear on threat/pressure, urgency on floor hunger, hunger otherwise), and logs every live decision through the shared `KarmaJev.log_decision`, which buffers per-species entries the Main flush writes out. Mock decisions never reach `log_decision`. Mock priority is already eat-first (covered by `test_mock_choice_prefers_eat`).

## Goals / Non-Goals

**Goals:**

- Ranker-readable need urgency in the lobo state string without removing fields.
- Automatic red-flag counting for hungry + `eat`-offered + `wander`-picked, visible in the already-read `jev_poll.json`.
- Zero change to menu legality, mock order, cadence, or sidecar protocol.

**Non-Goals:**

- No ranker-behavior guarantees (the sidecar decides; we only clarify input and count output).
- No per-species screens beyond lobo; no changes for the six other species.

## Decisions

### 1. Pure `need_token` on the bridge, appended to `state_text`

Why: keeps the rule next to `appraise_emocion` (same inputs, same ordering: floor-hunger urgency first, then hunger, then thirst-when-hunger-does-not-dominate, else none) and leaves `build_state` shape untouched. `state` is a free-form string in the server contract, so this is protocol-safe. Alternative (new snapshot field + text) was rejected: the text is the only thing the ranker reads.

### 2. Screen inside `log_decision`, counters on run state, flush includes them

Why: `log_decision` is the one place where snapshot + menu + choice + species meet, and it already early-outs for disabled species and mocks — so screening there inherits both guards for free (mocked decisions never counted, disabled species cost nothing). The counter (`state["jev_red_flags"]`, per-species cumulative) is bumped only for live, enabled decisions; `_jev_flush_log` writes the dict into `jev_poll.json` in one line, defaulting to `{}` when absent. Alternative (screening in the bridge's `apply_answer`) was rejected: apply runs for mocks too and lacks the enabled-flag context.

### 3. Mock order untouched

Why: verified eat-first by the existing test; the offline path already prefers consumption. No code change, just the verification task.

### 4. Species-dispatched screen, lobo-only for now

Why: the red-flag rule references the `eat` menu kind, which is lobo-specific today. `log_decision` dispatches the screen by species (`lobo` → `KarmaJevLobo.is_red_flag`, default → no screen), so other species gain screens later without touching the shared path. Trade-off: one more species branch in shared code, same shape as the existing per-species log keys.

## Risks / Trade-offs

- [Risk] Urgency token does not move ranker behavior → Mitigation: it is input clarification only; the counter tells us within one run whether picks change.
- [Risk] Archive stacking: the unarchived `ai-jev-lobo` change also edits the cadence telemetry text (six→seven species) → Mitigation: whoever archives second re-verifies the telemetry requirement; noted here so it is not lost.
- [Risk] Counters freeze when lobo logging is off → Mitigation: accepted and predictable — telemetry rides the log path by design.

## Migration Plan

None needed. New lives pick up the token immediately; counters start at zero per run. Rollback is revert.

## Open Questions

- None that change scope. Whether the token moves live ranker picks is answered empirically from the next `jev_lobo.log` + `red_flags` count.
