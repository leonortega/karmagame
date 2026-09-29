# Proposal: Forest Flora Lifecycle

## Why

The forest is a set of static supermarkets. Plants never give back: every fruit eaten is gone forever (except leaves), the map can only lose flora over a long session, and the only trees are tiny hollow-tholes that a fox can look straight past. The biome cannot feel alive while its plants cannot reproduce, die of old age, or shelter anyone. A living forest needs plants that are born, fruit, feed the fauna, drop seeds that sprout, and grow into shelter — closing the loop that the Ardilla's `saplings` counter hints at but never lands on the map.

## What Changes

- **Fruiting clocks**: every living fruiting plant regrows 1 fruit per `TUNING.fruitRegrow` (90s) up to its cap, using the same mechanism leaves already have (`regrowT`). A bush stripped to its last fruit revives slowly instead of dying forever; the "last fruit" karma rule stays untouched.
- **Plant birth from seeds**: eating a fruit leaves a seed bank: each consumed fruit has `TUNING.seedSproutChance` (35%) to sprout a **seedling** near where it was eaten. Seedlings mature into a new plant of their fruit kind after `TUNING.seedlingMaturity` (75s). World caps keep density honest: `TUNING.seedlingMax` (10 alive) and `TUNING.floraCap` (plants per kind, scaled by area like everything else).
- **Ardilla planting lands trees**: the planted sapling (player `C` or AI Ardilla planting) sprouts a **young oak** — a new `oak` flora entity — after maturity, giving the +10 karma deed a real, visible consequence beyond the current banked counter.
- **Old oak refuges**: new refuge entity `old-oak`: large trunk-canopy tree, no fruit at all, hides agents of `maxSize ≤ 3` from **ground** predators (zorro, lobo, saponpc). The Halcón strikes from above — the canopy does not blind it. Spawned sparse (2 per baseline area) and growable? No: fixed spawn table + Ardilla oak planting near an existing old-oak can grow a new one is out of scope; old-oaks spawn per life like other refuges.
- **Predator canopy blindness**: ground predators lose sight of agents hidden under an old-oak exactly like `state.hidden` does today (the hidden flag mechanism is reused; old-oak just becomes a fitting refuge type). The Halcón ignores canopy cover when picking targets.
- **Flora rendering**: seedlings render as tiny sprouts, young oaks as mid-size trunks, old-oaks as big canopy circles — the forest visibly ages.

## Capabilities

### New Capabilities
- `flora-lifecycle`: fruiting clocks, seed sprouting and maturation, plant death/replacement cycle, young-oak growth from planted saplings, old-oak canopy refuges that blind ground predators.

### Modified Capabilities
- `ecosystem-2d`: "Bushes hold finite fruit and die permanently" is replaced — bushes regrow and reproduce; "Vegetarian menu" counts become initial densities over a living total; new `old-oak` refuge in the size-gating requirement with the Halcón exception; lifelike rendering adds seedling/young-oak/old-oak silhouettes.
- `living-map`: "Persistent world across reincarnation" — flora keeps living across lives; planted young-oaks and seedlings carry over like bushes do today; AI Ardilla planting adds real young oaks.
- `ai-species-behavior`: AI Ardilla planting scenario now creates young oaks on the map (same +10 karma deed).
- `karma-core`: no rule changes — the planting deed's consequence is now a world object; last-fruit karma rule unchanged.

## Impact

- **`src/script/data.js`**: new TUNING (`fruitRegrow`, `seedSproutChance`, `seedlingMaturity`, `seedlingMax`, `floraCap`, `oldOakCount`), new REFUGES entry `old-oak`.
- **`src/script/state.js`**: `seedFood` seeds per-plant `regrowT`; new `state.seedlings` array; `old-oak` spawn in `seedCompany`.
- **`src/script/game.js`**: `ageWorld` grows seedlings, regrows fruit, matures planted oaks, caps flora.
- **`src/script/eat.js`**: `eatPatch`/`eatLastFruit` drop seeds (spawn seedlings); `carryAction` plants young oaks.
- **`src/script/ai.js`**: `aiArdilla` planting grows young oaks.
- **`src/script/predators.js`**: canopy blindness — halcón ignores old-oak hiding; ground predators respect it (via existing hidden flag).
- **`src/script/draw.js`**: render seedlings, young oaks, old-oak canopies.
- **`test/`**: new `test/flora.test.js`; updates to world/eat/game tests where "dies permanently" was asserted.
