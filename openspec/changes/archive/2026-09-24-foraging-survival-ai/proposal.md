# Proposal: Foraging & Survival AI

## Why

The map is full of food and full of corpses. AI grazers only eat what touches their nose (46–90px) and otherwise jitter randomly — any animal born in a food desert starves in under a minute, and the carcass count keeps climbing. Meanwhile the flora fix made plants spawn but they mature with 1 fruit while a 90s clock ticks per extra fruit: a hungry AI swarm strips each new plant the instant it appears, so the forest looks like it grows nothing. The animals have the verbs (hide, flee, shout) but never connect them: nothing seeks food, nothing seeks cover, nothing waits out a predator. The ecosystem needs agents that feed themselves and survive, not ornaments that starve.

## What Changes

- **Food seeking**: grazers pick the nearest diet patch within a `forageRange` (species vision, halved) and walk to it; carnivores do the same for carrion within their perception. Eating still happens only in eat-range.
- **Hunger priority**: at HP < 40% the AI stops wandering/grooming/courting death-by-drift and goes straight to the food-seeking state (grazers) or switches to carrion-first (predators).
- **Real hiding**: when a predator is hunting the agent (role-hunter within perception and targeting or too close), the AI enters a fitting nearby refuge (≤ `hideRange`), stays hidden while danger persists or up to `aiHideMax` (5s), then exits. Hidden AI is untargeted by ground predators per existing rules; hunger drains as always.
- **Flee toward cover**: when fleeing, the AI biases its escape vector toward the nearest fitting refuge instead of straight-away.
- **Plants born productive**: seedlings mature into plants with full fruit count (3/3/3/2/3) instead of 1; fruit regrow clock drops to 45s (`fruitRegrow`), so a mature plant feeds continuously.
- **Predator carrion-first**: hungry predators (HP < 40%) prefer fresh carrion within perception over hunting, only hunting when no carrion exists.

## Capabilities

### New Capabilities
- `ai-survival`: food seeking, hunger-priority behavior, real refuge hiding for AI, flee-toward-cover, predator carrion-first.

### Modified Capabilities
- `flora-lifecycle`: seedlings mature with full fruit; regrow clock 90s → 45s.
- `ai-species-behavior`: grazer species functions gain seek/priority/hide behaviors; predator functions gain distant-carrion foraging.

## Impact

- **`src/script/ai.js`**: `aiForage` (seek state), `aiTryHide`/`aiHideTick` (refuge entry/exit), `aiFlee` biased to cover, hunger-priority wiring in each species function, carrion-first for carnivores.
- **`src/script/data.js`**: `forageRangeMult`, `aiHideMax`, `hungerPriority` (0.4); `fruitRegrow` 90→45.
- **`src/script/game.js`**: none beyond what ai.js calls (resolveCollisions already shared).
- **`test/survival.test.js`**: seeking, priority, hiding, cover-flee, carrion-first, plant births.
