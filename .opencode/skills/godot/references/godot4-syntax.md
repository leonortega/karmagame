# Godot 4.3+ Syntax Reference — Migration & Modern Patterns

This reference covers all deprecated Godot 3 syntax and their modern Godot 4.3+ replacements.
The AI must never output any syntax from the "Deprecated" column.

## Table of Contents

- [Core Language Changes](#core-language-changes)
- [Math & Utility Functions](#math--utility-functions)
- [Type Names](#type-names)
- [Node Class Renames](#node-class-renames)
- [Physics Changes](#physics-changes)
- [Input System Changes](#input-system-changes)
- [Signal Connection Patterns](#signal-connection-patterns)
- [Await Patterns](#await-patterns)
- [Tween System (Complete Overhaul)](#tween-system-complete-overhaul)
- [Export Annotations (Godot 4 Expanded System)](#export-annotations-godot-4-expanded-system)
- [Resource System Changes](#resource-system-changes)
- [Array and Dictionary Typed Syntax](#array-and-dictionary-typed-syntax)
- [String Formatting](#string-formatting)

## Complete Deprecation Map

### Core Language Changes

| Godot 3 (BANNED) | Godot 4.3+ (REQUIRED) | Notes |
|---|---|---|
| `yield(object, "signal")` | `await object.signal` | First-class coroutine support |
| `yield(get_tree().create_timer(1), "timeout")` | `await get_tree().create_timer(1.0).timeout` | Timer coroutine |
| `emit_signal("name", args)` | `signal_name.emit(args)` | Signals are first-class objects |
| `connect("signal", target, "method")` | `signal.connect(callable)` | Callable-based connections |
| `disconnect("signal", target, "method")` | `signal.disconnect(callable)` | Callable-based disconnections |
| `is_connected("signal", target, "method")` | `signal.is_connected(callable)` | Callable-based check |
| `funcref(object, "method")` | `object.method` (Callable) | First-class Callable type |
| `instance()` | `instantiate()` | Scene instantiation |
| `export var` | `@export var` | Annotation syntax |
| `onready var` | `@onready var` | Annotation syntax |
| `tool` | `@tool` | Annotation syntax |
| `remote`, `puppet`, `master` | `@rpc("any_peer")` etc. | RPC annotations |

### Math & Utility Functions

| Godot 3 (BANNED) | Godot 4.3+ (REQUIRED) |
|---|---|
| `deg2rad(x)` | `deg_to_rad(x)` |
| `rad2deg(x)` | `rad_to_deg(x)` |
| `stepify(x, step)` | `snapped(x, step)` |
| `rand_range(a, b)` | `randf_range(a, b)` |
| `seed(x)` | Use `RandomNumberGenerator` class |
| `decimals(x)` | `str(x).get_slice(".", 1).length()` |
| `lerp(a, b, t)` | `lerpf(a, b, t)` for floats, `lerp()` still works for vectors |
| `polar2cartesian(r, th)` | `Vector2.from_angle(th) * r` |
| `cartesian2polar(x, y)` | `Vector2(x, y).length()` + `Vector2(x, y).angle()` |
| `range_lerp(val, a, b, c, d)` | `remap(val, a, b, c, d)` |

### Type Names

| Godot 3 (BANNED) | Godot 4.3+ (REQUIRED) |
|---|---|
| `PoolByteArray` | `PackedByteArray` |
| `PoolIntArray` | `PackedInt32Array` or `PackedInt64Array` |
| `PoolRealArray` | `PackedFloat32Array` or `PackedFloat64Array` |
| `PoolStringArray` | `PackedStringArray` |
| `PoolVector2Array` | `PackedVector2Array` |
| `PoolVector3Array` | `PackedVector3Array` |
| `PoolColorArray` | `PackedColorArray` |
| `Transform` | `Transform3D` |
| `Quat` | `Quaternion` |
| `AABB` | `AABB` (unchanged) |

### Node Class Renames

| Godot 3 (BANNED) | Godot 4.3+ (REQUIRED) |
|---|---|
| `KinematicBody2D` | `CharacterBody2D` |
| `KinematicBody` | `CharacterBody3D` |
| `RigidBody` | `RigidBody3D` |
| `Area` | `Area3D` |
| `Spatial` | `Node3D` |
| `Position2D` | `Marker2D` |
| `Position3D` | `Marker3D` |
| `RayCast` | `RayCast3D` |
| `RayCast2D` | `RayCast2D` (unchanged) |
| `Navigation2D` | `NavigationRegion2D` |
| `Navigation` | `NavigationRegion3D` |
| `TileMap` (monolithic) | `TileMapLayer` (per-layer, since 4.3) |
| `VisibilityNotifier2D` | `VisibleOnScreenNotifier2D` |
| `VisibilityNotifier` | `VisibleOnScreenNotifier3D` |
| `Listener` | `AudioListener3D` |
| `Camera` | `Camera3D` |

### Physics Changes

```gdscript
# Godot 3 — velocity passed as argument (BANNED)
velocity = move_and_slide(velocity, Vector2.UP)

# Godot 4 — velocity is a property on CharacterBody2D
velocity = Vector2(direction * speed, velocity.y + gravity * delta)
move_and_slide()
# Access results via: is_on_floor(), is_on_wall(), is_on_ceiling()
# Slide count via: get_slide_collision_count(), get_slide_collision(index)
```

### Input System Changes

```gdscript
# Godot 3 style (still works but less type-safe)
if Input.is_action_pressed("move_right"):
    pass

# Godot 4 preferred — use Input.get_axis for cleaner 1D input
var horizontal := Input.get_axis("move_left", "move_right")

# Godot 4 preferred — use Input.get_vector for 2D input
var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
```

### Signal Connection Patterns

```gdscript
# Godot 3 — string-based (BANNED)
button.connect("pressed", self, "_on_button_pressed")
button.connect("pressed", self, "_on_button_pressed", ["extra_arg"])

# Godot 4 — Callable-based (REQUIRED)
button.pressed.connect(_on_button_pressed)
button.pressed.connect(_on_button_pressed.bind("extra_arg"))

# One-shot connections
button.pressed.connect(_on_button_pressed, CONNECT_ONE_SHOT)

# Deferred connections
button.pressed.connect(_on_button_pressed, CONNECT_DEFERRED)

# Lambda connections
button.pressed.connect(func() -> void: print("pressed"))

# Disconnect
button.pressed.disconnect(_on_button_pressed)
```

### Await Patterns

```gdscript
# Wait for signal
await get_tree().create_timer(2.0).timeout

# Wait for animation
anim_player.play("attack")
await anim_player.animation_finished

# Wait for tween
var tween := create_tween()
tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
await tween.finished

# Wait for next frame
await get_tree().process_frame

# Wait for physics frame
await get_tree().physics_frame
```

### Tween System (Complete Overhaul)

```gdscript
# Godot 3 — Tween node (BANNED)
# var tween = $Tween
# tween.interpolate_property(sprite, "position", start, end, 1.0)
# tween.start()

# Godot 4 — SceneTreeTween (created via create_tween())
var tween := create_tween()
tween.tween_property(sprite, "position", target_pos, 1.0)
tween.tween_callback(func() -> void: print("done"))

# Chaining tweens (sequential by default)
var tween := create_tween()
tween.tween_property(sprite, "position:x", 100.0, 0.5)
tween.tween_property(sprite, "position:y", 200.0, 0.5)
tween.tween_interval(0.3)
tween.tween_callback(_on_tween_complete)

# Parallel tweens
var tween := create_tween().set_parallel(true)
tween.tween_property(sprite, "position", target, 1.0)
tween.tween_property(sprite, "modulate:a", 0.0, 1.0)

# Easing and transitions
tween.tween_property(node, "position", target, 1.0) \
    .set_ease(Tween.EASE_OUT) \
    .set_trans(Tween.TRANS_BOUNCE)

# Looping
var tween := create_tween().set_loops(3)  # or set_loops(0) for infinite
```

### Export Annotations (Godot 4 Expanded System)

```gdscript
# Basic exports
@export var health: int = 100
@export var speed := 200.0

# Range
@export_range(0, 100, 1) var health: int = 100
@export_range(0.0, 1.0, 0.01) var volume: float = 0.5

# Enums
@export var weapon: WeaponType = WeaponType.SWORD

# File paths
@export_file("*.tscn") var next_scene: String
@export_dir var save_directory: String

# Node references
@export var target_node: CharacterBody2D
@export var path_to_follow: Path2D

# Resource types
@export var weapon_data: WeaponResource
@export var character_stats: Array[StatResource]

# Groups and subgroups (visual organization in Inspector)
@export_group("Movement")
@export var move_speed := 200.0
@export var jump_force := -400.0

@export_subgroup("Advanced")
@export var acceleration := 1500.0
@export var friction := 2000.0

@export_group("Combat")
@export var attack_damage := 10

# Multiline string
@export_multiline var dialogue: String

# Color without alpha
@export_color_no_alpha var outline_color: Color

# Flags (bitmask)
@export_flags("Fire", "Water", "Earth", "Wind") var elements: int

# Layers
@export_flags_2d_physics var collision_mask: int
@export_flags_2d_render var visual_layers: int
```

### Resource System Changes

```gdscript
# Loading resources
var scene: PackedScene = load("res://scenes/enemy.tscn")          # Runtime load
var scene: PackedScene = preload("res://scenes/enemy.tscn")       # Compile-time load
var texture: Texture2D = ResourceLoader.load("res://icon.svg")    # Explicit loader

# Creating custom resources
class_name WeaponData
extends Resource

@export var weapon_name: String = ""
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var icon: Texture2D

# Saving resources
ResourceSaver.save(weapon_data, "user://saves/weapon.tres")

# Loading custom resources
var data := ResourceLoader.load("user://saves/weapon.tres") as WeaponData
```

### Array and Dictionary Typed Syntax

```gdscript
# Typed arrays (Godot 4)
var enemies: Array[Enemy] = []
var positions: Array[Vector2] = []
var names: Array[String] = ["Alice", "Bob"]

# Typed dictionaries (Godot 4.4+)
var inventory: Dictionary[String, int] = {}
var node_map: Dictionary[StringName, Node] = {}

# Array methods — modern naming
var arr := [3, 1, 2]
arr.sort()                    # In-place sort
var filtered := arr.filter(func(x: int) -> bool: return x > 1)
var mapped := arr.map(func(x: int) -> int: return x * 2)
var reduced := arr.reduce(func(acc: int, x: int) -> int: return acc + x, 0)
var found := arr.any(func(x: int) -> bool: return x == 2)
var all_positive := arr.all(func(x: int) -> bool: return x > 0)
```

### String Formatting

```gdscript
# Godot 3 — % formatting (still works)
var text := "Health: %d / %d" % [current, maximum]

# Godot 4 — also supports format strings with named placeholders
var text := "Player {name} has {hp} HP".format({"name": player_name, "hp": health})
```
