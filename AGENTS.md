# AGENTS.md — karmagame (Godot 4)

Godot 4.7, GDScript, zero third-party deps (addons: gdUnit4 + godot-mcp-toolkit only).
Repo root IS the Godot project (`project.godot`).

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

## Commands

- Run: open in Godot 4 editor, F5 (or `godot --path .`)
- Tests: gdUnit4 dock, or `godot --headless --path . --test`
- Syntax: editor parses on save; headless `--check-only` per script if needed

## Workflow (standing)

TDD always: one discrete behavior per gdUnit4 test → red/green → next; never whole
files up front. Apply `safe-refactor`, `solid`, `clean-code`, `ponytail` (+ review/audit),
and `design-pattern-review` on every change as the work requires. MCPs only when necessary.

## Skill enforcement protocol

Skills are not advisory — load and apply them via the `skill` tool (exact `id`) on every change:

- **Apply start**: load `tdd-workflow` + `safe-refactor` (+ `godot-best-practices` for any
  `.gd` work) before task 1. Every diff after that is judged through `solid` / `clean-code` /
  `ponytail` (full): smallest behavior-preserving step, table before pattern, no magic numbers.
- **Cross-cutting or new-pattern work**: load `design-pattern-review` during propose/plan.
- **Before done**: run `ponytail-review` on the diff; `ponytail-audit` when 3+ files changed.
- **Audit trail**: the completion message lists each loaded skill + one line on how it shaped the work.

## Verification gate

Every change: touched scripts parse → gdUnit4 suite green → no duplicate global
`class_name`/`func` collisions → main scene runs from F5.
