extends Control
## Main - Root scene controller
## Manages game flow, UI updates, and screen transitions

@onready var game_board: GameBoard = $GameWorld/GameBoard
@onready var world_map: WorldMap = $GameWorld/WorldMap
@onready var game_camera: Camera2D = $GameWorld/GameCamera
@onready var score_label: Label = $UILayer/UI/TopBar/StatsRow/ScoreContainer/HBox/ScoreValue
@onready var moves_label: Label = $UILayer/UI/TopBar/StatsRow/MovesContainer/HBox/MovesValue
@onready var level_label: Label = $UILayer/UI/TopBar/StatsRow/LevelContainer/HBox/LevelValue
@onready var highscore_label: Label = $UILayer/UI/SecondRow/HighscoreContainer/HBox/HighscoreValue
@onready var target_label: Label = $UILayer/UI/SecondRow/TargetContainer/HBox/TargetValue
@onready var combo_label: Label = $UILayer/UI/ComboDisplay
@onready var level_complete_panel: Panel = $UILayer/UI/LevelCompletePanel
@onready var game_over_panel: Panel = $UILayer/UI/GameOverPanel
@onready var final_score_label: Label = $UILayer/UI/LevelCompletePanel/VBoxContainer/FinalScore
@onready var gameover_score_label: Label = $UILayer/UI/GameOverPanel/VBoxContainer/FinalScore
@onready var menu_button: Button = $UILayer/UI/TopBar/MenuButton
@onready var cheat_menu: Control = $UILayer/CheatMenu
@onready var cheat_button: Button = $UILayer/BottomButtons/CheatButton

# Story mode currency display
var currency_bar: HBoxContainer = null
var essence_display: Label = null
var upgrades_button: Button = null

# Progression menu
var progression_menu_scene: PackedScene = preload("res://scenes/story_mode/progression_menu.tscn")

# Cheat menu spawn mode state
var cheat_spawn_active: bool = false
var cheat_spawn_color: GameManager.SlimeColor = GameManager.SlimeColor.RED
var cheat_spawn_special: GameManager.SpecialType = GameManager.SpecialType.NONE

# Hidden dev button unlock - swipe detection
var _swipe_sequence: Array[String] = []  # Stores "left" or "right" directions
var _swipe_start_pos: Vector2 = Vector2.ZERO
var _swipe_start_time: int = 0
var _last_swipe_time: int = 0
const SWIPE_THRESHOLD: float = 100.0  # Minimum swipe distance
const SWIPE_TIMEOUT_MS: int = 2000  # Max time between swipes (2 seconds)
const REQUIRED_SWIPES: int = 10  # 10 alternating swipes to unlock

# GameBoard base position (centered on screen)
# Viewport is 720 wide, GameBoard is 8 tiles * 72px = 576px
# Center: (720 - 576) / 2 = 72
const GAME_BOARD_BASE_X: float = 72.0
const GAME_BOARD_BASE_Y: float = 350.0  # Vertical position for gameplay
const LEVEL_HEIGHT: float = 1280.0  # One screen height


func _ready() -> void:
	# Load game from selected slot (saga or regular mode)
	if GameManager.is_saga_mode():
		GameManager.load_saga_level()
	else:
		GameManager.load_from_slot()

	_connect_signals()
	_update_ui()
	_hide_panels()
	_generate_world()
	SaveManager.increment_games_played()

	# Connect menu button
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

	# Setup cheat menu and hide dev button by default
	if cheat_menu:
		cheat_menu.game_board = game_board
		cheat_menu.world_map = world_map
		cheat_menu.visible = false
	if cheat_button:
		cheat_button.visible = false

	# Setup Story Mode UI
	if SaveManager.is_story_mode():
		_setup_story_mode_ui()


func _input(event: InputEvent) -> void:
	# Hidden dev button unlock via swipe pattern
	_handle_dev_unlock_swipe(event)


