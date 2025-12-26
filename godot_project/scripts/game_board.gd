extends Node2D
class_name GameBoard
## GameBoard - Main game board logic
## Handles grid management, matching, cascading, and special candy effects

signal board_settled()
signal no_moves_available()

const SlimeScene = preload("res://scenes/slime.tscn")
const Templates = preload("res://resources/board_templates.gd")

# Board state
var board: Array = []  # 2D array of Slime references
var board_template: Array = []  # Current board template (1 = playable, 0 = blocked)
var selected_slime: Slime = null
var is_processing: bool = false
var is_input_enabled: bool = true

# Cheat mode for spawning/replacing slimes
var cheat_spawn_mode: bool = false
var cheat_spawn_color: GameManager.SlimeColor = GameManager.SlimeColor.RED
var cheat_spawn_special: GameManager.SpecialType = GameManager.SpecialType.NONE

# Saga mode state
var saga_shuffle_count: int = 0  # For deterministic shuffling

# Safety timeout for stuck processing
var processing_start_time: float = 0.0
const PROCESSING_TIMEOUT: float = 3.0  # Reset after 3 seconds

# Input queue for fast moves
var queued_swap: Dictionary = {}  # {"slime1": Slime, "slime2": Slime}

# Animation timing
const SWAP_DURATION: float = 0.35  # Duration for hop swap animation with squash & stretch
const FALL_DURATION: float = 0.3
const MATCH_DELAY: float = 0.1
const CASCADE_DELAY: float = 0.15

# Visual feedback for cooldown
const COOLDOWN_DARKEN: float = 0.75  # 25% darker
const COOLDOWN_TRANSITION: float = 0.2  # Transition duration


func _ready() -> void:
	_initialize_board()
	_connect_signals()
	# Start board monitoring timer
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.timeout.connect(_check_and_fix_board)
	add_child(timer)


func _connect_signals() -> void:
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)


func _reset_board() -> void:
	# Clear existing slimes
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if board.size() > x and board[x].size() > y and board[x][y]:
				board[x][y].queue_free()

	# Reset state
	selected_slime = null
	is_processing = false

	# Reinitialize the board with new template
	_initialize_board()


func _initialize_board() -> void:
	# Get template for current level
	board_template = Templates.get_template_for_level(GameManager.level)

	# Set seed for saga mode (deterministic spawning)
	if GameManager.is_saga_mode():
		var saga_level = SaveManager.get_saga_level()
		var level_seed = GameManager.get_saga_seed(saga_level)
		seed(level_seed)
		saga_shuffle_count = 0

	board.clear()
	board.resize(GameManager.BOARD_SIZE)

	for x in range(GameManager.BOARD_SIZE):
		board[x] = []
		board[x].resize(GameManager.BOARD_SIZE)

		for y in range(GameManager.BOARD_SIZE):
			# Check if this cell is playable according to template
			if _is_cell_playable(x, y):
				var color = _get_non_matching_color(x, y)
				var slime = _create_slime(color, Vector2i(x, y))
				board[x][y] = slime
				slime.animate_spawn(0.02 * (x + y))
			else:
				board[x][y] = null


# Check if a cell is playable according to the current template
func _is_cell_playable(x: int, y: int) -> bool:
	if board_template.is_empty():
		return true  # No template = all cells playable
	if y < 0 or y >= board_template.size():
		return false
	if x < 0 or x >= board_template[y].size():
		return false
	return board_template[y][x] == 1


# Get available colors for Story Mode
# Green is always colored from the start, others are colorless until mastery unlocked
func _get_story_available_colors() -> Array:
	var colors: Array = []

	# Green is always colored (unlocked from start)
	colors.append(GameManager.SlimeColor.GREEN)

	# Other colors: check mastery level, if > 0 use colored, else colorless
	var mastery = ProgressionManager.color_mastery

	if mastery.get("red", 0) > 0:
		colors.append(GameManager.SlimeColor.RED)
	else:
		colors.append(GameManager.SlimeColor.RED_COLORLESS)

	if mastery.get("orange", 0) > 0:
		colors.append(GameManager.SlimeColor.ORANGE)
	else:
		colors.append(GameManager.SlimeColor.ORANGE_COLORLESS)

	if mastery.get("yellow", 0) > 0:
		colors.append(GameManager.SlimeColor.YELLOW)
	else:
		colors.append(GameManager.SlimeColor.YELLOW_COLORLESS)

	if mastery.get("blue", 0) > 0:
		colors.append(GameManager.SlimeColor.BLUE)
	else:
		colors.append(GameManager.SlimeColor.BLUE_COLORLESS)

	if mastery.get("purple", 0) > 0:
		colors.append(GameManager.SlimeColor.PURPLE)
	else:
		colors.append(GameManager.SlimeColor.PURPLE_COLORLESS)

	return colors


func _get_non_matching_color(x: int, y: int) -> GameManager.SlimeColor:
	# Get available colors based on mode
	var available_colors: Array
	if GameManager.is_saga_mode():
		available_colors = GameManager.get_saga_available_colors(GameManager.level).duplicate()
	elif SaveManager.is_story_mode():
		# Story mode: Green is always colored, others based on mastery
		available_colors = _get_story_available_colors()
	else:
		# Endless mode: all 6 base colors
		available_colors = [
			GameManager.SlimeColor.RED,
			GameManager.SlimeColor.ORANGE,
			GameManager.SlimeColor.YELLOW,
			GameManager.SlimeColor.GREEN,
			GameManager.SlimeColor.BLUE,
			GameManager.SlimeColor.PURPLE
		]

	# Check horizontal matches (only if cells are playable)
	# Use colors_match for saga mode (colorless matches base color)
	if x >= 2 and _is_cell_playable(x-1, y) and _is_cell_playable(x-2, y):
		if board[x-1][y] and board[x-2][y]:
			if GameManager.colors_match(board[x-1][y].slime_color, board[x-2][y].slime_color):
				# Remove all colors that match this base color
				var base = GameManager.get_base_color(board[x-1][y].slime_color)
				available_colors = available_colors.filter(func(c): return GameManager.get_base_color(c) != base)

	# Check vertical matches (only if cells are playable)
	if y >= 2 and _is_cell_playable(x, y-1) and _is_cell_playable(x, y-2):
		if board[x][y-1] and board[x][y-2]:
			if GameManager.colors_match(board[x][y-1].slime_color, board[x][y-2].slime_color):
				var base = GameManager.get_base_color(board[x][y-1].slime_color)
				available_colors = available_colors.filter(func(c): return GameManager.get_base_color(c) != base)

	if available_colors.is_empty():
		# Fallback
		if GameManager.is_saga_mode():
			return GameManager.get_saga_random_color(GameManager.level)
		elif SaveManager.is_story_mode():
			# Return random from story available colors
			var story_colors = _get_story_available_colors()
			return story_colors[randi() % story_colors.size()]
		return GameManager.get_random_slime_color()

	return available_colors[randi() % available_colors.size()]


