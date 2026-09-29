## Why

Current rendering mixes two visual languages — detailed vector portraits for animals (`drawSpecies`/`paint*` in `draw.js`) plus scattered emojis for icons, food, refuges, and tags. The result reads incoherently at a glance and silhouettes do not scale intuitively by category. Separately, hunger drains at a single global rate (`TUNING.hungerPerSec = 1.6`) for every species, so a short-lived Oruga and a long-lived Lobo starve on the same clock, contradicting life-expectancy fantasy.

## What Changes

- Emoji-first cohesive rendering: every animal, plant/food, and terrain element renders primarily as its emoji glyph, with a single shared helper for sizing, shadow, and tag.
- Size-by-category scale: animals largest, plants/food medium, terrain/small decor smallest, with small per-species offsets inside the animal band (apex slightly larger than prey).
- Retire or thin the vector portrait layer: vector `paint*` functions stop being the primary sprite (kept only as optional backdrop or removed per design decision).
- Species-paced life loss: replace the single global hunger rate with a per-species drain derived from a new `lifespan`/`hungerMult` datum on `SPECIES` (short-lived drains faster, long-lived slower), applied uniformly to player, company, fauna, and hunters.
- Legend, tags, and indicators updated to match the emoji-first language.

## Capabilities

### New Capabilities
- None — this change reworks behavior covered by existing capabilities.

### Modified Capabilities
- `ecosystem-2d`: rendering requirement changes from lifelike vector shapes to cohesive emoji-by-category with size tiers.
- `karma-core`: Vida-drain requirement changes from single global rate to species-paced rate driven by life expectancy.

## Impact

- Affected code: `src/script/draw.js` (render path, `drawSpecies`, `drawPatch`, refuge/rock/seedling/carrion painters, legend), `src/script/data.js` (`SPECIES`, `TUNING`), `src/script/game.js` (`update()` hunger line), `src/script/ai.js` (if AI drains separately), tests in `test/` covering draw and hunger.
- No API/dependency changes; zero deps preserved; canvas-only, no new assets.
- Balance impact: survival times shift per species; diet payoffs and predator damage unchanged.
