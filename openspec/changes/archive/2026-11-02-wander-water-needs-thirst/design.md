# Design: Wander water-POI needs thirst

## Context

`wander_poi`'s water arm made a sated agent travel to the nearest pond whenever
no food/cover/company qualified, and `move_toward` into a pond never resolves
out for a flying halcón (skips_water), so the bird hovered dead-center over the
water between thirst trips — "goes to water again and again". The thirst system
already has the correct gate: `ai_thirst` refuses unless sed is below the
personal water threshold AND the sed deficit outranks the hunger deficit.

## Goals / Non-Goals

- Goals: one shared predicate `KarmaAI.is_thirsty(a)`; the wander water arm uses
  it; sated wanderers fall to cover/company/jitter per the existing order.
- Non-Goals: no tuning changes (thresholds, rates, ranges untouched); no change
  to the food arm order, cover, company, or the JEV candidate menus; no change
  to thirst seeking itself — `ai_thirst` keeps identical behavior, now via the
  shared predicate (`if not is_thirsty(a): return false` replaces the two
  inline checks).

## Decisions

- **Gate in `wander_poi`, not in each species' steer tail.** One chokepoint in
  the shared helper covers all eight wander tails (spec: priority order is
  species-agnostic). Per-species gates would rewrite four `steer_intent` sails.
- **Reuse `water_threshold` + `seeks_water` verbatim** in `is_thirsty` so the
  wander arm and the thirst seeker fire on exactly the same edge. A
  legacy agent missing `caution_water` behaves as watermark 1.0 (always
  seeks at the first deficit) — the documented legacy semantics hold.
- **Spec delta scopes the conflicted sentence only**: the wander requirement's
  "else nearest water" becomes "else (while thirsty) nearest water"; the
  purposeful-wander scenarios gain a sated case mirroring `ai-survival`'s
  "sated animals shall not detour to water", which this change finally makes
  true everywhere.

## Risks / Trade-offs

- A sated halcón (no cover fits, company far) now jitters instead of sitting at
  a pond — maps look less "pond-shaped" for predators; accepted, it is the fix.
- Thirsty wander traffic at ponds is unchanged, so drinking congestion is not
  introduced or removed.
