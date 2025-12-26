extends Control
class_name SkillTree
## SkillTree - Interactive node-based upgrade system for Story Mode
## Pan with right mouse/two-finger drag, zoom with scroll, tap/click nodes to upgrade

signal node_purchased(node_id: String, new_level: int)
signal closed

const SkillTreeData = preload("res://resources/skill_tree_data.gd")

# UI scaling - Mobile optimized (touch targets min 44px per Apple/Google guidelines)
const NODE_SIZE: float = 70.0  # Increased for better touch targets
const NODE_SPACING: float = 110.0  # Slightly increased to maintain spacing ratio
const MIN_ZOOM: float = 0.5
const MAX_ZOOM: float = 2.0
const ZOOM_STEP: float = 0.1

# Visual settings
const LINE_WIDTH: float = 3.0
const LINE_COLOR_LOCKED: Color = Color(0.3, 0.3, 0.35, 0.6)
const LINE_COLOR_UNLOCKED: Color = Color(0.9, 0.7, 0.9, 0.8)
const NODE_BG_LOCKED: Color = Color(0.2, 0.2, 0.25, 0.9)
const NODE_BG_UNLOCKED: Color = Color(0.4, 0.3, 0.45, 0.95)
const NODE_BG_MAXED: Color = Color(0.3, 0.5, 0.35, 0.95)

# State
var current_zoom: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var pan_start: Vector2 = Vector2.ZERO

# Node data
var node_buttons: Dictionary = {}  # node_id -> Button
var node_levels: Dictionary = {}   # node_id -> current_level

# Tooltip
var tooltip_panel: Panel = null
var tooltip_label: RichTextLabel = null
var hovered_node: String = ""

# References
@onready var tree_container: Control = $TreeContainer
@onready var nodes_container: Control = $TreeContainer/NodesContainer
@onready var lines_container: Control = $TreeContainer/LinesContainer
@onready var currency_label: Label = $TopBar/CurrencyLabel
@onready var back_button: Button = $TopBar/BackButton
@onready var instructions_label: Label = $BottomBar/Instructions


func _ready() -> void:
	_setup_ui()
	_load_node_levels()
	_create_tree()
	_update_currency_display()
	_create_tooltip()

	back_button.pressed.connect(_on_back_pressed)


func _setup_ui() -> void:
	# Set up the main container - don't clip so nodes are always visible
	tree_container.clip_contents = false

	# Wait for size to be available
	await get_tree().process_frame

	# Center the view on the core node (which is at position 0,0)
	# The tree_container is offset by TopBar (80px top) and BottomBar (60px bottom)
	var container_center = tree_container.size / 2
	pan_offset = container_center
	_apply_transform()


func _load_node_levels() -> void:
	# Load from ProgressionManager
	node_levels = ProgressionManager.skill_tree_nodes.duplicate()

	# Ensure default unlocked nodes are set
	for node_id in SkillTreeData.get_all_node_ids():
		var node_data = SkillTreeData.get_node(node_id)
		if node_data.get("unlocked_by_default", false) and not node_levels.has(node_id):
			node_levels[node_id] = 1


func _create_tree() -> void:
	# Clear existing
	for child in nodes_container.get_children():
		child.queue_free()
	for child in lines_container.get_children():
		child.queue_free()
	node_buttons.clear()

	# Create connection lines first (behind nodes)
	_create_connection_lines()

	# Create node buttons
	for node_id in SkillTreeData.get_all_node_ids():
		_create_node_button(node_id)

	_update_all_nodes()


func _create_connection_lines() -> void:
	for node_id in SkillTreeData.get_all_node_ids():
		var node_data = SkillTreeData.get_node(node_id)
		var from_pos = _get_node_screen_position(node_id)

		for target_id in node_data.get("connections", []):
			var to_pos = _get_node_screen_position(target_id)
			var line = _create_line(from_pos, to_pos, node_id, target_id)
			lines_container.add_child(line)


func _create_line(from: Vector2, to: Vector2, from_id: String, to_id: String) -> Line2D:
	var line = Line2D.new()
	line.name = "%s_to_%s" % [from_id, to_id]
	line.add_point(from)
	line.add_point(to)
	line.width = LINE_WIDTH
	line.default_color = LINE_COLOR_LOCKED
	line.antialiased = true
	return line