func _handle_dev_unlock_swipe(event: InputEvent) -> void:
	# Skip if dev button already visible
	if cheat_button and cheat_button.visible:
		return

	# Track touch/mouse swipes
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var is_pressed = false
		var pos = Vector2.ZERO

		if event is InputEventScreenTouch:
			is_pressed = event.pressed
			pos = event.position
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			is_pressed = event.pressed
			pos = event.position
		else:
			return

		if is_pressed:
			_swipe_start_pos = pos
			_swipe_start_time = Time.get_ticks_msec()
		else:
			# Swipe ended - check direction
			var swipe_delta = pos - _swipe_start_pos
			var current_time = Time.get_ticks_msec()

			# Check if it's a valid horizontal swipe
			if abs(swipe_delta.x) > SWIPE_THRESHOLD and abs(swipe_delta.x) > abs(swipe_delta.y) * 2:
				var direction = "right" if swipe_delta.x > 0 else "left"

				# Reset sequence if too much time passed
				if _last_swipe_time > 0 and current_time - _last_swipe_time > SWIPE_TIMEOUT_MS:
					_swipe_sequence.clear()

				# Check if this continues the alternating pattern
				if _swipe_sequence.is_empty():
					_swipe_sequence.append(direction)
				elif _swipe_sequence[-1] != direction:
					# Alternating direction - add to sequence
					_swipe_sequence.append(direction)
				else:
					# Same direction twice - reset
					_swipe_sequence.clear()
					_swipe_sequence.append(direction)

				_last_swipe_time = current_time

				# Check if unlock pattern complete
				if _swipe_sequence.size() >= REQUIRED_SWIPES:
					_unlock_dev_button()


func _unlock_dev_button() -> void:
	if cheat_button:
		cheat_button.visible = true
		# Visual feedback
		AudioManager.play_sfx("combo")
		AudioManager.vibrate(200)

		# Flash animation
		var tween = create_tween()
		tween.tween_property(cheat_button, "modulate", Color(1, 0.84, 0.34), 0.1)
		tween.tween_property(cheat_button, "modulate", Color.WHITE, 0.1)
		tween.tween_property(cheat_button, "modulate", Color(1, 0.84, 0.34), 0.1)
		tween.tween_property(cheat_button, "modulate", Color.WHITE, 0.1)

	_swipe_sequence.clear()


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
	GameManager.saga_level_failed.connect(_on_saga_level_failed)
	GameManager.saga_shuffle_used.connect(_on_saga_shuffle_used)


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

	# Endless mode: Reset to level 1 but keep highscore
	if SaveManager.active_mode == SaveManager.MODE_ENDLESS:
		_reset_endless_progress()

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

	# Handle mode-specific completion
	if GameManager.is_saga_mode():
		GameManager.complete_saga_level()
	elif SaveManager.active_mode == SaveManager.MODE_ENDLESS:
		_save_endless_progress()
	else:
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

	# Saga mode: Go back to world map (can retry from there)
	if GameManager.is_saga_mode():
		_return_to_saga_world_map()
		return

	GameManager.reset_game()
	get_tree().reload_current_scene()


func _on_next_level_pressed() -> void:
	AudioManager.play_sfx("button")
	level_complete_panel.visible = false

	# Saga mode: Go back to world map
	if GameManager.is_saga_mode():
		_return_to_saga_world_map()
		return

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


func _on_cheat_pressed() -> void:
	AudioManager.play_sfx("button")
	if cheat_menu:
		cheat_menu.visible = true
		cheat_spawn_active = true
		if game_board:
			game_board.cheat_spawn_mode = true


func _on_cheat_menu_closed() -> void:
	if cheat_menu:
		cheat_menu.visible = false
	cheat_spawn_active = false
	if game_board:
		game_board.cheat_spawn_mode = false


func _on_spawn_mode_changed(active: bool, color: GameManager.SlimeColor, special: GameManager.SpecialType) -> void:
	cheat_spawn_active = active
	cheat_spawn_color = color
	cheat_spawn_special = special
	if game_board:
		game_board.cheat_spawn_mode = active
		game_board.cheat_spawn_color = color
		game_board.cheat_spawn_special = special


func _on_menu_pressed() -> void:
	AudioManager.play_sfx("button")

	# Save current progress
	GameManager.save_to_slot()

	# Fade out and return to mode selection
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/mode_selection.tscn")


