## Why

Every run starts from the same deterministic census (fixed `faunaFloor` + 4 company + 8 scripted hunters), so maps feel identical, AI social verbs that need nearby congeners rarely fire for non-player species, and hunter pressure (~1:1 prey:hunter on T1 lives) forces predators onto the player instead of the ecosystem.

## What Changes

- Replace the deterministic start census with a rolled census: same equilibrium rules every game, different numbers every game.
- Adopt a fixed-ecosystem rule: the rolled roster is constant for the run and the player possesses one member of their species instead of spawning extra bodies on top.
- Spawn each species as a loose community clustered around its food anchor (~500px jitter, predators offset) so short POI-travel closes the gap instead of uniform scatter.
- Set the oruga community as the feeder base (8 baseline, 4 floor) since it is hunted by all predators and fed by the most elastic food channel (leaves ~16/min).
- Roll gentle jitter (+/-1) plus an occasional theme (oruga bloom, rodent year, wet year, lean year, balanced); show the theme as a one-line birth log.
- Cap scripted hunter pressure when the rolled census already provides fauna predators, and soften predation when the player is T0.
- Name the babies/respawn system as the explicit follow-up that pulls rolled extremes back toward the baseline over time (out of scope here).

## Capabilities

### New Capabilities

- `ecosystem-census`: rolled initial-census calculation per game (per-species floor/mid/cap, diet-channel supply checks, prey:hunter invariant, theme + jitter roll, T0 softening, theme birth-log line).

### Modified Capabilities

- `ecosystem-2d`: initial spawn, placement, and pressure behavior change — fixed-roster possession (no extra company/hunter stacking), community anchors with travel-range clustering, oruga feeder baseline, reduced scripted-hunter multiplication.

## Impact

- Affected code: `KarmaData.POP` / `TIER_SPAWNS`, `KarmaState` seeding (`new_run`, `seed_fauna`, `seed_company`, `seed_foes`, `fauna_count`, `respawn_missing`, `possess_or_spawn`), `KarmaUtils` scaling/anchors, birth-log in `main.gd`.
- Systems: initial food-vs-population balance, AI social-verb availability (chorus/groom/howl/share/escort), early-game difficulty variance.
- No API or save-format changes; follow-up change will own birth/respawn regulation.
