## Why

`KarmaJev` still exposes roughly 30 delegating wrappers that no production code calls, plus old batch-picker APIs and dead helpers/constants in neighboring scripts. They make the live API hard to read, keep obsolete tests alive, and hide which entry points the game actually uses.

## What Changes

- Remove unused `KarmaJev` wrappers and the obsolete `pick_batch_species*` pickers after confirming zero production references.
- Remove dead helpers and constants such as unused state filters, draw legend lines, and unused tuning tables once reference checks prove they are unreachable.
- Update or delete tests that only exercised the removed obsolete APIs.
- Keep every live delegate and behavior unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/karma_jev.gd`, `scripts/karma_data.gd`, `scripts/karma_draw.gd`, `scripts/karma_predators.gd`, `scripts/karma_state.gd`, `tests/test_karma_jev.gd`.
- Systems: JEV facade surface and unused lookups only; runtime behavior must not change.
- Prerequisite: land after `dedupe-jev-bridge-plumbing` so the surviving surface is already settled.
