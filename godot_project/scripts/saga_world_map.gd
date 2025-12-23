extends Control
class_name SagaWorldMap
## SagaWorldMap - Linear world map for Saga mode level selection
## Similar to Candy Crush - shows levels as nodes along a path

signal level_selected(level: int)
signal back_pressed

const LEVELS_PER_WORLD: int = 10  # New world every 10 levels
const VISIBLE_LEVELS: int = 15  # How many level nodes to show at once
const NODE_SPACING_Y: int = 120  # Vertical spacing between level nodes
const PATH_WOBBLE: int = 80  # Horizontal wobble for zigzag path

# World themes (colors for different worlds)
const WORLD_THEMES: Array = [
	{"name": "Grüne Wiesen", "color": Color("#4ade80"), "bg": Color("#166534")},
	{"name": "Sandige Wüste", "color": Color("#fbbf24"), "bg": Color("#92400e")},
	{"name": "Eisige Berge", "color": Color("#60a5fa"), "bg": Color("#1e40af")},
	{"name": "Vulkanland", "color": Color("#f87171"), "bg": Color("#991b1b")},
	{"name": "Magischer Wald", "color": Color("#a78bfa"), "bg": Color("#5b21b6")},
	{"name": "Kristallhöhlen", "color": Color("#2dd4bf"), "bg": Color("#134e4a")},
]

# UI References
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var level_container: Control = $ScrollContainer/LevelContainer
@onready var world_label: Label = $TopBar/WorldLabel
@onready var back_button: Button = $TopBar/BackButton

var current_level: int = 1
var level_nodes: Array[Button] = []


func _ready() -> void:
	current_level = SaveManager.get_saga_level()
	_setup_ui()
	_generate_level_nodes()
	_scroll_to_current_level()

	back_button.pressed.connect(_on_back_pressed)


func _setup_ui() -> void:
	var world_index = _get_world_index(current_level)
	var theme = _get_world_theme(world_index)
	world_label.text = theme.name

	# Set background color based on world
	var bg = ColorRect.new()
	bg.color = theme.bg
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -10
	add_child(bg)
	move_child(bg, 0)


func _generate_level_nodes() -> void:
	# Clear existing nodes
	for child in level_container.get_children():
		child.queue_free()
	level_nodes.clear()

	# Calculate range of levels to show (centered on current level)
	var start_level = maxi(1, current_level - VISIBLE_LEVELS / 2)
	var end_level = start_level + VISIBLE_LEVELS

	# Container needs to be tall enough for all nodes
	var container_height = (end_level - start_level + 5) * NODE_SPACING_Y
	level_container.custom_minimum_size.y = container_height

	# Generate path and level nodes
	var center_x = 360  # Center of 720px screen

	for i in range(start_level, end_level + 1):
		var level_num = i
		var relative_index = i - start_level

		# Calculate position with zigzag pattern
		var y_pos = container_height - (relative_index * NODE_SPACING_Y) - 100
		var wobble = sin(level_num * 0.8) * PATH_WOBBLE
		var x_pos = center_x + wobble

		# Create level node button
		var node = _create_level_node(level_num, Vector2(x_pos, y_pos))
		level_container.add_child(node)
		level_nodes.append(node)

		# Draw path line to previous node
		if relative_index > 0:
			var prev_y = container_height - ((relative_index - 1) * NODE_SPACING_Y) - 100
			var prev_wobble = sin((level_num - 1) * 0.8) * PATH_WOBBLE
			var prev_x = center_x + prev_wobble
			_draw_path_segment(Vector2(prev_x, prev_y), Vector2(x_pos, y_pos))


func _create_level_node(level_num: int, pos: Vector2) -> Button:
	var btn = Button.new()
	btn.text = str(level_num)
	btn.custom_minimum_size = Vector2(70, 70)
	btn.position = pos - Vector2(35, 35)  # Center the button

	# Style based on level status
	var is_current = level_num == current_level
	var is_unlocked = level_num <= current_level
	var is_completed = level_num < current_level

	var world_index = _get_world_index(level_num)
	var theme = _get_world_theme(world_index)

	# Create circular style
	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(35)

	if is_current:
		# Current level - highlighted
		style.bg_color = theme.color
		style.border_width_bottom = 4
		style.border_width_top = 4
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_color = Color.WHITE
		btn.add_theme_font_size_override("font_size", 28)
		btn.add_theme_color_override("font_color", Color.WHITE)
	elif is_completed:
		# Completed level - normal color
		style.bg_color = theme.color.darkened(0.2)
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		# Locked level - grayed out
		style.bg_color = Color(0.3, 0.3, 0.3, 0.8)
		btn.add_theme_font_size_override("font_size", 24)
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		btn.disabled = true

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("disabled", style)

	if is_unlocked:
		btn.pressed.connect(func(): _on_level_selected(level_num))

	return btn


func _draw_path_segment(from: Vector2, to: Vector2) -> void:
	var line = Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 8
	line.default_color = Color(1, 1, 1, 0.5)
	line.z_index = -1
	level_container.add_child(line)


func _scroll_to_current_level() -> void:
	# Wait a frame for layout to complete
	await get_tree().process_frame

	# Calculate which level node index corresponds to current level
	var start_level = maxi(1, current_level - VISIBLE_LEVELS / 2)
	var current_index = current_level - start_level

	# Container height and level position
	var container_height = level_container.custom_minimum_size.y
	var level_y_pos = container_height - (current_index * NODE_SPACING_Y) - 100

	# Scroll so that current level is centered in the view
	var scroll_target = level_y_pos - scroll_container.size.y / 2
	scroll_target = clampf(scroll_target, 0, container_height - scroll_container.size.y)
	scroll_container.scroll_vertical = int(scroll_target)


func _get_world_index(level: int) -> int:
	return int((level - 1) / LEVELS_PER_WORLD) % WORLD_THEMES.size()


func _get_world_theme(world_index: int) -> Dictionary:
	return WORLD_THEMES[world_index % WORLD_THEMES.size()]


func _on_level_selected(level: int) -> void:
	AudioManager.play_sfx("button")
	level_selected.emit(level)

	# Set the saga level and start game
	SaveManager.set_saga_level(level)

	# Fade out and go to game
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	back_pressed.emit()

	# Fade out and go back to mode selection
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/mode_selection.tscn")