# Get a random color appropriate for the current game mode
func _get_random_color_for_mode() -> GameManager.SlimeColor:
	if GameManager.is_saga_mode():
		return GameManager.get_saga_random_color(GameManager.level)
	elif SaveManager.is_story_mode():
		var story_colors = _get_story_available_colors()
		return story_colors[randi() % story_colors.size()]
	else:
		return GameManager.get_random_slime_color()


func _create_slime(color: GameManager.SlimeColor, grid_pos: Vector2i, special: GameManager.SpecialType = GameManager.SpecialType.NONE) -> Slime:
	var slime = SlimeScene.instantiate()
	add_child(slime)
	slime.setup(color, grid_pos, special)

	slime.clicked.connect(_on_slime_clicked)
	slime.swap_requested.connect(_on_swap_requested.bind(slime))

	# Apply darkening if currently processing
	if is_processing:
		slime.modulate = Color(COOLDOWN_DARKEN, COOLDOWN_DARKEN, COOLDOWN_DARKEN)

	return slime


func _on_slime_clicked(slime: Slime) -> void:
	if not is_input_enabled or is_processing:
		return

	# Cheat mode: Replace clicked slime with selected type
	if cheat_spawn_mode:
		_replace_slime_at(slime.grid_position, cheat_spawn_color, cheat_spawn_special)
		return

	if selected_slime == null:
		# First selection
		selected_slime = slime
		slime.is_selected = true
		AudioManager.play_sfx("button")

	elif selected_slime == slime:
		# Deselect
		selected_slime.is_selected = false
		selected_slime = null

	else:
		# Check if adjacent and try swap
		var delta = slime.grid_position - selected_slime.grid_position
		if abs(delta.x) + abs(delta.y) == 1:
			_try_swap(selected_slime, slime)
		else:
			# Select new slime
			selected_slime.is_selected = false
			selected_slime = slime
			slime.is_selected = true
			AudioManager.play_sfx("button")


func _on_swap_requested(direction: Vector2i, slime: Slime) -> void:
	if not is_input_enabled:
		return

	var target_pos = slime.grid_position + direction
	if _is_valid_position(target_pos):
		var target_slime = board[target_pos.x][target_pos.y]
		if target_slime:
			if is_processing:
				# Queue this swap for when processing is done
				queued_swap = {"slime1": slime, "slime2": target_slime}
			else:
				_try_swap(slime, target_slime)


func _try_swap(slime1: Slime, slime2: Slime) -> void:
	is_processing = true
	is_input_enabled = false
	processing_start_time = Time.get_ticks_msec() / 1000.0
	_set_board_darkened(true)  # Darken all slimes during processing

	# Deselect
	if selected_slime:
		selected_slime.is_selected = false
		selected_slime = null

	AudioManager.play_sfx("swap")

	# Store original world positions BEFORE any animation
	var world_pos1 = slime1.position
	var world_pos2 = slime2.position

	# Swap in data FIRST
	_swap_slimes(slime1, slime2)

	# Animate BOTH slimes simultaneously with hop animation
	# They hop in opposite directions to pass each other
	# Don't await slime1 - let both run in parallel
	slime1.animate_swap_hop(world_pos2, 1, SWAP_DURATION)
	await slime2.animate_swap_hop(world_pos1, -1, SWAP_DURATION)

	# Safety check: Verify slimes still exist after animation
	if not is_instance_valid(slime1) or not is_instance_valid(slime2):
		is_processing = false
		return

	# Check for matches or special combinations
	var has_special_combo = _check_special_combination(slime1, slime2)
	var matches = _find_all_matches()

	if has_special_combo or matches.size() > 0:
		# Valid move
		GameManager.use_move()

		if has_special_combo:
			await _handle_special_combination(slime1, slime2)
			# Apply gravity and fill after special combination
			await _apply_gravity()
			await _fill_empty_spaces()

		await _process_matches()
		GameManager.check_win_condition()
	else:
		# Invalid move - swap back with hop animation
		# Safety check before swap back
		if is_instance_valid(slime1) and is_instance_valid(slime2):
			# Swap data back first
			_swap_slimes(slime1, slime2)
			# Now animate back to their original positions
			slime1.animate_swap_hop(world_pos1, -1, SWAP_DURATION)  # Hop back
			await slime2.animate_swap_hop(world_pos2, 1, SWAP_DURATION)  # Hop back

	# Final board check before re-enabling input
	_force_fill_empty_cells()

	is_processing = false
	is_input_enabled = true
	_set_board_darkened(false)  # Restore normal brightness

	# Check for available moves (handles saga mode shuffle limits)
	await _check_no_moves_available()

	# Process queued swap if any
	if not queued_swap.is_empty():
		var s1 = queued_swap.get("slime1")
		var s2 = queued_swap.get("slime2")
		queued_swap.clear()
		if is_instance_valid(s1) and is_instance_valid(s2):
			# Small delay before processing queued swap
			await get_tree().create_timer(0.05).timeout
			_try_swap(s1, s2)


