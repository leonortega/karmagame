# Godot 4 Migration

Migrate the full Karma MVP (vanilla JS, `src/` + `test/` harness) to Godot 4 with full behavioral parity, then remove the JS-only files.

## Why

- Single engine target (Godot 4.7, GL Compatibility) instead of split JS/Godot.
- gdUnit4 replaces `node:test` as the verification suite.
- Repo root becomes the Godot project (promote `godot/*` to root).

## Scope

- Port all 10 `src/script/*.js` modules to GDScript under `scripts/`:
  `data, utils, state, predators, eat, shop, ai, game (verbs+world), draw (icons/sizes), hud`.
- `Main` scene (`scenes/main.tscn` + `scripts/main.gd`): Node2D world render + CanvasLayer HUD + input.
- gdUnit4 tests in `tests/` covering karma-core, diet, predators, verbs, reincarnation.
- Promote `godot/*` to repo root; delete `src/`, `test/*.test.js` (JS), `test/harness.js`, `serve.bat`; update `README.md` + `AGENTS.md`.
- Keep `openspec/` (specs + archive) as the behavior source of truth.

## Non-goals

- No new mechanics, species, or balance changes (numbers stay in `KarmaData.TUNING`).
- No export presets / mobile packaging in this change.
