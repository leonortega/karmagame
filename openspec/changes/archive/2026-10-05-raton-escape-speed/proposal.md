## Why

The Ratón dies too early: at base speed 150 it cannot outrun a Zorro (185) in the open, so it gets caught before reaching refuge cover. Giving the Ratón a base speed above the Zorro restores its escape fantasy while predator chase multipliers keep every hunt closable.

## What Changes

- Ratón base speed 150 → 190 (faster than Zorro 185, still below Halcón 215).
- No other numbers change: Zorro/Lobo chase multipliers still close on a fleeing Ratón (249.75 / 214.5 vs 190), and refuge hiding is untouched.

## Capabilities

### New Capabilities

(none — pure rebalance)

### Modified Capabilities

- `karma-core`: Ratón form gains its escape speed; Ardilla form wording drops the faster-than-Ratón claim (175 stays, now the slower of the pair).

## Impact

- Affected code: `scripts/karma_data.gd` (one number in `SPECIES.raton`).
- Tests: new invariant tests (raton > zorro base; both chases still close).
- Systems: none (no save format, no protocol, no new files).
