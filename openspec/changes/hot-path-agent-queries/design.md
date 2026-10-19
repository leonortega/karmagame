## Context

See proposal.md. The simulation runs one tick per physics frame; `KarmaGame.update_agents` calls `KarmaAI.ai_step` for every non-hunter agent, predator passes call `stalk_victims`, and `main.gd` calls `_jev_poll` every tick. Several of these paths build a filtered array or recompute `_jev_view_diag()` per agent. `nearest_from` and `nearest_victim_karma_aware` define the selection tie-breaks that must survive any rewrite.

## Goals / Non-Goals

**Goals:**

- Remove per-call array allocation from the named hot paths while keeping the exact same selected result.
- Reuse per-tick data only where nothing mutates it in between.
- Keep JEV cadence, fairness, busy-skip accounting, and all range/perception rules unchanged.

**Non-Goals:**

- No new spatial index, quadtree, or caching layer across ticks.
- No cadence or tuning change, and no new magic intervals.
- No change to AI decisions, only to how the same decisions are computed.

## Decisions

- **Direct loops beat filtered arrays.** Replace `.filter()` in `is_hunted`, `ai_hide_tick`, `stalk_victims`, and the repeated inline predator queries with loops that apply the same predicate and return the same selected value. For existence checks like `is_hunted`, early exit is safe because only the boolean is consumed. For nearest-selection, keep using `nearest_from` on a prebuilt list so tie-breaking is unchanged. Alternative: keep `.filter()` and micro-optimize elsewhere; rejected because allocation is the measured churn.
- **Reuse the victim list inside one predator pass, rebuild after mutation.** Compute `stalk_victims` once and pass it to the strike/feast checks that read it before any kill mutates the agent list; recompute after a mutation or death. Alternative: a persistent victims cache on state; rejected as stale and state-polluting.
- **Hoist invariant per-tick work.** Compute `_jev_view_diag()` once per poll and pass the value into the due checks instead of recomputing the vector length per agent. Skip species whose agent list is empty before running cadence checks. Alternative: cache the diag on state; rejected because it is a single cheap value for the poll scope.
- **No cross-tick cache.** Any cache added lives for the tick only. Alternative: cache role buckets on state; rejected because births, deaths, and role changes would silently invalidate it.

## Risks / Trade-offs

- [Risk] A loop rewrite changes nearest selection tie-breaks -> Mitigation: characterization tests pin the selected victim for multi-candidate, equal-distance, and hidden-agent cases before the rewrite.
- [Risk] Reusing a victim list after a kill hides a newly eligible victim -> Mitigation: rebuild the list at every point the agent set changes, and test a tick that kills one prey among several.
- [Risk] Skipping empty species changes busy-skip telemetry -> Mitigation: assert `poll_note` counters are unchanged for empty and busy polls.

## Migration Plan

Refactor only; rollback is the touched loops. No data or save migration.