func _create_node_button(node_id: String) -> void:
	var node_data = SkillTreeData.get_node(node_id)
	var pos = _get_node_screen_position(node_id)

	# Create button container
	var container = Control.new()
	container.name = node_id
	container.position = pos - Vector2(NODE_SIZE / 2, NODE_SIZE / 2)
	container.size = Vector2(NODE_SIZE, NODE_SIZE)

	# Create the button
	var btn = Button.new()
	btn.name = "Button"
	btn.custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
	btn.size = Vector2(NODE_SIZE, NODE_SIZE)

	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = NODE_BG_LOCKED
	style.set_corner_radius_all(int(NODE_SIZE / 2))
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = SkillTreeData.get_color_from_type(node_data.type)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = hover_style.bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	# Add icon/text - larger font for mobile readability
	var type_name = SkillTreeData.NODE_ICONS.get(node_data.type, "?")
	btn.text = _get_node_icon(node_data.type)
	btn.add_theme_font_size_override("font_size", 28)

	# Connect signals
	btn.pressed.connect(_on_node_pressed.bind(node_id))
	btn.mouse_entered.connect(_on_node_hovered.bind(node_id))
	btn.mouse_exited.connect(_on_node_unhovered)

	container.add_child(btn)

	# Add level indicator - larger for mobile
	var level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.position = Vector2(0, NODE_SIZE - 20)
	level_label.size = Vector2(NODE_SIZE, 20)
	level_label.add_theme_font_size_override("font_size", 16)
	level_label.add_theme_color_override("font_color", Color.WHITE)
	container.add_child(level_label)

	# Add "+" indicator for upgradeable nodes - larger for mobile
	var plus_label = Label.new()
	plus_label.name = "PlusLabel"
	plus_label.text = "+"
	plus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus_label.position = Vector2(NODE_SIZE - 22, -6)
	plus_label.size = Vector2(24, 24)
	plus_label.add_theme_font_size_override("font_size", 20)
	plus_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
	plus_label.visible = false
	container.add_child(plus_label)

	nodes_container.add_child(container)
	node_buttons[node_id] = container


func _get_node_icon(node_type: SkillTreeData.NodeType) -> String:
	match node_type:
		SkillTreeData.NodeType.CORE:
			return "O"  # Core/center
		SkillTreeData.NodeType.COLOR:
			return "C"  # Color
		SkillTreeData.NodeType.SCORING:
			return "$"  # Points
		SkillTreeData.NodeType.SPECIAL:
			return "*"  # Special
		SkillTreeData.NodeType.COMBO:
			return "x"  # Multiplier
		SkillTreeData.NodeType.ABILITY:
			return "A"  # Ability
		SkillTreeData.NodeType.MOVES:
			return "M"  # Moves
		_:
			return "?"


func _get_node_screen_position(node_id: String) -> Vector2:
	var node_data = SkillTreeData.get_node(node_id)
	var grid_pos: Vector2 = node_data.get("position", Vector2.ZERO)
	return grid_pos * NODE_SPACING


func _update_all_nodes() -> void:
	# First calculate visibility distances for all nodes
	_calculate_node_visibility()
	for node_id in node_buttons.keys():
		_update_node_visual(node_id)
	_update_connection_lines()


# Visibility distance: 0 = unlocked, 1 = directly connected to unlocked (unlockable), 2+ = further away
var node_visibility: Dictionary = {}  # node_id -> distance from unlocked

