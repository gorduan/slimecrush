extends Node2D
class_name Slime
## Slime - Individual slime piece on the game board
## Handles rendering, animations, and special effects

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

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var special_overlay: Sprite2D = $SpecialOverlay
@onready var selection_highlight: Sprite2D = $SelectionHighlight
@onready var particles: GPUParticles2D = $MatchParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite

# Use sprites instead of draw
var use_sprites: bool = true

# Sprite frames (loaded once)
static var sprite_frames: SpriteFrames = null


func _ready() -> void:
	_setup_sprite_frames()
	_update_visual()
	_update_special_visual()
	_update_selection_visual()

	# Start idle animation at random frame
	if use_sprites and animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.frame = randi() % 4  # Random start frame (0-3)


func _setup_sprite_frames() -> void:
	if not use_sprites or not animated_sprite:
		return

	# Create SpriteFrames if not exists
	if sprite_frames == null:
		sprite_frames = SpriteFrames.new()

		# Load textures
		var idle_texture = load("res://assets/slimes/idle.png")
		var death_texture = load("res://assets/slimes/death.png")
		var fall_texture = load("res://assets/slimes/fall.png")

		# Add idle animation (4 frames)
		sprite_frames.add_animation("idle")
		sprite_frames.set_animation_speed("idle", 3.0)  # Slower animation
		sprite_frames.set_animation_loop("idle", true)
		if idle_texture:
			var frame_width = idle_texture.get_width() / 4
			var frame_height = idle_texture.get_height()
			for i in range(4):
				var atlas = AtlasTexture.new()
				atlas.atlas = idle_texture
				atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
				sprite_frames.add_frame("idle", atlas)

		# Add death animation (8 frames)
		sprite_frames.add_animation("death")
		sprite_frames.set_animation_speed("death", 15.0)
		sprite_frames.set_animation_loop("death", false)
		if death_texture:
			var frame_width = death_texture.get_width() / 8
			var frame_height = death_texture.get_height()
			for i in range(8):
				var atlas = AtlasTexture.new()
				atlas.atlas = death_texture
				atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
				sprite_frames.add_frame("death", atlas)

		# Add fall animation (12 frames)
		sprite_frames.add_animation("fall")
		sprite_frames.set_animation_speed("fall", 20.0)
		sprite_frames.set_animation_loop("fall", false)
		if fall_texture:
			var frame_width = fall_texture.get_width() / 12
			var frame_height = fall_texture.get_height()
			for i in range(12):
				var atlas = AtlasTexture.new()
				atlas.atlas = fall_texture
				atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
				sprite_frames.add_frame("fall", atlas)

	animated_sprite.sprite_frames = sprite_frames


func _draw() -> void:
	# Skip drawing if using sprites
	if use_sprites:
		# Only draw special indicators on top of sprite
		var radius = GameManager.CELL_SIZE * 0.4
		_draw_special_indicator(radius)
		return

	# Draw the slime as a circle with gradient (fallback)
	var color = GameManager.get_slime_color(slime_color)
	var radius = GameManager.CELL_SIZE * 0.4

	# Main slime body
	draw_circle(Vector2.ZERO, radius, color)

	# Highlight (top-left)
	var highlight_color = Color(1, 1, 1, 0.4)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.25, highlight_color)

	# Small highlight
	var small_highlight = Color(1, 1, 1, 0.3)
	draw_circle(Vector2(radius * 0.15, -radius * 0.4), radius * 0.12, small_highlight)

	# Draw special indicators
	_draw_special_indicator(radius)


func _draw_special_indicator(radius: float) -> void:
	match special_type:
		GameManager.SpecialType.STRIPED_H:
			# Horizontal stripe
			var stripe_color = Color(1, 1, 1, 0.8)
			draw_rect(Rect2(-radius * 0.8, -radius * 0.1, radius * 1.6, radius * 0.2), stripe_color)

		GameManager.SpecialType.STRIPED_V:
			# Vertical stripe
			var stripe_color = Color(1, 1, 1, 0.8)
			draw_rect(Rect2(-radius * 0.1, -radius * 0.8, radius * 0.2, radius * 1.6), stripe_color)

		GameManager.SpecialType.WRAPPED:
			# Wrapped border
			var border_color = Color(1, 1, 1, 0.8)
			draw_arc(Vector2.ZERO, radius * 0.9, 0, TAU, 32, border_color, 4.0)
			# Inner glow
			draw_circle(Vector2.ZERO, radius * 0.3, Color(1, 1, 1, 0.4))

		GameManager.SpecialType.COLOR_BOMB:
			# Rainbow circle segments
			var segment_count = 6
			for i in range(segment_count):
				var start_angle = (TAU / segment_count) * i
				var end_angle = start_angle + (TAU / segment_count)
				var segment_color = GameManager.SLIME_COLORS.values()[i]
				draw_arc(Vector2.ZERO, radius * 0.7, start_angle, end_angle, 8, segment_color, radius * 0.3)


func _update_visual() -> void:
	if use_sprites and animated_sprite:
		# Apply color tint via shader parameter
		# The base sprite is blue, so we use color_tint to shift the hue
		var tint_color = _get_color_tint(slime_color)
		_set_shader_color(tint_color)
	else:
		queue_redraw()


