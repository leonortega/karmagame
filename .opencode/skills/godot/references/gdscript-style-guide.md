# GDScript Style Guide — Complete Reference

Source: Official Godot Engine documentation (stable). This is the authoritative reference
for all naming, formatting, and code organization rules.

## Table of Contents

- [Naming Conventions Matrix](#naming-conventions-matrix)
- [Special Naming Rules](#special-naming-rules)
- [Formatting Rules](#formatting-rules)
- [One Statement Per Line](#one-statement-per-line)
- [Boolean Operators](#boolean-operators)
- [Parentheses](#parentheses)
- [Multi-line Conditions](#multi-line-conditions)
- [Number Separators](#number-separators)
- [Enum Formatting](#enum-formatting)
- [Trailing Commas](#trailing-commas)
- [Code Organization — The 17-Step Declaration Sequence](#code-organization--the-17-step-declaration-sequence)
- [Complete Example](#complete-example)
- [Local Variable Placement](#local-variable-placement)
- [Comments and Documentation](#comments-and-documentation)

## Naming Conventions Matrix

| Code Element | Convention | Rationale | Correct | Incorrect |
|---|---|---|---|---|
| File names | `snake_case.gd` | Avoids cross-platform case-sensitivity export errors (Windows → Linux) | `weapon_system.gd` | `WeaponSystem.gd` |
| Class names | `PascalCase` | Differentiates global types from variables | `class_name NetworkManager` | `class_name network_manager` |
| Node names | `PascalCase` | Parity with built-in Godot node names | `PlayerController` | `player_controller` |
| Functions | `snake_case()` | Distinguishes executable logic from class definitions | `func calculate_velocity():` | `func calculateVelocity():` |
| Private/Virtual | `_snake_case()` | Denotes internal/engine callbacks not to be called externally | `func _physics_process(delta):` | `func physicsProcess(delta):` |
| Variables | `snake_case` | Standard state containers | `var current_health: int` | `var currentHealth: int` |
| Signals | `snake_case` (past tense) | Observer pattern — events that already happened | `signal enemy_defeated` | `signal onEnemyDefeated` |
| Constants | `CONSTANT_CASE` | Visually separates immutable from mutable | `const MAX_SPEED := 600.0` | `const maxSpeed := 600.0` |
| Enum names | `PascalCase` (singular) | Represents a distinct type | `enum WeaponType` | `enum weapon_types` |
| Enum members | `CONSTANT_CASE` | Treated as immutable constant values | `PLASMA_RIFLE` | `PlasmaRifle` |

### Special Naming Rules

- **Preloaded classes**: Use PascalCase even when stored in `const`:
  ```gdscript
  const Weapon = preload("res://weapon.gd")
  const BulletScene = preload("res://bullet.tscn")
  ```

- **Private variables**: Prefix with underscore `_`:
  ```gdscript
  var _internal_state := 0
  func _calculate_damage() -> float:
  ```

- **Boolean variables**: Use prefixes like `is_`, `has_`, `can_`, `should_`:
  ```gdscript
  var is_jumping := false
  var has_key := false
  var can_attack := true
  ```

## Formatting Rules

### One Statement Per Line

```gdscript
# CORRECT
if is_colliding():
    handle_collision()

# WRONG — never combine conditional and execution on one line
if is_colliding(): handle_collision()
```

**Exception**: Ternary operator for simple assignments:
```gdscript
var next_state := "idle" if is_on_floor() else "fall"
```

### Boolean Operators

Always use plain English operators:

```gdscript
# CORRECT
if is_on_floor() and not is_stunned:
    jump()

if has_ammo or has_melee_weapon:
    attack()

# WRONG — never use symbolic operators
if is_on_floor() && !is_stunned:   # FORBIDDEN
if has_ammo || has_melee_weapon:   # FORBIDDEN
```

### Parentheses

Avoid unnecessary parentheses:

```gdscript
# CORRECT
if is_colliding():
    pass

# WRONG
if (is_colliding()):
    pass
```

### Multi-line Conditions

Use parentheses (not backslashes) for wrapping. Place `and`/`or` at start of continuation.
Use **two indentation levels** for continuation to separate from the body:

```gdscript
# CORRECT — parentheses, double indent, operator at line start
if (
        is_on_floor()
        and input_velocity.length() > 0.1
        and not is_against_wall
):
    start_running()

# WRONG — backslash wrapping
if is_on_floor() \
        and input_velocity.length() > 0.1:
    start_running()

# WRONG — operator at end of line
if (
        is_on_floor() and
        input_velocity.length() > 0.1
):
    start_running()
```

### Number Separators

Use underscores for readability with large numbers:

```gdscript
var population := 1_000_000
var hex_color := 0xFF_AA_00
var small_number := 12_345
```

### Enum Formatting

Place each member on its own line for clean version control diffs:

```gdscript
# CORRECT
enum Direction {
    NORTH,
    SOUTH,
    EAST,
    WEST,
}

# WRONG — hard to diff
enum Direction { NORTH, SOUTH, EAST, WEST }
```

### Trailing Commas

Use trailing commas in multi-line arrays, dictionaries, enums, and function calls:

```gdscript
var items := [
    "sword",
    "shield",
    "potion",
]

var stats := {
    "health": 100,
    "mana": 50,
    "stamina": 75,
}
```

## Code Organization — The 17-Step Declaration Sequence

Every GDScript file must follow this exact order. Godot parses sequentially, and certain
annotations (`@onready`) are evaluated at specific lifecycle points.

### The Sequence

```
 1. @tool, @icon, @static_unload
 2. class_name (with @abstract if applicable)
 3. extends
 4. ## Doc comments
 5. signal declarations
 6. enum declarations
 7. const declarations
 8. static var declarations
 9. @export variables
10. Public var → then private _var declarations
11. @onready var declarations
12. _static_init()
13. static func declarations
14. Virtual callbacks: _init → _enter_tree → _ready → _process → _physics_process → others
15. Public custom methods
16. Private custom methods (prefixed _)
17. Inner classes (at absolute bottom)
```

### The Four Laws Behind This Ordering

1. **Properties and signals precede all methods**
2. **Public access precedes private access**
3. **Built-in virtual callbacks precede custom methods**
4. **Construction/initialization precedes runtime modification**

### Complete Example

```gdscript
@tool
@icon("res://assets/icons/player.svg")
class_name Player
extends CharacterBody2D

## The main player character. Handles movement, combat, and inventory.
## Emits signals for UI updates and game state changes.

signal health_changed(new_health: int)
signal died

enum State {
    IDLE,
    RUNNING,
    JUMPING,
    FALLING,
    ATTACKING,
}

const MAX_HEALTH := 100
const GRAVITY := 980.0

static var player_count := 0

@export_group("Movement")
@export var move_speed := 200.0
@export var jump_force := -450.0
@export var acceleration := 1500.0
@export var friction := 2000.0

@export_group("Combat")
@export var attack_damage := 10
@export var invincibility_duration := 1.5

var current_health := MAX_HEALTH
var current_state := State.IDLE
var _is_invincible := false
var _attack_cooldown := 0.0

@onready var sprite := $Sprite2D as Sprite2D
@onready var anim_player := $AnimationPlayer as AnimationPlayer
@onready var collision := $CollisionShape2D as CollisionShape2D
@onready var hurtbox := $Hurtbox as Area2D

func _init() -> void:
    player_count += 1

func _ready() -> void:
    hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _physics_process(delta: float) -> void:
    _apply_gravity(delta)
    _handle_input(delta)
    _update_state()
    move_and_slide()
    _update_animation()

func take_damage(amount: int) -> void:
    if _is_invincible:
        return
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health)
    if current_health <= 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = min(MAX_HEALTH, current_health + amount)
    health_changed.emit(current_health)

func _apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += GRAVITY * delta

func _handle_input(delta: float) -> void:
    var direction := Input.get_axis("move_left", "move_right")
    if direction:
        velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_force

func _update_state() -> void:
    if is_on_floor():
        current_state = State.RUNNING if abs(velocity.x) > 10.0 else State.IDLE
    else:
        current_state = State.JUMPING if velocity.y < 0.0 else State.FALLING

func _update_animation() -> void:
    match current_state:
        State.IDLE:
            anim_player.play("idle")
        State.RUNNING:
            anim_player.play("run")
            sprite.flip_h = velocity.x < 0.0
        State.JUMPING:
            anim_player.play("jump")
        State.FALLING:
            anim_player.play("fall")

func _on_hurtbox_area_entered(area: Area2D) -> void:
    if area.is_in_group("enemy_attack"):
        take_damage(area.get_meta("damage", 10))
```

## Local Variable Placement

Declare local variables as close as possible to their first use:

```gdscript
# CORRECT — declared near usage
func process_enemies() -> void:
    for enemy in get_tree().get_nodes_in_group("enemies"):
        var distance := global_position.distance_to(enemy.global_position)
        if distance < detection_range:
            _engage_enemy(enemy)

# WRONG — declared far from usage
func process_enemies() -> void:
    var distance: float  # unnecessary early declaration
    for enemy in get_tree().get_nodes_in_group("enemies"):
        distance = global_position.distance_to(enemy.global_position)
        if distance < detection_range:
            _engage_enemy(enemy)
```

Never promote a local variable to a member variable if it's only used in one function.

## Comments and Documentation

```gdscript
## Doc comments use double hash (##). They appear in Godot's documentation panel.
## Use for class-level and public method documentation.

# Regular comments use single hash.
# Use sparingly — explain WHY, not WHAT.

# WHY comment (good) — explains design decision
# Clamp velocity before move_and_slide to prevent tunneling at high speeds
velocity = velocity.clamp(-MAX_VELOCITY, MAX_VELOCITY)

# WHAT comment (bad) — restates obvious code
# Set velocity to zero
velocity = Vector2.ZERO
```
