# Design: Forest Flora Lifecycle

## Context

Current flora model: six static patch arrays (`bushes`, `shrubs`, `patches`, `clusters`, `clumps`, `oaks`) + `insects`. Only `clumps` (leaves) regrow — via `regrowT` ticking in `ageWorld` and `eatSustainable` resetting it. Every other plant dies with its last fruit (`eatLastFruit` sets `alive=false`); the "último fruto" karma (−15) punishes the player, but the world still trends empty. The Ardilla's `C` deed banks `state.saplings` which only converts to *extra berry bushes next life* — nothing grows in the world you planted it in. Refuges include `hollow-tree` (climb-only, size ≤2) but no canopy that blocks line-of-sight from above. The user approved three decisions: dual seed-spread (ardilla planting + spontaneous seedlings), anti-ground-predator old-oak refuges, and a full birth/death plant cycle.

## Goals / Non-Goals

**Goals:**
- Fruit regrows on every living plant; stripped plants revive on a slow clock.
- Eaten fruit can sprout seedlings that mature into new plants of the same kind.
- Ardilla planting (player + AI) grows real young oaks in the world.
- Old-oak refuges: no fruit, size ≤3, block ground-predator perception; Halcón sees through canopy.
- The forest visibly ages (seedling → plant → old oak) and persists across lives.

**Non-Goals:**
- No new fruit kinds or diet changes (same 7 foods, same payoffs).
- No growth stages for existing plants beyond dead/alive (no sapling→bush for berries — only oak lineage gets stages; that's the species the game already treats as trees).
- No pathfinding around trees (trees are not obstacles; canopy is cover, not collision).
- No per-seedling inheritance of toxicity (mimic/toxic rolls stay at original spawn time per kind).

## Decisions

### 1. One regrow mechanism for all fruiting plants
`eatSustainable` already resets `regrowT = 0` on leaves; `eatLastFruit` does not. Change: every `mkPatch` gains `regrowT: 0`; `ageWorld` ticks `regrowT` for every **dead or under-cap** fruiting patch and adds 1 fruit when the clock expires. `alive=false` patches revive the same way (the plant recovers; only the *fruit* was gone). This deletes the "permanent death" special case rather than adding a second system — leaves are just the first instance of a general rule.

**Alternative rejected**: per-kind regrow tables. Six near-identical timers is drift bait; one clock + `TUNING.fruitRegrow` covers all, leaves keep their faster `leafRegrow` since it predates this change and is spec-pinned.

### 2. Seedlings as a single homogeneous array
`state.seedlings: [{ kind, x, y, age }]` — one array for all kinds. On `age >= TUNING.seedlingMaturity`, the seedling becomes a new patch of its `kind` at a random free-fruit count (1) and is removed. Cap checks at sprout time (`seedlings.length < seedlingMax`) and maturation time (per-kind flora cap scaled by area). Seed drop: `eatPatch`/`eatLastFruit`/`eatMimic` push a seedling candidate with probability `seedSproutChance` — rolled once per eaten fruit, positioned near the plant (±60px), regardless of who ate it (player or AI forage also sows the forest).

**Alternative rejected**: seeds as world objects that need carrying/planting by any agent. That's a whole verb for marginal depth; spontaneous sprouting captures the ecology with one array.

### 3. Oak lineage: planted sapling → young oak → nothing more
`carryAction` (player) and `aiArdilla` planting currently increment a counter. Now: planting spawns a seedling `{ kind: 'oak-tree', ... }` that matures into a `young-oak` patch (`kind: 'nuts'`, amount 3, count toward oak flora cap) — the deed literally grows a tree in the lived-in world. `state.saplings` remains as the cross-life banked counter (unchanged semantics).

**Alternative rejected**: saplings maturing into old-oak refuges directly. Two trees from one deed muddles the mental model; young oaks are food-bearing, old oaks are shelter — different jobs.

### 4. Old-oak as a refuge type, canopy = hidden flag
`REFUGES` gains `{ type: 'old-oak', maxSize: 3, count: 2 }`. Hiding in it uses `toggleHide` untouched (size gating, freeze, hunger). The one new behavior: `canopyCover()` — when the player is hidden in an old-oak, ground predators (zorro, lobo, saponpc) treat the player as `state.hidden` already does (camping rule reused); the Halcón ignores this cover: `pickTarget`'s canopy check exempts `p.type === 'halcon'`, and `feast`/`strikeAgents` targeting likewise. AI agents get the same deal: `aiFlee`-ing grazers may dive into old-oaks only via the existing hide verb equivalence — out of scope; AI does not use refuges this change (documented ceiling).

**Alternative rejected**: a separate `concealed` state parallel to `hidden`. Two concealment systems would double every predator check for one tree type.

### 5. Flora caps scale with area
Per-kind cap = `scaledCount(base)` of its spawn count (e.g. bushes cap at `scaledCount(7) + saplingCap`). Caps checked at maturation, not sprouting — a seedling always sprouts (bounded by `seedlingMax`), but only matures into a plant if the kind's cap has room; otherwise it lingers as a seedling until a slot opens (with retry each tick). This makes the forest's total biomass roughly conserved, like `POP` floors do for fauna.

**Alternative rejected**: global flora cap only. One greedy kind (berries via ardilla spam) would starve out mushrooms.

## Risks / Trade-offs

- **[Risk] Food inflation**: regrow + seedlings could flood the map. Mitigation: caps per kind + `seedlingMax` + 90s regrow are deliberately slower than consumption at current fauna density; `flora.test.js` asserts caps hold.
- **[Risk] "Last fruit" karma loses meaning** if bushes revive anyway. Mitigation: rule unchanged — eating the last fruit is still −15 and the bush still reads dead for the regrow duration; the message says the plant recovers slowly, the moral judgment stands.
- **[Risk] Old-oak makes grazers unkillable** when a refuge is near. Mitigation: size ≤3 excludes nobody but the maxSize gate still applies to halcon-camping… actually halcón ignores cover entirely, so any camper can just be the halcón; also `campTime` (3s) unchanged — cover buys seconds, not safety.
- **[Risk] `eatMimic` sowing seeds from poison fruit sprouts toxic plants** — actually correct ecology (mimics are a plant trait, not fruit rot); the new bush rolls its own mimic/toxic state at maturation. Documented here so tests don't "fix" it.

## Migration Plan

Static game, no deployment. Verification: `node --check` touched files → full suite green → no duplicate function names → `index.html` refs. Rollback: revert the change's files.

## Open Questions

- Should old-oaks block `saponpc` hop-pressure specifically (T0 oruga runs are the suffering case)? Design says yes via generic ground-blindness; confirm in playtest.
- Should seedling sprout chance scale with karma of the eater (karma literally greens the forest)? Tempting flavor, deferred as scope creep.
