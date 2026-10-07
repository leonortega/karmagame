## 1. Traits at spawn

- [x] 1.1 Add failing tests: `mk_agent` and `mk_predator` assign `caution_food`/`caution_water` in 0..1 when absent and keep explicit values when present
- [x] 1.2 Roll both traits with `randf()` at spawn in `mk_agent` and `mk_predator`

## 2. Gates

- [x] 2.1 Add failing unit tests: `is_hungry` follows `30 + 70 × caution_food` (hungry at 80/1.0, not hungry at 80/0.0, hungry at 29/0.0); missing keys behave as 1.0
- [x] 2.2 Implement personal thresholds (`food_threshold`, `water_threshold` beside `is_hungry`) and rewire `is_hungry`, `ai_forage` gating, and `ai_thirst` gating to them
- [x] 2.3 Add failing tests: ladder forage treks when hungry-by-trait and idles when satiated; thirst acts below the personal water line only when thirstier
- [x] 2.4 Switch all five JEV `drink` candidacies to the personal water threshold (`seek_food` follows via `is_hungry` unchanged)

## 3. Urgency at the floor

- [x] 3.1 Add failing tests: `ai_urgent_seek` treks toward diet food at `hambre` 25 for any traits and stays put above the floor or with no food in range; urgency moves reset `stillT`
- [x] 3.2 Implement the diet-aware urgency helper and wire the branch (after thirst/contact-eat, before forage/verbs/intent) into all ladder and `step_jev` step functions
- [x] 3.3 Add failing tests: `appraise_emocion` returns `Urgencia` at the floor even when calm, `Miedo` wins under pressure+floor, fed stays `Hambre`; sapo `apply_answer` backfills `Urgencia` at the floor
- [x] 3.4 Extend the shared fallback order to danger → urgency → carry → hunger

## 4. Verification gate

- [x] 4.1 Full gdUnit4 run: new tests green, no new failures vs the stashed baseline
- [x] 4.2 Run `ponytail-review` over the diff; fix or explicitly defer each finding
