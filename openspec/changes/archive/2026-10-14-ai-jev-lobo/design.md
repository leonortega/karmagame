## Context

See proposal.md (Why) for motivation. Six species already run the Option B split: per-species `karma_jev_<sp>.gd` bridge (legal-only menu, snapshot, apply) + per-species `karma_ai_<sp>.gd` driver (`step` / `step_jev` / `step_ladder` / `steer_intent`), fronted by the `KarmaJev` facade and pumped by the Main-owned single-flight HTTP batch path (`pick_batch_species_6`, per-species send/answer/flush/clear arms). Lobo's ladder (`KarmaAI._ai_lobo`) is the last one left: strike-hunter, thirst, hungry seek-carrion, urgent-seek, regurg-packmate verb, prey hunt, contact carrion eat.

Constraint from code inspection: lobo verbs `howl` (slot 1), `escort` (slot 4), and `cull` (slot 5) return false for agents in `karma_game.gd` — they read player position/karma. Only `regurg` (slot 2) and `strike` (slot 3) plus generic `shout` have agent-capable paths. Lobo has no fears (`PRED[lobo].fears = []`), so there is no flee/hide branch to preserve.

## Goals / Non-Goals

**Goals:**

- Lobo plugs into the identical 7-touchpoint migration shape as the previous six species (bridge, driver, facade, scheduler, scene wiring, spec, tests).
- Player parity for every ranked move: each menu kind resolves through the same eat/drink/hunt/verb functions as a player lobo.
- Scheduler stays fair at seven species with no lone-species regression.

**Non-Goals:**

- No new verb mechanics: howl/escort/cull are not extended to AI agents in this change (documented exclusion, topo-`nestdig` precedent).
- No tuning value changes, no HUD changes, no sidecar protocol changes.
- No refactor of the `main.gd` answer-dispatch chain beyond adding the lobo arm (cleanup is a separate change).

## Decisions

### 1. Exclude howl / escort / cull from the AI menu (Option A)

Why: they are player-only today (`if a != null: return false`), and making them agent-capable redefines game behavior (whose position, whose karma, escort moves whom) — a separate spec-level change. Alternative (extend-then-rank) was considered and deferred; `hunt` already lets the ranker express "kill the weak one" without the cull karma bonus.

### 2. Mirror `karma_jev_topo.gd` as the bridge template, `karma_ai_zorro.gd` as the steering template

Why: topo is the most recent bridge (same file layout, `candidate_ids`, `build_http_body_for` with the <2-criteria skip, local emocion appraisal fallback); zorro is the closest steering relative (predator: carrion + hunt + strike + wander-POI tail). Alternatives (copying raton/grazer) fit worse — lobo is a carrion/mates predator with no hide behavior.

### 3. Reuse the shared `KarmaJev.should_ask / mark_asked / intent_tick` cadence unchanged

Why: per-species cadence specs are identical (1s staggered, 3s far-LOD, 0.5s backoff); lobo adds no new event class beyond the existing set (fresh carrion, hunger transition, hungry-packmate presence treated as the topo-style sharing-target event, kill/intent resolution). No new tuning keys.

### 4. Extend the picker to `pick_batch_species_7`, keep single-flight

Why: minimal, consistent with the 4→5→6 history; `_pick_best` core already generalizes over order/due/served. Alternative (rewriting dispatch as data-driven) was rejected as out of scope — noted as follow-up tech debt since the `main.gd` nested-ternary chain grows to seven levels.

### 5. Lobo log flag defaults off, schema `jev-lobo/v1`, file `user://logs/jev_lobo.log`

Why: matches every species except topo (the active debug species); per-species isolation means enabling lobo never touches other files.

## Risks / Trade-offs

- [Risk] Lone-lobo polls: `faunaFloor` lobo is 1, so batches are often single-agent; a thin menu could hit the <2-criteria skip and never send → Mitigation: wander-always plus 7+ conditional kinds keeps menus ≥2 in practice; test asserts a representative menu sends.
- [Risk] `hunt` vs `cull` confusion: ranker may chase weak prey via `hunt` without awarding cull karma → Mitigation: documented as accepted parity gap; cull extension is a named follow-up, not silent behavior.
- [Risk] Seven-level answer-dispatch chain in `main.gd` becomes harder to read → Mitigation: keep the established pattern this once; file the data-driven dispatch cleanup as tech debt in Open Questions.
- [Risk] Regurg targeting edge (packmate dies/leaves between rank and apply) → Mitigation: stale-answer hygiene resolves to wander, same as all species; test covers it.

## Migration Plan

No data migration. Rollout is flag-gated per file: `KarmaJevLobo.USE_JEV = true` with `step_ladder` preserved, so setting the flag false restores ladder behavior. Rollback is revert of the change; no persistent state depends on the new schema. Log files are additive (`jev_lobo.log`, extended `jev_poll.json`).

## Open Questions

- Data-driven batch dispatch in `main.gd` (replacing the per-species arm chain with a species table) — safe to answer later; does not change specs or task breakdown.
- Whether a future change should extend howl/escort/cull to AI agents — explicitly out of this change; needs its own proposal since it changes verb behavior specs.
