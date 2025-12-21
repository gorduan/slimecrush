# GDScript Patterns - SlimeCrush

## Signal Pattern

```gdscript
# Deklaration
signal match_found(positions: Array[Vector2i], color: GameManager.SlimeColor)

# Emission
match_found.emit(matched_positions, slime.slime_color)

# Connection
slime.match_found.connect(_on_match_found)

# Handler
func _on_match_found(positions: Array[Vector2i], color: GameManager.SlimeColor) -> void:
    pass
```

## Coroutine Pattern (Animationen)

```gdscript
# Animation mit await
func animate_swap(target: Vector2, duration: float = 0.2) -> void:
    is_animating = true
    var tween = create_tween()
    tween.tween_property(self, "position", target, duration)
    await tween.finished
    is_animating = false

# Mehrere Animationen parallel
func animate_all_falls() -> void:
    var tweens: Array[Tween] = []
    for slime in falling_slimes:
        var tween = slime.create_tween()
        tween.tween_property(slime, "position", target, 0.3)
        tweens.append(tween)

    # Warten auf alle
    for tween in tweens:
        await tween.finished
```

## State Machine Pattern

```gdscript
enum State { IDLE, PROCESSING, ANIMATING, GAME_OVER }

var current_state: State = State.IDLE

func _process(delta: float) -> void:
    match current_state:
        State.IDLE:
            _handle_idle()
        State.PROCESSING:
            _handle_processing()
        State.ANIMATING:
            pass  # Wait for animation
        State.GAME_OVER:
            _handle_game_over()
```

## Processing Guard Pattern

```gdscript
var is_processing: bool = false
var processing_start_time: float = 0.0
const PROCESSING_TIMEOUT: float = 3.0

func _try_swap(slime1: Slime, slime2: Slime) -> void:
    if is_processing:
        return

    is_processing = true
    processing_start_time = Time.get_ticks_msec() / 1000.0

    # ... do work ...

    is_processing = false

func _check_timeout() -> void:
    if is_processing:
        var elapsed = Time.get_ticks_msec() / 1000.0 - processing_start_time
        if elapsed > PROCESSING_TIMEOUT:
            push_warning("Processing stuck - forcing reset")
            is_processing = false
```

## Singleton Access Pattern

```gdscript
# In autoload/game_manager.gd
extends Node

var score: int = 0
var current_level: int = 1

# Access from anywhere
func _ready() -> void:
    GameManager.score += 100
    GameManager.check_win_condition()
```

## Resource Preload Pattern

```gdscript
# Preload at compile time
const SlimeScene: PackedScene = preload("res://scenes/slime.tscn")

# Instantiate
func _create_slime() -> Slime:
    var slime = SlimeScene.instantiate()
    add_child(slime)
    return slime
```

## Type-Safe Dictionary Pattern

```gdscript
# Define structure
var board: Array[Array] = []  # 2D array of Slime or null

func _init_board() -> void:
    board.resize(BOARD_SIZE)
    for x in range(BOARD_SIZE):
        board[x] = []
        board[x].resize(BOARD_SIZE)
        for y in range(BOARD_SIZE):
            board[x][y] = null
```

## Visual Feedback Pattern

```gdscript
const COOLDOWN_DARKEN: float = 0.75
const COOLDOWN_TRANSITION: float = 0.2

func _set_board_darkened(darkened: bool) -> void:
    var target = Color(COOLDOWN_DARKEN, COOLDOWN_DARKEN, COOLDOWN_DARKEN) if darkened else Color.WHITE
    for x in range(BOARD_SIZE):
        for y in range(BOARD_SIZE):
            var slime = board[x][y]
            if slime and is_instance_valid(slime):
                var tween = slime.create_tween()
                tween.tween_property(slime, "modulate", target, COOLDOWN_TRANSITION)
```

---

**Version:** 1.0.0
**Last Updated:** 2025-12-21
