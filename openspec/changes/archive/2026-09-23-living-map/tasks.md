# Tasks

## 1. Data tables and world size

- [x] 1.1 Promote lobo to SPECIES (tier 2, size 4, diet carrion/mates) with draw entry, and verify `node --test test/world.test.js` covers the 8-species roster and diet payoffs
- [x] 1.2 Bump WORLD to 3200x2400 with POP_DENSITY composition table calibrated to reproduce current counts at baseline area, and verify seed counts equal current constants when area is set back to 1600x1200
- [x] 1.3 Convert food/refuge seeding to density × area, and verify counts scale proportionally with area in a unit test

## 2. Un-globalize shared verbs (player as default)

- [x] 2.1 Add agent-param cores `nearestFrom`/`edibleFor` with player-default wrappers, and verify existing world/predator tests pass unmodified
- [x] 2.2 Convert eat payoffs (`eatPatch`, `eatInsect`, `eatCarrion`) to agent-param cores granting Vida only to AI and full karma/PA only to the possessed agent, and verify eat tests pass for both brains
- [x] 2.3 Convert kill verbs (pounce/dive/strike values + carrion spawn) to agent-param cores, and verify predator tests pass for AI-vs-agent kills

## 3. Unified agents roster

- [x] 3.1 Replace mates/predators/player-position triples with `agents[]` plus possessed index and run wallet, keeping old call shapes as wrappers, and verify full suite green with `node --check` on touched files
- [x] 3.2 Seed mixed-species population (all 8 kinds, density floors) on fresh world, and verify composition test finds every species present
- [x] 3.3 Retarget hunter AI (`pickTarget`/`chase`/`strikeContact`/`fleeCheck`) from `state.px/py` to `agents[]` candidates of any brain, and verify NPC-vs-NPC hunt and carrion-spawn tests pass

## 4. NPC hunger-eat-die loop and respawn

- [x] 4.1 Run per-agent hunger drain and diet-gated grazing each tick, and verify an AI raton eats berries for Vida and starves to carrion without food
- [x] 4.2 Add below-floor respawn at distant spawn points on a bounded timer, and verify a wiped species repopulates within the bound

## 5. Start-select and persistent reincarnation

- [x] 5.1 Add start-select overlay with all 8 species starting at 0 karma / 0 PA, and verify first life skips the judgment matrix in a test
- [x] 5.2 Switch reincarnation to possess-or-spawn in the SAME world (food/carrion/refuges/survivors carry over; timer/history/adaptations/nut reset; saplings convert in place), and verify eaten-food-stays-eaten and killer-persists scenarios

## 6. Render, HUD, and judgment wiring

- [x] 6.1 Render all agents via `drawSpecies` by species key with hunter outline, and verify all 8 silhouettes render without console errors
- [x] 6.2 Point HUD, vision ring, camera, refuge prompt, and judgment stats at the possessed agent, and verify HUD follows possession after reincarnation

## 7. Verification gate

- [x] 7.1 Run `node --check` on all touched files, full suite `node --test test/utils.test.js test/world.test.js test/state.test.js test/eat.test.js test/predators.test.js test/shop.test.js test/game.test.js` green, no duplicate function names across `src/script/`, and `src/index.html` refs resolve
