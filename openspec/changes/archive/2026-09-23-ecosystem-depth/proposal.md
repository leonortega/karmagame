# Proposal

## Why

The MVP loop (eat → shout → die → reincarnate) is proven, but the world is flat: one prey food, faceless predators, nowhere to hide, nothing to learn. Depth — a real chain, refuges, and food you must judge — is what turns the karma fantasy from a minigame into an ecosystem.

## What Changes

- Autonomous food chain: Zorro NPCs hunt the player and congeners with hunger of their own, and flee from Lobo; Lobo (NPC apex, Tier 3) spawns once the player reaches Tier 2 and fears nothing.
- Playable predator: ascension at Karma ≥ +50 and PA ≥ 100 offers **Halcón or Zorro** (free pick); Zorro gets Pounce (dash-kill that spawns carrion) and cannot shout — predators don't warn prey.
- Three new animals: Sapo (Tier 1, tongue grabs fruit at range, fits size-1 refuges, redemption hop for good Orugas), Topo (Tier 1 lateral, Dig creates a burrow, can shout), Zorro (Tier 2 playable, Pounce).
- Refuges with size gating: burrow-S (size ≤ 1), burrow-M (size ≤ 2), hollow-tree (size ≤ 2 + climber), thorn-bush (size ≤ 2); press H to hide — predators camp ~3s, hunger still drains, no eating while hidden.
- Bad food: carrion clock (fresh +20 Vida → stale +8 → rotten −25 Vida, never karma) fed by predator kills; mimic poison fruit (−20 Vida) with a subtle tint, revealed exactly by Keen nose.
- Wasteful-kill karma: a carnivore kill made while Vida ≥ 80% max grants −10 karma ("mataste por deporte").
- Halcón must land to eat: attempting E near food lands it for 1s (vulnerable), takeoff on next move — this is what keeps the sky god mortal.

## Capabilities

### New Capabilities

None — all behavior lands in the existing three capabilities.

### Modified Capabilities

- `karma-core`: size stat + 3 new species verbs (Pounce, Tongue, Dig), wasteful-kill karma rule, Keen-nose-reveals-mimics, shout restricted to non-predators (Ratón/Ardilla/Topo/Sapo croak).
- `ecosystem-2d`: predator hunger/target/flee/camp AI states, tier-based spawn table (T0: 2 Zorro; T1: 2 Zorro; T2: 1 Zorro + 1 Lobo), 4 refuge types + hide key H, carrion entity with rot clock, mimic fruit, Halcón landing rule.
- `reincarnation`: matrix v2 — dual T2 ascension pick (Halcón/Zorro), Oruga-with-karma-≥+20 → Sapo redemption hop, T1 lateral cycle (Ratón → Ardilla → Topo → Sapo → Ratón), lateral Choose-form (15 PA) picks any T1 pool member.

## Impact

- Code: `game.js` grows predator AI, refuge/carrion/mimic entities, 3 species, hide + landing states; `index.html` gains refuge prompts and T2 pick buttons; `style.css` gains carrion/mimic/hidden styling. No new files, no dependencies.
- Balance risk is the point of the change: predator-vs-predator tuning and carrion economy get a dedicated balance task.
