extends Node2D
class_name Slime
## Slime - Individual slime piece on the game board
## Handles rendering, animations, and special effects
## All animations are script-based using a single sprite

signal clicked(slime: Slime)
signal swap_requested(direction: Vector2i)
signal match_animation_complete()
signal fall_animation_complete()

# Slime properties
var slime_color: GameManager.SlimeColor = GameManager.SlimeColor.RED:
	set(value):
		slime_color = value
		_update_visual()

var special_type: GameManager.SpecialType = GameManager.SpecialType.NONE:
	set(value):
		special_type = value
		_update_special_visual()

var grid_position: Vector2i = Vector2i.ZERO
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selection_visual()

var is_animating: bool = false

# Touch/Swipe handling
var touch_start_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false
const SWIPE_THRESHOLD: float = 30.0

# Node references - 2 layer system (back + front sprites)
@onready var back_slime: Sprite2D = $BackSlime
@onready var front_slime: Sprite2D = $FrontSlime
@onready var item_container: Node2D = $ItemContainer
@onready var particles: GPUParticles2D = $MatchParticles

# Current item instance
var current_item: Node2D = null

# Item scene preloads
const ITEM_STRIPED_H = preload("res://assets/items/striped_h/striped_h.tscn")
const ITEM_STRIPED_V = preload("res://assets/items/striped_v/striped_v.tscn")
const ITEM_WRAPPED = preload("res://assets/items/wrapped/wrapped.tscn")
const ITEM_COLOR_BOMB = preload("res://assets/items/color_bomb/color_bomb.tscn")

# Breathing animation - anchored at bottom via sprite offset
var breathing_tween: Tween = null
const BREATH_SCALE_MIN: Vector2 = Vector2(1.5, 1.7)   # Taller and thinner when "inhaling"
const BREATH_SCALE_MAX: Vector2 = Vector2(1.7, 1.5)   # Wider and shorter when "exhaling"
const BREATH_DURATION_MIN: float = 1.6
const BREATH_DURATION_MAX: float = 3.0


func _ready() -> void:
	_update_visual()
	_update_special_visual()
	_update_selection_visual()
	# Start breathing with random delay so slimes are out of sync
	_start_breathing_animation()


func _update_visual() -> void:
	# Apply color tint via shader parameter to both layers
	var tint_color = _get_color_tint(slime_color)
	var outline_color = _get_outline_color(slime_color)
	_set_shader_color(tint_color, outline_color)


func _set_shader_color(tint_color: Color, outline_color: Color = Color(0, 0, 0, 0)) -> void:
	# Set color via shader parameter for gel effect on both layers
	if back_slime and back_slime.material:
		back_slime.material.set_shader_parameter("color_tint", tint_color)
		back_slime.material.set_shader_parameter("outline_color", outline_color)
	if front_slime and front_slime.material:
		front_slime.material.set_shader_parameter("color_tint", tint_color)
		front_slime.material.set_shader_parameter("outline_color", outline_color)


func _get_color_tint(color: GameManager.SlimeColor) -> Color:
	# Map slime colors to tint colors
	match color:
		GameManager.SlimeColor.RED:
			return Color(1.8, 0.4, 0.4)
		GameManager.SlimeColor.ORANGE:
			return Color(1.8, 1.0, 0.3)
		GameManager.SlimeColor.YELLOW:
			return Color(1.8, 1.8, 0.4)
		GameManager.SlimeColor.GREEN:
			return Color(0.4, 1.5, 0.5)
		GameManager.SlimeColor.BLUE:
			return Color(1.0, 1.0, 1.0)  # Keep original blue
		GameManager.SlimeColor.PURPLE:
			return Color(1.4, 0.5, 1.5)
		# Colorless variants - grayscale with slight tint hints
		GameManager.SlimeColor.RED_COLORLESS:
			return Color(0.9, 0.7, 0.7)  # Grayish with red hint
		GameManager.SlimeColor.ORANGE_COLORLESS:
			return Color(0.9, 0.8, 0.7)  # Grayish with orange hint
		GameManager.SlimeColor.YELLOW_COLORLESS:
			return Color(0.9, 0.9, 0.7)  # Grayish with yellow hint
		GameManager.SlimeColor.GREEN_COLORLESS:
			return Color(0.7, 0.85, 0.7)  # Grayish with green hint
		GameManager.SlimeColor.BLUE_COLORLESS:
			return Color(0.7, 0.7, 0.85)  # Grayish with blue hint
		GameManager.SlimeColor.PURPLE_COLORLESS:
			return Color(0.8, 0.7, 0.85)  # Grayish with purple hint
		_:
			return Color.WHITE


