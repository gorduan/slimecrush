extends Node
## GameManager - Global game state management singleton
## Handles score, moves, level progression, and game events

# Signals
signal score_changed(new_score: int)
signal moves_changed(new_moves: int)
signal level_changed(new_level: int)
signal combo_triggered(combo_count: int)
signal game_over()
signal level_complete()
signal highscore_achieved(score: int)
signal saga_level_failed()  # No shuffles remaining in saga mode
signal saga_shuffle_used(remaining: int)  # Shuffle used in saga mode

# Slime Colors (Candy Crush inspired)
enum SlimeColor {
	RED,
	ORANGE,
	YELLOW,
	GREEN,
	BLUE,
	PURPLE,
	# Colorless variants (placeholders) - same points as GREEN (1)
	RED_COLORLESS,
	ORANGE_COLORLESS,
	YELLOW_COLORLESS,
	GREEN_COLORLESS,
	BLUE_COLORLESS,
	PURPLE_COLORLESS
}

# Special Types
enum SpecialType {
	NONE,
	STRIPED_H,    # Horizontal striped - clears row
	STRIPED_V,    # Vertical striped - clears column
	WRAPPED,      # Wrapped - explodes 3x3 area twice
	COLOR_BOMB    # Color bomb - clears all of one color
}

# Color hex values matching Candy Crush
const SLIME_COLORS: Dictionary = {
	SlimeColor.RED: Color("#ff6b6b"),
	SlimeColor.ORANGE: Color("#ffa502"),
	SlimeColor.YELLOW: Color("#feca57"),
	SlimeColor.GREEN: Color("#26de81"),
	SlimeColor.BLUE: Color("#45aaf2"),
	SlimeColor.PURPLE: Color("#a55eea"),
	# Colorless variants - grayscale versions
	SlimeColor.RED_COLORLESS: Color("#a0a0a0"),
	SlimeColor.ORANGE_COLORLESS: Color("#b0b0b0"),
	SlimeColor.YELLOW_COLORLESS: Color("#c0c0c0"),
	SlimeColor.GREEN_COLORLESS: Color("#909090"),
	SlimeColor.BLUE_COLORLESS: Color("#a8a8a8"),
	SlimeColor.PURPLE_COLORLESS: Color("#989898")
}

const SLIME_COLOR_NAMES: Dictionary = {
	SlimeColor.RED: "red",
	SlimeColor.ORANGE: "orange",
	SlimeColor.YELLOW: "yellow",
	SlimeColor.GREEN: "green",
	SlimeColor.BLUE: "blue",
	SlimeColor.PURPLE: "purple",
	SlimeColor.RED_COLORLESS: "red_colorless",
	SlimeColor.ORANGE_COLORLESS: "orange_colorless",
	SlimeColor.YELLOW_COLORLESS: "yellow_colorless",
	SlimeColor.GREEN_COLORLESS: "green_colorless",
	SlimeColor.BLUE_COLORLESS: "blue_colorless",
	SlimeColor.PURPLE_COLORLESS: "purple_colorless"
}

# Base point values per slime color (multiplied by match size)
# Green=1, Blue=2, Purple=3, Yellow=4, Orange=5, Red=6
# Colorless variants all have value 1 (same as Green)
const SLIME_POINT_VALUES: Dictionary = {
	SlimeColor.GREEN: 1,
	SlimeColor.BLUE: 2,
	SlimeColor.PURPLE: 3,
	SlimeColor.YELLOW: 4,
	SlimeColor.ORANGE: 5,
	SlimeColor.RED: 6,
	# Colorless variants - all worth 1 point (placeholder value)
	SlimeColor.RED_COLORLESS: 1,
	SlimeColor.ORANGE_COLORLESS: 1,
	SlimeColor.YELLOW_COLORLESS: 1,
	SlimeColor.GREEN_COLORLESS: 1,
	SlimeColor.BLUE_COLORLESS: 1,
	SlimeColor.PURPLE_COLORLESS: 1
}

