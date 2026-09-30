## Why

Birth by player choice undermines the karma fantasy: the player negotiates with judgment instead of receiving it. Replacing start-select and judgment picks with azar (fate draw) makes karma the sole gate and each birth a dramatic reveal.

## What Changes

- **BREAKING** First life: remove 8-button start-select; single "Nacer" action draws uniform azar over all 8 species (Oruga, Sapo, Ratón, Ardilla, Topo, Halcón, Zorro, Lobo).
- **BREAKING** Judgment matrix: pool = f(karma) only. PA removed from judgment; deadForm removed; lateral cycle removed; Lobo loses its start-only exception and draws like any T2.
  - Karma <= -50 → pool {oruga} (forced involution, unchanged meaning).
  - -50 < karma < +50 → pool {sapo, raton, ardilla, topo} (T1 full, no cycle order).
  - karma >= +50 → pool {sapo, raton, ardilla, topo, halcon, zorro, lobo} (F1 additive floor: good karma adds T2, never guarantees it).
- **BREAKING** Remove player overrides at judgment: delete free T2 pick (`pickT2`) and paid Choose-form (`chooseForm`, 15 PA). No reroll; fate is final.
- Judgment reveal becomes drama: text "los dioses eligen que reencarnes en..." plus species blocks that light up / cycle among the eligible pool and settle on the drawn form. Same treatment on start screen (all 8 blocks). Reincarnar button + R shortcut retained.
- Karma carry (20% rounded) retained; PA carry retained as shop wallet; persistent world across reincarnation retained.
- **BREAKING** Shop: replace 4 global stat adaptations with 3 unique items per species (24 total, e.g. Sapo tongue/toxin/chorus upgrades). Keep per-life, no-stacking, no-debt, lost-on-death. AI buys from its own species catalog with the same logic. Costs raised to 50–80 PA range so a typical life (~60–100 PA earned) affords ~1 item.

## Capabilities

### New Capabilities

- None — this change reworks existing behavior, no new top-level capability.

### Modified Capabilities

- `reincarnation`: karma-only unlock-floor pool, azar draw, gods-reveal UI, removal of picks/reroll, Lobo normalization, start-azar.
- `karma-core`: global SHOP replaced by per-species catalogs (3 each), higher pricing, AI per-species buying.

## Impact

- `src/script/shop.js` (judge, showJudgment, pickT2, chooseForm), `src/script/state.js` (reincarnate/possessOrSpawn, carry rules), `src/script/game.js` (start screen wiring), `src/script/data.js` (SHOP → per-species catalogs, TUNING costs), `src/index.html` (start/judgment blocks), `test/shop.test.js`, `test/state.test.js`, `test/game.test.js` expectations for choice-based judgment break and need rewrite.