func _get_outline_color(color: GameManager.SlimeColor) -> Color:
	# Return outline color for colorless variants (their base color)
	# Alpha 0 means no outline for regular colored slimes
	match color:
		GameManager.SlimeColor.RED_COLORLESS:
			return Color(1.0, 0.4, 0.4, 1.0)  # Red outline
		GameManager.SlimeColor.ORANGE_COLORLESS:
			return Color(1.0, 0.65, 0.2, 1.0)  # Orange outline
		GameManager.SlimeColor.YELLOW_COLORLESS:
			return Color(1.0, 0.9, 0.3, 1.0)  # Yellow outline
		GameManager.SlimeColor.GREEN_COLORLESS:
			return Color(0.2, 0.85, 0.35, 1.0)  # Green outline
		GameManager.SlimeColor.BLUE_COLORLESS:
			return Color(0.3, 0.5, 1.0, 1.0)  # Blue outline
		GameManager.SlimeColor.PURPLE_COLORLESS:
			return Color(0.7, 0.3, 0.9, 1.0)  # Purple outline
		_:
			return Color(0, 0, 0, 0)  # No outline for regular colors


func _update_special_visual() -> void:
	# Remove old item
	if current_item:
		current_item.queue_free()
		current_item = null

	# Create new item if needed
	if special_type != GameManager.SpecialType.NONE:
		var item_scene = _get_item_scene(special_type)
		if item_scene:
			current_item = item_scene.instantiate()
			current_item.set_slime_color(_get_color_tint(slime_color))
			item_container.add_child(current_item)


func _get_item_scene(type: GameManager.SpecialType) -> PackedScene:
	match type:
		GameManager.SpecialType.STRIPED_H:
			return ITEM_STRIPED_H
		GameManager.SpecialType.STRIPED_V:
			return ITEM_STRIPED_V
		GameManager.SpecialType.WRAPPED:
			return ITEM_WRAPPED
		GameManager.SpecialType.COLOR_BOMB:
			return ITEM_COLOR_BOMB
	return null


func _update_selection_visual() -> void:
	var base_color = _get_color_tint(slime_color)
	var outline_color = _get_outline_color(slime_color)
	if is_selected:
		var bright_color = Color(base_color.r * 1.3, base_color.g * 1.3, base_color.b * 1.3)
		_set_shader_color(bright_color, outline_color)
	else:
		_set_shader_color(base_color, outline_color)


func setup(color: GameManager.SlimeColor, pos: Vector2i, special: GameManager.SpecialType = GameManager.SpecialType.NONE) -> void:
	slime_color = color
	grid_position = pos
	special_type = special
	position = grid_to_world(pos)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2,
				   grid_pos.y * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2)


# Breathing animation - makes slimes feel alive
func _start_breathing_animation() -> void:
	if not back_slime or not front_slime:
		return

	# Random delay so slimes don't breathe in sync
	var delay = randf_range(0.0, 2.0)
	await get_tree().create_timer(delay).timeout

	if not is_instance_valid(self) or not back_slime:
		return

	_do_breath_cycle()


