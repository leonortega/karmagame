## Why

Four live `jev_ardilla.log` runs (40–51 decisions each) plus the new `jev_poll.json` telemetry show per-agent macro cadence at 26–48s against the specified 1s/3s timers: the single-flight round-robin scheduler lets always-due species dominate (sent counts 77/55/35/30 over one 390s run), threatened agents re-fire event re-asks with no new information (6 asks in 0.68s), and `carry_nut` is offered but never outranks bark/eat. The scheduler is healthy (0 sidecar errors, ~160ms flights) — the wait is queueing, not latency.

## What Changes

- Replace round-robin-from-last batch picking with longest-waiting-due-species-first across the four JEV species; single-flight HTTP is kept.
- Bound event re-asks with a per-agent minimum interval (`jevReaskBackoff`, 0.5s) so timer cadence keeps dominating while sub-second churn stops.
- Contract the shipped poll telemetry (`busy_skip` / per-species `sent` / `error` counters, `user://logs/jev_poll.json` snapshot on flush) as specified behavior.
- Add criteria-label salience hints on ardilla carry/bury entries (same mechanism as the shipped `(hunted!)` labels, which verified live) to give the ranker a temperament nudge without touching menus, odds, or tuning values.

## Capabilities

### New Capabilities

- `ai-jev-cadence`: fair-share JEV batch scheduling, event re-ask backoff, and the poll telemetry contract for all JEV species.

### Modified Capabilities

- `ai-jev-zorro`: cadence requirement — event re-ask is now backoff-bounded instead of unconditional-immediate.
- `ai-jev-halcon`: cadence requirement — same backoff bound.
- `ai-jev-raton`: cadence requirement — same backoff bound.

## Impact

- Affected code: `scripts/karma_jev.gd` (picker + `should_ask` + telemetry, already partially shipped), `scripts/main.gd` (poll match arm), `scripts/karma_data.gd` (`TUNING` gains `jevReaskBackoff`), `scripts/karma_jev_ardilla.gd` (carry/bury labels only), `tests/test_karma_jev_ardilla.gd` plus picker/backoff unit tests.
- No save-format migration: new state keys (`jev_last_served`, `jev_last_asked`) are additive with `.get` defaults; logs stay append-only outside saves.
- Dependency: archive `ardilla-jev-decisions` first so `ai-jev-ardilla` exists in main specs; the backoff covers ardilla through the new `ai-jev-cadence` spec regardless.
- Systems: F5 dev needs the NanoJev sidecar as before; behavior with the sidecar down is unchanged (ladder/micro fallbacks untouched).