func _calculate_node_visibility() -> void:
	node_visibility.clear()

	# Start with all unlocked nodes at distance 0
	var frontier: Array = []
	for node_id in SkillTreeData.get_all_node_ids():
		if node_levels.get(node_id, 0) > 0:
			node_visibility[node_id] = 0
			frontier.append(node_id)

	# BFS to calculate distances
	var current_distance = 0
	while frontier.size() > 0:
		var next_frontier: Array = []
		for node_id in frontier:
			var node_data = SkillTreeData.get_node(node_id)
			# Check connections in both directions
			for connected_id in node_data.get("connections", []):
				if not node_visibility.has(connected_id):
					node_visibility[connected_id] = current_distance + 1
					next_frontier.append(connected_id)
			# Also check reverse connections (nodes that connect TO this node)
			for other_id in SkillTreeData.get_all_node_ids():
				var other_data = SkillTreeData.get_node(other_id)
				if node_id in other_data.get("connections", []) and not node_visibility.has(other_id):
					node_visibility[other_id] = current_distance + 1
					next_frontier.append(other_id)
		frontier = next_frontier
		current_distance += 1

	# Any nodes not reached are very far (set to 99)
	for node_id in SkillTreeData.get_all_node_ids():
		if not node_visibility.has(node_id):
			node_visibility[node_id] = 99


func _update_node_visual(node_id: String) -> void:
	var container = node_buttons.get(node_id)
	if not container:
		return

	var btn: Button = container.get_node("Button")
	var level_label: Label = container.get_node("LevelLabel")
	var plus_label: Label = container.get_node("PlusLabel")

	var node_data = SkillTreeData.get_node(node_id)
	var current_level = node_levels.get(node_id, 0)
	var max_level = node_data.get("max_level", 1)
	var is_unlockable = SkillTreeData.is_node_unlockable(node_id, node_levels)
	var is_unlocked = current_level > 0
	var is_maxed = current_level >= max_level

	# Get visibility distance (0 = unlocked, 1 = adjacent to unlocked, 2+ = further)
	var visibility_distance = node_visibility.get(node_id, 99)

	# Update level text based on visibility
	if visibility_distance <= 1:
		# Fully visible or adjacent - show level info
		if max_level > 1:
			level_label.text = "%d/%d" % [current_level, max_level]
		else:
			level_label.text = "1" if is_unlocked else "0"
		level_label.visible = true
	else:
		# Hidden nodes - no level text
		level_label.visible = false

	# Update button style based on state
	var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()

	if is_maxed:
		style.bg_color = NODE_BG_MAXED
		plus_label.visible = false
	elif is_unlocked:
		style.bg_color = NODE_BG_UNLOCKED
		plus_label.visible = current_level < max_level and _can_afford_node(node_id)
	else:
		style.bg_color = NODE_BG_LOCKED
		plus_label.visible = is_unlockable and _can_afford_node(node_id) and visibility_distance <= 1

	btn.add_theme_stylebox_override("normal", style)

	# Apply fog of war visibility
	if visibility_distance == 0:
		# Unlocked - full visibility
		container.modulate = Color.WHITE
	elif visibility_distance == 1:
		# Adjacent to unlocked (unlockable) - 50% visible, hover allowed
		container.modulate = Color(1, 1, 1, 0.5)
	elif visibility_distance == 2:
		# One step further - 25% visible, no info
		container.modulate = Color(1, 1, 1, 0.25)
	else:
		# Very far - hidden completely
		container.modulate = Color(1, 1, 1, 0.1)


func _update_connection_lines() -> void:
	for line in lines_container.get_children():
		var parts = line.name.split("_to_")
		if parts.size() == 2:
			var from_id = parts[0]
			var to_id = parts[1]
			var from_unlocked = node_levels.get(from_id, 0) > 0
			var to_unlocked = node_levels.get(to_id, 0) > 0

			# Get visibility distance for both nodes
			var from_visibility = node_visibility.get(from_id, 99)
			var to_visibility = node_visibility.get(to_id, 99)
			var max_visibility = max(from_visibility, to_visibility)

			if from_unlocked and to_unlocked:
				line.default_color = LINE_COLOR_UNLOCKED
				line.modulate = Color.WHITE
			elif from_unlocked:
				line.default_color = LINE_COLOR_UNLOCKED.lerp(LINE_COLOR_LOCKED, 0.5)
				line.modulate = Color.WHITE
			else:
				line.default_color = LINE_COLOR_LOCKED
				# Apply fog of war to lines based on the furthest node's visibility
				if max_visibility == 1:
					line.modulate = Color(1, 1, 1, 0.5)
				elif max_visibility == 2:
					line.modulate = Color(1, 1, 1, 0.25)
				elif max_visibility > 2:
					line.modulate = Color(1, 1, 1, 0.1)
				else:
					line.modulate = Color.WHITE


