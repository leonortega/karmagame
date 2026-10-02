## Context

See proposal.md Why. Current state: `KarmaAI._ai_zorro` is a synchronous priority ladder inside `KarmaGame.update_agents`, called every physics tick; agents are plain Dictionaries; only `Main` owns I/O and there are no autoloads (AGENTS.md). NanoJev runs as a LAN sidecar (`serve_decisions.py`, `POST http://192.168.100.80:8766/api/evaluate`, `Choice` over 2-255 dynamic candidates, stock `unified-games-v1` checkpoint trained on Maze/Snake/ViZDoom, not karmagame). Zorro values live in `KarmaData` (`SPECIES`, `DIET`, `VERB_DEFS[zorro]` 5 verbs, `PRED[zorro]`, `TUNING`, `SHOP_BY_SPECIES[zorro]`).

## Goals / Non-Goals

**Goals:**
- Give AI zorros the full 5-verb player menu through a batch-ranked decision that is always executable.
- Keep 60Hz steering responsive with zero API blocking; macro intent at ~1s/event cadence.
- Ship zorro-only behind a seam the other 7 species can reuse later.

**Non-Goals:**
- No behavior-tree framework, no autoload AI Manager, no per-animal scene nodes.
- No checkpoint training in this change (log first, train later).
- No remote hosting, auth, or GPU provisioning; dev-local sidecar only.
- No rebalancing of karma/HP/PA numbers.

## Decisions

**1. Static `KarmaJev` helper owned by Main, not an autoload.**
Why: preserves the `no autoloads, only Main owns I/O` rule while getting the same single-batch-per-window behavior the summary wanted from an AI Manager. Main collects zorro snapshots, calls the helper to build the batch, awaits one HTTP call, applies answers.
Alternative considered: global Autoload AI Manager. Rejected: breaks standing convention and complicates headless tests.
Alternative considered: per-zorro HTTP calls. Rejected: N roundtrips per window, saturates the sidecar, violates the parallel-batch goal.

**2. Option B: code builds candidates, JEV ranks (Choice).**
Why: NanoJev's native `Choice` primitive is a distribution over caller-supplied candidates; pre-filtering by cooldown/range/diet/HP-cost makes illegal answers structurally impossible and keeps game rules authoritative in GDScript. Matches the `ai-jev-zorro` spec and the no-fallback constraint (any pick executes; `wander` always present).
Alternative considered: fixed enum (`HUIR`, `CAZAR`, ...) picked freely by the model. Rejected: needs a validate/repair layer for cooldowns and targets, and still needs code to resolve `HUIR where`.

**3. Micro/macro split at the intent line.**
Micro (every tick, sync): `move_toward` steering to intent target, contact kill resolve, drink-in-range, flee-lobo vector with refuge blend, needs/cooldown ticks. Macro (async): intent object `{kind, target_id, pos}` with TTL. Steering never awaits; macro answers only replace intent. Stale answers (target gone, actor dead) fall through to prior intent or wander.
Alternative considered: full-tick delegation to JEV. Rejected: latency stalls movement and contact kills.

**4. Staggered 1s timer + event re-ask + data-LOD.**
Why: timer bounds load (zorro count is small, typically 2), events give responsiveness (threat, hunger threshold, carrion spawn, kill, intent reached/expired), stagger avoids frame spikes. Data-LOD (3s when far from camera) replaces `VisibleOnScreenNotifier` because agents are Dictionaries without nodes.
Alternative considered: fixed 60Hz/10Hz polling. Rejected: wasteful, no perceptual gain.

**5. HTTP via async Main call with request IDs, timeout as hygiene only.**
One `HTTPRequest` reused by Main; batch JSON matches the sidecar's `validate_request` contract exactly: `{"states": [{id, state, questions: {intent: {type: "choice", instructions, criteria: {kind: label}}}}]}` with 2+ candidates per zorro (single-candidate menus are skipped locally). Response `{"states": [{id, answers: {intent: {choice: <kind-string>, probabilities: {kind: p}}}]}`; the service returns no `emocion`, so live answers carry empty emocion (spec allows it) while the mock keeps `"Instinto"`. Failures surface via `push_error` plus `state["jev_last_error"]` (code + body snippet). Timeout/stale handling maps to prior-intent/wander, which is answer hygiene rather than a fallback brain. Decision log (snapshot, menu, choice, probs, outcome) written every apply for the future training spike.

**6. Deterministic seam for gdUnit4.**
Bridge exposes pure builders (`build_menu`, `build_state`, `apply_answer`) testable without the service; service client is injected/mockable so the suite stays green and deterministic. Live-service tests are manual-only.

## Risks / Trade-offs

- [Risk] Stock checkpoint plays zorro poorly (never saw karmagame) → Mitigation: scope expectations to parity-of-legality first, log everything, plan training as a follow-up change.
- [Risk] Sidecar down stalls zorro intent (no fallback by request) → Mitigation: micro keeps animals moving/eating/fleeing; document F5-requires-service; timeout hygiene to prior-intent only.
- [Risk] Batch latency spikes with many zorros → Mitigation: small N, staggered slots, short state strings, 2-12 candidates typical (cap 255 never approached).
- [Risk] Non-determinism leaks into tests → Mitigation: mocked-answer tests for builders/apply; no live HTTP in gdUnit4.
- [Risk] State serialization drift vs checkpoint inputs → Mitigation: version the state/menu schema string in the log from day one.

## Migration Plan

- Additive + seam: add helper and Main wiring; gate zorro path behind a flag defaulting to JEV on for dev with one-line revert to the ladder for comparison.
- Rollback: flip the flag back to `_ai_zorro` ladder; no data migration (logs are append-only files outside save format).
- Deploy: sidecar reachable at `http://192.168.100.80:8766` before F5; CI/headless runs mocked path only.

## Open Questions

- Exact `/api/evaluate` field names for Choice + emocion side-channel (confirm against sidecar version in use; does not change specs or tasks).
- Log sink location and rotation (user:// vs repo-adjacent; same reason).
