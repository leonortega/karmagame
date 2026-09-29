## Context

See `proposal.md` for motivation. Current state (observed):
- `src/script/draw.js`: `drawSpecies()` dispatches to 8 vector `paint*` portrait functions by `SPECIES[form].radius`; emojis exist only as icons via `SPECIES_ICON`/`FOOD_ICON`/`REFUGE_ICON` plus `drawEmoji(icon,x,y,size)` with ad-hoc sizes (12–17px). Foods also have vector `paintBerries`/`paintApples`/etc. under the emoji, refuges/rocks/seedlings have vector painters with a small emoji on top.
- `src/script/data.js`: `SPECIES` carries `maxHp/radius/size` but no lifespan datum; `TUNING.hungerPerSec = 1.6` is the single global drain.
- `src/script/game.js` `update()`: `state.hp -= TUNING.hungerPerSec * dt` for the player; `src/script/ai.js`: 8 species ticks (`aiOruga`…`aiHalcon`) each repeat `a.hp -= TUNING.hungerPerSec * dt`.
- Specs affected: `ecosystem-2d` (Lifelike animal rendering), `karma-core` (Vida drain + NPC hunger loop). See delta specs in `specs/ecosystem-2d/spec.md` and `specs/karma-core/spec.md` for the behavior contract.

## Goals / Non-Goals

**Goals:**
- One emoji-first render path with category size tiers, removing the vector-vs-emoji split.
- Per-species hunger pacing via data, applied identically to player and AI.

**Non-Goals:**
- New art assets, fonts, or dependencies; animation-frame work beyond existing `t` wiggle.
- Rebalancing diet payoffs, predator damage, shop costs, or spawn counts.
- Changing Judgment, reincarnation carryover, or karma math.

## Decisions

### D1: Single `EMOJI_SIZE` table by category (table before pattern)
`draw.js` gains one table, e.g. `EMOJI_SIZE = { animal: 28, food: 18, terrain: 15, decor: 10 }` plus a small per-species offset map (e.g. lobo +6, halcon/zorro +4, oruga −4) instead of a Strategy/State hierarchy. `drawSpecies()` becomes `drawEmoji(speciesIcon(form), x, y, animalSize(form))` + existing shadow/outline/tag. `drawPatch`/`drawCarrionPile`/`drawRefugeField`/`drawRockField`/`drawSeedlingField` drop their vector painters and call the same helper. Alternative considered: keep vector portraits as base with emoji badge — rejected, preserves the incoherence the proposal removes.

### D2: Keep base rate, add per-species multiplier datum
`data.js`: add `hungerMult` (or `lifespan` inverted at read time) per entry in `SPECIES`, e.g. oruga 1.5, sapo 1.25, raton 1.0, ardilla 1.0, topo 1.1, halcon 0.8, zorro 0.85, lobo 0.7 — tuned so Ratón ≈ historic baseline. Keep `TUNING.hungerPerSec` as the base. Add one pure helper `hungerRateFor(key)` (in `utils.js` or `state.js`) returning `TUNING.hungerPerSec * (SPECIES[key].hungerMult || 1)`. Alternative considered: absolute `drainPerSec` per species — rejected, duplicates the base and complicates tuning.

### D3: One call-site swap for player + one for AI
`game.js` `update()`: `state.hp -= hungerRateFor(state.speciesKey) * dt`. `ai.js`: replace the 8 identical drain lines with the same helper (single helper, 9 call sites, no behavior fork). Company/fauna/hunter agents all flow through `aiStep`, so no separate path. Alternative considered: drain inside `aiBase` — rejected, `aiBase` runs after early returns in some ticks and would shift timing.

### D4: Retire vector painters without breaking tests
Delete or stop calling `paintOruga`…`paintLobo`, `paintBerries`…`paintLeaves`, `paintOldOak`/`paintHollowTree`/`paintThornBush`/`paintBurrow` once emoji path lands; keep `drawEmoji`, `drawShadow`, `drawTag`, `drawAgentIndicators`, legend (updated glyphs). Verify no duplicate `function` names across `src/script/` and that `src/index.html` refs still resolve. Harness stubs canvas so emoji sizes are asserted via recorded `font`/`fillText` args.

## Risks / Trade-offs

- [Risk] Emoji rendering varies by platform font → Mitigation: fixed `serif` stack already used by `drawEmoji`; sizes are px, no layout depends on exact metrics.
- [Risk] Larger animal glyphs overlap solids/tags → Mitigation: animal band sized against existing `radius` values; tags already offset by `radius`.
- [Risk] Longer-lived apex becomes easier (slower drain) → Mitigation: multipliers are data; playtest Ratón baseline first, adjust table only.
- [Risk] Dead vector code left behind → Mitigation: removal is an explicit task with `node --check` + suite-green gate.

## Migration Plan

- Pure in-place change, no save format or spec-archive migration beyond the two delta specs.
- Rollback: revert `draw.js`/`data.js`/`game.js`/`ai.js` to prior commit; no persistent state.
- Verification per change: `node --check` touched files → full `node --test` suite green → manual `serve.bat` glance at legend/map density.

## Open Questions

- None — size numbers and multiplier values are initial data, tunable during apply without changing specs or task shape.
