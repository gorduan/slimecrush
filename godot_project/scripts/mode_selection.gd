extends Control
## Mode Selection Screen - Choose game mode and save slot

const MODE_ENDLESS = SaveManager.MODE_ENDLESS
const MODE_STORY = SaveManager.MODE_STORY

var selected_mode: String = MODE_ENDLESS
var slot_buttons: Array[Button] = []

@onready var endless_button: Button = $VBoxContainer/ModeButtons/EndlessButton
@onready var story_button: Button = $VBoxContainer/ModeButtons/StoryButton
@onready var slots_container: VBoxContainer = $VBoxContainer/SlotsContainer
@onready var highscores_button: Button = $VBoxContainer/HighscoresButton
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	_setup_mode_buttons()
	_update_slots_display()

	highscores_button.pressed.connect(_on_highscores_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _setup_mode_buttons() -> void:
	endless_button.pressed.connect(func(): _select_mode(MODE_ENDLESS))
	story_button.pressed.connect(func(): _select_mode(MODE_STORY))
	_highlight_selected_mode()


func _select_mode(mode: String) -> void:
	selected_mode = mode
	_highlight_selected_mode()
	_update_slots_display()


func _highlight_selected_mode() -> void:
	# Reset colors
	endless_button.modulate = Color.WHITE
	story_button.modulate = Color.WHITE

	# Highlight selected
	if selected_mode == MODE_ENDLESS:
		endless_button.modulate = Color(1, 0.84, 0.34)  # Golden
	else:
		story_button.modulate = Color(1, 0.84, 0.34)


func _update_slots_display() -> void:
	# Clear existing slot buttons
	for child in slots_container.get_children():
		if child is Button:
			child.queue_free()
	slot_buttons.clear()

	# Create slot buttons
	for slot in range(1, SaveManager.NUM_SLOTS + 1):
		var btn = _create_slot_button(slot)
		slots_container.add_child(btn)
		slot_buttons.append(btn)


func _create_slot_button(slot: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(400, 70)
	btn.add_theme_font_size_override("font_size", 20)

	var data = SaveManager.get_slot_data(selected_mode, slot)

	if data.is_empty:
		btn.text = "Slot %d: Leer" % slot
		btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		var score = data.score
		var level = data.max_level
		btn.text = "Slot %d: %d Punkte, Level %d" % [slot, score, level]
		btn.add_theme_color_override("font_color", Color.WHITE)

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.set_corner_radius_all(15)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.3, 0.3, 0.35, 0.9)
	hover_style.set_corner_radius_all(15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(1, 0.42, 0.42, 0.9)
	pressed_style.set_corner_radius_all(15)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.pressed.connect(func(): _on_slot_selected(slot))

	return btn


func _on_slot_selected(slot: int) -> void:
	# Story mode coming soon
	if selected_mode == MODE_STORY:
		_show_coming_soon()
		return

	# Set active slot and start game
	SaveManager.set_active_slot(selected_mode, slot)

	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _show_coming_soon() -> void:
	# Quick flash message
	var label = Label.new()
	label.text = "Coming Soon!"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(1, 0.84, 0.34))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchors_preset = Control.PRESET_CENTER
	label.position = Vector2(-100, 0)
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 1.5)
	await tween.finished
	label.queue_free()


func _on_highscores_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/highscore_menu.tscn")


func _on_back_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
