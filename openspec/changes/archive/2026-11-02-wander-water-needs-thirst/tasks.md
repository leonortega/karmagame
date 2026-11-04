# Tasks: Wander water-POI needs thirst

## 1. Tests first (red)

- [x] 1.1 Add `test_sated_wanderer_skips_water_poi`: a sated halcón with only a
      pond in range gets `wander_poi == null`; made thirsty it gets the pond.
- [x] 1.2 Add `test_possession_clears_hiding_state`: a host AI taken over while
      hidden becomes the player with `hidden=false` and `hideRef=null`
      (bug: invisible, input-frozen body after reincarnation).

## 2. Spec delta

- [x] 2.1 Modify the "Wander travel is purposeful" requirement
      (`specs/ai-species-behavior/spec.md`): the water arm applies only while
      thirsty; link the resolved conflict with `ai-survival`'s sated rule.

## 3. Implementation (green)

- [x] 3.1 Extract `KarmaAI.is_thirsty(a)`; use it in `ai_thirst`.
- [x] 3.2 Gate the `wander_poi` water arm behind `KarmaAI.is_thirsty(a)`.
- [x] 3.3 Clear `hidden`/`hideRef` in `KarmaState.possess_member` when a census
      host is promoted (numbered possession arrives awake).

## 4. Existing test migration

- [x] 4.1 `test_wander_poi_falls_back_to_water`, `test_halcon_wander_travels_to_water`,
      `test_zorro_wander_travels_to_water`: set a thirsty agent; intent (POI
      travel to water) preserved under the new spec.

## 5. Verification

- [x] 5.1 Full gdUnit4 suite green (31 suites, no silent aborts, full count).
- [x] 5.2 Touched scripts parse clean (`--check-only`).
- [x] 5.3 Main scene boots headless 120 frames, no script errors.
- [x] 5.4 Sim drivers: sated halcón no longer parks at a pond; run → die →
      reincarnate keeps control (20/20 seeded movement; the single pinned case
      is the driver holding into a rock rim, not a control blocker).