func _set_shader_color(tint_color: Color) -> void:
	# Set color via shader parameter for gel effect
	# Material is resource_local_to_scene so each slime has its own
	if animated_sprite and animated_sprite.material:
		animated_sprite.material.set_shader_parameter("color_tint", tint_color)


func _get_color_tint(color: GameManager.SlimeColor) -> Color:
	# Map slime colors to tint colors
	# The source sprite is blue (#5b6ee1), so we adjust accordingly
	match color:
		GameManager.SlimeColor.RED:
			return Color(1.8, 0.4, 0.4)  # Red tint
		GameManager.SlimeColor.ORANGE:
			return Color(1.8, 1.0, 0.3)  # Orange tint
		GameManager.SlimeColor.YELLOW:
			return Color(1.8, 1.8, 0.4)  # Yellow tint
		GameManager.SlimeColor.GREEN:
			return Color(0.4, 1.5, 0.5)  # Green tint
		GameManager.SlimeColor.BLUE:
			return Color(1.0, 1.0, 1.0)  # Keep original blue
		GameManager.SlimeColor.PURPLE:
			return Color(1.4, 0.5, 1.5)  # Purple tint
		_:
			return Color.WHITE


func _update_special_visual() -> void:
	queue_redraw()


func _update_selection_visual() -> void:
	if use_sprites and animated_sprite:
		# For sprites, apply selection effect via shader
		var base_color = _get_color_tint(slime_color)
		if is_selected:
			var bright_color = Color(base_color.r * 1.3, base_color.g * 1.3, base_color.b * 1.3)
			_set_shader_color(bright_color)
		else:
			_set_shader_color(base_color)
	else:
		if is_selected:
			modulate = Color(1.2, 1.2, 1.2, 1.0)
		else:
			modulate = Color.WHITE


func setup(color: GameManager.SlimeColor, pos: Vector2i, special: GameManager.SpecialType = GameManager.SpecialType.NONE) -> void:
	slime_color = color
	grid_position = pos
	special_type = special
	position = grid_to_world(pos)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2,
				   grid_pos.y * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2)


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
	# Convert screen position to world position considering camera
	var canvas_transform = get_canvas_transform()
	return canvas_transform.affine_inverse() * screen_pos


func _is_point_in_cell(world_pos: Vector2) -> bool:
	# Use rectangular hit detection covering the entire cell
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
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tween.finished
	is_animating = false


func animate_invalid_swap(original_pos: Vector2, target_pos: Vector2, duration: float = 0.15) -> void:
	is_animating = true
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position", original_pos, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	is_animating = false


func animate_match() -> void:
	is_animating = true
	AudioManager.play_sfx("match")

	# Emit particles
	if particles:
		particles.emitting = true

	# Play death animation if using sprites
	if use_sprites and animated_sprite and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
		await get_tree().create_timer(0.3).timeout
		# Fade out
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.15)
		await tween.finished
	else:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)\
			.set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)\
			.set_ease(Tween.EASE_IN)
		await tween.finished

	match_animation_complete.emit()
	is_animating = false


func animate_fall(target_pos: Vector2, delay: float = 0.0, duration: float = 0.3) -> void:
	# Store target for safety - we MUST end up here
	var final_target = target_pos

	# Kill previous tween if exists
	if has_meta("_fall_tween"):
		var old_tween = get_meta("_fall_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	is_animating = true

	if delay > 0:
		await get_tree().create_timer(delay).timeout
		# Check if still valid after delay
		if not is_instance_valid(self):
			return

	var tween = create_tween()
	set_meta("_fall_tween", tween)
	tween.tween_property(self, "position", final_target, duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)

	await tween.finished

	# FORCE position to target in case animation was interrupted
	if is_instance_valid(self):
		position = final_target

	fall_animation_complete.emit()
	is_animating = false


func animate_spawn(delay: float = 0.0) -> void:
	scale = Vector2.ZERO
	modulate.a = 0.0

	if delay > 0:
		await get_tree().create_timer(delay).timeout

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)


func animate_special_creation() -> void:
	AudioManager.play_sfx("special")
	AudioManager.vibrate(100)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.15)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func animate_pulse() -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.3)\
		.set_ease(Tween.EASE_IN_OUT)


var breathing_tween: Tween = null

func _start_breathing_animation() -> void:
	if not animated_sprite:
		return

	# Random delay so slimes don't breathe in sync
	var delay = randf_range(0.0, 2.0)
	await get_tree().create_timer(delay).timeout

	if not is_instance_valid(self) or not animated_sprite:
		return

	breathing_tween = create_tween()
	breathing_tween.set_loops()
	# Subtle scale animation for breathing effect
	breathing_tween.tween_property(animated_sprite, "scale", Vector2(1.64, 1.56), 0.8)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	breathing_tween.tween_property(animated_sprite, "scale", Vector2(1.6, 1.6), 0.8)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


func _stop_breathing_animation() -> void:
	if breathing_tween and breathing_tween.is_valid():
		breathing_tween.kill()
		breathing_tween = null
	if animated_sprite:
		animated_sprite.scale = Vector2(1.6, 1.6)