func _swap_slimes(slime1: Slime, slime2: Slime) -> void:
	var pos1 = slime1.grid_position
	var pos2 = slime2.grid_position

	board[pos1.x][pos1.y] = slime2
	board[pos2.x][pos2.y] = slime1

	slime1.grid_position = pos2
	slime2.grid_position = pos1


func _is_valid_position(pos: Vector2i) -> bool:
	if pos.x < 0 or pos.x >= GameManager.BOARD_SIZE or pos.y < 0 or pos.y >= GameManager.BOARD_SIZE:
		return false
	# Also check if cell is playable in template
	return _is_cell_playable(pos.x, pos.y)


# Match finding
func _find_all_matches() -> Array:
	var matches: Array = []
	var checked: Dictionary = {}

	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if checked.has(Vector2i(x, y)):
				continue

			var slime = board[x][y]
			if slime == null or slime.special_type == GameManager.SpecialType.COLOR_BOMB:
				continue

			# Check horizontal
			var h_match = _get_horizontal_match(x, y)
			if h_match.size() >= 3:
				for pos in h_match:
					checked[pos] = true
				matches.append({"cells": h_match, "direction": "horizontal"})

			# Check vertical
			var v_match = _get_vertical_match(x, y)
			if v_match.size() >= 3:
				for pos in v_match:
					checked[pos] = true
				matches.append({"cells": v_match, "direction": "vertical"})

	return _merge_matches(matches)


func _get_horizontal_match(start_x: int, y: int) -> Array:
	var slime = board[start_x][y]
	if slime == null:
		return []

	var color = slime.slime_color
	var match_cells: Array = [Vector2i(start_x, y)]

	# Check left - use colors_match for saga mode compatibility
	for x in range(start_x - 1, -1, -1):
		if board[x][y] and GameManager.colors_match(board[x][y].slime_color, color):
			match_cells.insert(0, Vector2i(x, y))
		else:
			break

	# Check right
	for x in range(start_x + 1, GameManager.BOARD_SIZE):
		if board[x][y] and GameManager.colors_match(board[x][y].slime_color, color):
			match_cells.append(Vector2i(x, y))
		else:
			break

	return match_cells


func _get_vertical_match(x: int, start_y: int) -> Array:
	var slime = board[x][start_y]
	if slime == null:
		return []

	var color = slime.slime_color
	var match_cells: Array = [Vector2i(x, start_y)]

	# Check up - use colors_match for saga mode compatibility
	for y in range(start_y - 1, -1, -1):
		if board[x][y] and GameManager.colors_match(board[x][y].slime_color, color):
			match_cells.insert(0, Vector2i(x, y))
		else:
			break

	# Check down
	for y in range(start_y + 1, GameManager.BOARD_SIZE):
		if board[x][y] and GameManager.colors_match(board[x][y].slime_color, color):
			match_cells.append(Vector2i(x, y))
		else:
			break

	return match_cells


func _merge_matches(matches: Array) -> Array:
	# Merge overlapping matches for L/T shape detection
	var merged: Array = []
	var used: Array = []

	for i in range(matches.size()):
		if i in used:
			continue

		var current = matches[i].duplicate(true)

		for j in range(i + 1, matches.size()):
			if j in used:
				continue

			var has_intersection = false
			for cell1 in current.cells:
				for cell2 in matches[j].cells:
					if cell1 == cell2:
						has_intersection = true
						break
				if has_intersection:
					break

			if has_intersection:
				# Merge
				for cell in matches[j].cells:
					if cell not in current.cells:
						current.cells.append(cell)
				current.direction = "both"
				used.append(j)

		merged.append(current)

	return merged


# Match processing
func _process_matches() -> void:
	GameManager.reset_combo()

	while true:
		var matches = _find_all_matches()
		if matches.is_empty():
			break

		GameManager.trigger_combo()

		# Process each match
		for match_data in matches:
			await _process_single_match(match_data)

		await get_tree().create_timer(MATCH_DELAY).timeout

		# Apply gravity
		await _apply_gravity()

		# Fill empty spaces
		await _fill_empty_spaces()

		await get_tree().create_timer(CASCADE_DELAY).timeout

	# Final safety check - ensure board is completely full
	await _ensure_board_full()

	board_settled.emit()


func _process_single_match(match_data: Dictionary) -> void:
	var cells = match_data.cells
	var direction = match_data.direction

	if cells.is_empty():
		return

	var first_slime = board[cells[0].x][cells[0].y]
	if first_slime == null:
		return

	var color = first_slime.slime_color

	# Calculate score
	var score = GameManager.calculate_match_score(cells.size())
	GameManager.add_score(score)

	# Award currencies in Story Mode
	if SaveManager.is_story_mode():
		_award_story_currencies(color, cells.size())

	# Determine special candy creation
	var special_type = GameManager.SpecialType.NONE
	var special_position: Vector2i = cells[cells.size() / 2]

	if cells.size() >= 5 and direction != "both":
		# Color bomb for 5+ in a line
		special_type = GameManager.SpecialType.COLOR_BOMB
	elif direction == "both" and cells.size() >= 5:
		# Wrapped for L/T shape
		special_type = GameManager.SpecialType.WRAPPED
		special_position = _find_intersection(cells)
	elif cells.size() == 4:
		# Striped for 4 in a row
		if direction == "horizontal":
			special_type = GameManager.SpecialType.STRIPED_V
		else:
			special_type = GameManager.SpecialType.STRIPED_H

	# Activate any existing special candies in the match
	for cell in cells:
		var slime = board[cell.x][cell.y]
		if slime and slime.special_type != GameManager.SpecialType.NONE:
			await _activate_special(cell, slime.special_type, slime.slime_color)

	# Animate and remove matched slimes
	var animations: Array = []
	for cell in cells:
		var slime = board[cell.x][cell.y]
		if slime:
			slime.animate_match()
			animations.append(slime)

	await get_tree().create_timer(0.25).timeout

	# Remove slimes
	for cell in cells:
		var slime = board[cell.x][cell.y]
		if slime:
			slime.queue_free()
			board[cell.x][cell.y] = null

	# Create special candy if applicable
	if special_type != GameManager.SpecialType.NONE:
		var new_slime = _create_slime(color, special_position, special_type)
		board[special_position.x][special_position.y] = new_slime
		new_slime.animate_special_creation()


