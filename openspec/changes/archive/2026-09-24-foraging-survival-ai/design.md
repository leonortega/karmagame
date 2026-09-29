# Design: Foraging & Survival AI

## Context

`aiGrazerEat(a, range)` calls `nearestEdiblePatchFor(a, range)` with `TUNING.eatRange` (46) or `TUNING.tongueRange` (90) — eating is contact-only. All grazer functions fall through to a `±20px/s` random jitter (the `Math.random() - 0.5) * 40 * dt` lines). `aiZorro`/`aiLobo`/`aiHalcon` eat carrion only within `eatRange`. Predators already hunt via `nearestAiPrey`. Hiding exists only for the player (`toggleHide` → `state.hidden` + `hideRef`); `canopyBlind` and camp logic read those fields, so an AI that sets them through the same path inherits all predator-side behavior for free. Flora: `matureSeedlings` pushes `mkPatch(kind, x, y, 1)`; `regrowFruit` ticks `fruitRegrow: 90`.

## Goals / Non-Goals

**Goals:**
- No AI dies of starvation while food exists within its forage range.
- Hiding is real: hidden AI survives hunts, at hunger cost, for a bounded time.
- The forest out-produces consumption: new plants carry fruit immediately.
- All of it reuses existing primitives (eatPatch/eatCarrion, toggleHide's state fields, resolveCollisions).

**Non-Goals:**
- No new verbs or keybinds — AI-only change plus flora tuning.
- No memory of food locations (re-scan each tick; entity counts are small — ponytail ceiling).
- No player behavior changes (player keeps manual H).
- No group tactics (herding, pack hunts) — individual survival only.

## Decisions

### 1. Seek = walk toward nearest diet patch within `forageRange`
`aiForage(a, dt)`: target = `nearestEdiblePatchFor(a, SPECIES[a.speciesKey].vision * TUNING.forageRangeMult)`; if found, move toward it at species speed and return true (caller skips idle behaviors). Eating still resolves through `aiGrazerEat` at contact range on later ticks — seek and eat are the same function family, just different radii. `forageRangeMult: 0.5`.

**Alternative rejected**: waypoint caching or scent trails. State per agent per food kind is a memory system for a map where vision already covers need.

### 2. Hunger priority as a gate on low-value behaviors
`a.hp < maxHp * TUNING.hungerPriority (0.4)` short-circuits grooming (raton), digging (topo), planting carry (ardilla drops the nut where it stands — it eats first), curling/camouflage stillness (oruga/sapo keep moving to food). Predators: at low HP they check carrion within perception *before* `nearestAiPrey` (carrion-first) and extend perception ×1.4 while low.

**Alternative rejected**: a numeric utility score blending hunger/need. Three thresholds in code read clearer than a fake utility function.

### 3. Real hiding through the player's own state fields
`aiTryHide(a)`: find fitting refuge within `TUNING.hideRange` (reuse `refugeFits`), set `a.hidden = true; a.hideRef = ref`, `a.hideT = TUNING.aiHideMax (5s)`. `aiHideTick(a)`: decrement; exit when `hideT <= 0` or no hunter within perception (`a.hideT` max even if danger persists — bounded vulnerability window). While hidden, grazers skip seek/move (existing hidden semantics). Ground predators already ignore/camp hidden agents via `canopyBlind`+`campStep`; AI hiding rides those rails with zero predator changes.

**Alternative rejected**: a parallel `aiConcealed` flag. Two concealment systems double every predator check (the exact anti-goal from the design of old-oak).

### 4. Flee-toward-cover: bias vector, not pathfind
In `aiFlee`, if a fitting refuge exists within 250px, blend the away-from-fear vector with the toward-refuge vector (60/40). The agent still flees but arrives near cover, where trunk LOS does the rest.

**Alternative rejected**: full pathfinding around solids. Slide handles trunks; a blended vector is 3 lines.

### 5. Flora: full-fruit births + 45s regrow
`matureSeedlings` spawns patches at `FRUIT_CAP[kind]`; `fruitRegrow: 90 → 45`. Planting deed unchanged (young oaks already born at 3 nuts).

**Alternative rejected**: raising `seedlingMax`/caps. The bottleneck was fruit-per-plant, not plant count.

## Risks / Trade-offs

- **[Risk] Hidden AI farms safety**: hide-5s-exit-hide cycles could stall hunts forever. Mitigation: `aiHideMax` bounds each stay; hunger keeps draining; hidden AI can't eat (existing rule).
- **[Risk] Everybody beelines to the same bush**: no dispersion. Mitigation: caps + regrow make the bush sustainable; wander still applies when fed. Accept for now.
- **[Risk] Predators never hunt if carrion always exists**: carrion-first only at low HP; sated/full predators hunt as today (and zorro cedes when full).
- **[Risk] 45s regrow floods food**: caps bound total; consumption rises with feeding AI. Watch in playtest.

## Migration Plan

Static game. Verify: node --check → suite green → no dup functions → refs. Rollback: revert files.

## Open Questions

- Should hidden AI exit *early* if danger is gone vs waiting the full 5s? (Design: exit when no hunter within perception — feels alive; the 5s is the hard cap, not the target.)
- Should planting ardilla eat the carried nut instead of dropping it when starving? (Design: drop-then-eat later; carrying is the deed.)
