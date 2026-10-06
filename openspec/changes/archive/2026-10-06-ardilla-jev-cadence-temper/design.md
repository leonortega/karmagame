## Context

See proposal.md (Why). Current state: `Main._jev_poll` runs every physics tick, collects due agents per species via `KarmaJev.should_ask`, and sends one batch per poll through `pick_batch_species_4` (round-robin from last sender) over a single shared `HTTPRequest`. `mark_asked` sets the next timer slot (1s near / 3s far + stagger); event branches in `should_ask` bypass it with no lower bound. `poll_note` counters and `jev_poll.json` already ship. Numbers live in `KarmaData.TUNING`; no rebalancing without spec (this change is that spec).

## Goals / Non-Goals

**Goals:**
- Bound worst-case per-species wait with a scheduler no bigger than the current picker.
- Bound per-agent event re-ask rate without losing sub-second threat response.
- Keep single-flight HTTP and all existing menu/odds/tuning values.

**Non-Goals:**
- Parallel per-species flights, sidecar prompt/weight changes, shop/pa-hoarding fixes, spawn rebalance.

## Decisions

- **Fair-share = longest-waiting due species first** (`state["jev_last_served"]`, updated on send; picker takes due flags + map). Over strict rotation (status quo, measured skewed 77/55/35/30) because rotation only fair-shares among the due set while always-due species crowd out intermittent ones; over parallel flights (4 `HTTPRequest` nodes + response routing + 4× sidecar load) because the pipe is idle 91% of ticks — throughput is not the bottleneck, ordering is.
- **Backoff = per-agent timestamp, 0.5s window** (`state` per-agent `jev_last_asked`, set in `mark_asked`; event branches in `should_ask` require `now - last >= TUNING["jevReaskBackoff"]`). 0.5s = 30 physics ticks of micro response (hide reflex runs every tick regardless), well under the 1s timer so timers keep dominating, and an order above the observed 100ms churn. Over transition-only re-ask (needs per-agent prev-state memory — more state than one timestamp).
- **Telemetry = as shipped, now contractual.** `poll_note` + `jev_poll.json` overwrite on flush already exist from the prior round; this change specs them so they cannot silently regress. No migration: all new state keys are additive with `.get` defaults.
- **Carry temperament = criteria-label salience only** (same mechanism as the live-verified `(hunted!)` labels). No menu, odds, or tuning changes — the ranker sees identical options with clearer stakes, exactly the lever that worked for threats.
- **Emocion null = local appraisal with source marking** (added scope). The sidecar demonstrably sends no emotion field (`intent_keys` identical across live runs), so `KarmaJev.appraise_emocion` fills empty answers from snapshot state (Miedo/Esperanza/Hambre, else empty) and `emocion_source` (`ranker`/`local`) flows parse→log so flavor origin stays auditable. No spec delta: the requirement says answers MAY carry emocion and it never gates execution — both hold.

## Risks / Trade-offs

- [Risk] Backoff delays a genuine rapid event sequence (threat appears 0.2s after a timer ask) by up ??? Mitigation: micro hide/flee reflexes run every physics tick independent of macro intent (audit-tested), so immediate safety never waits for ranking.
- [Risk] Longest-waiting can delay a threatened species behind a long-waiting calm one ??? Mitigation: no worse than rotation today; the threatened agent's next poll re-arms it, and event re-ask still jumps the timer queue.
- [Risk] `jevReaskBackoff` value proves wrong in F5 (too chatty / too sleepy) ??? Mitigation: single TUNING key, one-line change, gdUnit4 boundary tests pin both sides of the window.

## Migration Plan

Land behind no flags (scheduler/backoff are corrections toward specified cadence, not new features). Rollback = revert; old logs remain parseable (only additive fields). Archive `ardilla-jev-decisions` first so `ai-jev-ardilla` exists before these deltas merge.
