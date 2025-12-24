extends Control
## CheatMenu - Debug menu for spawning slimes and game cheats
## Allows selecting color/special type and replacing slimes on the board

signal closed
signal spawn_mode_changed(active: bool, color: GameManager.SlimeColor, special: GameManager.SpecialType)
signal grid_toggled(active: bool)

@onready var selection_info: Label = $Panel/VBox/SelectionInfo
@onready var mode_label: Label = $Panel/VBox/ModeLabel
@onready var grid_button: Button = $Panel/VBox/GameButtons/GridButton

# Currently selected slime configuration
var selected_color: GameManager.SlimeColor = GameManager.SlimeColor.RED
var selected_special: GameManager.SpecialType = GameManager.SpecialType.NONE
var spawn_mode_active: bool = false
var grid_active: bool = false

# Reference to game board (set by parent)
var game_board: Node2D = null

# Reference to world map for grid overlay
var world_map: Node2D = null

# Color names for display
const COLOR_NAMES = ["RED", "ORANGE", "YELLOW", "GREEN", "BLUE", "PURPLE"]
const SPECIAL_NAMES = ["NORMAL", "STRIPED H", "STRIPED V", "WRAPPED", "COLOR BOMB"]


func _ready() -> void:
	_update_selection_display()
	# Start with spawn mode active
	spawn_mode_active = true
	_update_mode_display()


func _update_selection_display() -> void:
	var color_name = COLOR_NAMES[selected_color]
	var special_name = SPECIAL_NAMES[selected_special]
	selection_info.text = "Selected: %s - %s" % [color_name, special_name]


func _update_mode_display() -> void:
	if spawn_mode_active:
		mode_label.text = "Tap a cell on the board to replace slime"
		mode_label.add_theme_color_override("font_color", Color(0.15, 0.87, 0.51, 1))
	else:
		mode_label.text = "Spawn mode inactive"
		mode_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))


# Game cheat buttons
func _on_win_pressed() -> void:
	AudioManager.play_sfx("button")
	GameManager.score = GameManager.target_score + 100
	GameManager.check_win_condition()


func _on_add_score_pressed() -> void:
	AudioManager.play_sfx("button")
	GameManager.add_score(1000)


func _on_add_moves_pressed() -> void:
	AudioManager.play_sfx("button")
	GameManager.moves += 10


func _on_shuffle_pressed() -> void:
	AudioManager.play_sfx("button")
	if game_board and game_board.has_method("_shuffle_board"):
		game_board._shuffle_board()


func _on_grid_pressed() -> void:
	AudioManager.play_sfx("button")
	grid_active = not grid_active

	# Update button visual
	if grid_button:
		if grid_active:
			grid_button.add_theme_color_override("font_color", Color(0.15, 0.87, 0.51, 1))
		else:
			grid_button.remove_theme_color_override("font_color")

	# Toggle grid on world map
	if world_map and world_map.has_method("toggle_debug_grid"):
		world_map.toggle_debug_grid(grid_active)

	grid_toggled.emit(grid_active)


# Color selection
func _on_color_selected(color_index: int) -> void:
	AudioManager.play_sfx("button")
	selected_color = color_index as GameManager.SlimeColor
	_update_selection_display()
	spawn_mode_changed.emit(spawn_mode_active, selected_color, selected_special)


# Special type selection
func _on_special_selected(special_index: int) -> void:
	AudioManager.play_sfx("button")
	selected_special = special_index as GameManager.SpecialType
	_update_selection_display()
	spawn_mode_changed.emit(spawn_mode_active, selected_color, selected_special)


func _on_close_pressed() -> void:
	AudioManager.play_sfx("button")
	spawn_mode_active = false
	spawn_mode_changed.emit(false, selected_color, selected_special)
	closed.emit()


func _on_reset_all_pressed() -> void:
	AudioManager.play_sfx("button")
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "ALLE DATEN LÖSCHEN?\n\nDies setzt das Spiel auf Neuinstallations-Zustand zurück:\n- Alle Highscores\n- Alle Spielstände\n- Alle freigeschalteten Bilder\n- Story Fortschritt\n\nDiese Aktion kann NICHT rückgängig gemacht werden!"
	dialog.ok_button_text = "LÖSCHEN"
	dialog.cancel_button_text = "Abbrechen"
	dialog.confirmed.connect(_confirm_reset_all.bind(dialog))
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()


func _confirm_reset_all(dialog: ConfirmationDialog) -> void:
	dialog.queue_free()

	# Delete all save data
	SaveManager.reset_all_data()

	# Reset ProgressionManager if available
	if ProgressionManager and ProgressionManager.has_method("reset_progression"):
		ProgressionManager.reset_progression()

	AudioManager.play_sfx("special")
	AudioManager.vibrate(300)

	# Return to title screen
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


# Called by game_board when a cell is tapped in spawn mode
func get_spawn_config() -> Dictionary:
	return {
		"active": spawn_mode_active,
		"color": selected_color,
		"special": selected_special
	}
