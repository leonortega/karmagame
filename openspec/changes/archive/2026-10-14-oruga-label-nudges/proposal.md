## Why

Live `jev_oruga.log` entries show the ranker picking wander over drink ~0.8/0.2 even as an oruga's `sed` falls 86 → 36: the static labels (`"Drink water"`, `"Eat leaves"`) give the ranker no urgency signal, so need never weighs into ranking. Halcon solved this exact problem with floor-gated hunger hints in labels.

## What Changes

- Oruga candidate labels carry urgency hints when the need hits the floor band: `eat` appends a hunger hint when `hambre <= regenHambre`, `drink` appends a thirst hint when `sed <= regenSed`, `seek_food` appends a hunger hint (it is only offered when hungry; the hint fires at the floor).
- Candidate kinds, legality gates, cooldown/affordability checks, steering, cadence, and logging are untouched. Labels stay what they always were — ranking input plus HUD flavor — and SHALL never gate execution.
- Schema stays `jev-oruga/v1` (label text is criteria data, not schema, same as halcon's hints which never bumped its version).

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `ai-jev-oruga`: the candidate-menu requirement gains label-hint behavior — need hints on eat/drink/seek_food at floor need so the ranking can weigh urgency, mirroring the halcon hunger-hint precedent.

## Impact

- Touched code: `scripts/karma_jev_oruga.gd` `build_menu` label strings only; new tests in `tests/test_karma_jev_oruga.gd` mirroring halcon's label tests (`test_halcon_eat_label_plain_when_sated`, `test_halcon_eat_label_hints_hunger_when_needy`).
- No tuning-number changes, no new candidates, no Main/batch/log changes.
- Ordering dependency: the base `ai-jev-oruga` spec still lives in the unarchived `ai-jev-oruga` change (`openspec/changes/ai-jev-oruga/specs/`), not yet in `openspec/specs/`. Archive `ai-jev-oruga` BEFORE this change so this delta lands on the real main spec.