func _find_intersection(cells: Array) -> Vector2i:
	var row_counts: Dictionary = {}
	var col_counts: Dictionary = {}

	for cell in cells:
		row_counts[cell.y] = row_counts.get(cell.y, 0) + 1
		col_counts[cell.x] = col_counts.get(cell.x, 0) + 1

	for cell in cells:
		if row_counts.get(cell.y, 0) > 1 and col_counts.get(cell.x, 0) > 1:
			return cell

	return cells[0]


# Special candy effects
func _check_special_combination(slime1: Slime, slime2: Slime) -> bool:
	var s1 = slime1.special_type
	var s2 = slime2.special_type

	# Color bomb combinations
	if s1 == GameManager.SpecialType.COLOR_BOMB or s2 == GameManager.SpecialType.COLOR_BOMB:
		return true

	# Two specials
	if s1 != GameManager.SpecialType.NONE and s2 != GameManager.SpecialType.NONE:
		return true

	return false


func _handle_special_combination(slime1: Slime, slime2: Slime) -> void:
	var s1 = slime1.special_type
	var s2 = slime2.special_type
	var pos1 = slime1.grid_position
	var pos2 = slime2.grid_position

	AudioManager.play_sfx("special")
	AudioManager.vibrate(150)

	# Color bomb + Color bomb = clear entire board
	if s1 == GameManager.SpecialType.COLOR_BOMB and s2 == GameManager.SpecialType.COLOR_BOMB:
		await _clear_entire_board()
		return

	# Color bomb + any color
	if s1 == GameManager.SpecialType.COLOR_BOMB:
		await _activate_color_bomb(pos1, slime2.slime_color, s2)
		return
	if s2 == GameManager.SpecialType.COLOR_BOMB:
		await _activate_color_bomb(pos2, slime1.slime_color, s1)
		return

	# Striped + Striped = cross explosion
	if _is_striped(s1) and _is_striped(s2):
		await _cross_explosion(pos1)
		return

	# Wrapped + Wrapped = large explosion
	if s1 == GameManager.SpecialType.WRAPPED and s2 == GameManager.SpecialType.WRAPPED:
		await _large_explosion(pos1, 4)
		return

	# Striped + Wrapped = giant cross
	if (s1 == GameManager.SpecialType.WRAPPED and _is_striped(s2)) or \
	   (s2 == GameManager.SpecialType.WRAPPED and _is_striped(s1)):
		await _giant_cross_explosion(pos1)
		return


func _is_striped(special: GameManager.SpecialType) -> bool:
	return special == GameManager.SpecialType.STRIPED_H or special == GameManager.SpecialType.STRIPED_V


func _activate_special(pos: Vector2i, special: GameManager.SpecialType, color: GameManager.SlimeColor) -> void:
	match special:
		GameManager.SpecialType.STRIPED_H:
			await _clear_row(pos.y, pos.x)
		GameManager.SpecialType.STRIPED_V:
			await _clear_column(pos.x, pos.y)
		GameManager.SpecialType.WRAPPED:
			await _wrapped_explosion(pos)
		GameManager.SpecialType.COLOR_BOMB:
			var target_color = _get_most_common_color()
			await _activate_color_bomb(pos, target_color, GameManager.SpecialType.NONE)


func _clear_row(row: int, source_col: int) -> void:
	AudioManager.play_sfx("explosion")
	GameManager.add_score(GameManager.BOARD_SIZE * 10)

	_spawn_line_effect(Vector2i(source_col, row), true)

	# Collect specials to activate and slimes to remove
	var specials_to_activate: Array = []
	var slimes_to_clear: Array = []

	for x in range(GameManager.BOARD_SIZE):
		var slime = board[x][row]
		if slime and x != source_col:
			if slime.special_type != GameManager.SpecialType.NONE:
				specials_to_activate.append({"pos": Vector2i(x, row), "type": slime.special_type, "color": slime.slime_color})
			slimes_to_clear.append(Vector2i(x, row))

	# Animate all slimes
	for pos in slimes_to_clear:
		if board[pos.x][pos.y]:
			board[pos.x][pos.y].animate_match()

	await get_tree().create_timer(0.2).timeout

	# Remove slimes
	for pos in slimes_to_clear:
		if board[pos.x][pos.y] and is_instance_valid(board[pos.x][pos.y]):
			board[pos.x][pos.y].queue_free()
			board[pos.x][pos.y] = null

	# Activate specials after clearing
	for special_data in specials_to_activate:
		await _activate_special(special_data.pos, special_data.type, special_data.color)


func _clear_column(col: int, source_row: int) -> void:
	AudioManager.play_sfx("explosion")
	GameManager.add_score(GameManager.BOARD_SIZE * 10)

	_spawn_line_effect(Vector2i(col, source_row), false)

	# Collect specials to activate and slimes to remove
	var specials_to_activate: Array = []
	var slimes_to_clear: Array = []

	for y in range(GameManager.BOARD_SIZE):
		var slime = board[col][y]
		if slime and y != source_row:
			if slime.special_type != GameManager.SpecialType.NONE:
				specials_to_activate.append({"pos": Vector2i(col, y), "type": slime.special_type, "color": slime.slime_color})
			slimes_to_clear.append(Vector2i(col, y))

	# Animate all slimes
	for pos in slimes_to_clear:
		if board[pos.x][pos.y]:
			board[pos.x][pos.y].animate_match()

	await get_tree().create_timer(0.2).timeout

	# Remove slimes
	for pos in slimes_to_clear:
		if board[pos.x][pos.y] and is_instance_valid(board[pos.x][pos.y]):
			board[pos.x][pos.y].queue_free()
			board[pos.x][pos.y] = null

	# Activate specials after clearing
	for special_data in specials_to_activate:
		await _activate_special(special_data.pos, special_data.type, special_data.color)


