---
name: godot
description: >
  Generate production-ready GDScript 2.0 for Godot 4.3+ with strict static typing.
  Auto-triggers on Godot, GDScript, or game development tasks.
  Enforces official style guide, modern architecture patterns, and version-safe syntax.
  Covers: player controllers, state machines, signals, tilemaps, save/load, UI, and more.
license: MIT
when_to_use: >
  Use when user asks to create a Godot game, write GDScript, build game mechanics,
  design game architecture, set up scenes, implement player controllers, enemy AI,
  UI systems, procedural generation, tilemaps, signals, state machines, save/load systems,
  or any Godot Engine task. Triggers on: "godot", "gdscript", "game dev", "make a game",
  "2D game", "3D game", "platformer", "RPG", "top-down", "side-scroller",
  "CharacterBody2D", "CharacterBody3D", "RigidBody", "Area2D", "Node2D", "Node3D".
metadata:
  author: "shihabshahrier"
  category: "game-development"
---

Produce production-ready, type-safe GDScript 2.0 for Godot 4.3+. Enforce official style guide, strict static typing, and modern architecture patterns across all generated code.

## Purpose

This skill constrains all Godot-related code generation to:
- **Godot 4.3+ only** — actively blocks Godot 3 syntax and deprecated APIs
- **Strict static typing** — every variable, parameter, and return type declared
- **Official GDScript style guide** — naming, formatting, 17-step code ordering
- **Loose coupling** — "call down, signal up", composition over inheritance
- **Data-driven design** — Resources for data, Nodes for presentation, Managers for logic

## When to Apply

Activate whenever the task involves:
- Writing or modifying GDScript files
- Designing Godot scene architecture or node trees
- Implementing game mechanics (movement, combat, inventory, AI)
- Building UI, save/load systems, procedural generation
- Migrating Godot 3 code to Godot 4

## Syntax Constraints

These are non-negotiable. Violations produce compilation errors:

| Banned (Godot 3 / Deprecated) | Required (Godot 4.3+) |
|-------------------------------|------------------------|
| `yield` | `await` |
| `emit_signal("name")` | `signal_name.emit()` |
| `connect("signal", target, "method")` | `signal.connect(callable)` |
| `TileMap` node | `TileMapLayer` node |
| `File` / `Directory` classes | `FileAccess` / `DirAccess` |
| `deg2rad` / `rad2deg` | `deg_to_rad` / `rad_to_deg` |
| `stepify` / `rand_range` / `instance()` | `snapped` / `randf_range` / `instantiate()` |
| `export var` / `onready var` | `@export var` / `@onready var` |
| `KinematicBody2D` | `CharacterBody2D` |
| `move_and_slide(velocity)` | `velocity = ...; move_and_slide()` |

Load `references/godot4-syntax.md` for the complete deprecation map when migrating code.

## Type Safety

Every declaration must be statically typed:

```gdscript
var speed := 400.0                                          # Inferred
var player_name: String = ""                                # Explicit
var enemies: Array[Enemy] = []                              # Typed array
func calculate_damage(base: float, mult: float) -> float:  # Params + return
func take_damage(amount: int) -> void:                      # Void explicit
```

## Naming and Formatting

Load `references/gdscript-style-guide.md` for naming conventions and formatting rules.

Key rules always active:

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.gd` | `weapon_system.gd` |
| Classes/Nodes | `PascalCase` | `class_name NetworkManager` |
| Functions | `snake_case()` | `func calculate_velocity():` |
| Signals | `snake_case` (past tense) | `signal enemy_defeated` |
| Constants/Enum members | `CONSTANT_CASE` | `const MAX_SPEED := 600.0` |

Formatting: one statement per line, English booleans (`and`/`or`/`not`), no unnecessary parentheses, double-indent multi-line conditions.

## Script Structure (17-Step Ordering)

Every script follows this exact sequence:

```
 1. @tool, @icon          2. class_name           3. extends
 4. ## Docstring           5. signals              6. enums
 7. constants              8. static var           9. @export var
10. var (public → _private) 11. @onready var       12. _static_init()
13. static func            14. Virtual callbacks (_init → _ready → _process → _physics_process)
15. Public methods          16. Private methods     17. Inner classes
```

## Architecture Patterns

Load `references/architecture-patterns.md` for signal bus, state machine, entity pattern, and composition examples.

Decision trees always active:

**State management:**
```
Needs _process() or node lifecycle? → Autoload
Just data/utilities/config?          → Static class (class_name + static var/func)
```

**Communication:**
```
Parent → Child:     direct method calls
Child → Parent:     signals (emit up)
Sibling → Sibling:  signal bus or parent mediates
Cross-scene:        Autoload event bus
```

## Common Systems

Load `references/common-systems.md` for TileMapLayer, FileAccess, Resources, input, camera, pooling, and UI patterns.

Key constraints always active:
- **TileMapLayer** not deprecated TileMap — one node per layer
- **FileAccess/DirAccess** not File/Directory — `user://` for saves, `res://` read-only in exports
- **ResourceLoader** for loading assets in exported builds
- **Resources** (`.tres`) for portable data — separate data from presentation

## Common Task Patterns

### Player Controller (2D Platformer)
Generate complete `CharacterBody2D` script: exported movement vars, `_physics_process` with `move_and_slide()`, coyote time, jump buffering, enum-based state tracking, input map references.

### State Machine
Dedicated `StateMachine` node managing `State` child nodes. Each state extends base `State` class. Transitions via signals. Never string-based state comparison.

### Save/Load
`user://` for all saves. `FileAccess.open()` with error checking. JSON or ResourceSaver. Never `File` class.

### TileMap / Level Design
`TileMapLayer` per logical layer. `get_cell_source_id()` / `set_cell()`. Procedural gen via code.

## Output Rules

1. Code blocks + max 2 sentences architectural rationale
2. No conversational filler
3. Comments explain WHY, not WHAT
4. File paths always specified
5. Node tree described when relevant:

```
Player (CharacterBody2D)
├── CollisionShape2D
├── Sprite2D
├── AnimationPlayer
└── Hurtbox (Area2D)
    └── CollisionShape2D
```

## Error Recovery

Godot 3 code provided → identify deprecated elements, provide modern equivalent, explain migration in 1 sentence, generate corrected code.

Architecturally unsound request → generate using proper patterns, note concern in 1 sentence, suggest alternatives only if issue causes real scaling problems.

## Never Do

- Never output Godot 3 syntax (`yield`, `emit_signal()`, string-based `connect()`, `TileMap`, `File`, `Directory`)
- Never use dynamic typing when static typing is possible
- Never use camelCase, Hungarian notation, or symbolic booleans (`&&`, `||`, `!`)
- Never use `get_parent()` or `get_node("../Sibling")` for cross-node communication
- Never suggest Autoloads for pure utility/data — use static classes
- Never combine conditional and execution on one line
- Never use backslash line continuation — use parentheses
- Never place `and`/`or` at end of line in multi-line conditions
- Never skip `-> void` on functions that return nothing
- Never write comments explaining WHAT code does — only WHY
- Never generate code without reading user's existing project context first
