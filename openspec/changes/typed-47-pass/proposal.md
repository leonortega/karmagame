## Why

Large parts of the simulation pass untyped `Array` and `Dictionary` values around, so mistakes such as a missing `target` key are only caught at runtime. The 4.7 script pass adds explicit types where they are cheap and safe, letting the parser catch shape errors before they reach the game.

## What Changes

- Add element and value types to arrays, dictionaries, loop variables, and local bindings that are currently untyped.
- Replace ad-hoc `{x, y}` dictionaries with `Vector2` where a value is only a position, starting with camera and facing data.
- Replace manual movement-key axis assembly with `Input.get_vector` while preserving deadzone and normalization behavior.
- Keep every calculation, ordering, and result identical; no gameplay or tuning change.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/karma_*.gd` and `scripts/main.gd` in small per-file slices.
- Systems: type surface of the pure static simulation; no behavior change.
- Risk: typing a `Dictionary` too narrowly can reject deliberately heterogeneous state, so slices stay file-local and the suite gates each one.
