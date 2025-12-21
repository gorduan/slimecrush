extends Control
## Main - Root scene controller
## Manages game flow, UI updates, and screen transitions

@onready var game_board: GameBoard = $GameWorld/GameBoard
@onready var world_map: WorldMap = $GameWorld/WorldMap
@onready var game_camera: Camera2D = $GameWorld/GameCamera
@onready var score_label: Label = $UILayer/UI/TopBar/StatsRow/ScoreContainer/ScoreValue
@onready var moves_label: Label = $UILayer/UI/TopBar/StatsRow/MovesContainer/MovesValue
@onready var level_label: Label = $UILayer/UI/TopBar/StatsRow/LevelContainer/LevelValue
@onready var highscore_label: Label = $UILayer/UI/TopBar/SecondRow/HighscoreContainer/HighscoreValue
@onready var target_label: Label = $UILayer/UI/TopBar/SecondRow/TargetContainer/TargetValue
@onready var combo_label: Label = $UILayer/UI/ComboDisplay
@onready var level_complete_panel: Panel = $UILayer/UI/LevelCompletePanel
@onready var game_over_panel: Panel = $UILayer/UI/GameOverPanel
@onready var final_score_label: Label = $UILayer/UI/LevelCompletePanel/VBoxContainer/FinalScore
@onready var gameover_score_label: Label = $UILayer/UI/GameOverPanel/VBoxContainer/FinalScore

# GameBoard base position (relative to screen)
const GAME_BOARD_BASE_X: float = 72.0
const GAME_BOARD_BASE_Y: float = 220.0
const LEVEL_HEIGHT: float = 1280.0


func _ready() -> void:
	_connect_signals()
	_update_ui()
	_hide_panels()
	_generate_world()
	SaveManager.increment_games_played()


func _generate_world() -> void:
	# Generate world based on current stage/level
	if world_map:
		var stage = GameManager.get_current_stage()
		var level_in_stage = GameManager.get_level_in_stage()
		world_map.generate_world(stage, level_in_stage)


func _connect_signals() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.moves_changed.connect(_on_moves_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.combo_triggered.connect(_on_combo_triggered)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)
	GameManager.highscore_achieved.connect(_on_highscore_achieved)


func _hide_panels() -> void:
	level_complete_panel.visible = false
	game_over_panel.visible = false
	combo_label.visible = false


func _update_ui() -> void:
	score_label.text = str(GameManager.score)
	moves_label.text = str(GameManager.moves)
	level_label.text = str(GameManager.level)
	highscore_label.text = str(SaveManager.get_highscore())
	target_label.text = str(GameManager.target_score)


func _on_score_changed(new_score: int) -> void:
	# Animate score change
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)
	score_label.text = str(new_score)


func _on_moves_changed(new_moves: int) -> void:
	moves_label.text = str(new_moves)

	# Warning animation for low moves
	if new_moves <= 5:
		moves_label.add_theme_color_override("font_color", Color("#ff6b6b"))
		var tween = create_tween()
		tween.tween_property(moves_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(moves_label, "scale", Vector2.ONE, 0.1)
	else:
		moves_label.remove_theme_color_override("font_color")


func _on_level_changed(new_level: int) -> void:
	level_label.text = str(new_level)
	target_label.text = str(GameManager.target_score)


func _on_combo_triggered(combo_count: int) -> void:
	if combo_count >= 2:
		combo_label.text = str(combo_count) + "x COMBO!"
		combo_label.visible = true

		var tween = create_tween()
		tween.tween_property(combo_label, "scale", Vector2.ZERO, 0.0)
		tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.2)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(combo_label, "scale", Vector2.ONE, 0.1)
		tween.tween_property(combo_label, "modulate:a", 0.0, 0.5).set_delay(0.5)
		tween.tween_callback(func(): combo_label.visible = false; combo_label.modulate.a = 1.0)

		AudioManager.play_sfx("combo")
		AudioManager.vibrate(50)


func _on_game_over() -> void:
	gameover_score_label.text = str(GameManager.score)
	game_over_panel.visible = true
	game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# Disable game board input
	if game_board:
		game_board.is_input_enabled = false

	var tween = create_tween()
	game_over_panel.modulate.a = 0.0
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.3)

	AudioManager.play_sfx("lose")


func _on_level_complete() -> void:
	final_score_label.text = str(GameManager.score)
	level_complete_panel.visible = true
	level_complete_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	SaveManager.unlock_level(GameManager.level + 1)

	# Disable game board input
	if game_board:
		game_board.is_input_enabled = false

	var tween = create_tween()
	level_complete_panel.modulate.a = 0.0
	tween.tween_property(level_complete_panel, "modulate:a", 1.0, 0.3)

	AudioManager.play_sfx("win")
	AudioManager.vibrate(200)


func _on_highscore_achieved(score: int) -> void:
	highscore_label.text = str(score)

	# Celebration effect
	var tween = create_tween()
	tween.tween_property(highscore_label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(highscore_label, "scale", Vector2.ONE, 0.2)


# Button handlers
func _on_new_game_pressed() -> void:
	AudioManager.play_sfx("button")
	game_over_panel.visible = false
	level_complete_panel.visible = false
	GameManager.reset_game()
	get_tree().reload_current_scene()


func _on_next_level_pressed() -> void:
	AudioManager.play_sfx("button")
	level_complete_panel.visible = false

	var old_stage = GameManager.get_current_stage()
	GameManager.next_level()
	var new_stage = GameManager.get_current_stage()

	# Check if we changed stages (need to regenerate world completely)
	if new_stage != old_stage:
		# Reset camera and regenerate world for new biome
		game_camera.reset_camera()
		_generate_world()
		# Reset GameBoard position
		game_board.position = Vector2(GAME_BOARD_BASE_X, GAME_BOARD_BASE_Y)
	else:
		# Same stage - scroll up and generate next screen
		# Generate next screen before scrolling
		world_map.generate_next_screen(new_stage)

		# Move GameBoard to next level position (one screen up)
		var new_y = GAME_BOARD_BASE_Y - (game_camera.current_level_offset + 1) * LEVEL_HEIGHT
		game_board.position = Vector2(GAME_BOARD_BASE_X, new_y)

		# Scroll camera up
		game_camera.scroll_up()

	# Reset game board for new level
	if game_board:
		game_board.is_input_enabled = true
		game_board._reset_board()

	_update_ui()


func _on_shuffle_pressed() -> void:
	AudioManager.play_sfx("button")
	if game_board:
		game_board._shuffle_board()


func _on_win_cheat_pressed() -> void:
	# Cheat button - instantly win the level
	AudioManager.play_sfx("button")
	# Set score to target + extra to trigger win
	GameManager.score = GameManager.target_score + 100
	GameManager.check_win_condition()
