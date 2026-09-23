# Proposal

## Why

Every herbivore eats the same green dot, a zorro hunts caterpillars, all animals are colored circles, and karma has one shared verb (shout). A food menu with hard diets, a realistic size-gated chain, lifelike shapes, and one signature virtue per animal turn feeding, fear, and goodness into per-species gameplay.

## What Changes

- Full vegetarian menu: berries (renamed current fruit), apples (scarce/rich shrubs), carrots (patches), mushrooms (1-in-4 toxic, reuses tint + Keen-nose reveal), leaves (oruga staple, regrows, exempt from last-fruit karma), nuts (oak clumps, carriable), insects (wandering, sapo/topo food).
- **BREAKING** Hard diet restrictions: each form eats only its diet table entries; off-diet E does nothing (one hint log). Carrion and mates stay carnivore-only (Zorro, Halcón).
- Size-gated predation (optimal foraging): predators ignore prey 2+ sizes smaller except contact-range snap; T0 spawn becomes 1 Zorro + 1 Sapo-NPC (toads really eat caterpillars), restoring Oruga pressure honestly.
- Lifelike canvas art in 3 rungs (silhouette → facing → motion wiggle); predator NPCs reuse species draw functions with red outline.
- New verbs: Carry/bury (C, Ardilla), species-sense (V: Topo tremor / Zorro track), Camouflage (Sapo, motionless, fools Zorro only), Curl (Oruga, motionless, half damage), Squeeze (Ratón fits size-1 refuges, passive), Dive (Halcón E on mate).
- Signature karma deeds: Oruga +2 prudent nibbling, Sapo +3 pest control, Ratón +5 Groom (3s near mate), Ardilla +10 Plant (bury nut → +1 bush next life via sapling carry), Topo +3 Aerate per burrow, Halcón +20 drive off Lobo (strike a Lobo), Zorro +15 Cede the kill (E on carrion at ≥80% Vida leaves it).

## Capabilities

### New Capabilities

None — all behavior lands in the existing three capabilities.

### Modified Capabilities

- `karma-core`: hard diet matrix (new table), 7 verbs, 7 signature deeds, wasteful-kill extended to Halcón dive-kills, Squeeze size rule.
- `ecosystem-2d`: 6 new food entities with spawn/payoff rules, size-gated targeting + Sapo-NPC + T0 spawn swap, lifelike render recipes, V/C keys, sapling-carry bushes.
- `reincarnation`: sapling carry (+1 bush per buried nut, cap +3, consumed on use) in world reset.

## Impact

- Code: `game.js` gains diet gate, food entities, Sapo-NPC, draw-per-species, V/C keys, sapling carry; `index.html` control hints; `style.css` food/refuge art. No new files, no dependencies.
- Balance risk concentrated in spawn densities per diet (oruga/sapo worlds shrink) — dedicated density task included.
