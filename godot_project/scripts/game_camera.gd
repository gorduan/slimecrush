extends Camera2D
## GameCamera - Handles camera scrolling between levels
## Scrolls upward when level is completed

signal scroll_complete
signal scroll_started

# Camera settings
const SCROLL_DURATION: float = 1.0
const LEVEL_HEIGHT: float = 1280.0  # One screen height per level

# Camera center position (middle of viewport)
const CAMERA_CENTER: Vector2 = Vector2(360, 640)

var current_level_offset: int = 0
var is_scrolling: bool = false


func _ready() -> void:
	# Keep camera at center position - don't override scene position
	pass


func _get_level_position(level_offset: int) -> Vector2:
	# Each level is one screen height above the previous
	# Level 1 = center, Level 2 = center - LEVEL_HEIGHT, etc.
	return Vector2(CAMERA_CENTER.x, CAMERA_CENTER.y - level_offset * LEVEL_HEIGHT)


func scroll_to_level(level_offset: int, animate: bool = true) -> void:
	if is_scrolling:
		return

	var target_pos = _get_level_position(level_offset)

	if animate:
		is_scrolling = true
		scroll_started.emit()
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", target_pos, SCROLL_DURATION)
		tween.tween_callback(_on_scroll_complete)
	else:
		position = target_pos
		current_level_offset = level_offset


func scroll_up() -> void:
	current_level_offset += 1
	scroll_to_level(current_level_offset)


func _on_scroll_complete() -> void:
	is_scrolling = false
	scroll_complete.emit()


func reset_camera() -> void:
	current_level_offset = 0
	position = CAMERA_CENTER
	is_scrolling = false


func get_current_level_y_offset() -> float:
	# Returns the Y position offset for the current level (for placing GameBoard)
	return -current_level_offset * LEVEL_HEIGHT
