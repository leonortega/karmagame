## 1. Karma-floor pool + azar draw

- [x] 1.1 Add `poolFor(karma)` pure table test (≤-50 → oruga; -50..+50 → T1 four; ≥+50 → T1+T2 seven incl. lobo) in test/shop.test.js, red then green in src/script/shop.js
- [x] 1.2 Add `drawFrom(pool, rand)` uniform draw with stubbed rand (first/last/middle index) + wire `judge()` to return `{ pool, next, reason }` with no PA/deadForm inputs
- [x] 1.3 Update judgment reason strings to cite floor + eligible pool; keep 20% karma carry and PA carry-as-wallet

## 2. Delete choice paths

- [x] 2.1 Remove `pickT2`/`chooseForm`, `pendingChoice`/`formChosen`, T2-pick + Choose-form buttons and handlers; assert in tests that no choice controls render or function
- [x] 2.2 Remove lateral-cycle index logic and Lobo start-only exception from judge paths; full suite green

## 3. Gods reveal UI

- [x] 3.1 Render judgment pool as one block per eligible species with ineligible dimmed, drama line "los dioses eligen que reencarnes en...", settled form announced; outcome settled synchronously before animation
- [x] 3.2 Add cycling highlight animation (~1s, slows, settles on pre-drawn form) as cosmetic-only layer; R/Reencarnar active immediately; test pool + settled form without timers

## 4. Start azar

- [x] 4.1 Replace 8 start buttons with single Nacer action + 8-block grid cycling over all species; uniform draw over all 8 with no karma evaluation
- [x] 4.2 Rewire `startRun` to azar entry (`startRunAzar`) keeping `newRun` spawn semantics; update start-screen tests

## 5. Per-species shop (3 each, AI parity)

- [x] 5.1 Add `SHOP_BY_SPECIES` data shape (3 items/species: 1 stat + 1 verb-upgrade + 1 signature, 50–80 PA) in src/script/data.js with concrete effect numbers per design open question
- [x] 5.2 Rewire `buyItem`/`renderShop` to resolve against buyer's species catalog for player; update shop tests to per-species buying, no-stack, no-debt, per-life clearing
- [x] 5.3 Wire AI buying to own-species catalog via same logic; assert cross-species items unbuyable and AI parity scenarios green

## 6. Verification gate

- [x] 6.1 Rewrite test/shop.test.js judgment block (pool/draw, no-reroll, carry-wallet) plus start-azar tests; `node --check` touched files → full suite green → no duplicate `function` names → index.html refs resolve
- [x] 6.2 `ponytail-review` pass over the diff; fix or explicitly defer each finding
