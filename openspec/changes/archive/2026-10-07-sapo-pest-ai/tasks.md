## 1. Pest verb AI mirror

- [x] 1.1 Add failing gdUnit4 test: AI sapo with insect in tongue range casts slot 2 through `cast_verb_for` and eats (+10 vida, +3 karma, 8s cooldown starts)
- [x] 1.2 Implement agent branch of `call_verb` `pest`: nearest insect within tongue range (`tongueRange` + 40 with `tonguePlus`) resolved through the existing `eat_insect` path
- [x] 1.3 Add failing-then-passing tests: no insect in range fails with no cooldown/cost/karma, `tonguePlus` 120px reach succeeds, AI/player payoff parity matches

## 2. Ladder order

- [x] 2.1 Add failing gdUnit4 test: sapo `ai_maybe_verb` tries toxin before pest, and pest before burrow-in/chorus, with survival reflexes (hide, thirst, contact eat, forage) unchanged ahead of all verbs
- [x] 2.2 Implement the toxin → pest → burrow/chorus order in the sapo branch

## 3. Verification gate

- [x] 3.1 Run full gdUnit4 suite green; touched scripts parse with no duplicate `class_name`/`func` collisions
- [x] 3.2 Run `ponytail-review` over the diff; fix or explicitly defer each finding
