## Why

AI zorros and halcons currently apply JEV pounce/hunt/dive intents without the target they ranked, so steering sees a missing prey and clears the intent instead of chasing or killing. The existing tests inject `jev_intent` manually and never exercise the apply path, which is why the regression is invisible.

## What Changes

- Preserve the selected candidate's `target` when zorro and halcon JEV answers are converted into `jev_intent`.
- Add regression tests that drive `apply_answer` / `apply_halcon_answer` from a real menu and then run micro steering to contact.
- Keep all candidate menus, ranking, cadence, logging, and steering thresholds unchanged.
- No schema, save-format, tuning, or API changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ai-jev-zorro`: the applied-intent contract must retain the prey/carrion target selected by ranking.
- `ai-jev-halcon`: the applied-intent contract must retain the prey/carrion target selected by ranking.

## Impact

- Affected code: `scripts/karma_jev_zorro.gd`, `scripts/karma_jev_halcon.gd`, `tests/test_karma_jev.gd`.
- Systems: AI predator chase/kill behavior for zorro and halcon; no player-facing UI or balance change.
- Risk: low; the fix restores the already-declared steering contract and is covered by contact-kill tests.