# Board configuration
const BOARD_SIZE: int = 8
const CELL_SIZE: int = 72  # Größere Zellen für bessere Sichtbarkeit

# Stage/Level configuration
const LEVELS_PER_STAGE: int = 10

# Game state
var score: int = 0:
	set(value):
		score = value
		score_changed.emit(score)

var moves: int = 30:
	set(value):
		moves = value
		moves_changed.emit(moves)

var level: int = 1:
	set(value):
		level = value
		level_changed.emit(level)

var target_score: int = 1000
var combo_count: int = 0
var is_game_active: bool = true

# Current mode and slot (managed by SaveManager)
var current_mode: String:
	get: return SaveManager.active_mode

var current_slot: int:
	get: return SaveManager.active_slot

# Scoring constants
const SCORE_MATCH_3: int = 30
const SCORE_MATCH_4: int = 60
const SCORE_MATCH_5: int = 100
const SCORE_SPECIAL_ACTIVATION: int = 50
const COMBO_MULTIPLIER: float = 1.5


func _ready() -> void:
	# Don't reset on ready - wait for slot selection
	pass


func reset_game() -> void:
	score = 0
	moves = 30
	level = 1
	target_score = 1000
	combo_count = 0
	is_game_active = true


func load_from_slot() -> void:
	var data = SaveManager.get_current_slot_data()
	if data.is_empty:
		# New game
		reset_game()
	else:
		# Continue from saved progress
		score = 0  # Start fresh score for this session
		level = data.get("level", 1)
		moves = 30 + (level * 2)
		target_score = 1000 + (level - 1) * 500
		combo_count = 0
		is_game_active = true


func save_to_slot() -> void:
	var data = {
		"score": SaveManager.get_highscore(),  # Best score achieved
		"level": level,
		"max_level": max(level, SaveManager.get_max_level()),
		"total_matches": SaveManager.get_total_matches(),
		"games_played": SaveManager.get_games_played()
	}
	SaveManager.save_current_slot_data(data)


func start_level(level_num: int) -> void:
	level = level_num
	score = 0
	moves = 30 + (level_num * 2)

	# Story Mode: Add bonus starting moves from upgrades
	if SaveManager.is_story_mode():
		moves += ProgressionManager.get_bonus_starting_moves()
		ProgressionManager.reset_game_state()  # Reset per-game state

	target_score = 1000 + (level_num - 1) * 500
	combo_count = 0
	is_game_active = true


func next_level() -> void:
	start_level(level + 1)


func add_score(points: int) -> void:
	if not is_game_active:
		return

	# Apply Story Mode score bonuses
	var final_points = points
	if SaveManager.is_story_mode():
		final_points = int(points * ProgressionManager.get_score_multiplier())

	# Apply combo multiplier with Story Mode bonus
	var combo_mult = COMBO_MULTIPLIER
	if SaveManager.is_story_mode():
		combo_mult += ProgressionManager.get_combo_multiplier_bonus()

	var multiplied_points = int(final_points * pow(combo_mult, combo_count))
	score += multiplied_points

	# Check for highscore
	if score > SaveManager.get_highscore():
		SaveManager.save_highscore(score)
		highscore_achieved.emit(score)


func use_move() -> void:
	if not is_game_active:
		return

	# Story Mode: Check for time freeze (free moves)
	if SaveManager.is_story_mode():
		if ProgressionManager.consume_time_freeze_move():
			return  # Move was free due to Time Freeze ability

		# Story Mode: Check for move saver chance
		if ProgressionManager.check_move_saver():
			return  # Move was saved by upgrade

	moves -= 1

	# Story Mode: Check for emergency moves at 0
	if moves <= 0 and SaveManager.is_story_mode():
		var emergency = ProgressionManager.use_emergency_moves()
		if emergency > 0:
			moves += emergency
			return

	if moves <= 0:
		check_game_over()


func trigger_combo() -> void:
	combo_count += 1
	if combo_count > 1:
		combo_triggered.emit(combo_count)


