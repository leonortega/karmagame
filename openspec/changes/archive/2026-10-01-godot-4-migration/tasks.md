## 1. Core data + state (TDD)

- [x] 1.1 gdUnit4: species table, diet matrix, tuning anchor (lobo 30-min), pool/judge rules
- [x] 1.2 `scripts/karma_data.gd` (class_name KarmaData): WORLD, SPECIES, DIET, PRED, TUNING, SHOP, VERB_DEFS, LOCO, CONTROLS, SEC_PER_YEAR
- [x] 1.3 `scripts/karma_state.gd`: blank_state/new_run/seed_*, eff_*, karma/pa/ledger, refuge/hide/shout

## 2. Systems parity

- [x] 2.1 `scripts/karma_utils.gd`: scatter/nearest/needs/collisions/LOS
- [x] 2.2 `scripts/karma_predators.gd`: edible_for, step/update, chase/feast
- [x] 2.3 `scripts/karma_eat.gd`: try_eat per species, carrion lifecycle, bury/carry, sense
- [x] 2.4 `scripts/karma_shop.gd`: pool_for/draw_from/judge/catalog/has_adapt/buy
- [x] 2.5 `scripts/karma_ai.gd`: perception karma-aware, forage/thirst/hide/verbs per species
- [x] 2.6 `scripts/karma_game.gd`: age_world/flora/insects, verbs VERB_FN, move, update tick
- [x] 2.7 `scripts/karma_draw.gd`: icons, emoji sizes, carrion/refuge/water lookups (pure)

## 3. Runnable game

- [x] 3.1 `scenes/main.tscn` + `scripts/main.gd` (Node2D render via _draw, HUD labels, _unhandled_input verbs)
- [x] 3.2 project.godot: main scene, window 960x600, input actions
- [x] 3.3 gdUnit4 suite green in `tests/`

## 4. Promote + cleanup

- [x] 4.1 Promote `godot/*` to repo root (project.godot, scripts/, scenes/, tests/, addons/, .godot/)
- [x] 4.2 Delete `src/`, JS `test/*.test.js` + `harness.js`, `serve.bat`
- [x] 4.3 Update `README.md`, `AGENTS.md`; full verification gate