func _wrapped_explosion(center: Vector2i) -> void:
	AudioManager.play_sfx("explosion")
	GameManager.add_score(9 * 15)

	_spawn_explosion_effect(center)

	# Collect specials to activate and slimes to remove
	var specials_to_activate: Array = []
	var slimes_to_clear: Array = []

	# Clear 3x3 area
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var pos = center + Vector2i(dx, dy)
			if _is_valid_position(pos):
				var slime = board[pos.x][pos.y]
				if slime and pos != center:
					if slime.special_type != GameManager.SpecialType.NONE:
						specials_to_activate.append({"pos": pos, "type": slime.special_type, "color": slime.slime_color})
					slimes_to_clear.append(pos)

	# Animate all slimes
	for pos in slimes_to_clear:
		if board[pos.x][pos.y]:
			board[pos.x][pos.y].animate_match()

	await get_tree().create_timer(0.25).timeout

	# Remove slimes
	for pos in slimes_to_clear:
		if board[pos.x][pos.y] and is_instance_valid(board[pos.x][pos.y]):
			board[pos.x][pos.y].queue_free()
			board[pos.x][pos.y] = null

	# Also clear center
	if board[center.x][center.y] and is_instance_valid(board[center.x][center.y]):
		board[center.x][center.y].queue_free()
		board[center.x][center.y] = null

	# Activate specials after clearing
	for special_data in specials_to_activate:
		await _activate_special(special_data.pos, special_data.type, special_data.color)


func _cross_explosion(center: Vector2i) -> void:
	await _clear_row(center.y, center.x)
	await _clear_column(center.x, center.y)


func _giant_cross_explosion(center: Vector2i) -> void:
	AudioManager.play_sfx("explosion")
	GameManager.add_score(GameManager.BOARD_SIZE * 6 * 10)

	_spawn_explosion_effect(center)

	# Clear 3 rows and 3 columns
	for offset in range(-1, 2):
		var row = center.y + offset
		var col = center.x + offset

		if row >= 0 and row < GameManager.BOARD_SIZE:
			for x in range(GameManager.BOARD_SIZE):
				if board[x][row]:
					board[x][row].animate_match()

		if col >= 0 and col < GameManager.BOARD_SIZE:
			for y in range(GameManager.BOARD_SIZE):
				if board[col][y]:
					board[col][y].animate_match()

	await get_tree().create_timer(0.3).timeout

	for offset in range(-1, 2):
		var row = center.y + offset
		var col = center.x + offset

		if row >= 0 and row < GameManager.BOARD_SIZE:
			for x in range(GameManager.BOARD_SIZE):
				if board[x][row]:
					board[x][row].queue_free()
					board[x][row] = null

		if col >= 0 and col < GameManager.BOARD_SIZE:
			for y in range(GameManager.BOARD_SIZE):
				if board[col][y]:
					board[col][y].queue_free()
					board[col][y] = null


func _large_explosion(center: Vector2i, radius: int) -> void:
	AudioManager.play_sfx("explosion")
	GameManager.add_score((radius * 2 + 1) * (radius * 2 + 1) * 10)

	_spawn_explosion_effect(center)

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var pos = center + Vector2i(dx, dy)
			if _is_valid_position(pos) and board[pos.x][pos.y]:
				board[pos.x][pos.y].animate_match()

	await get_tree().create_timer(0.3).timeout

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			var pos = center + Vector2i(dx, dy)
			if _is_valid_position(pos) and board[pos.x][pos.y]:
				board[pos.x][pos.y].queue_free()
				board[pos.x][pos.y] = null


func _activate_color_bomb(pos: Vector2i, target_color: GameManager.SlimeColor, convert_to: GameManager.SpecialType) -> void:
	AudioManager.play_sfx("explosion")
	GameManager.add_score(200)

	_spawn_explosion_effect(pos)

	var cells_to_clear: Array = []

	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if board[x][y] and board[x][y].slime_color == target_color:
				cells_to_clear.append(Vector2i(x, y))

	# If combined with a special, convert all matching to that special
	if convert_to != GameManager.SpecialType.NONE:
		for cell in cells_to_clear:
			if board[cell.x][cell.y]:
				board[cell.x][cell.y].special_type = convert_to

		await get_tree().create_timer(0.3).timeout

		for cell in cells_to_clear:
			if board[cell.x][cell.y]:
				await _activate_special(cell, convert_to, target_color)
	else:
		# Just clear all matching colors
		for cell in cells_to_clear:
			if board[cell.x][cell.y]:
				board[cell.x][cell.y].animate_match()

		await get_tree().create_timer(0.3).timeout

		for cell in cells_to_clear:
			if board[cell.x][cell.y]:
				board[cell.x][cell.y].queue_free()
				board[cell.x][cell.y] = null

	# Clear the color bomb itself
	if board[pos.x][pos.y]:
		board[pos.x][pos.y].queue_free()
		board[pos.x][pos.y] = null


func _clear_entire_board() -> void:
	AudioManager.play_sfx("explosion")
	GameManager.add_score(GameManager.BOARD_SIZE * GameManager.BOARD_SIZE * 20)

	var center = Vector2i(GameManager.BOARD_SIZE / 2, GameManager.BOARD_SIZE / 2)
	_spawn_explosion_effect(center)

	# Clear from center outward
	for radius in range(GameManager.BOARD_SIZE):
		for x in range(GameManager.BOARD_SIZE):
			for y in range(GameManager.BOARD_SIZE):
				var dist = max(abs(x - center.x), abs(y - center.y))
				if dist == radius and board[x][y]:
					board[x][y].animate_match()

		await get_tree().create_timer(0.05).timeout

	await get_tree().create_timer(0.2).timeout

	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if board[x][y]:
				board[x][y].queue_free()
				board[x][y] = null


