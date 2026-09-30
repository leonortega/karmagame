## Why

A single `hp` number currently conflates hunger, thirst, age, and damage, and there is no water on the map. Animals cannot get thirsty, lakes and puddles do not exist, and future behaviour-shaping stats have nowhere to attach. Splitting vitals now unblocks a real thirst loop while keeping `edad` passive until it earns gameplay meaning.

## What Changes

- Split the single Vida drain into explicit needs: `vida` (0..maxHp), `hambre` (0..100 stock, 100 = full), `sed` (0..100 stock, 100 = hydrated), `edad` (passive seconds-lived counter, no effect yet), `karma` unchanged; PA stays as the wallet.
- Vida rule: time regenerates vida only when hambre AND sed are both above thresholds; otherwise vida drains with a deficit multiplier; predator/poison/verb damage always hits vida directly; all healing capped at max.
- Eating refills hambre plus a direct vida heal (existing `FOODDEF` values kept); drinking refills sed plus a small direct vida sip.
- Add infinite water terrain: `charcos` (small drink radius, scattered) and `lagos` (large drink radius, few) following the existing density/area-scale pattern; no sips, no evaporation, no depletion state.
- Anchor insects to lagos: insect spawn biased near lagos, then wander as today, making lakes drink-plus-hunt hotspots for Sapo/Topo.
- Drink on the same `E` button as eat (need-driven priority: thirstier drinks, hungrier eats; kill verbs still win for carnivores); Halcon uses the existing 1s landing window to drink.
- HUD shows vida, hambre, sed, edad, karma (plus PA/time as today); AI agents obey the identical needs, thresholds, and drink rules.
- **BREAKING**: survival balance changes — food alone no longer sustains an animal indefinitely; thirst must also be managed; existing hp-drain-rate test expectations change.

## Capabilities

### New Capabilities
- `vitals-water`: split needs model (vida/hambre/sed/edad), threshold-gated regen algorithm, infinite charco/lago water terrain with insect anchoring, E-to-drink interaction and need-driven food-vs-water priority.

### Modified Capabilities
- `karma-core`: vida drain/heal rule changes from single species-paced hp drain to threshold-gated regen plus deficit drain; diet payoffs now also refill hambre stocks.
- `ecosystem-2d`: world gains water entities with densities, HUD gains hambre/sed/edad displays, E gains drink context, insect spawning gains lake bias.
- `ai-survival`: grazers seek water beyond contact range and prioritize drink when thirsty, mirroring existing food-seeking and hunger-priority rules.
- `living-map`: every agent carries hambre/sed/edad and follows the same regen, drain, drink, and death rules as the player.

## Impact

- `src/script/data.js` (TUNING thresholds/rates, water counts/radii, WATERDEF), `state.js` (agent fields, water seeding/persistence), `eat.js`/`game.js` (needs tick, drink branch, insect bias), `hud.js`/`src/index.html` (3 new bars), `draw.js` (water + insect rendering), `ai.js`/`predators.js` (water seeking, thirst priority).
- Test suite (`test/utils, world, state, eat, predators, shop, game`) — survival-rate, eat-payoff, and forage assertions change to the needs model.
