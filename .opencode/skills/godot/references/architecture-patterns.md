# Godot 4 Architecture Patterns Reference

## Table of Contents

- [Signal Architecture — "Call Down, Signal Up"](#signal-architecture--call-down-signal-up)
- [Signal Bus Pattern (Global Event Bus)](#signal-bus-pattern-global-event-bus)
- [Autoload vs Static Class Decision](#autoload-vs-static-class-decision)
- [State Machine Pattern](#state-machine-pattern)
- [Entity Pattern — Data-Driven Design with Resources](#entity-pattern--data-driven-design-with-resources)
- [Composition Over Inheritance](#composition-over-inheritance)
- [Groups for Cross-Cutting Concerns](#groups-for-cross-cutting-concerns)
- [Scene Instancing Patterns](#scene-instancing-patterns)
- [Scene Transition Pattern](#scene-transition-pattern)

## Signal Architecture — "Call Down, Signal Up"

The fundamental communication rule in Godot:

- **Parent → Child**: Direct method calls (call down the tree)
- **Child → Parent**: Emit signals (signal up the tree)
- **Sibling → Sibling**: Parent mediates, or use a signal bus Autoload
- **Cross-scene**: Autoload event bus

### Why This Matters

Tight coupling (using `get_parent()`, `get_node("../Sibling")`) creates fragile code that
breaks on any scene restructure. Signals decouple sender from receiver — the emitter doesn't
know or care who's listening.

### Signal Declaration and Usage

```gdscript
# Declaration — always past tense, with typed parameters
signal health_changed(new_health: int)
signal enemy_defeated(enemy: Enemy, reward: int)
signal game_over

# Emission — first-class object syntax (never string-based)
health_changed.emit(current_health)
enemy_defeated.emit(self, loot_value)
game_over.emit()

# Connection — Callable-based
func _ready() -> void:
    # Connect child signals (signal up)
    $Player.health_changed.connect(_on_player_health_changed)
    
    # Connect with bound parameters
    $Button.pressed.connect(_on_button_pressed.bind("start"))
    
    # One-shot (auto-disconnects after first call)
    $AnimationPlayer.animation_finished.connect(_on_intro_done, CONNECT_ONE_SHOT)

# BANNED patterns:
# emit_signal("health_changed", current_health)  — string-based
# connect("pressed", self, "_on_pressed")         — Godot 3 syntax
# get_parent().some_method()                       — calling up
# get_node("../Sibling").do_thing()               — reaching across
```

### Signal Bus Pattern (Global Event Bus)

For truly decoupled cross-system communication, use an Autoload signal bus:

```gdscript
# events.gd — registered as Autoload "Events"
class_name Events
extends Node

## Global event bus for cross-system communication.
## All signals here represent game-wide events.

signal player_died
signal level_completed(level_id: int)
signal score_changed(new_score: int)
signal item_collected(item_data: ItemResource)
signal dialog_started(dialog_id: String)
signal dialog_ended
signal screen_transition_requested(scene_path: String)
```

Usage from any script:
```gdscript
# Emitting
Events.player_died.emit()

# Listening
func _ready() -> void:
    Events.level_completed.connect(_on_level_completed)

func _on_level_completed(level_id: int) -> void:
    save_progress(level_id)
```

## Autoload vs Static Class Decision

### When to Use Autoloads (Singletons)

Use Autoloads **only** when the system requires node lifecycle:

- **Audio Manager** — needs `_process()` for fade/crossfade
- **Scene Transition Manager** — needs node tree access, animation
- **Event Bus** — needs to persist across scene changes
- **Input Buffer** — needs `_process()` or `_input()` per frame
- **Background Music** — needs AudioStreamPlayer node

```gdscript
# audio_manager.gd — Autoload "AudioManager"
extends Node

@onready var music_player := $MusicPlayer as AudioStreamPlayer
@onready var sfx_pool: Array[AudioStreamPlayer] = []

var _current_volume := 1.0
var _target_volume := 1.0
var _fade_speed := 2.0

func _process(delta: float) -> void:
    # Smooth volume transitions require per-frame updates
    _current_volume = move_toward(_current_volume, _target_volume, _fade_speed * delta)
    music_player.volume_db = linear_to_db(_current_volume)

func play_music(stream: AudioStream) -> void:
    music_player.stream = stream
    music_player.play()

func fade_out(duration: float) -> void:
    _target_volume = 0.0
    _fade_speed = 1.0 / duration
```

### When to Use Static Classes

Use static classes when NO node lifecycle is needed:

- **Math utilities** — pure functions
- **Data definitions** — enums, constants, type aliases
- **Configuration** — game-wide settings
- **Factory methods** — creating objects without instance state
- **Serialization helpers** — save/load utilities

```gdscript
# game_math.gd — NO Autoload, just class_name
class_name GameMath

## Pure math utilities. No instance state, no node lifecycle needed.

static var rng := RandomNumberGenerator.new()

static func roll_dice(sides: int, count: int = 1) -> int:
    var total := 0
    for i in count:
        total += rng.randi_range(1, sides)
    return total

static func weighted_random(weights: Array[float]) -> int:
    var total := weights.reduce(func(acc: float, w: float) -> float: return acc + w, 0.0)
    var roll := randf() * total
    var cumulative := 0.0
    for i in weights.size():
        cumulative += weights[i]
        if roll <= cumulative:
            return i
    return weights.size() - 1

static func direction_to_angle(direction: Vector2) -> float:
    return direction.angle()
```

Usage:
```gdscript
var damage := GameMath.roll_dice(6, 3)  # 3d6
var index := GameMath.weighted_random([0.5, 0.3, 0.2])
```

### Decision Flowchart

```
Does it need _process(), _input(), or _physics_process()?
├── YES → Autoload
│
Does it need child nodes (AudioStreamPlayer, Timer, etc.)?
├── YES → Autoload
│
Does it need to persist across scene changes?
├── YES, and it has state that updates per frame → Autoload
├── YES, but it's just data → Static class (or Resource)
│
└── NO to all → Static class
```

## State Machine Pattern

### Architecture

```
StateMachine (Node)
├── IdleState (Node, extends State)
├── RunState (Node, extends State)
├── JumpState (Node, extends State)
└── AttackState (Node, extends State)
```

### Base State Class

```gdscript
# state.gd
class_name State
extends Node

## Base class for all states in a finite state machine.
## Override enter(), exit(), process(), and physics_process().

signal transition_requested(new_state_name: StringName)

func enter() -> void:
    pass

func exit() -> void:
    pass

func process(delta: float) -> void:
    pass

func physics_process(delta: float) -> void:
    pass

func handle_input(event: InputEvent) -> void:
    pass
```

### State Machine Controller

```gdscript
# state_machine.gd
class_name StateMachine
extends Node

## Manages state transitions. Add State nodes as children.

@export var initial_state: State

var current_state: State
var _states: Dictionary[StringName, State] = {}

func _ready() -> void:
    for child in get_children():
        if child is State:
            _states[child.name] = child
            child.transition_requested.connect(_on_transition_requested)
    
    if initial_state:
        current_state = initial_state
        current_state.enter()

func _process(delta: float) -> void:
    if current_state:
        current_state.process(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_process(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func _on_transition_requested(new_state_name: StringName) -> void:
    var new_state := _states.get(new_state_name)
    if new_state and new_state != current_state:
        current_state.exit()
        current_state = new_state
        current_state.enter()
```

### Example State Implementation

```gdscript
# idle_state.gd
class_name IdleState
extends State

## Player does nothing. Transitions to Run on input, Fall if not grounded.

@export var player: CharacterBody2D

func enter() -> void:
    player.get_node("AnimationPlayer").play("idle")

func physics_process(delta: float) -> void:
    # Transition to fall if not on floor
    if not player.is_on_floor():
        transition_requested.emit(&"FallState")
        return
    
    # Transition to run on movement input
    var input_direction := Input.get_axis("move_left", "move_right")
    if abs(input_direction) > 0.1:
        transition_requested.emit(&"RunState")
        return
    
    # Transition to jump
    if Input.is_action_just_pressed("jump"):
        transition_requested.emit(&"JumpState")
        return
    
    # Apply friction while idle
    player.velocity.x = move_toward(player.velocity.x, 0.0, 2000.0 * delta)
    player.move_and_slide()
```

## Entity Pattern — Data-Driven Design with Resources

Separate **data** (Resources) from **presentation** (Nodes) from **logic** (Managers).

### Custom Resource for Data

```gdscript
# weapon_resource.gd
class_name WeaponResource
extends Resource

## Defines weapon stats as portable data. Saved as .tres files.

@export var weapon_name: String = ""
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var range_value: float = 50.0
@export var icon: Texture2D
@export var projectile_scene: PackedScene

func get_dps() -> float:
    return damage * attack_speed
```

### Node That Uses the Resource

```gdscript
# weapon_node.gd
class_name WeaponNode
extends Node2D

## Visual and behavioral representation of a weapon.
## Data comes from the Resource; this handles presentation only.

signal attack_performed(damage: int)

@export var weapon_data: WeaponResource

var _cooldown_timer := 0.0

func _process(delta: float) -> void:
    if _cooldown_timer > 0.0:
        _cooldown_timer -= delta

func attack() -> void:
    if _cooldown_timer > 0.0:
        return
    _cooldown_timer = 1.0 / weapon_data.attack_speed
    attack_performed.emit(weapon_data.damage)
    
    if weapon_data.projectile_scene:
        var projectile := weapon_data.projectile_scene.instantiate()
        get_tree().current_scene.add_child(projectile)
        projectile.global_position = global_position
```

### Benefits of Resource Separation

1. **Reusable** — same WeaponResource used by player, enemies, shops, UI
2. **Inspector-editable** — designers modify .tres files without touching code
3. **Serializable** — `ResourceSaver.save()` for persistence
4. **Lightweight** — no node overhead, pure data
5. **Version control friendly** — .tres is human-readable text

## Composition Over Inheritance

### Bad: Deep Inheritance

```
Node2D
└── Entity
    └── LivingEntity
        └── Humanoid
            └── Player
            └── NPC
                └── Merchant
                └── Guard
```

### Good: Composition with Components

```
Player (CharacterBody2D)
├── HealthComponent (Node)
├── MovementComponent (Node)
├── InventoryComponent (Node)
├── CombatComponent (Node)
└── InteractionComponent (Area2D)

NPC (CharacterBody2D)
├── HealthComponent (Node)      ← same component, reused
├── AIComponent (Node)
├── DialogComponent (Node)
└── InteractionComponent (Area2D) ← same component, reused
```

### Component Example

```gdscript
# health_component.gd
class_name HealthComponent
extends Node

## Reusable health system. Attach to any entity that can take damage.

signal health_changed(current: int, maximum: int)
signal died

@export var max_health := 100

var current_health: int

func _ready() -> void:
    current_health = max_health

func take_damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    if current_health <= 0:
        died.emit()

func heal(amount: int) -> void:
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

func is_alive() -> bool:
    return current_health > 0
```

## Groups for Cross-Cutting Concerns

Use groups instead of type checks for identifying nodes across the tree:

```gdscript
# Adding to groups (in _ready or via editor)
func _ready() -> void:
    add_to_group("enemies")
    add_to_group("damageable")

# Querying groups
var all_enemies := get_tree().get_nodes_in_group("enemies")

# Calling group methods (broadcast)
get_tree().call_group("enemies", "alert", player_position)

# Type-safe group operations
for node in get_tree().get_nodes_in_group("damageable"):
    if node.has_method("take_damage"):
        node.take_damage(explosion_damage)
```

## Scene Instancing Patterns

```gdscript
# Preload at compile time (preferred for known scenes)
const BulletScene := preload("res://scenes/bullet.tscn")

func spawn_bullet(origin: Vector2, direction: Vector2) -> void:
    var bullet := BulletScene.instantiate() as Bullet
    bullet.global_position = origin
    bullet.direction = direction
    # Add to scene tree — use get_tree().current_scene for top-level
    get_tree().current_scene.add_child(bullet)

# Runtime load (for dynamic/optional content)
func load_level(path: String) -> void:
    var scene := ResourceLoader.load(path) as PackedScene
    if scene:
        var level := scene.instantiate()
        add_child(level)
```

## Scene Transition Pattern

```gdscript
# scene_manager.gd — Autoload "SceneManager"
extends Node

signal transition_started
signal transition_finished

@onready var animation_player := $AnimationPlayer as AnimationPlayer

var _next_scene_path: String = ""

func change_scene(scene_path: String) -> void:
    _next_scene_path = scene_path
    transition_started.emit()
    animation_player.play("fade_out")
    await animation_player.animation_finished
    get_tree().change_scene_to_file(_next_scene_path)
    animation_player.play("fade_in")
    await animation_player.animation_finished
    transition_finished.emit()
```
