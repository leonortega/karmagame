# Proposal: Wander water-POI needs thirst

## Why

A sated wanderer picked the nearest pond as its point of interest, then parked
there indefinitely: a fed halcón flew to water within seconds and never left it
(90 s sim: visits 3, then pinned at distance-to-water 0–3 px for 80 s straight).
Two specs conflict today — `ai-species-behavior` ("Wander travel is purposeful":
food, else water, else cover, else company, unconditionally) versus `ai-survival`
("Sated animals SHALL NOT detour to water"). For species whose only cover DOES
not fit and whose company is scarce (the halcón), water won every idle tick, so
the map showed birds shuttling to ponds again and again.

## What Changes

- The `wander_poi` water arm fires only while the agent is thirsty by its own
  water gate (`sed < 30 + 70 × caution_water` AND more thirsty than hungry) —
  the exact predicate `ai_thirst` uses, extracted as `KarmaAI.is_thirsty(a)`.
- A sated wanderer falls through to fitting cover, then company, then jitter,
  as `ai-species-behavior` already reads.
- No changes to thirst seeking (`ai_thirst`, `ai_seek_water`), drink ranges,
  JEV drink candidates, speeds, or any other POI arm.

## Impact

- Affected specs: `ai-species-behavior` ("Wander travel is purposeful")
- Affected code: `scripts/karma_ai.gd` (extract `is_thirsty`, use in `ai_thirst`),
  `scripts/karma_game.gd` (`wander_poi` water arm)
- Affected tests: `tests/test_karma_systems.gd` — sated-wander-water scenarios
  become thirsty; new sated-wander-skips-water test; species wander-to-water
  tests (halcón, zorro, raton fallback) keep their intent with a thirsty setup.
