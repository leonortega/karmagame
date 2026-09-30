## Context

See proposal.md Why. Current state (observed, not assumed): `state.hp` is the only survival stock (`game.js:76` drains `hungerRateFor(species) × dt`, even while hidden); eating heals it directly (`eat.js:217`); HUD shows Vida + Karma only (`hud.js`, `index.html:17-26`); `ageWorld(dt)` is the world clock (carrion/fruit/insects), not animal age; insects respawn globally (`game.js:154`, 1 per 20s max 6); AI forages food via `aiForage` with `hungerPriority: 0.4` and hides with hunger still draining. There is no water, thirst, or age field anywhere. Counts for food/refuges/rocks/agents all scale by world area (`floraCap`, `scaledCount`, `areaScale`) — water follows the same pattern.

## Goals / Non-Goals

**Goals:**
- One shared needs tick for player and AI so `living-map` parity holds and the algorithm stays testable without an engine.
- Water as the cheapest new entity: terrain with position + radius, infinite, no depletion state machine.
- E stays the single mouth button; need-driven food-vs-water choice shared by player and AI.
- Edad ships as a passive counter with a named hook for future modifiers, zero behavior today.

**Non-Goals:**
- No evaporation, rain, dry states, or water quality; no swimming or movement effects in water.
- No age effects (speed, hunger, lifespan cap) — field plus `effAgeMult() = 1.0` stub only.
- No new keys, no shop items for needs, no karma for drinking, no PA for drinking.
- No insect AI changes beyond spawn bias; wander/eat payoffs untouched.

## Decisions

- **Needs stored as stocks, 100 = full.** `hambre`/`sed` start at 100 each life, drain toward 0; `edad` starts at 0 and climbs. Rationale: matches the existing "eat heals upward" mental model and keeps `FOODDEF` payoffs additive; alternative (100 = starving) would invert every HUD bar and test. Thresholds `H_thresh`/`S_thresh` in `TUNING` gate regen.
- **One `updateNeeds(dt)` helper, called for `state` and for each agent in `updateAgents`.** Computes deficit, applies regen or deficit drain, advances edad, caps vida. Rationale: parity by construction, single place to unit-test the algorithm (mirrors how `hungerRateFor` is tested today); alternative of inline code in two loops would drift.
- **Water = `state.waters[]` of `{kind: 'charco'|'lago', x, y, r}`, seeded by density (`WATER_BASE` + `scaledCount`), persisted across reincarnation like `refuges`/`rocks`.** Rationale: reuses the refuge pattern (position + radius, no amount/alive/regrowT) instead of the bush pattern; infinite per exploration decision, so no depletion, evaporation, or recovery rendering. Lago differs only by larger `r` plus insect bias.
- **Drink branch inside the existing `eat.js` E-chain, not a parallel system.** Order: kill verbs → `thirstier()` ? water-then-food : food-then-water → species fallback (dig/hint). `thirstier()` compares sed deficit vs hambre deficit, ties favor water. Rationale: one mouth, one priority function shared with AI; fixed food-first order was considered but would show "off-diet hint" to a thirsty animal standing in water next to an inedible bush.
- **Halcon drinks through the existing landing window.** Generalize `landForCarrion` intent: E near water when airborne lands 1s grounded/vulnerable, then the drink resolves on the next E (or same press after landing per current timing). Rationale: reuses the risk mechanic and the `grounded`/`landT` fields; no Halcon exemption.
- **Insect bias at spawn only.** `spawnPt()` gains a lake-biased variant: with probability `P_lake`, pick a random lago and scatter within shore range; otherwise uniform as today. Wander, cap, cadence unchanged. Rationale: cheapest hotspot (one branch at spawn) that makes Sapo/Topo forage naturally target lakes via the existing `nearest()` seek without new insect AI.
- **HUD reuses the `.bar` row pattern twice more plus an edad readout.** Hambre/sed as fill bars with threshold tick marks; edad as a number (or thin progress without max, since unbounded). Rationale: no new HUD framework; threshold marks explain why E drank vs ate and why regen is/isn't running.
- **Hidden still drains both needs and suspends regen unless both stay above threshold.** Rationale: extends the existing "hambre sigue drenando" rule symmetrically so hiding can't dodge thirst.
- **Future hook: `effAgeMult()` returning 1.0, called in the drain/regen path.** Rationale: one-line future for old-age frailty/speed without touching call sites later; YAGNI-safe because it does nothing now.

## Risks / Trade-offs

- [Risk] Regen outruns drain and animals never die → Mitigation: default regen below worst-case deficit drain; tune so below-threshold net is always negative and verify with a 60s unfed/unwatered test per species.
- [Risk] Death spirals too fast when both needs empty (double drain) → Mitigation: deficit multiplier capped in TUNING; thirst ~2x hunger so one need dominates the warning window; HUD threshold marks plus log hints on first threshold crossing.
- [Risk] E ambiguity frustrates ("I wanted to eat, it drank") → Mitigation: log line naming what E did plus current deficits; need-driven order documented in the controls hint; AI uses the same rule so behavior is learnable by watching fauna.
- [Risk] Lake hotspots become predator camps, lakes unusable → Mitigation: accepted emergent pressure (same as food patches today); no extra predator-attraction tuning in this change; revisit only if playtests show lakes as death traps.
- [Risk] Wide test churn (survival rates, eat payoffs, forage) → Mitigation: TDD per task, one behavior per test, keep `FOODDEF` vida/PA numbers untouched so only drain/regen assertions move; shared helper keeps player/AI expectations identical.
- [Risk] `ageWorld` vs `edad` name confusion → Mitigation: agent field named `edad`/`age`, never `time`; world clock stays `ageWorld`; lint for duplicate function names across `src/script/` per repo gate.

## Migration Plan

- No saved games or storage migration (all state is per-run in memory).
- Deploy as a single change; tuning ships as `TUNING` defaults and can be hot-adjusted without spec changes.
- Rollback: revert the change; specs delta is additive plus four narrow MODIFIED blocks, so the parent specs stand alone again.

## Open Questions

- Final TUNING numbers (H/S thresholds, thirst multiple, regen rate, sip values, charco/lago counts and radii, lake-spawn probability): deferrable — all live in `TUNING` and can be set during implementation playtests without changing specs, design, or tasks.
- Exact HUD threshold-mark styling: deferrable — any visible shortfall state satisfies the spec.
