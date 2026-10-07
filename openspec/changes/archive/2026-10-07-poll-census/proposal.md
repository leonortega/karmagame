## Why

Live-log diagnosis keeps stalling on unanswerable questions: poll counters prove batches go out, species logs prove what agents perceived — but nothing records how many insects exist or how many agents of each species are alive. Two consecutive sapo runs show zero insect encounters without revealing whether supply or positioning is at fault.

## What Changes

- Each `jev_poll.json` flush gains a `census` snapshot alongside the cumulative `poll` counters: live insect count, carrion count, and agent count per species key.
- One pure helper (`KarmaJev.census`) builds it from run state; the flush merges it in. No sim, tuning, scheduling, or log-schema breaking changes (additive keys only).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `ai-jev-cadence`: the poll telemetry snapshot gains the per-flush census next to the cumulative counters.

## Impact

- Affected code: one helper in `scripts/karma_jev.gd`, one merged line in `Main._jev_flush_log`.
- Tests: helper unit tests (counts, empty state, per-species buckets).
- No gameplay, economy, or cadence changes; downstream log readers ignore unknown keys safely.
