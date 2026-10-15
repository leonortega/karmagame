## 1. Universality harness

- [x] 1.1 Add failing gdUnit4 tests proving every verb runs for agents (no `a != null: false` wall) with player/agent parity of costs, cooldowns, and ledgers.
- [x] 1.2 Remove player-only guards so each verb branches on actor; keep fail-without-burn (no cost/cooldown/karma on missing precondition) for all 40 verbs.
- [x] 1.3 Differentiate E-duplicates (`prudent`/`pounce`/`dive`) from bare `E` aliases with their own preconditions; tests red then green, suite green.

## 2. Social verbs touch the other body

- [x] 2.1 Rework sapo `chorus` to steer nearby conspecifics toward the caller's water (or leave a foam ring slowing hunters); fail with no choir, no burn.
- [x] 2.2 Rework raton/ardilla `groom` to cleanse mimic/toxin from the mate plus small mate heal; fail with no mate in range, no burn.

## 3. Radar verbs leave a shared mark

- [x] 3.1 Rework raton `scout` to drop a scent-post entity sharing reveal with mates in radius for its ttl; solo cast grants nothing.
- [x] 3.2 Rework halcon `thermal` to project a circling-shadow disc that scatters prey and is visible to others; solo buff grants nothing.

## 4. Harvest verbs consume stock

- [x] 4.1 Rework ardilla `bark` to consume oak stock and set a stripped state with regrow timer before PA/karma.
- [x] 4.2 Rework topo `worm` to consume a refuge charge and unearth a real insect entity before healing.
- [x] 4.3 Replace `tunneline` write-only `firm` with a burrow network link (or capacity raise); fail with no second burrow/capacity, no burn.

## 5. Escape and guard verbs touch hunter or mate

- [x] 5.1 Rework oruga `silk` to leave a sticky thread entity slowing the crossing hunter plus self displacement.
- [x] 5.2 Rework sapo `burrowin` to leave a wallow pit entity (sip plus slows ground hunters) plus self hide.
- [x] 5.3 Rework oruga `bristle` to sting immediately (hunter in range gains restT now) instead of armed-only flag.
- [x] 5.4 Rework lobo `escort` to shepherd the mate toward cover and deter nearby hunters; fail with no threatened mate, no burn.

## 6. JEV handleability

- [x] 6.1 Extend per-species JEV menus with the reworked verbs using legal-only preconditions (cooldown, range, stock/charge, hunter/mate presence, HP/PA affordability); wander always present.
- [x] 6.2 Route ranked reworked-verb picks through the same player functions with affordability recheck; stale/illegal picks fall back to steering/wander with no burn; state text carries the need token.
- [x] 6.3 Add gdUnit4 JEV suites per touched species (menu legality, ranked apply parity, stale fallback, no-burn on failed affordability).

## 7. Verification gate

- [x] 7.1 Touched scripts parse, full gdUnit4 suite green, no duplicate global class_name/func collisions, main scene runs from F5.
- [x] 7.2 Run ponytail-review over the diff; fix or explicitly defer each finding and record loaded skills in the completion message.
