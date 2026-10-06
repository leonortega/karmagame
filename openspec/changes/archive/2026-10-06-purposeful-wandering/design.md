## Context

See proposal.md Why. Current state: every species' wander arm (JEV `steer_intent` `_` branches, ladder wander tails in `_ai_*`, and `wander_mates` company drift) random-walks `(randf() - 0.5) * K * dt`. All needed queries already exist and are diet/need-aware: `KarmaEat.nearest_edible_patch_for` (diet + range), `KarmaUtils.nearest_water_for`, refuge fit via `KarmaAI.refuge_fits_size`, `KarmaState.company_agents`. Only `Main` owns I/O; simulation stays pure static funcs on `Dictionary` state.

## Goals / Non-Goals

**Goals:**
- Zero idle drift for every mover type with one shared helper.
- Wander stays the lowest-priority fallback: reflexes, intents, deeds, and mocks all run before it, exactly as today.

**Non-Goals:**
- No karma/cost/cooldown changes; no new verbs, menus, or log entries.
- No gait changes (`species-locomotion` untouched — direction changes, envelopes don't).
- No player movement change.

## Decisions

- **One shared helper, species-agnostic.** `KarmaGame.wander_poi(state, a)` (name TBD in implementation) returns the best destination in priority order — edible food (new `TUNING.wanderSeekRange`, proposed 1000.0, far beyond daily forage so travel actually happens), else water, else fitting cover, else company — or null when nothing qualifies. Every wander arm calls it and falls back to today's jitter on null. Alternative (per-species POI logic) rejected: destination preference is identical across species; only diets differ, and the food query is already diet-aware.
- **New TUNING knob, not a magic number.** The seek horizon lives in `KarmaData.TUNING` per the no-magic-numbers rule; 1000.0 proposed (a third of map width — travel, not teleport).
- **Mates follow the possessed agent.** For company drift, the point of interest is the player position first (stay with the party), then fellow mates — today's `wander_mates` scatters them; the helper composition differs but the call-site swap is the same one line.
- **Hunters keep hunting.** Predator pursuit, lures, and fear-flee all run before wander and are untouched; only the no-target drift arm changes.
- **Oruga/sapo terminal tails exempt.** Their stillness-gated defenses (curl at `stillT` ≥ 0.01, camouflage at `stillT` ≥ 2) require motionlessness; traveling would void spec-pinned scenarios, so those two tails keep accumulating stillness. The defense counts as the deed.

## Risks / Trade-offs

- [Risk] Everything converges on the same food patch → clumping and overgrazing one bush → Mitigation: nearest-POI is per-agent and agents spread out; jitter fallback breaks ties; monitor live, tune `wanderSeekRange` down if clumps form.
- [Risk] More encounters → more hunts → higher predation → Mitigation: encounter-driven behavior is the point; chase math and refuges unchanged, so balance shifts are honest ecosystem dynamics, not free kills.
- [Trade-off] Slightly more queries per wander tick (4 nearest-scans) → Accepted: scans are linear over small lists, same cost class as existing forage checks.

## Migration Plan

- Additive: one helper + call-site swaps; no callers removed.
- Rollback: revert the swaps (jitter lines stay in diff context).
- No data migration.
