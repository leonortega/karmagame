# Design

## Context

See proposal.md (Why) for motivation. Current state shaping this design: `WORLD` fixed at 1600x1200 with fixed spawn counts (`state.js:seedFood/seedFoes/seedCompany`); three entity castes (global player `state.px/py`, `state.mates`, `state.predators`); player verbs read global `state` (`eat.js`, `utils.js:nearest`, `predators.js:playerEdibleFor`); `PRED` vs `SPECIES` dual tables with lobo PRED-only; `newRun('raton')` hardcoded start (`game.js:150`); `judge()` matrix gates T2; per-death full world regen. Specs: `living-map` (new), `ecosystem-2d`, `karma-core`, `reincarnation` deltas.

## Goals / Non-Goals

**Goals:**
- One agents array; possessed-agent model with player-only karma/PA/shop/judgment.
- Mixed-species seeding plus density-scaled food/refuges on the bigger map.
- NPC hunger/eat/die loop and carnivore-vs-agent hunting with carrion output.
- Start-select and persistent-world re-possession.

**Non-Goals:**
- NPC fancy verbs (dig, groom, plant, shout, sense, carry, shop, hide-via-H): player-only this change.
- Biomes/zones, minimap, multiplayer, save/load: explicitly out.
- Full NPC-vs-NPC food-web balancing passes beyond floor-respawn: follow-up tuning.

## Decisions

1. **Agent record + possessed index.** `agents[]` entries `{ id, speciesKey, x, y, face, hp, brain: 'PLAYER'|'AI', ai: {kind: grazer|hunter, state, timers}, cooldowns }`. Keep the global life-scoped wallet (`karma, pa, owned, lifeLog, saplings, time`) on a `run` object, not per agent, so possession transfer is an index swap. Alternative (per-agent karma) rejected: karma is the player's moral ledger, not a property of bodies.
2. **Un-globalize verbs with agent param, player as default.** `eatPatch(agent, patch)`, `nearestFrom(agent, list, maxD)`, `edibleFor(hunterSpecies, victimSpecies, dist)`. Keep thin wrappers (`eatPatch(p)` → `eatPatch(playerAgent, p)`) so existing tests/harness keep compiling during migration. Alternative (duplicate NPC-only eat functions) rejected: two implementations of diet payoffs drift.
3. **Lobo promoted to SPECIES (tier 2, size 4) + DIET carrion/mates + draw entry.** Reuse zorro-style body art at larger scale with distinct color rather than the current bespoke predator circle, so `drawSpecies` covers all 8 uniformly. PRED keeps only behavioral rows (damage/perception/fears) keyed by species.
4. **Brains in three levels, no new framework.** Grazer: wander + `nearestEdiblePatch` graze + flee-fear (reuse `fleeCheck` generalized to agents). Hunter (zorro/lobo/halcon/sapo-vs-oruga): reuse `pickTarget/chase/strikeContact` retargeted to `agents[]` + mates, PLAYER included as one candidate. `TABLE` (`PRED.huntsTiers`, fears, optimal-foraging size gate) stays the single source of who hunts whom. Table-first per project convention; no Strategy/State pattern until a 3rd brain divergence.
5. **Composition as density table `POP_DENSITY` (agents per 1M px²) + floors.** Fresh world seeds floor counts for all 8 species; respawn timer tops up below-floor species at distant spawn points. Food/refuge seed counts become `density × area` with baseline calibrated to reproduce current counts at 1600x1200, so balance at baseline is provably unchanged.
6. **Bigger WORLD via single constant bump (e.g. 3200x2400, 4x area) + density scaling.** One constant, everything derives. Hunger/speed/vision untouched; travel-time parity comes from density, not stat retuning. Alternative (biomes) deferred as non-goal.
7. **Persistent world, possess-or-spawn reincarnation.** On death: world arrays (food, carrion with ages, refuges incl. dug, surviving agents) untouched; timer/history/adaptations/nut/dug-count reset; saplings convert to extra bushes in place; next form possessed from a same-species AI agent when available else spawned. Alternative (still regen) rejected: it would nuke the ecosystem story the change exists to create.
8. **Start-select as pre-run overlay in `index.html`.** Buttons for all 8 species; sets `pendingStart` consumed by first `newRun`. Zero carry by construction (fresh wallet).

## Risks / Trade-offs

- [Risk] Per-frame `nearest` scans go from ~10 entities to ~30+ per hunter → Mitigation: hunters scan agents at existing perception ranges only; keep counts bounded by density floors + carrion cap pattern; profile before optimizing (no spatial index yet — ponytail: YAGNI).
- [Risk] Un-globalling breaks every test stubbing `state.px/py` → Mitigation: default-param wrappers keep old call shapes; migrate tests file-by-file (world → eat → predators → game).
- [Risk] Persistent world overgrazes into starvation spirals → Mitigation: leaf/insect regrow timers already exist; floor-respawn plus density-scaled food;/starvation deaths produce carrion which feeds carnivores — the loop self-corrects; tuning follow-up if playtests show collapse.
- [Risk] Free predator start trivializes the earn-the-predator arc → Mitigation: accepted deliberately; matrix still gates post-death T2 returns; start-select framed as "first life is free, karma takes over after."
- [Risk] Duplicate `function` names across `src/script/` (project verification gate) → Mitigation: wrappers replace in place; no parallel old/new implementations checked in.

## Migration Plan

No deployment (static game, `serve.bat`). Rollback: revert change files; specs are deltas, main specs untouched until archive. Verification per project gate: `node --check` touched files → full suite green → no duplicate function names → `index.html` refs resolve. Balance check at baseline area: seed counts equal current constants before scaling up.

## Open Questions

- Exact WORLD dimensions and per-species densities (propose 3200x2400 + calibrated densities; confirm by playtest, adjustable without spec changes since specs state proportionality, not numbers).
- Whether mates/HUD "saved" flee semantics extend to all same-species agents or stay group-scoped (spec says group subset; implementation detail).
