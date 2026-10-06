## Why

Animals spend much of their lives in `wander` intent doing random drift with no purpose and no karma: menus collapse to `[wander]`, mocks pick it, and the forest looks and logs idle. Giving wander a destination (nearest food, water, cover, or mate) makes every animal read as doing something on every tick, with zero new rewards to balance and richer encounters feeding the existing menus for free.

## What Changes

- Every wander arm (all JEV steer micros, all ladder fallbacks, company-mate drift) steers toward the nearest point of interest instead of random-walking: nearest edible food, else nearest water, else nearest fitting cover, else nearest company mate, else a short random step as last resort.
- No karma, cost, or cooldown changes: this alters movement targets only, so the moral spectrum is untouched.
- Player movement is unchanged (possessed agent keeps free control).

## Capabilities

### New Capabilities

(none — behavior refinement)

### Modified Capabilities

- `ai-species-behavior`: ADD a wander-travel requirement (new requirement in the existing capability; no existing requirement text changes).

## Impact

- Affected code: one shared helper (nearest point of interest) plus one-line call-site swaps in each species' wander arm, ladder wander tails, and `wander_mates`.
- Tests: wander-destination tests per mover type (JEV wander arms, ladder tails, mates).
- Systems: none (no save format, no protocol, no new files, no rebalancing).