func _get_most_common_color() -> GameManager.SlimeColor:
	var color_counts: Dictionary = {}

	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if board[x][y]:
				var color = board[x][y].slime_color
				color_counts[color] = color_counts.get(color, 0) + 1

	var max_count = 0
	var most_common = GameManager.SlimeColor.RED

	for color in color_counts:
		if color_counts[color] > max_count:
			max_count = color_counts[color]
			most_common = color

	return most_common


# Gravity and fill - Peanuts Code approach (synchronous array update)
func _apply_gravity() -> void:
	# FIRST: Clean up ALL invalid references synchronously
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if not _is_cell_playable(x, y):
				continue  # Skip non-playable cells
			if board[x][y] != null and not is_instance_valid(board[x][y]):
				board[x][y] = null

	var max_fall_distance = 0

	# Collapse each column - move pieces down to fill gaps
	for x in range(GameManager.BOARD_SIZE):
		# Start from bottom and go up
		for y in range(GameManager.BOARD_SIZE - 1, -1, -1):
			# Skip non-playable cells
			if not _is_cell_playable(x, y):
				continue
			# If this cell is empty, find a piece above to fill it
			if board[x][y] == null:
				# Search upward for a piece (only in playable cells)
				for k in range(y - 1, -1, -1):
					if not _is_cell_playable(x, k):
						continue  # Skip non-playable cells
					if board[x][k] != null and is_instance_valid(board[x][k]):
						var slime = board[x][k]
						# Move in array IMMEDIATELY
						board[x][y] = slime
						board[x][k] = null
						slime.grid_position = Vector2i(x, y)
						# Animate the fall
						var target_pos = slime.grid_to_world(Vector2i(x, y))
						var fall_distance = y - k
						if fall_distance > max_fall_distance:
							max_fall_distance = fall_distance
						slime.animate_fall(target_pos, 0.0, 0.1 * fall_distance)
						break  # Found a piece, move to next empty cell

	# Wait for longest animation to finish (0.1s per row + buffer)
	var wait_time = 0.1 * max_fall_distance + 0.15
	await get_tree().create_timer(wait_time).timeout

	# SYNC: Only fix slimes that are way off (animation glitch protection)
	_sync_visual_positions_silent()


func _sync_visual_positions_silent() -> void:
	# Silently fix slimes that are more than 5 pixels off their target
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if not _is_cell_playable(x, y):
				continue  # Skip non-playable cells
			if board[x][y] != null and is_instance_valid(board[x][y]):
				var slime = board[x][y]
				var correct_pos = slime.grid_to_world(Vector2i(x, y))
				var distance = slime.position.distance_to(correct_pos)
				if distance > 5.0:
					# Animate to correct position instead of snapping
					var tween = slime.create_tween()
					tween.tween_property(slime, "position", correct_pos, 0.1)
				slime.grid_position = Vector2i(x, y)


func _fill_empty_spaces() -> void:
	# Clean up invalid references FIRST
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if not _is_cell_playable(x, y):
				continue  # Skip non-playable cells
			if board[x][y] != null and not is_instance_valid(board[x][y]):
				board[x][y] = null

	var max_fall_distance = 0

	# Spawn new pieces at empty positions (only playable cells)
	for x in range(GameManager.BOARD_SIZE):
		# Count how many empties in this column (for staggered spawning)
		var spawn_index = 0
		for y in range(GameManager.BOARD_SIZE):
			if not _is_cell_playable(x, y):
				continue  # Skip non-playable cells
			if board[x][y] == null:
				# Use mode-appropriate colors (saga/story/endless)
				var color = _get_random_color_for_mode()
				var slime = _create_slime(color, Vector2i(x, y))
				board[x][y] = slime
				# Start above board - higher for pieces that need to fall further
				var start_y = -1 - spawn_index
				slime.position = slime.grid_to_world(Vector2i(x, start_y))
				var target_pos = slime.grid_to_world(Vector2i(x, y))
				var fall_distance = y - start_y
				if fall_distance > max_fall_distance:
					max_fall_distance = fall_distance
				slime.animate_fall(target_pos, spawn_index * 0.05, 0.08 * fall_distance)
				spawn_index += 1

	# Wait for longest animation to finish
	var wait_time = 0.08 * max_fall_distance + 0.3
	await get_tree().create_timer(wait_time).timeout

	# SYNC: Fix any glitched positions
	_sync_visual_positions_silent()

	# VERIFY playable cells are full - if not, recursively fill
	var still_empty = false
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if not _is_cell_playable(x, y):
				continue  # Skip non-playable cells
			if board[x][y] == null or not is_instance_valid(board[x][y]):
				still_empty = true
				print("WARNING: Still empty at ", x, ", ", y)
				break
		if still_empty:
			break

	if still_empty:
		print("Board not full after fill, retrying...")
		await _fill_empty_spaces()


func _has_empty_cells() -> bool:
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if not _is_cell_playable(x, y):
				continue  # Skip non-playable cells
			if board[x][y] == null or not is_instance_valid(board[x][y]):
				return true
	return false


func _cleanup_invalid_slimes() -> void:
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if not _is_cell_playable(x, y):
				continue  # Skip non-playable cells
			if board[x][y] != null and not is_instance_valid(board[x][y]):
				board[x][y] = null


# Move validation
func _has_valid_moves() -> bool:
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			# Skip if current cell is empty
			if board[x][y] == null:
				continue

			# Check swap right
			if x < GameManager.BOARD_SIZE - 1 and board[x+1][y] != null:
				_swap_slimes(board[x][y], board[x+1][y])
				var has_match = _find_all_matches().size() > 0
				_swap_slimes(board[x][y], board[x+1][y])
				if has_match:
					return true

			# Check swap down
			if y < GameManager.BOARD_SIZE - 1 and board[x][y+1] != null:
				_swap_slimes(board[x][y], board[x][y+1])
				var has_match = _find_all_matches().size() > 0
				_swap_slimes(board[x][y], board[x][y+1])
				if has_match:
					return true

	return false