func reset_combo() -> void:
	combo_count = 0


func check_win_condition() -> void:
	if score >= target_score and is_game_active:
		is_game_active = false
		level_complete.emit()


func check_game_over() -> void:
	if moves <= 0 and score < target_score:
		is_game_active = false
		game_over.emit()


func calculate_match_score(match_size: int, has_special: bool = false) -> int:
	var base_score: int
	match match_size:
		3:
			base_score = SCORE_MATCH_3
		4:
			base_score = SCORE_MATCH_4
		5, _:
			base_score = SCORE_MATCH_5 + (match_size - 5) * 20

	if has_special:
		base_score += SCORE_SPECIAL_ACTIVATION

	return base_score


# Calculate score based on slime color and match size
# Score = base_value × match_size (e.g., Green 3-match = 1×3 = 3, Red 3-match = 6×3 = 18)
func calculate_color_match_score(slime_color: SlimeColor, match_size: int) -> int:
	var base_value: int = SLIME_POINT_VALUES.get(slime_color, 1)
	# Additive scoring: base value multiplied by match size
	return base_value * match_size


# Get the base point value for a slime color
func get_slime_point_value(slime_color: SlimeColor) -> int:
	return SLIME_POINT_VALUES.get(slime_color, 1)


func get_slime_color(color_enum: SlimeColor) -> Color:
	return SLIME_COLORS.get(color_enum, Color.WHITE)


# Number of base colors (excluding colorless variants)
const BASE_COLOR_COUNT: int = 6

func get_random_slime_color() -> SlimeColor:
	# Only return base colors (0-5), not colorless variants
	return randi() % BASE_COLOR_COUNT as SlimeColor


# Check if a slime color is a colorless variant
func is_colorless(color: SlimeColor) -> bool:
	return color >= SlimeColor.RED_COLORLESS


# Get the colorless variant of a color
func get_colorless_variant(color: SlimeColor) -> SlimeColor:
	if is_colorless(color):
		return color  # Already colorless
	match color:
		SlimeColor.RED: return SlimeColor.RED_COLORLESS
		SlimeColor.ORANGE: return SlimeColor.ORANGE_COLORLESS
		SlimeColor.YELLOW: return SlimeColor.YELLOW_COLORLESS
		SlimeColor.GREEN: return SlimeColor.GREEN_COLORLESS
		SlimeColor.BLUE: return SlimeColor.BLUE_COLORLESS
		SlimeColor.PURPLE: return SlimeColor.PURPLE_COLORLESS
		_: return color


# Get the base color from a colorless variant
func get_base_color(color: SlimeColor) -> SlimeColor:
	if not is_colorless(color):
		return color  # Already a base color
	match color:
		SlimeColor.RED_COLORLESS: return SlimeColor.RED
		SlimeColor.ORANGE_COLORLESS: return SlimeColor.ORANGE
		SlimeColor.YELLOW_COLORLESS: return SlimeColor.YELLOW
		SlimeColor.GREEN_COLORLESS: return SlimeColor.GREEN
		SlimeColor.BLUE_COLORLESS: return SlimeColor.BLUE
		SlimeColor.PURPLE_COLORLESS: return SlimeColor.PURPLE
		_: return color


# Check if two colors match (considering colorless as matching their base color)
func colors_match(color1: SlimeColor, color2: SlimeColor) -> bool:
	return get_base_color(color1) == get_base_color(color2)


# Stage/Level helpers
func get_current_stage() -> int:
	# Stage 1 = Level 1-10, Stage 2 = Level 11-20, etc.
	return int((level - 1) / LEVELS_PER_STAGE) + 1


func get_level_in_stage() -> int:
	# Returns 1-10 for which level within the current stage
	var level_in_stage = ((level - 1) % LEVELS_PER_STAGE) + 1
	return level_in_stage


func get_total_stages_completed() -> int:
	return int((level - 1) / LEVELS_PER_STAGE)


# ============ SAGA MODE FUNCTIONS ============