func _on_saga_level_failed() -> void:
	# Show game over panel with "Level Failed" message
	gameover_score_label.text = "Level %d gescheitert!\nKeine Shuffles mehr." % GameManager.level
	game_over_panel.visible = true
	game_over_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	if game_board:
		game_board.is_input_enabled = false

	var tween = create_tween()
	game_over_panel.modulate.a = 0.0
	tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.3)

	AudioManager.play_sfx("lose")


func _return_to_saga_world_map() -> void:
	# Fade out and return to saga world map
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/saga_world_map.tscn")


# ============ ENDLESS MODE FUNCTIONS ============

func _save_endless_progress() -> void:
	# Save current level progress for Endless mode
	var data = SaveManager.get_current_slot_data()
	data["level"] = GameManager.level + 1  # Next level
	data["max_level"] = maxi(data.get("max_level", 1), GameManager.level + 1)
	SaveManager.save_current_slot_data(data)


func _reset_endless_progress() -> void:
	# Reset to level 1 but keep highscore and max_level
	var data = SaveManager.get_current_slot_data()
	data["level"] = 1  # Reset to level 1
	# Keep max_level and other stats
	SaveManager.save_current_slot_data(data)


func _on_saga_shuffle_used(remaining: int) -> void:
	# Show shuffle notification
	combo_label.text = "SHUFFLE! (%d übrig)" % remaining
	combo_label.visible = true

	var tween = create_tween()
	tween.tween_property(combo_label, "scale", Vector2.ZERO, 0.0)
	tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.2)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.1)
	tween.tween_property(combo_label, "modulate:a", 0.0, 0.5).set_delay(1.0)
	tween.tween_callback(func(): combo_label.visible = false; combo_label.modulate.a = 1.0)

	AudioManager.play_sfx("combo")


# ============ STORY MODE FUNCTIONS ============

func _setup_story_mode_ui() -> void:
	# Create essence display in the top bar
	var top_bar = $UILayer/UI/TopBar

	# Create currency row
	var currency_row = HBoxContainer.new()
	currency_row.name = "CurrencyRow"
	currency_row.add_theme_constant_override("separation", 15)
	currency_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(currency_row)
	top_bar.move_child(currency_row, 2)  # After title

	# Essence display
	var essence_container = _create_currency_display("◆", ProgressionManager.currencies.slime_essence, Color(0.27, 0.87, 0.51))
	currency_row.add_child(essence_container)
	essence_display = essence_container.get_node("Value")

	# Upgrades button
	upgrades_button = Button.new()
	upgrades_button.text = "UPGRADES"
	upgrades_button.custom_minimum_size = Vector2(120, 40)
	upgrades_button.add_theme_font_size_override("font_size", 16)
	upgrades_button.add_theme_color_override("font_color", Color(1, 0.84, 0.34))
	upgrades_button.pressed.connect(_on_upgrades_pressed)
	currency_row.add_child(upgrades_button)

	# Connect to currency changes
	ProgressionManager.currency_changed.connect(_on_story_currency_changed)


func _create_currency_display(icon: String, value: int, color: Color) -> HBoxContainer:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)

	var icon_label = Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.add_theme_color_override("font_color", color)
	container.add_child(icon_label)

	var value_label = Label.new()
	value_label.name = "Value"
	value_label.text = str(value)
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", color)
	container.add_child(value_label)

	return container


func _on_story_currency_changed(currency: String, new_amount: int) -> void:
	if currency == "slime_essence" and essence_display:
		essence_display.text = str(new_amount)
		# Animate
		var tween = create_tween()
		tween.tween_property(essence_display, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(essence_display, "scale", Vector2.ONE, 0.1)


func _on_upgrades_pressed() -> void:
	AudioManager.play_sfx("button")

	# Disable game board input while menu is open
	if game_board:
		game_board.is_input_enabled = false

	# Instance and show progression menu
	var menu = progression_menu_scene.instantiate()
	menu.closed.connect(_on_progression_menu_closed)
	$UILayer.add_child(menu)

	# Fade in
	menu.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(menu, "modulate:a", 1.0, 0.3)


func _on_progression_menu_closed() -> void:
	# Re-enable game board input
	if game_board:
		game_board.is_input_enabled = true
