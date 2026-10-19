## Why

The world draw pass rebuilds the same text layout every frame: `_pill` calls `font.get_string_size` and `draw_string` for every visible label, and `species_medal` parses a color string on every agent. With a full map this is per-frame string shaping and color parsing for labels that did not change.

## What Changes

- Cache shaped label text so an unchanged label at the same size and width is not re-shaped every frame.
- Cache per-species colors once instead of parsing the data color string on every agent draw.
- Draw the static legend as one multiline call instead of repeated label work.
- Keep every glyph, size, color, position, and visibility rule identical.
- No spec-level, save-format, tuning, or API changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. Pure refactor; `skip_specs: true` in `.openspec.yaml`.

## Impact

- Affected code: `scripts/main.gd` draw helpers and `scripts/karma_draw.gd` lookups.
- Systems: per-frame world rendering cost; visuals and HUD behavior must not change.
- Verification: compare captures before/after for a representative full-map frame, plus the existing suite.
