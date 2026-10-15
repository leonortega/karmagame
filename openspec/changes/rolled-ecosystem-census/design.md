## Context

See proposal.md Why. Current state: `new_run` builds the world as player + 4 same-species company + `faunaFloor` fauna (`fauna_count` = floor at area 4x) + `TIER_SPAWNS x reps=4` scripted hunters, all placed by uniform `scatter_dry`. Food is area-scaled 4x with regrow clocks (`fruitRegrow` 45s, `leafRegrow` 60s, insect 1/12s cap 40); fauna is effectively unscaled and hunters are multiplied, which inverts the prey:hunter ratio on T1 lives. Reincarnation already uses host-takeover (`possess_or_spawn`); first-life spawn does not. Predator targeting lives in `KarmaPredators.pick_target`/`strike_agents` with the trophic table; community travel uses `wander_poi` + `wanderSeekRange`.

## Goals / Non-Goals

**Goals:**

- Every new game rolls a different census that still satisfies floors, diet-channel supply, and the 3:1 prey:hunter invariant.
- Player possession never changes the roster size; communities spawn clustered so social verbs are castable after short travel.
- Oruga baseline of 8 holds as the feeder surplus; scripted hunters stop stacking on top of fauna predators.

**Non-Goals:**

- Birth, babies, juveniles, and long-run population regulation (explicit follow-up change).
- Food payoff, hunger rate, or AI behavior rebalancing; regrow/respawn cadences stay as-is.
- HUD, shop, judgment, or reincarnation-matrix changes beyond the one theme birth-log line.

## Decisions

- **Census tables live with numbers, roller stays pure.** Add per-species floor/mid/cap plus theme weights next to `POP` in data (no magic numbers in logic, per project convention); the roll itself is a pure static taking `rng` returning `{species: count, theme}` so gdUnit4 tests can seed it deterministically. Alternative (inline roll inside `seed_fauna`) rejected: untestable and spreads tuning across call sites.
- **Fixed roster via possess-a-member on first life too.** `new_run` spawns the full rolled census as AI, then converts one member of the drawn species to the player (same pattern as `possess_or_spawn` host takeover). Alternative (spawn player plus census) rejected: it reintroduces the player-distortion this change removes. `respawn_missing` retargets to the rolled census stored on the run instead of the static floor.
- **Anchored loose clusters reuse existing scatter primitives.** Oruga around leaf clumps, sapo on lago/charco shore rings (reuse the insect water-ring helper shape), raton/ardilla near bushes+shrubs+oaks, topo near patches, predators via farthest-point offset from prey clusters; ~500px jitter, `scatter_dry` + `nudge_dry` so nothing lands in water. Alternative (tight same-point packs) rejected per the travel decision: it would crash local food and bypass the POI-travel logic the game already has.
- **Hunter pressure capped, not deleted.** `seed_foes` multiplication drops to floor-only and is skipped when rolled fauna predators already cover that tier; T0 softening is spawn offset plus no-initiate (contact damage unchanged), implemented as a guard in target selection rather than a new predator type. Alternative (delete scripted hunters entirely) rejected: lean rolls with small fauna predator counts still need a pressure floor.
- **Theme is data + one log line.** Theme weights pick bloom/rodent/wet/lean/balanced, jitter applies, then gates re-enforce; `add_log` writes the year line at birth. No new UI surface.

## Risks / Trade-offs

- [Risk] Insect bottleneck binds first: sapo-heavy + topo insect share can exceed 5/min → Mitigation: diet gate clamps sapo or shifts topo share to carrots/nuts before spawn; tests assert the clamp.
- [Risk] Oruga base overgrazes its anchor clump before `leafRegrow` catches up → Mitigation: anchor each oruga cluster across 2+ clumps and keep jitter wide enough that `nearest_edible_patch_for` spreads load.
- [Risk] Existing tests assert fixed counts (company 4, fauna floors, hunter tables) → Mitigation: update those tests to seeded-roll expectations; keep one legacy test pinning floors as minima.
- [Risk] Predator offset fails on water-heavy maps → Mitigation: fall back to farthest-point dry scatter, never inside water radii.

## Migration Plan

- New-run path only; no save migration (no persisted census yet). Reincarnation keeps the persistent world and carries the rolled census reference forward. Rollback is the previous deterministic seeding block, kept behind until the suite passes on seeded rolls.
