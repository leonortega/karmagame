# Design

## Context

Shipped: 7 species, chain table, refuges, carrion/mimic, shop, matrix v2 (`game.js` ~762 lines, 30 requirements). See proposal.md - Why. This change adds a food economy, hard diets, one NPC type, and per-species art — all inside the existing entity patterns.

## Goals / Non-Goals

**Goals:**
- One diet matrix enforced at a single gate (`canEat`), so new foods/species plug rows/columns, not branches.
- Sapo-NPC reuses the Zorro wander/hunt skeleton with a hop gait and contact snap.
- Art as `drawSpecies(ctx, form, x, y, dir, t)` — one function, NPCs call it with outline+scale.

**Non-Goals:**
- No sprite assets, particles, day/night, water, seasons.
- No new predator types, no mate-eating AI, no cross-life effects beyond saplings.

## Decisions

- **Rules table (single source of truth):**
  | # | Rule | Value |
  |---|---|---|
  | R1 | Diet gate | hard: off-diet E = no-op + hint (throttled 1 per 5s) |
  | R2 | Optimal foraging | ignore prey diff ≥ 2 sizes, snap at contact (< 25px) |
  | R3 | Poison never karma | mimic/toxic/rot = Vida only, always |
  | R4 | Last-fruit guilt | bushes/shrubs/oaks/patches only; leaves exempt (regrow) |
  | R5 | Marginal foods | none — hard means hard (no half-payoffs) |
  | R6 | Camouflage scope | fools Zorro NPC + Zorro player? No: NPCs only; Lobo immune |
  | R7 | Sapling cap | +3 bushes max, consumed on use, no stacking across lives |
- **Foods as one entity kind (`{kind, x, y, amount, age/state}`):** berries/apples/nuts share bush-logic with different counts/payoffs; carrots = patch with same logic; mushrooms add toxic flag; leaves add regrow timer; insects add wander. Alternative separate classes discarded — one update/render path with a `kind` switch.
- **Sapo-NPC minimal:** speed 70, perception 150, hunts oruga-player only, contact snap 28 dmg? No — snap = scare (10 dmg) not kill; T0 must stay survivable. Alternative full tongue-kill discarded as overtuned.
- **Carry on C, sense on V:** one key per cross-species verb keeps E contextual and H/V/C/B/Q mappable without chords. Alternative E-everything discarded — bury-vs-eat conflict unresolvable.
- **Art rung order (silhouette → facing → motion):** each rung is independently shippable; if motion busts the frame budget, rungs 1–2 still read. Facing from velocity dir, motion from `sin(time*freq)`.
- **Oruga/sapo density compensation:** leaf-clumps 4 + regrow, insects 6 + fast respawn, because hard diets shrink their worlds. Tuned in the density task, not guessed here.

## Risks / Trade-offs

- [Hard walls frustrate new players] → Mitigación: hint log names what the form eats ("los sapos comen insectos"); density task verifies a full life is survivable per diet.
- [7 verbs × 7 forms untestable by hand] → Mitigación: headless harness asserts per verb; playtest only routes (oruga/sapo/zorro lives).
- [Sapo-NPC + Zorro double pressure on T0] → Mitigación: T0 table is 1+1 (not 2+1); snap is 10 dmg scare, Zorro still the killer.
- [File crosses 900 lines] → Mitigación: split `foods.js`/`draw.js` at apply time (task included).

## Open Questions

- Should mates share the player's diet (social eating) or stay decorative? Deferred — no behavior depends on it.