func _can_afford_node(node_id: String) -> bool:
	var current_level = node_levels.get(node_id, 0)
	var cost = SkillTreeData.get_node_cost(node_id, current_level)
	return ProgressionManager.currencies.slime_essence >= cost


func _on_node_pressed(node_id: String) -> void:
	var node_data = SkillTreeData.get_node(node_id)
	var current_level = node_levels.get(node_id, 0)
	var max_level = node_data.get("max_level", 1)

	# Ignore clicks on hidden nodes (fog of war)
	var visibility_distance = node_visibility.get(node_id, 99)
	if visibility_distance >= 2:
		return

	# Check if can upgrade
	if current_level >= max_level:
		AudioManager.play_sfx("button")
		return

	if not SkillTreeData.is_node_unlockable(node_id, node_levels):
		AudioManager.play_sfx("button")
		return

	var cost = SkillTreeData.get_node_cost(node_id, current_level)
	if not _can_afford_node(node_id):
		AudioManager.play_sfx("button")
		return

	# Purchase the upgrade
	ProgressionManager.currencies.slime_essence -= cost
	current_level += 1
	node_levels[node_id] = current_level

	# Save to ProgressionManager
	ProgressionManager.skill_tree_nodes[node_id] = current_level
	ProgressionManager.save_progression()

	# Handle special node effects (color unlocks)
	_apply_node_effect(node_id, node_data)

	# Update visuals
	_update_all_nodes()
	_update_currency_display()
	_update_tooltip(node_id)

	# Play sound and emit signal
	AudioManager.play_sfx("combo")
	AudioManager.vibrate(50)
	node_purchased.emit(node_id, current_level)


func _apply_node_effect(node_id: String, node_data: Dictionary) -> void:
	# Handle color unlocks
	if node_data.has("color"):
		var color_name = node_data.color
		ProgressionManager.color_mastery[color_name] = 1
		ProgressionManager.save_progression()

	# Handle ability unlocks
	if node_data.has("ability_id"):
		var ability_id = node_data.ability_id
		ProgressionManager.abilities[ability_id] = {"unlocked": true, "level": 0}
		ProgressionManager.save_progression()


func _on_node_hovered(node_id: String) -> void:
	hovered_node = node_id
	# Only show tooltip for nodes within visibility range (distance <= 1)
	var visibility_distance = node_visibility.get(node_id, 99)
	if visibility_distance <= 1:
		_update_tooltip(node_id)
		_show_tooltip()
	else:
		_hide_tooltip()


func _on_node_unhovered() -> void:
	hovered_node = ""
	_hide_tooltip()


func _create_tooltip() -> void:
	tooltip_panel = Panel.new()
	tooltip_panel.name = "Tooltip"
	tooltip_panel.visible = false
	tooltip_panel.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.98)
	style.set_corner_radius_all(12)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	tooltip_panel.add_theme_stylebox_override("panel", style)

	tooltip_label = RichTextLabel.new()
	tooltip_label.bbcode_enabled = true
	tooltip_label.fit_content = true
	tooltip_label.scroll_active = false
	# Mobile-first: Use almost full screen width (720 - 40px padding = 680px)
	tooltip_label.custom_minimum_size = Vector2(640, 0)
	# Mobile-optimized font size (min 16sp per Google Material Design)
	tooltip_label.add_theme_font_size_override("normal_font_size", 20)
	tooltip_label.add_theme_font_size_override("bold_font_size", 22)

	tooltip_panel.add_child(tooltip_label)
	add_child(tooltip_panel)


