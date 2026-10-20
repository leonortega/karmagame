## 1. Census roller with guardrails (TDD)

- [x] 1.1 Add failing gdUnit4 tests for the rolled census: seeded rolls vary between games, every species stays within floor-cap, player species count includes the player, insect diet gate clamps sapo/topo shares, prey:hunter ratio holds at 3:1 minimum.
- [x] 1.2 Add census floor/mid/cap plus theme weights next to POP data (no magic numbers in logic) and implement the pure seeded roller returning counts plus theme.
- [x] 1.3 Turn the new roller tests green without touching spawn code yet.

## 2. Fixed-roster first-life spawn

- [x] 2.1 Add failing gdUnit4 tests for fixed roster: new run spawns exactly the rolled census, the drawn species converts one member to the player (no extra company bodies), and reincarnation keeps carrying the rolled census reference.
- [x] 2.2 Rework first-life seeding to spawn the census as AI then possess-a-member, retargeting respawn bookkeeping from the static floor to the rolled census.
- [x] 2.3 Turn the fixed-roster tests green and update legacy tests that assert company-4 / fixed-floor / hunter-table counts to seeded-roll expectations (keeping one test pinning floors as minima).

## 3. Community anchors, hunter caps, birth log

- [x] 3.1 Add failing gdUnit4 tests for placement and pressure: communities cluster near food anchors within travel range with nothing inside water, at least two social congeners start in verb range, scripted hunters stay at floor when fauna predators cover the tier, and T0 starts spawn offset with lobo not initiating on T0/T1.
- [x] 3.2 Implement anchored loose-cluster placement reusing dry scatter and shore-ring placement, cap scripted hunter multiplication, add the T0 no-initiate guard in target selection, and write the theme year birth-log line.
- [x] 3.3 Turn placement and pressure tests green across all five themes plus a lean T0 draw.

## 4. Suite and balance validation

- [x] 4.1 Run the full gdUnit4 suite plus headless syntax checks on touched scripts until green, with no duplicate global class_name or func collisions.
- [x] 4.2 Validate balance on seeded rolls: leaf demand within regrow, insect demand within respawn with topo flex, oruga baseline of 8 holds the feeder surplus, and main scene boots from F5 into a themed census.
- [x] 4.3 Run the ponytail-review pass over the diff and record or defer every finding before handoff to the babies follow-up.
