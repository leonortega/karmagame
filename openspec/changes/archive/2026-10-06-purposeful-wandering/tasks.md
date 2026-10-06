## 1. Purposeful wander (TDD)

- [x] 1.1 Add `TUNING.wanderSeekRange` (1000.0) with a data test pinning the knob
- [x] 1.2 Add shared POI helper (food → water → cover → company → null) with destination-priority tests
- [x] 1.3 Swap every wander arm to the helper (JEV steers, ladder tails, `wander_mates`) keeping jitter fallback, with per-mover tests
- [x] 1.4 Verify suite green + live run with no errors and no clumping, run `ponytail-review`
