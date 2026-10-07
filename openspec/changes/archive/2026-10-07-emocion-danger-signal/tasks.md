## 1. Pressure rule

- [x] 1.1 Add failing direct unit tests of `KarmaJev.appraise_emocion`: pressure-near snapshot appraises `Miedo` even when hungry; calm hungry snapshot stays `Hambre`; empty snapshot stays empty
- [x] 1.2 Extend the first appraisal check with the missing-key-safe `pressure_near` read
- [x] 1.3 Add failing bridge test: sapo `apply_answer` with empty emocion under pressure sets `jev_emocion` to `Miedo`

## 2. Verification gate

- [x] 2.1 Full gdUnit4 run: new tests green, no new failures vs the stashed baseline
- [x] 2.2 Run `ponytail-review` over the diff; fix or explicitly defer each finding
