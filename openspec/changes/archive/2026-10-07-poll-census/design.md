## Context

See proposal.md (Why). Current state: `Main._jev_flush_log` writes `{"t", "poll": state["jev_poll"]}` (cumulative counters via `KarmaJev.poll_note`); species `all_jev_*` selectors already filter agents per species. Nothing counts population or supply.

## Goals / Non-Goals

**Goals:**
- One snapshot dict, computed at flush from already-in-memory state, zero sim impact.

**Non-Goals:**
- No per-agent details (positions go in species logs, not here).
- No water-kind split (map composition is static per run; one in-game look settles it).
- No counter semantics change (`poll` stays cumulative as specified).

## Decisions

- **Helper `KarmaJev.census(state)` returns `{insects: int, carrions: int, agents: {key: int}}`.** Pure read of `state["insects"]`, `state["carrions"]`, and a speciesKey histogram over `state["agents"]` (all roles; missing lists count 0). Alternative (incremental counters on spawn/death) rejected: more touchpoints, drift risk, same result.
- **Flush merges, never replaces.** `{"t", "poll", "census"}` — old readers parsing `t`/`poll` keep working. The census is recomputed per flush, not accumulated.

## Risks / Trade-offs

- [Risk] Histogram each 0.5s flush costs little (agents number in the tens) → Mitigation: none needed; bounded by existing flush cadence.

## Migration Plan

Helper plus one flush line plus tests. Rollback is the line out (file returns to the two-key shape).
