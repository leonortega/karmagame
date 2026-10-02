# Godot 4.3+ Common Systems Reference

## Table of Contents

- [TileMapLayer (Replaces Deprecated TileMap)](#tilemaplayer-replaces-deprecated-tilemap)
- [Procedural Generation with TileMapLayer](#procedural-generation-with-tilemaplayer)
- [Terrain Auto-Tiling (Godot 4.3+)](#terrain-auto-tiling-godot-43)
- [File System — FileAccess and DirAccess](#file-system--fileaccess-and-diraccess)
- [Resource System](#resource-system)
- [Input Handling Patterns](#input-handling-patterns)
- [Camera Patterns](#camera-patterns)
- [Object Pooling](#object-pooling)
- [Timer Patterns](#timer-patterns)
- [Animation Patterns](#animation-patterns)
- [UI Patterns](#ui-patterns)

## TileMapLayer (Replaces Deprecated TileMap)

`TileMap` was deprecated in Godot 4.3. Always use `TileMapLayer`.

### Key Differences

| Legacy TileMap | Modern TileMapLayer |
|---|---|
| Single node, multiple layers | One node per layer |
| `get_cell(layer, coords)` | `get_cell_source_id(coords)` |
| Layers managed by index | Layers are separate scene nodes |
| Complex layer management API | Simple single-layer API |

### Scene Structure

```
World (Node2D)
├── GroundLayer (TileMapLayer)
├── WallLayer (TileMapLayer)
├── DecorationLayer (TileMapLayer)
└── ForegroundLayer (TileMapLayer)
```

### TileMapLayer API

```gdscript
# Reading cells
var source_id := tile_layer.get_cell_source_id(Vector2i(x, y))
var atlas_coords := tile_layer.get_cell_atlas_coords(Vector2i(x, y))
var alt_tile := tile_layer.get_cell_alternative_tile(Vector2i(x, y))

# Check if cell is empty (-1 means no tile)
if tile_layer.get_cell_source_id(Vector2i(x, y)) == -1:
    print("Empty cell")

# Setting cells
tile_layer.set_cell(Vector2i(x, y), source_id, atlas_coords, alternative_tile)

# Erasing cells
tile_layer.erase_cell(Vector2i(x, y))

# Getting all used cells
var used_cells := tile_layer.get_used_cells()
var cells_by_id := tile_layer.get_used_cells_by_id(source_id)

# Coordinate conversion
var local_pos := tile_layer.map_to_local(Vector2i(5, 3))
var map_pos := tile_layer.local_to_map(global_position)

# Getting tile data for custom properties
var tile_data := tile_layer.get_cell_tile_data(Vector2i(x, y))
if tile_data:
    var is_solid: bool = tile_data.get_custom_data("is_solid")
    var damage: int = tile_data.get_custom_data("damage")
```

### Procedural Generation with TileMapLayer

```gdscript
class_name LevelGenerator
extends Node2D

## Procedurally generates terrain using TileMapLayer.

@export var ground_layer: TileMapLayer
@export var wall_layer: TileMapLayer
@export var width := 64
@export var height := 36

const GROUND_SOURCE := 0
const GROUND_ATLAS := Vector2i(0, 0)
const WALL_ATLAS := Vector2i(1, 0)

func generate() -> void:
    ground_layer.clear()
    wall_layer.clear()
    
    for x in width:
        for y in height:
            var coords := Vector2i(x, y)
            
            if y == height - 1:
                # Bottom row is always ground
                ground_layer.set_cell(coords, GROUND_SOURCE, GROUND_ATLAS)
            elif y == 0 or x == 0 or x == width - 1:
                # Borders are walls
                wall_layer.set_cell(coords, GROUND_SOURCE, WALL_ATLAS)
            elif randf() < 0.05:
                # Random platforms
                ground_layer.set_cell(coords, GROUND_SOURCE, GROUND_ATLAS)
```

### Terrain Auto-Tiling (Godot 4.3+)

Terrain in Godot 4 replaces the old autotile system. Configure terrain sets and terrain types
in the TileSet resource via the editor. At runtime:

```gdscript
# Set terrain — requires terrain set index and terrain index
# Use set_cells_terrain_connect for auto-connecting
var cells_to_paint: Array[Vector2i] = [
    Vector2i(0, 0),
    Vector2i(1, 0),
    Vector2i(2, 0),
]
tile_layer.set_cells_terrain_connect(cells_to_paint, terrain_set, terrain_index)

# Or paint individually and let neighbors update
tile_layer.set_cells_terrain_path(cells_to_paint, terrain_set, terrain_index)
```

## File System — FileAccess and DirAccess

### Critical Export Rule

In exported builds (`.pck` files):
- `res://` is **read-only** — cannot write, and raw source files may not exist
- `user://` is **read-write** — all save data goes here
- Use `ResourceLoader` for loading assets, not `FileAccess`

### FileAccess

```gdscript
# Writing text
func save_text_file(path: String, content: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_string(content)
        # File auto-closes when variable goes out of scope
    else:
        push_error("Failed to open file: %s (error: %s)" % [path, FileAccess.get_open_error()])

# Reading text
func load_text_file(path: String) -> String:
    var file := FileAccess.open(path, FileAccess.READ)
    if file:
        return file.get_as_text()
    return ""

# Check file exists
if FileAccess.file_exists("user://save.json"):
    pass

# Writing JSON save data
func save_game(data: Dictionary) -> void:
    var json_string := JSON.stringify(data, "\t")
    var file := FileAccess.open("user://savegame.json", FileAccess.WRITE)
    if file:
        file.store_string(json_string)

# Reading JSON save data
func load_game() -> Dictionary:
    if not FileAccess.file_exists("user://savegame.json"):
        return {}
    var file := FileAccess.open("user://savegame.json", FileAccess.READ)
    if not file:
        return {}
    var json_string := file.get_as_text()
    var parsed: Variant = JSON.parse_string(json_string)
    if parsed is Dictionary:
        return parsed
    return {}

# Encrypted files
func save_encrypted(data: String, key: PackedByteArray) -> void:
    var file := FileAccess.open_encrypted("user://secure.dat", FileAccess.WRITE, key)
    if file:
        file.store_string(data)

# Compressed files
func save_compressed(data: String) -> void:
    var file := FileAccess.open_compressed(
        "user://data.gz", FileAccess.WRITE, FileAccess.COMPRESSION_GZIP
    )
    if file:
        file.store_string(data)

# Binary data
func save_binary(path: String) -> void:
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file:
        file.store_32(12345)
        file.store_float(3.14)
        file.store_var({"key": "value"})
```

### DirAccess

```gdscript
# Open directory (static method — cannot use new())
var dir := DirAccess.open("user://")
if dir:
    dir.list_dir_begin()
    var file_name := dir.get_next()
    while file_name != "":
        if dir.current_is_dir():
            print("Directory: %s" % file_name)
        else:
            print("File: %s" % file_name)
        file_name = dir.get_next()

# Create directory
DirAccess.make_dir_absolute("user://saves")
DirAccess.make_dir_recursive_absolute("user://saves/profiles/backup")

# Check directory exists
if DirAccess.dir_exists_absolute("user://saves"):
    pass

# Copy file
DirAccess.copy_absolute("user://save1.json", "user://save1_backup.json")

# Remove file
DirAccess.remove_absolute("user://old_save.json")

# Rename/move
DirAccess.rename_absolute("user://temp.json", "user://save.json")
```

## Resource System

### Custom Resources

```gdscript
# character_stats.gd
class_name CharacterStats
extends Resource

## Portable character data. Create .tres files in editor or save at runtime.

@export var character_name: String = ""
@export var level: int = 1
@export var max_health: int = 100
@export var attack: int = 10
@export var defense: int = 5
@export var experience: int = 0
@export var skills: Array[SkillResource] = []

func get_health_for_level() -> int:
    return max_health + (level - 1) * 15

func add_experience(amount: int) -> bool:
    experience += amount
    var threshold := level * 100
    if experience >= threshold:
        level += 1
        experience -= threshold
        return true  # Leveled up
    return false
```

### Saving and Loading Resources

```gdscript
# Save resource to user:// (for runtime-modified data)
func save_character(stats: CharacterStats, slot: int) -> void:
    var path := "user://saves/character_%d.tres" % slot
    DirAccess.make_dir_recursive_absolute("user://saves")
    var error := ResourceSaver.save(stats, path)
    if error != OK:
        push_error("Failed to save character: %s" % error_string(error))

# Load resource
func load_character(slot: int) -> CharacterStats:
    var path := "user://saves/character_%d.tres" % slot
    if ResourceLoader.exists(path):
        return ResourceLoader.load(path) as CharacterStats
    return null

# Duplicate resource to avoid shared references
func clone_stats(original: CharacterStats) -> CharacterStats:
    return original.duplicate() as CharacterStats
```

### Resource vs. Autoload for Data

```
Is this data that multiple nodes read?
├── YES → Resource (pass via @export, or load from path)
│
Does this data change at runtime and need to notify listeners?
├── YES, frequently → Resource + signals or Autoload
├── YES, infrequently → Resource (just read when needed)
│
Is this read-only configuration?
├── YES → Resource (.tres file) or const in static class
│
Does it need serialization (save/load)?
├── YES → Resource (use ResourceSaver/ResourceLoader)
```

## Input Handling Patterns

### Modern Input API

```gdscript
# 1D axis (returns -1.0 to 1.0)
var horizontal := Input.get_axis("move_left", "move_right")

# 2D vector (returns normalized Vector2)
var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")

# Action checks
if Input.is_action_just_pressed("jump"):
    jump()

if Input.is_action_pressed("fire"):
    shoot()

if Input.is_action_just_released("charge"):
    release_charge()

# Action strength (0.0 to 1.0, useful for analog triggers)
var trigger_strength := Input.get_action_strength("accelerate")
```

### Input in _unhandled_input vs _input

```gdscript
# _unhandled_input — for gameplay input (can be consumed by UI first)
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("interact"):
        interact_with_nearest()
        get_viewport().set_input_as_handled()

# _input — for UI or input that must always respond
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        toggle_pause()
```

## Camera Patterns

### 2D Camera Following

```gdscript
# Attach Camera2D as child of player for basic follow.
# For advanced smoothing:

class_name GameCamera
extends Camera2D

@export var target: Node2D
@export var smoothing := 5.0
@export var look_ahead := 50.0

func _physics_process(delta: float) -> void:
    if not target:
        return
    var target_pos := target.global_position
    # Add look-ahead based on target velocity
    if target is CharacterBody2D:
        target_pos += target.velocity.normalized() * look_ahead
    global_position = global_position.lerp(target_pos, smoothing * delta)
```

### Screen Shake

```gdscript
var _shake_strength := 0.0
var _shake_decay := 5.0

func shake(strength: float) -> void:
    _shake_strength = strength

func _process(delta: float) -> void:
    if _shake_strength > 0.01:
        offset = Vector2(
            randf_range(-_shake_strength, _shake_strength),
            randf_range(-_shake_strength, _shake_strength),
        )
        _shake_strength = lerp(_shake_strength, 0.0, _shake_decay * delta)
    else:
        _shake_strength = 0.0
        offset = Vector2.ZERO
```

## Object Pooling

For frequently spawned/despawned objects (bullets, particles, enemies):

```gdscript
class_name ObjectPool
extends Node

## Reuses deactivated objects instead of instantiate/queue_free cycles.

@export var scene: PackedScene
@export var initial_size := 20

var _pool: Array[Node] = []

func _ready() -> void:
    for i in initial_size:
        _create_instance()

func get_object() -> Node:
    for obj in _pool:
        if not obj.visible:
            return obj
    # Pool exhausted — grow it
    return _create_instance()

func _create_instance() -> Node:
    var instance := scene.instantiate()
    instance.visible = false
    instance.process_mode = Node.PROCESS_MODE_DISABLED
    add_child(instance)
    _pool.append(instance)
    return instance

# Call this instead of queue_free()
static func release(obj: Node) -> void:
    obj.visible = false
    obj.process_mode = Node.PROCESS_MODE_DISABLED
```

## Timer Patterns

```gdscript
# One-shot timer (inline, no Timer node needed)
await get_tree().create_timer(1.5).timeout

# Reusable timer via node
@onready var attack_timer := $AttackTimer as Timer

func _ready() -> void:
    attack_timer.timeout.connect(_on_attack_timer_timeout)
    attack_timer.wait_time = 0.5
    attack_timer.one_shot = true

func start_attack() -> void:
    attack_timer.start()

func _on_attack_timer_timeout() -> void:
    can_attack = true

# Creating timer in code
func start_cooldown(duration: float) -> void:
    var timer := Timer.new()
    timer.wait_time = duration
    timer.one_shot = true
    timer.timeout.connect(func() -> void:
        _cooldown_finished = true
        timer.queue_free()
    )
    add_child(timer)
    timer.start()
```

## Animation Patterns

### AnimationPlayer Usage

```gdscript
@onready var anim := $AnimationPlayer as AnimationPlayer

func _ready() -> void:
    anim.animation_finished.connect(_on_animation_finished)

func play_attack() -> void:
    anim.play("attack")
    await anim.animation_finished
    # Attack animation done, return to idle
    anim.play("idle")

func _on_animation_finished(anim_name: StringName) -> void:
    match anim_name:
        &"death":
            queue_free()
        &"hit":
            anim.play("idle")
```

### AnimationTree with State Machine

```gdscript
@onready var anim_tree := $AnimationTree as AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = anim_tree.get(
    "parameters/playback"
)

func _physics_process(_delta: float) -> void:
    # Blend parameter for movement
    anim_tree.set("parameters/blend_position", velocity.normalized())
    
    # Travel to state
    if is_on_floor():
        if abs(velocity.x) > 10.0:
            state_machine.travel(&"run")
        else:
            state_machine.travel(&"idle")
    else:
        state_machine.travel(&"jump")
```

## UI Patterns

### Control Node Anchoring

```gdscript
# Always use anchors and containers, never absolute positioning.
# Common layout:

# HUD (CanvasLayer)
# └── MarginContainer
#     └── VBoxContainer
#         ├── HealthBar (TextureProgressBar)
#         ├── ScoreLabel (Label)
#         └── ItemContainer (HBoxContainer)
```

### Connecting UI to Game State

```gdscript
# hud.gd
class_name HUD
extends CanvasLayer

@onready var health_bar := %HealthBar as TextureProgressBar
@onready var score_label := %ScoreLabel as Label

# Player connects via signal (child signals up)
func update_health(current: int, maximum: int) -> void:
    health_bar.max_value = maximum
    health_bar.value = current

func update_score(score: int) -> void:
    score_label.text = "Score: %d" % score
```

Using unique name references (`%NodeName`) requires marking nodes as "Access as Unique Name"
in the editor (right-click node → "Access as Unique Name").
