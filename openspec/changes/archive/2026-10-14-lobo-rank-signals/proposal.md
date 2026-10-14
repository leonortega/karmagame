## Why

Live `jev_lobo.log` batches show the ranker picking `wander` at 0.76–0.85 over `eat`/`drink` whenever the lobo is sated — plausibly correct, but the Godot side gives the ranker no explicit need-urgency signal (just raw `hambre`/`sed` numbers) and offers no automatic screen for the genuinely worrying pattern (hungry + food offered + wander picked). tighten the signal and the monitoring without touching the menu contract.

## What Changes

- Lobo `state_text` gains an explicit urgency token derived from the same snapshot rules as `appraise_emocion` (e.g. `need=urgent|hunger|thirst|none`), so the ranker reads need state directly instead of inferring it from numbers. Mock order is already eat-first (verified, no change).
- Each flushed lobo decision is screened for the red-flag pattern (snapshot hungry + `eat` in menu + ranked choice `wander`); the count rides along in `jev_poll.json` next to the existing poll/census snapshot, so the file the operator already reads surfaces it.
- No menu-legality changes, no new candidates, no tuning changes, no sidecar protocol changes (the state string and poll JSON are free-form today).

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `ai-jev-lobo-pack`: ADDED — urgency framing in the lobo state text; ADDED — red-flag screening of flushed lobo decisions.
- `ai-jev-cadence`: MODIFIED — poll telemetry snapshot gains per-species red-flag counters.

## Impact

- Modified: `scripts/karma_jev_lobo.gd` (`state_text` + pure `is_red_flag` screen), `scripts/karma_jev.gd` (counter helper), `scenes/main.gd` (flush writes counters), `tests/test_karma_jev_lobo.gd` (+ framing/screen tests), specs `ai-jev-lobo-pack` + `ai-jev-cadence` deltas.
- Mock priority order untouched (eat-first already, covered by existing test).