func _update_tooltip(node_id: String) -> void:
	var node_data = SkillTreeData.get_node(node_id)
	if node_data.is_empty():
		return

	var current_level = node_levels.get(node_id, 0)
	var max_level = node_data.get("max_level", 1)
	var cost = SkillTreeData.get_node_cost(node_id, current_level)
	var is_maxed = current_level >= max_level
	var can_afford = _can_afford_node(node_id)
	var is_unlockable = SkillTreeData.is_node_unlockable(node_id, node_levels)

	var color = SkillTreeData.get_color_from_type(node_data.type)
	var color_hex = color.to_html(false)

	var text = "[b][color=#%s]%s[/color][/b]\n" % [color_hex, node_data.name]
	text += "[color=#aaaaaa]%s[/color]\n\n" % node_data.description

	if max_level > 1:
		text += "Level: %d / %d\n" % [current_level, max_level]
		var effect_text = SkillTreeData.get_node_effect_description(node_id, current_level)
		if effect_text:
			text += "Current: [color=#88ff88]%s[/color]\n" % effect_text

	if is_maxed:
		text += "\n[color=#88ff88]MAXED[/color]"
	elif not is_unlockable:
		text += "\n[color=#ff8888]Unlock a connected node first[/color]"
	else:
		var cost_color = "#88ff88" if can_afford else "#ff8888"
		text += "\nCost: [color=%s]%d Essence[/color]" % [cost_color, cost]

	tooltip_label.text = text

	# Resize panel to fit content
	await get_tree().process_frame
	tooltip_panel.size = tooltip_label.size + Vector2(40, 32)


func _show_tooltip() -> void:
	tooltip_panel.visible = true
	_position_tooltip()


func _hide_tooltip() -> void:
	tooltip_panel.visible = false


func _position_tooltip() -> void:
	var tooltip_size = tooltip_panel.size

	# Mobile-first: Center tooltip horizontally, position at bottom of screen
	# This ensures the tooltip is always fully visible and easy to read
	var pos = Vector2(
		(size.x - tooltip_size.x) / 2,  # Centered horizontally
		size.y - tooltip_size.y - 80     # Above bottom bar with padding
	)

	# Ensure tooltip stays within screen bounds
	pos.x = clampf(pos.x, 20, size.x - tooltip_size.x - 20)
	pos.y = clampf(pos.y, 100, size.y - tooltip_size.y - 20)

	tooltip_panel.position = pos


func _update_currency_display() -> void:
	currency_label.text = "%d Essence" % ProgressionManager.currencies.slime_essence


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")

	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		closed.emit()
		queue_free()
	)


# ============ INPUT HANDLING ============

func _input(event: InputEvent) -> void:
	# Zoom with mouse wheel
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(ZOOM_STEP, get_local_mouse_position())
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(-ZOOM_STEP, get_local_mouse_position())
		# Pan with right OR left mouse button (hold and drag)
		elif event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Only start panning if not clicking on a node button
				var mouse_pos = get_global_mouse_position()
				var clicked_on_node = false
				for container in node_buttons.values():
					var btn = container.get_node("Button") as Button
					if btn and btn.get_global_rect().has_point(mouse_pos):
						clicked_on_node = true
						break
				if not clicked_on_node:
					is_panning = true
					pan_start = event.position
			else:
				is_panning = false

	# Pan with mouse drag (left or right button)
	if event is InputEventMouseMotion and is_panning:
		var delta = event.position - pan_start
		pan_start = event.position
		_pan(delta)

	# Touch panning (single finger drag)
	if event is InputEventScreenTouch:
		if event.pressed:
			is_panning = true
			pan_start = event.position
		else:
			is_panning = false

	if event is InputEventScreenDrag:
		if is_panning:
			_pan(event.relative)

	# Update tooltip position
	if tooltip_panel and tooltip_panel.visible:
		_position_tooltip()


func _zoom(amount: float, focus_point: Vector2) -> void:
	var old_zoom = current_zoom
	current_zoom = clamp(current_zoom + amount, MIN_ZOOM, MAX_ZOOM)

	if current_zoom != old_zoom:
		# Adjust pan to zoom towards focus point
		var zoom_ratio = current_zoom / old_zoom
		pan_offset = focus_point + (pan_offset - focus_point) * zoom_ratio

		_apply_transform()


func _pan(delta: Vector2) -> void:
	pan_offset += delta
	_apply_transform()


func _apply_transform() -> void:
	# Apply scale to the content containers (nodes and lines)
	nodes_container.scale = Vector2(current_zoom, current_zoom)
	lines_container.scale = Vector2(current_zoom, current_zoom)

	# Position the content so it's centered based on pan_offset
	nodes_container.position = pan_offset
	lines_container.position = pan_offset


