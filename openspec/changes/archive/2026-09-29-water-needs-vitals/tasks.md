## 1. Needs core (TUNING + shared tick)

- [x] 1.1 Add needs TUNING defaults (H/S thresholds, thirst multiple ~2x, regen rate, sip values, capped deficit multiplier) with one test per default's observable effect
- [x] 1.2 Add hambre/sed/edad fields to player state and AI agents (100/100/0 at life start, reset on reincarnate) with reset covered by tests
- [x] 1.3 Implement shared `updateNeeds(dt)` (threshold-gated regen vs deficit drain, direct-damage bypass, max cap, `effAgeMult() = 1.0` stub) TDD: regen-above-threshold, drain-below-threshold, emptier-drains-faster, damage-bypass, cap-at-max
- [x] 1.4 Wire `updateNeeds` into the player tick and `updateAgents` loop, replacing the bare `hp -= rate*dt` line; keep Judgment at 0 and PA accrual untouched

## 2. Water terrain (charcos + lagos)

- [x] 2.1 Seed `state.waters[]` (`charco` small radius scattered, `lago` large radius few) via area-scaled densities, persisted across reincarnation like refuges/rocks
- [x] 2.2 Render waters with distinct glyphs and drink radii through existing draw helpers, plus a freshness-free infinite affordance (no depletion visuals)
- [x] 2.3 Cover water seeding/persistence/rendering with tests (counts scale with area, positions persist, drink radius differs by kind)

## 3. Drink on E (shared mouth)

- [x] 3.1 Implement `thirstier()` need comparison (sed deficit vs hambre deficit, ties favor water) with unit tests
- [x] 3.2 Add the drink branch to the E-chain (kill verbs first, then need-driven drink/eat, then species fallback) including eat-refills-hambre and drink-refills-sed-plus-sip, TDD per branch
- [x] 3.3 Route Halcon drinking through the existing 1s landing window and cover it with a grounded-drink test

## 4. Lake-anchored insects

- [x] 4.1 Bias insect spawns near lagos (probability split, shore-range scatter, uniform fallback) keeping respawn cadence, cap, wander, and payoffs unchanged
- [x] 4.2 Cover spawn bias with tests (shore clustering rate above uniform, cap/cadence unchanged, Sapo tongue payoff unchanged)

## 5. HUD (vida / hambre / sed / edad / karma)

- [x] 5.1 Add hambre/sed bars with threshold marks plus an edad readout to `index.html`/`hud.js` reusing the `.bar` pattern, updating live with the needs tick
- [x] 5.2 Add E-outcome and threshold-crossing log hints (what E did and why, first shortfall warning) covered by HUD-level tests

## 6. AI parity (seek, override, hide)

- [x] 6.1 Add AI water-seeking within `vision x forageRangeMult` with need-driven food-vs-water choice, mirroring `aiForage`, TDD per seek branch
- [x] 6.2 Add thirst override of secondary deeds (groom/dig/plant/curl/camouflage skipped when thirsty with water available) and thirst-aware predator scavenging parity
- [x] 6.3 Drain hunger and thirst while hidden, suspending regen unless both needs hold above threshold, for player and AI alike

## 7. Suite, balance, and review gate

- [x] 7.1 Retune and green the full suite (`node --test` all files): update only drain/regen/forage assertions, keep `FOODDEF` vida/PA numbers untouched, add 60s unfed/unwatered death-spiral checks per species archetype
- [x] 7.2 Run the repo verification gate: `node --check` touched files, no duplicate `function` names across `src/script/`, `src/index.html` refs resolve
- [x] 7.3 Run a `ponytail-review` pass over the diff; fix or explicitly defer each finding and record skill audit lines (tdd-workflow, safe-refactor, solid, clean-code, ponytail) in the completion message
