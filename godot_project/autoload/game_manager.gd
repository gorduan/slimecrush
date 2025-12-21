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

# Slime Colors (Candy Crush inspired)
enum SlimeColor {
	RED,
	ORANGE,
	YELLOW,
	GREEN,
	BLUE,
	PURPLE
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
	SlimeColor.PURPLE: Color("#a55eea")
}

const SLIME_COLOR_NAMES: Dictionary = {
	SlimeColor.RED: "red",
	SlimeColor.ORANGE: "orange",
	SlimeColor.YELLOW: "yellow",
	SlimeColor.GREEN: "green",
	SlimeColor.BLUE: "blue",
	SlimeColor.PURPLE: "purple"
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
	target_score = 1000 + (level_num - 1) * 500
	combo_count = 0
	is_game_active = true


func next_level() -> void:
	start_level(level + 1)


func add_score(points: int) -> void:
	if not is_game_active:
		return

	var multiplied_points = int(points * pow(COMBO_MULTIPLIER, combo_count))
	score += multiplied_points

	# Check for highscore
	if score > SaveManager.get_highscore():
		SaveManager.save_highscore(score)
		highscore_achieved.emit(score)


func use_move() -> void:
	if not is_game_active:
		return

	moves -= 1

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


func get_slime_color(color_enum: SlimeColor) -> Color:
	return SLIME_COLORS.get(color_enum, Color.WHITE)


func get_random_slime_color() -> SlimeColor:
	return randi() % SlimeColor.size() as SlimeColor


# Stage/Level helpers
func get_current_stage() -> int:
	# Stage 1 = Level 1-10, Stage 2 = Level 11-20, etc.
	return ((level - 1) / LEVELS_PER_STAGE) + 1


func get_level_in_stage() -> int:
	# Returns 1-10 for which level within the current stage
	var level_in_stage = ((level - 1) % LEVELS_PER_STAGE) + 1
	return level_in_stage


func get_total_stages_completed() -> int:
	return (level - 1) / LEVELS_PER_STAGE
