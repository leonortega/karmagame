## 1. Test-first scaffolding

- [x] 1.1 Add HUD/feed cases to test harness (per-species controls rows, PA markup, edad animal-years format, vertical verb rows, otherLog emoji prefix, no empty-message drops)
- [x] 1.2 Confirm new cases fail on current code (red baseline)

## 2. Per-species controls with cooldowns

- [x] 2.1 Add controls table (BASE + per-species extras, R excluded in-life) following VERB_DEFS table convention
- [x] 2.2 Render controls per possessed species with verb-style `(Ns)` cooldown counters and dim-while-cooling
- [x] 2.3 Remove static R row from in-life panel; keep reincarnation entry on Judgment screen only

## 3. Identity split plus PA, time, edad

- [x] 3.1 Split species/tier identity from cooldown state in the HUD bar
- [x] 3.2 Emphasize PA readout (icon + distinct color/weight, numeric updates unchanged)
- [x] 3.3 Label elapsed time as run clock; add per-species seconds-per-year table and display edad as animal-years plus raw seconds (display-only, no needs-math change)

## 4. Vertical verb list

- [x] 4.1 Render verb bar 1-5 as vertical list rows (slot + name + cooldown, keep poor/cd states)
- [x] 4.2 Style list via CSS without changing verb behavior, costs, or cooldowns

## 5. Emoji-first karma feed for all species

- [x] 5.1 Prefix every AI addKarma feed entry with actor species emoji plus existing text
- [x] 5.2 Replace empty-message AI karma writes (shout, silent hunts) with real deed messages so all species surface
- [x] 5.3 Keep roster block, player feed, and karma-only scope unchanged (no eat/drink firehose)

## 6. Verification gate

- [x] 6.1 Run node --check on touched files and full node --test suite green
- [x] 6.2 Confirm no duplicate function names across src/script and index.html refs resolve
