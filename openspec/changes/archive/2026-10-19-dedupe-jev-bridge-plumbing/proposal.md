## Why

The eight `karma_jev_<species>.gd` bridges copy the same plumbing: `_verb_ready` (8 copies), `mock_macro` (7), `candidate_ids` (7), `build_http_body_for` (7), `_set_intent` (6 plus 2 buggy), `build_batch` (7), `all_jev_*` (8), and smaller helpers. The copies already diverged and produced the target-dropping bug fixed in `fix-jev-target-intent`.

## What Changes

- Extract the duplicated bridge helpers into one shared static class while keeping each species' menu builder, schema, log flag, and definition local to its own file.
- Keep batch shapes, candidate ids, state text, HTTP bodies, mock selection, and delegation through `KarmaJev` byte-for-byte compatible.
- Keep the shared intent helper target-preserving so the regression stays fixed.
- No spec-level, save-format, tuning, or API changes; behavior is preserved.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/karma_jev_*.gd` (8 bridge files), `scripts/karma_jev.gd`, `tests/test_karma_jev.gd`.
- Systems: JEV candidate building, batching, parsing, mock path, and per-species delegation; no menu or ranking changes.
- Prerequisite: land `fix-jev-target-intent` first, then prove the target tests still pass on the shared helper.
