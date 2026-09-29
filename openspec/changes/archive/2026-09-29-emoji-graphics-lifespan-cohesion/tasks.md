## 1. Data tables + helpers

- [x] 1.1 Add `hungerMult` per `SPECIES` in `data.js` (Ratón 1.0 baseline, short-lived >1, apex <1) keeping `TUNING.hungerPerSec` as base
- [x] 1.2 Add pure `hungerRateFor(speciesKey)` helper and unit test: Oruga drains faster than Lobo, Ratón ≈ historic base
- [x] 1.3 Add `EMOJI_SIZE` category table + `animalEmojiSize(form)` helper in `draw.js` and unit test: animal > food > terrain/decor, Lobo > Oruga

## 2. Emoji-first rendering

- [x] 2.1 Swap `drawSpecies()` to emoji-primary via shared helper (shadow/outline/tag preserved) and test species glyph + size per form
- [x] 2.2 Swap food `drawPatch()` to medium-tier emoji (drop vector `paint*` food painters from path) and test patch glyph/size
- [x] 2.3 Swap refuge/rock/seedling/carrion fields to small-tier emoji and test each glyph/size
- [x] 2.4 Update `drawLegend()` lines to emoji-first language and test legend content
- [x] 2.5 Remove retired vector `paint*` functions, verify no duplicate `function` names and `src/index.html` refs resolve

## 3. Species-paced hunger wiring

- [x] 3.1 Swap player drain in `game.js` `update()` to `hungerRateFor(state.speciesKey)` and test Oruga vs Lobo loss over fixed dt
- [x] 3.2 Swap all 8 AI species drains in `ai.js` to `hungerRateFor(a.speciesKey)` and test AI Oruga vs AI Lobo pacing
- [x] 3.3 Regression-test Judgment at 0, diet payoffs, and NPC eat/die/carrion loop unchanged apart from rate

## 4. Verification gate

- [x] 4.1 Run `node --check` on touched files and full `node --test` suite green
- [x] 4.2 Manual glance via `serve.bat`: map reads by emoji + size tier, survival times feel species-paced
