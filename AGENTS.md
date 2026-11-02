# AGENTS.md — karmagame (Godot 4)

Instructions for any coding agent working in this repo (Claude Code, Codex, Cursor,
Codebuff, or anything else). Read this file before touching code; it applies to every
change. Nothing here assumes a particular assistant, tool, MCP, or operating system —
if a capability isn't available in your environment, do the equivalent by hand and say
so in the completion message rather than skipping it.

Godot 4.7, GDScript, zero third-party deps (addons: gdUnit4 + godot-mcp-toolkit only).
Repo root IS the Godot project (`project.godot`).

`godot` below means any Godot 4.7 binary — on `PATH`, a `.exe`, an `.app`, a flatpak,
whatever this machine has. Substitute its real path/name.

## Layout

- `project.godot` — main scene `res://scenes/main.tscn`, viewport 960×600
- `scripts/` — `karma_data, karma_utils, karma_state, karma_predators, karma_eat, karma_shop, karma_ai, karma_game, karma_draw, karma_hud` (pure `class_name` statics) + `main.gd` (scene-owned)
- `scenes/main.tscn` — `Main` (Node2D + `main.gd`)
- `tests/` — gdUnit4 suite (`test_*.gd`), mirrors the behavior specs
- `openspec/` — spec-driven changes + archive (source of truth for behavior)

## Conventions

- `snake_case` files/vars/funcs, `PascalCase` nodes/`class_name`, `SCREAMING_SNAKE_CASE` consts
- Simulation = pure static funcs on `Dictionary` state (no autoloads); only `Main` owns I/O
- Numbers live in `KarmaData.TUNING` — no magic numbers, no rebalancing without a spec change
- `_physics_process` for movement/tick, `_unhandled_input` for verbs (never poll `Input` in `_process`)
- State fixtures: `KarmaState.blank_state()` has NO possessed body (`new_run()` possesses one).
  Tests that drive the player through `KarmaGame`/`KarmaState.player()` must append a body
  with `brain = "PLAYER"` themselves — see the `_with_player` / `_player_state` / `_t1_scene`
  fixtures. A missing body makes `player()` return `null`, which aborts the test body and
  turns later assertions into silent passes.

## Commands

- Run: open in the Godot editor and press F5, or `godot --path .`
- Tests: `godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests --ignoreHeadlessMode`
  - `--ignoreHeadlessMode` is required for headless runs; UI/input tests need a windowed run.
  - The `--test` flag only exists in test-enabled builds (`tests=yes`); stock binaries abort with
    "compiled without support for unit tests" — use the gdUnit4 command above instead.
  - The runner exits non-zero on failure. A parse error in any test file aborts the whole run,
    and a runtime script error silently skips the rest of that suite — so a falling test count
    is a red flag, not a pass.
- Parse one script without running: `godot --headless -s <script.gd> --check-only --path .`

## Workflow

- TDD always: one discrete behavior per gdUnit4 test → red/green → next; never whole files up front.
- MCPs only when necessary.

## Skills

Skills inform every change; they are not a hard dependency on any one runtime.

- Ids in use: `tdd-workflow`, `safe-refactor`, `solid`, `clean-code`, `ponytail`,
  `ponytail-review`, `ponytail-audit`, `design-pattern-review`.
- If your runtime exposes a skill-loading tool, load by exact id: `tdd-workflow` +
  `safe-refactor` before task 1, `design-pattern-review` when the work is cross-cutting
  or introduces a new pattern.
- Whether loaded by tool or applied from memory, the bar is the same: judge every diff
  through `solid` / `clean-code` / `ponytail` (full) — smallest behavior-preserving step,
  table before pattern, no magic numbers, reuse an existing fixture before adding one.
- Before done: review the diff for over-engineering; audit the whole repo when 3+ files changed.
- Completion messages list each skill applied and one line on how it shaped the work.

## Verification gate

Every change: touched scripts parse → gdUnit4 suite green (full count, no silent suite
aborts) → no duplicate global `class_name`/`func` collisions → main scene runs.