func _shuffle_board() -> void:
	var slimes: Array = []
	var playable_positions: Array[Vector2i] = []

	# Collect all slimes and playable positions
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if _is_cell_playable(x, y):
				playable_positions.append(Vector2i(x, y))
				if board[x][y]:
					slimes.append(board[x][y])

	# Shuffle slimes
	slimes.shuffle()

	# Redistribute only to playable positions
	var index = 0
	for pos in playable_positions:
		if index < slimes.size():
			board[pos.x][pos.y] = slimes[index]
			slimes[index].grid_position = pos
			var target_pos = slimes[index].grid_to_world(pos)
			slimes[index].animate_swap(target_pos, 0.3)
			index += 1

	# If still no valid moves, regenerate board
	await get_tree().create_timer(0.4).timeout
	if not _has_valid_moves():
		_regenerate_board()


# Saga mode shuffle - uses deterministic shuffling and tracks shuffle count
func _shuffle_board_saga() -> bool:
	"""
	Attempts to shuffle the board in Saga mode.
	Returns true if shuffle was allowed, false if no shuffles remaining.
	"""
	if not GameManager.use_saga_shuffle():
		return false  # No shuffles remaining - level failed

	saga_shuffle_count += 1

	var slimes: Array = []
	var playable_positions: Array[Vector2i] = []

	# Collect all slimes and playable positions
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if _is_cell_playable(x, y):
				playable_positions.append(Vector2i(x, y))
				if board[x][y]:
					slimes.append(board[x][y])

	# Deterministic shuffle using saga seed + shuffle count
	var shuffle_seed = SaveManager.get_saga_seed() + saga_shuffle_count * 1000
	seed(shuffle_seed)

	# Fisher-Yates shuffle with deterministic random
	for i in range(slimes.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = slimes[i]
		slimes[i] = slimes[j]
		slimes[j] = temp

	# Redistribute only to playable positions
	var index = 0
	for pos in playable_positions:
		if index < slimes.size():
			board[pos.x][pos.y] = slimes[index]
			slimes[index].grid_position = pos
			var target_pos = slimes[index].grid_to_world(pos)
			slimes[index].animate_swap(target_pos, 0.3)
			index += 1

	await get_tree().create_timer(0.4).timeout
	return true


# Check for no moves and handle shuffle logic
func _check_no_moves_available() -> void:
	if _has_valid_moves():
		return

	if GameManager.is_saga_mode():
		# Saga mode: Use limited shuffles
		var shuffles_remaining = GameManager.get_saga_shuffles_remaining()
		if shuffles_remaining > 0:
			print("No moves! Shuffling... (%d shuffles remaining)" % shuffles_remaining)
			await _shuffle_board_saga()
			# Check again after shuffle
			if not _has_valid_moves():
				await _check_no_moves_available()
		else:
			# No shuffles left - level failed
			print("No moves and no shuffles remaining - level failed!")
			GameManager.saga_level_failed.emit()
	else:
		# Endless mode: Free shuffle
		print("No moves! Shuffling board...")
		await _shuffle_board()


func _regenerate_board() -> void:
	# Clear all slimes
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			if board[x][y]:
				board[x][y].queue_free()
				board[x][y] = null

	# Create new board
	_initialize_board()


# Cheat mode: Replace slime at position with new color and special type
func _replace_slime_at(pos: Vector2i, color: GameManager.SlimeColor, special: GameManager.SpecialType) -> void:
	if not _is_valid_position(pos):
		return

	# Remove old slime
	var old_slime = board[pos.x][pos.y]
	if old_slime:
		old_slime.queue_free()

	# Create new slime with specified properties
	var slime = SlimeScene.instantiate()
	add_child(slime)
	slime.setup(color, pos, special)

	# Connect signals
	slime.clicked.connect(_on_slime_clicked)
	slime.swap_requested.connect(func(dir): _on_swap_requested(dir, slime))

	# Add to board
	board[pos.x][pos.y] = slime

	# Play spawn animation
	slime.animate_special_creation()
	AudioManager.play_sfx("special")


# Visual effects
func _spawn_explosion_effect(pos: Vector2i) -> void:
	# Create explosion particle effect
	var effect = GPUParticles2D.new()
	add_child(effect)
	effect.position = Vector2(pos.x * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2,
							  pos.y * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2)

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 30.0
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0
	material.initial_velocity_min = 100.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 300, 0)
	material.scale_min = 1.0
	material.scale_max = 2.0

	effect.process_material = material
	effect.amount = 20
	effect.lifetime = 0.5
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.emitting = true

	# Clean up after effect
	await get_tree().create_timer(1.0).timeout
	effect.queue_free()


func _spawn_line_effect(pos: Vector2i, horizontal: bool) -> void:
	# Line explosion visual effect
	var effect = GPUParticles2D.new()
	add_child(effect)
	effect.position = Vector2(pos.x * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2,
							  pos.y * GameManager.CELL_SIZE + GameManager.CELL_SIZE / 2)

	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX

	if horizontal:
		material.emission_box_extents = Vector3(GameManager.BOARD_SIZE * GameManager.CELL_SIZE / 2, 10, 0)
	else:
		material.emission_box_extents = Vector3(10, GameManager.BOARD_SIZE * GameManager.CELL_SIZE / 2, 0)

	material.direction = Vector3(0, 0, 0)
	material.spread = 45.0
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 200, 0)

	effect.process_material = material
	effect.amount = 30
	effect.lifetime = 0.4
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.emitting = true

	await get_tree().create_timer(0.8).timeout
	effect.queue_free()


