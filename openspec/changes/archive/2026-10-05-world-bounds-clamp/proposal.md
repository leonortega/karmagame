## Why

Ratons were seen walking off the map edge. Only the player was ever clamped to world bounds; AI steering, wandering, mate drift, and predator chases all write positions with no bounds check (faster animals made the leak visible sooner).

## What Changes

- Every agent (AI fauna, company mates, hunters) is clamped to the world margin each tick, same 20px margin as the player, in one pass after all movement resolves.

## Capabilities

### New Capabilities

(none — bug fix)

### Modified Capabilities

- `ecosystem-2d`: the bounded-world requirement already pins the player; extend it to all agents.

## Impact

- Affected code: `scripts/karma_game.gd` (`clamp_agents` at end of `update`).
- Tests: `test_agents_cannot_leave_world` in `tests/test_karma_systems.gd`.
- Systems: none (no save format, no protocol, no new files).