# Color unlock order for Saga mode (from lowest to highest points)
const SAGA_COLOR_UNLOCK_ORDER: Array = [
	SlimeColor.GREEN,   # Level 1+  (1 point)
	SlimeColor.BLUE,    # Level 11+ (2 points)
	SlimeColor.PURPLE,  # Level 21+ (3 points)
	SlimeColor.YELLOW,  # Level 31+ (4 points)
	SlimeColor.ORANGE,  # Level 41+ (5 points)
	SlimeColor.RED      # Level 51+ (6 points)
]

# Colorless variants in same order
const SAGA_COLORLESS_ORDER: Array = [
	SlimeColor.GREEN_COLORLESS,
	SlimeColor.BLUE_COLORLESS,
	SlimeColor.PURPLE_COLORLESS,
	SlimeColor.YELLOW_COLORLESS,
	SlimeColor.ORANGE_COLORLESS,
	SlimeColor.RED_COLORLESS
]


func is_saga_mode() -> bool:
	return SaveManager.is_saga_mode()


func load_saga_level() -> void:
	var saga_data = SaveManager.get_current_saga_data()
	level = saga_data.get("level", 1)
	score = 0
	moves = calculate_saga_moves(level)
	target_score = calculate_saga_target(level)
	combo_count = 0
	is_game_active = true


func calculate_saga_moves(saga_level: int) -> int:
	# Start with 15 moves, +1 every 5 levels, max 30
	return mini(15 + int(saga_level / 5), 30)


func calculate_saga_target(saga_level: int) -> int:
	# Target based on available colors and level
	var unlocked = get_saga_unlocked_color_count(saga_level)
	# Base target scales with unlocked colors (more colors = more points possible)
	var base_target = 50 + (unlocked * 30)
	# Scale with level
	return int(base_target * (1.0 + saga_level * 0.05))


func get_saga_unlocked_color_count(saga_level: int) -> int:
	# 1 color per 10 levels, max 6
	return mini(1 + int((saga_level - 1) / 10), 6)


func get_saga_available_colors(saga_level: int) -> Array:
	"""
	Returns array of available SlimeColors for the given saga level.
	Includes unlocked real colors + remaining colorless variants.
	"""
	var unlocked_count = get_saga_unlocked_color_count(saga_level)
	var available: Array = []

	# Add unlocked real colors
	for i in range(unlocked_count):
		available.append(SAGA_COLOR_UNLOCK_ORDER[i])

	# Add colorless variants for locked colors
	for i in range(unlocked_count, 6):
		available.append(SAGA_COLORLESS_ORDER[i])

	return available


func get_saga_random_color(saga_level: int) -> SlimeColor:
	"""
	Returns a random color from the available colors for the given saga level.
	This is used for deterministic spawning in saga mode.
	"""
	var available = get_saga_available_colors(saga_level)
	return available[randi() % available.size()]


func get_saga_seed(_saga_level: int) -> int:
	"""
	Returns a deterministic seed for the given saga level.
	Same level always produces same seed.
	"""
	return SaveManager.get_saga_seed()


func use_saga_shuffle() -> bool:
	"""
	Attempts to use a shuffle in saga mode.
	Returns true if shuffle was allowed, false if no shuffles remaining.
	Emits saga_shuffle_used or saga_level_failed signal.
	"""
	if SaveManager.use_saga_shuffle():
		var remaining = SaveManager.get_saga_shuffles_remaining()
		saga_shuffle_used.emit(remaining)
		return true
	else:
		is_game_active = false
		saga_level_failed.emit()
		return false


func get_saga_shuffles_remaining() -> int:
	return SaveManager.get_saga_shuffles_remaining()


func complete_saga_level() -> void:
	"""Called when a saga level is completed successfully."""
	SaveManager.advance_saga_level()
	level_complete.emit()


func retry_saga_level() -> void:
	"""Restart the current saga level with the same seed."""
	SaveManager.reset_saga_shuffles()
	load_saga_level()