# Ensure board is completely full - runs gravity and fill until no empty spaces
func _ensure_board_full() -> void:
	var max_iterations = 10  # Safety limit
	var iteration = 0

	while iteration < max_iterations:
		var has_empty = false

		# Check for any empty or invalid cells
		for x in range(GameManager.BOARD_SIZE):
			for y in range(GameManager.BOARD_SIZE):
				if board[x][y] == null or not is_instance_valid(board[x][y]):
					has_empty = true
					if board[x][y] != null and not is_instance_valid(board[x][y]):
						board[x][y] = null  # Clear invalid reference
					break
			if has_empty:
				break

		if not has_empty:
			break

		print("Board has empty cells - iteration ", iteration, " - applying gravity and fill")

		# Apply gravity and fill
		await _apply_gravity()
		await _fill_empty_spaces()

		iteration += 1

	if iteration > 0:
		print("Board filled after ", iteration, " iteration(s)")


# Force fill any empty or broken cells immediately (synchronous)
func _force_fill_empty_cells() -> void:
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			# Skip non-playable cells
			if not _is_cell_playable(x, y):
				continue

			var needs_replacement = false
			var reason = ""

			if board[x][y] == null:
				needs_replacement = true
				reason = "null"
			elif not is_instance_valid(board[x][y]):
				needs_replacement = true
				reason = "invalid"
			elif board[x][y].modulate.a < 0.5:
				needs_replacement = true
				reason = "invisible (alpha=" + str(board[x][y].modulate.a) + ")"
				board[x][y].queue_free()
			else:
				# Check if slime position matches grid position
				var slime = board[x][y]
				var expected_pos = slime.grid_to_world(Vector2i(x, y))
				var actual_pos = slime.position
				if slime.grid_position != Vector2i(x, y):
					needs_replacement = true
					reason = "wrong grid_pos: " + str(slime.grid_position) + " expected " + str(Vector2i(x, y))
					slime.queue_free()
				elif actual_pos.distance_to(expected_pos) > 100:
					# Slime is at wrong visual position
					needs_replacement = true
					reason = "wrong position: " + str(actual_pos) + " expected " + str(expected_pos)
					slime.queue_free()

			if needs_replacement:
				board[x][y] = null
				var color = _get_random_color_for_mode()
				var slime = _create_slime(color, Vector2i(x, y))
				board[x][y] = slime
				print("FORCE FILL: ", x, ",", y, " - ", reason)


# Board monitoring - catches any missed empty cells
func _check_and_fix_board() -> void:
	# Check for stuck processing state
	if is_processing:
		var current_time = Time.get_ticks_msec() / 1000.0
		var elapsed = current_time - processing_start_time
		if elapsed > PROCESSING_TIMEOUT:
			print("WARNING: Processing stuck for ", elapsed, "s - forcing reset")
			is_processing = false
			is_input_enabled = true
			_set_board_darkened(false)  # Restore brightness on timeout
		else:
			return  # Don't interfere while processing matches

	var has_empty = false
	var fixed_count = 0

	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			# Skip non-playable cells
			if not _is_cell_playable(x, y):
				continue

			var needs_fix = false

			if board[x][y] == null:
				needs_fix = true
				print("MONITOR: null at ", x, ", ", y)
			elif not is_instance_valid(board[x][y]):
				needs_fix = true
				board[x][y] = null
				print("MONITOR: invalid instance at ", x, ", ", y)

			if needs_fix:
				has_empty = true
				# Immediately create a new slime
				var color = _get_random_color_for_mode()
				var slime = _create_slime(color, Vector2i(x, y))
				board[x][y] = slime
				fixed_count += 1

	if has_empty:
		print("MONITOR: Fixed ", fixed_count, " empty cells")


# Visual feedback for processing state
func _set_board_darkened(darkened: bool) -> void:
	var target_modulate = Color(COOLDOWN_DARKEN, COOLDOWN_DARKEN, COOLDOWN_DARKEN) if darkened else Color.WHITE
	for x in range(GameManager.BOARD_SIZE):
		for y in range(GameManager.BOARD_SIZE):
			var slime = board[x][y]
			if slime and is_instance_valid(slime):
				var tween = slime.create_tween()
				tween.tween_property(slime, "modulate", target_modulate, COOLDOWN_TRANSITION)


# Event handlers
func _on_game_over() -> void:
	is_input_enabled = false


func _on_level_complete() -> void:
	is_input_enabled = false


# ============ STORY MODE CURRENCY FUNCTIONS ============

func _award_story_currencies(color: GameManager.SlimeColor, match_size: int) -> void:
	# Award Slime Essence based on color value and match size
	var cascade_level = ProgressionManager.get_current_cascade()
	var essence = ProgressionManager.calculate_essence_earned(color, match_size, cascade_level)
	ProgressionManager.add_currency("slime_essence", essence)

	# Color Crystal chance for Match-4+
	if match_size >= 4:
		var crystal_chance = 0.10  # 10% base chance
		if randf() < crystal_chance:
			var color_name = _get_color_name(color)
			if color_name != "":
				ProgressionManager.add_color_crystal(color_name)


func _get_color_name(color: GameManager.SlimeColor) -> String:
	# Convert SlimeColor enum to string for color crystals
	match color:
		GameManager.SlimeColor.RED, GameManager.SlimeColor.RED_COLORLESS:
			return "red"
		GameManager.SlimeColor.ORANGE, GameManager.SlimeColor.ORANGE_COLORLESS:
			return "orange"
		GameManager.SlimeColor.YELLOW, GameManager.SlimeColor.YELLOW_COLORLESS:
			return "yellow"
		GameManager.SlimeColor.GREEN, GameManager.SlimeColor.GREEN_COLORLESS:
			return "green"
		GameManager.SlimeColor.BLUE, GameManager.SlimeColor.BLUE_COLORLESS:
			return "blue"
		GameManager.SlimeColor.PURPLE, GameManager.SlimeColor.PURPLE_COLORLESS:
			return "purple"
	return ""