func _do_breath_cycle() -> void:
	if not is_instance_valid(self) or not back_slime or not front_slime:
		return

	# Kill any existing breathing tween
	if breathing_tween and breathing_tween.is_valid():
		breathing_tween.kill()

	# Random duration for this breath
	var breath_duration = randf_range(BREATH_DURATION_MIN, BREATH_DURATION_MAX)

	breathing_tween = create_tween()
	breathing_tween.set_loops()  # Loop forever

	# Inhale - get taller and thinner (sprite offset keeps bottom anchored)
	breathing_tween.tween_property(back_slime, "scale", BREATH_SCALE_MIN, breath_duration * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breathing_tween.parallel().tween_property(front_slime, "scale", BREATH_SCALE_MIN, breath_duration * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Exhale - get wider and shorter
	breathing_tween.tween_property(back_slime, "scale", BREATH_SCALE_MAX, breath_duration * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breathing_tween.parallel().tween_property(front_slime, "scale", BREATH_SCALE_MAX, breath_duration * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_breathing_animation() -> void:
	if breathing_tween and breathing_tween.is_valid():
		breathing_tween.kill()
		breathing_tween = null
	# Reset to default scale
	if back_slime:
		back_slime.scale = Vector2(1.6, 1.6)
	if front_slime:
		front_slime.scale = Vector2(1.6, 1.6)


# Input handling
func _input(event: InputEvent) -> void:
	if is_animating:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion and is_touching:
		_handle_mouse_motion(event)


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	var canvas_transform = get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos


func _is_point_in_cell(world_pos: Vector2) -> bool:
	var half_size = GameManager.CELL_SIZE * 0.5
	var cell_rect = Rect2(
		global_position.x - half_size,
		global_position.y - half_size,
		GameManager.CELL_SIZE,
		GameManager.CELL_SIZE
	)
	return cell_rect.has_point(world_pos)


func _handle_touch(event: InputEventScreenTouch) -> void:
	var world_pos = _screen_to_world(event.position)

	if event.pressed:
		if _is_point_in_cell(world_pos):
			is_touching = true
			touch_start_pos = event.position
	else:
		if is_touching:
			_check_swipe(event.position)
		is_touching = false


func _handle_drag(event: InputEventScreenDrag) -> void:
	if is_touching:
		_check_swipe(event.position)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	var world_pos = _screen_to_world(event.position)

	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_point_in_cell(world_pos):
				is_touching = true
				touch_start_pos = event.position
				clicked.emit(self)
		else:
			if is_touching:
				_check_swipe(event.position)
			is_touching = false


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	_check_swipe(event.position)


func _check_swipe(end_pos: Vector2) -> void:
	var delta = end_pos - touch_start_pos

	if delta.length() > SWIPE_THRESHOLD:
		var direction = Vector2i.ZERO

		if abs(delta.x) > abs(delta.y):
			direction = Vector2i(1, 0) if delta.x > 0 else Vector2i(-1, 0)
		else:
			direction = Vector2i(0, 1) if delta.y > 0 else Vector2i(0, -1)

		swap_requested.emit(direction)
		is_touching = false


# Animations

func animate_swap(target_pos: Vector2, duration: float = 0.2) -> void:
	is_animating = true
	_stop_breathing_animation()

	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished

	is_animating = false
	_start_breathing_animation()


# Animated swap with hop - slimes jump over each other in an arc
# Uses squash & stretch for juicy animation
func animate_swap_hop(target_pos: Vector2, hop_direction: int, duration: float = 0.3) -> void:
	is_animating = true
	_stop_breathing_animation()

	var start_pos = position

	# Base scale for sprites
	const BASE_SCALE = Vector2(1.6, 1.6)
	# Squash & stretch scales (relative to base)
	var stretch_scale = Vector2(1.3, 1.9) * 1.0  # Tall and thin in air (multiply by base later)
	var squash_scale = Vector2(2.0, 1.2) * 1.0   # Wide and flat on land
	var anticipation_scale = Vector2(1.8, 1.3) * 1.0  # Slight squash before jump

	# Calculate arc - always hop upward for visual clarity
	var delta = target_pos - start_pos
	var hop_height = 50.0  # Pixels to hop up
	var perpendicular: Vector2
	if abs(delta.x) > abs(delta.y):
		# Horizontal swap - hop up
		perpendicular = Vector2(0, -hop_height * abs(hop_direction))
	else:
		# Vertical swap - hop sideways based on direction
		perpendicular = Vector2(-hop_height * hop_direction * 0.5, -hop_height * 0.7)

	var mid_point = (start_pos + target_pos) / 2.0 + perpendicular

	# Phase 1: Anticipation - quick squash before jumping
	var tween0 = create_tween()
	tween0.set_parallel(true)
	tween0.tween_property(back_slime, "scale", anticipation_scale, duration * 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween0.tween_property(front_slime, "scale", anticipation_scale, duration * 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween0.finished

	# Phase 2: Jump up - stretch tall and thin
	var tween1 = create_tween()
	tween1.set_parallel(true)
	tween1.tween_property(self, "position", mid_point, duration * 0.35)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween1.tween_property(back_slime, "scale", stretch_scale, duration * 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween1.tween_property(front_slime, "scale", stretch_scale, duration * 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween1.finished

	# Phase 3: Fall down - start transitioning to squash
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(self, "position", target_pos, duration * 0.35)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween2.tween_property(back_slime, "scale", squash_scale, duration * 0.35)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween2.tween_property(front_slime, "scale", squash_scale, duration * 0.35)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await tween2.finished

	# Phase 4: Bounce back to normal with overshoot
	var tween3 = create_tween()
	tween3.set_parallel(true)
	tween3.tween_property(back_slime, "scale", BASE_SCALE, duration * 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween3.tween_property(front_slime, "scale", BASE_SCALE, duration * 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	await tween3.finished

	is_animating = false
	_start_breathing_animation()


func animate_invalid_swap(original_pos: Vector2, target_pos: Vector2, duration: float = 0.15) -> void:
	is_animating = true
	_stop_breathing_animation()

	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position", original_pos, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished

	is_animating = false
	_start_breathing_animation()


func animate_match() -> void:
	is_animating = true
	_stop_breathing_animation()
	AudioManager.play_sfx("match")

	# Emit particles
	if particles:
		particles.emitting = true

	# Pop and fade animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Quick scale up (pop effect)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.1)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.25)\
		.set_ease(Tween.EASE_IN)

	# Shrink after pop
	tween.chain().tween_property(self, "scale", Vector2(0.5, 0.5), 0.15)\
		.set_ease(Tween.EASE_IN)

	await tween.finished

	match_animation_complete.emit()
	is_animating = false


func animate_fall(target_pos: Vector2, delay: float = 0.0, duration: float = 0.3) -> void:
	var final_target = target_pos

	# Kill previous tween if exists
	if has_meta("_fall_tween"):
		var old_tween = get_meta("_fall_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	is_animating = true
	_stop_breathing_animation()

	if delay > 0:
		await get_tree().create_timer(delay).timeout
		if not is_instance_valid(self):
			return

	var tween = create_tween()
	set_meta("_fall_tween", tween)
	tween.tween_property(self, "position", final_target, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

	await tween.finished

	# Force position to target
	if is_instance_valid(self):
		position = final_target

	fall_animation_complete.emit()
	is_animating = false
	_start_breathing_animation()


func animate_spawn(delay: float = 0.0) -> void:
	_stop_breathing_animation()
	scale = Vector2.ZERO
	modulate.a = 0.0

	if delay > 0:
		await get_tree().create_timer(delay).timeout

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	await tween.finished
	_start_breathing_animation()


func animate_special_creation() -> void:
	AudioManager.play_sfx("special")
	AudioManager.vibrate(100)
	_stop_breathing_animation()

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	await tween.finished
	_start_breathing_animation()


func animate_pulse() -> void:
	_stop_breathing_animation()

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_ease(Tween.EASE_IN_OUT)
