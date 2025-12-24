extends Control
## Mode Selection Screen - Choose game mode and save slot

const MODE_ENDLESS = SaveManager.MODE_ENDLESS
const MODE_SAGA = SaveManager.MODE_SAGA
const MODE_STORY = SaveManager.MODE_STORY

var selected_mode: String = MODE_ENDLESS
var slot_buttons: Array[Button] = []
var pending_delete_slot: int = -1  # Slot pending deletion confirmation
var gallery_button: Button = null

@onready var endless_button: Button = $VBoxContainer/ModeButtons/EndlessButton
@onready var saga_button: Button = $VBoxContainer/ModeButtons/SagaButton
@onready var story_button: Button = $VBoxContainer/ModeButtons/StoryButton
@onready var slots_container: VBoxContainer = $VBoxContainer/SlotsContainer
@onready var highscores_button: Button = $VBoxContainer/HighscoresButton
@onready var back_button: Button = $VBoxContainer/BackButton
var delete_dialog: ConfirmationDialog = null  # Created dynamically


func _ready() -> void:
	_setup_mode_buttons()
	_update_slots_display()
	_setup_delete_dialog()
	_setup_gallery_button()

	highscores_button.pressed.connect(_on_highscores_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _setup_delete_dialog() -> void:
	# Create delete confirmation dialog
	delete_dialog = ConfirmationDialog.new()
	delete_dialog.name = "DeleteConfirmDialog"
	delete_dialog.title = "Slot löschen"
	delete_dialog.dialog_text = "Möchtest du diesen Spielstand wirklich löschen?\nDies kann nicht rückgängig gemacht werden!"
	delete_dialog.ok_button_text = "Löschen"
	delete_dialog.cancel_button_text = "Abbrechen"
	delete_dialog.size = Vector2(400, 150)
	add_child(delete_dialog)

	delete_dialog.confirmed.connect(_on_delete_confirmed)
	delete_dialog.canceled.connect(_on_delete_canceled)


func _setup_mode_buttons() -> void:
	endless_button.pressed.connect(func(): _select_mode(MODE_ENDLESS))
	saga_button.pressed.connect(func(): _select_mode(MODE_SAGA))
	story_button.pressed.connect(func(): _select_mode(MODE_STORY))
	_highlight_selected_mode()


func _select_mode(mode: String) -> void:
	selected_mode = mode
	_highlight_selected_mode()
	_update_slots_display()


func _highlight_selected_mode() -> void:
	# Reset colors
	endless_button.modulate = Color.WHITE
	saga_button.modulate = Color.WHITE
	story_button.modulate = Color.WHITE

	# Highlight selected
	match selected_mode:
		MODE_ENDLESS:
			endless_button.modulate = Color(1, 0.84, 0.34)  # Golden
		MODE_SAGA:
			saga_button.modulate = Color(1, 0.84, 0.34)
		MODE_STORY:
			story_button.modulate = Color(1, 0.84, 0.34)


func _update_slots_display() -> void:
	# Clear existing slot rows
	for child in slots_container.get_children():
		child.queue_free()
	slot_buttons.clear()

	# Create slot rows (button + delete button)
	for slot in range(1, SaveManager.NUM_SLOTS + 1):
		var row = _create_slot_row(slot)
		slots_container.add_child(row)


func _create_slot_row(slot: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	# Create main slot button
	var btn = _create_slot_button(slot)
	row.add_child(btn)
	slot_buttons.append(btn)

	# Create delete button or placeholder (for consistent alignment)
	var is_empty = _is_slot_empty(slot)
	if not is_empty:
		var delete_btn = _create_delete_button(slot)
		row.add_child(delete_btn)
	else:
		# Add invisible placeholder to maintain alignment
		var placeholder = Control.new()
		placeholder.custom_minimum_size = Vector2(50, 70)
		row.add_child(placeholder)

	return row


func _is_slot_empty(slot: int) -> bool:
	if selected_mode == MODE_SAGA:
		var data = SaveManager.get_saga_slot_data(slot)
		return data.is_empty
	elif selected_mode == MODE_STORY:
		# Use SaveManager's is_slot_empty which checks essence, completed levels, and skill nodes
		return SaveManager.is_slot_empty(MODE_STORY, slot)
	else:
		var data = SaveManager.get_slot_data(selected_mode, slot)
		return data.is_empty


func _create_slot_button(slot: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(340, 70)
	btn.add_theme_font_size_override("font_size", 20)

	if selected_mode == MODE_SAGA:
		var data = SaveManager.get_saga_slot_data(slot)
		if data.is_empty:
			btn.text = "Slot %d: Leer" % slot
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		else:
			var saga_level = data.level
			var world = int((saga_level - 1) / 10) + 1  # World changes every 10 levels
			btn.text = "Slot %d: Level %d (Welt %d)" % [slot, saga_level, world]
			btn.add_theme_color_override("font_color", Color.WHITE)
	elif selected_mode == MODE_STORY:
		# Story mode shows campaign progress and currencies for THIS SLOT
		var progression = SaveManager.load_story_progression_for_slot(slot)
		var campaign = progression.get("campaign", {})
		var currencies = progression.get("currencies", {})
		var chapter = campaign.get("current_chapter", 1)
		var level = campaign.get("current_level", 1)
		var essence = currencies.get("slime_essence", 0)

		if campaign.get("completed_levels", []).is_empty():
			btn.text = "Slot %d: New Game" % slot
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		else:
			btn.text = "Slot %d: Ch.%d Lv.%d | %d Essence" % [slot, chapter, level, essence]
			btn.add_theme_color_override("font_color", Color.WHITE)
	else:
		# Endless mode
		var data = SaveManager.get_slot_data(selected_mode, slot)
		if data.is_empty:
			btn.text = "Slot %d: Leer" % slot
			btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		else:
			var current_level = data.level
			var max_level = data.max_level
			btn.text = "Slot %d: Level %d (Best: %d)" % [slot, current_level, max_level]
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


func _create_delete_button(slot: int) -> Button:
	var btn = Button.new()
	btn.text = "X"
	btn.custom_minimum_size = Vector2(50, 70)
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(1, 0.4, 0.4))

	# Style - red background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.15, 0.15, 0.9)
	style.set_corner_radius_all(15)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.6, 0.2, 0.2, 0.9)
	hover_style.set_corner_radius_all(15)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.8, 0.25, 0.25, 0.9)
	pressed_style.set_corner_radius_all(15)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.pressed.connect(func(): _on_delete_slot_pressed(slot))

	return btn


func _on_slot_selected(slot: int) -> void:
	# Set active slot and start game
	SaveManager.set_active_slot(selected_mode, slot)

	# Story mode: Load progression and go to game
	if selected_mode == MODE_STORY:
		ProgressionManager.load_progression()

	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Saga mode goes to world map, others go directly to game
	if selected_mode == MODE_SAGA:
		get_tree().change_scene_to_file("res://scenes/saga_world_map.tscn")
	else:
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


# ============ DELETE SLOT FUNCTIONS ============

func _on_delete_slot_pressed(slot: int) -> void:
	pending_delete_slot = slot
	delete_dialog.dialog_text = "Möchtest du Slot %d wirklich löschen?\nDies kann nicht rückgängig gemacht werden!" % slot
	delete_dialog.popup_centered()
	AudioManager.play_sfx("button")


func _on_delete_confirmed() -> void:
	if pending_delete_slot > 0:
		# If deleting a story mode slot, always reset ProgressionManager
		# (will be reloaded when slot is selected again)
		if selected_mode == MODE_STORY:
			# Temporarily set active slot to the one being deleted so reset works
			var old_active = SaveManager.active_slot
			SaveManager.active_slot = pending_delete_slot
			ProgressionManager.reset_progression()
			SaveManager.active_slot = old_active

		# Delete the slot data
		SaveManager.delete_slot(selected_mode, pending_delete_slot)
		pending_delete_slot = -1

		# Refresh the display
		_update_slots_display()

		# Play confirmation sound
		AudioManager.play_sfx("combo")


func _on_delete_canceled() -> void:
	pending_delete_slot = -1


# ============ GALLERY BUTTON ============

func _setup_gallery_button() -> void:
	# Only show gallery button if images are unlocked
	if not SaveManager.has_unlocked_images():
		return

	gallery_button = Button.new()
	gallery_button.text = "Galerie"
	gallery_button.custom_minimum_size = Vector2(340, 60)
	gallery_button.add_theme_font_size_override("font_size", 22)

	# Purple style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.3, 0.7, 0.9)
	style.set_corner_radius_all(15)
	gallery_button.add_theme_stylebox_override("normal", style)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.6, 0.4, 0.8, 0.9)
	hover_style.set_corner_radius_all(15)
	gallery_button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.7, 0.5, 0.9, 0.9)
	pressed_style.set_corner_radius_all(15)
	gallery_button.add_theme_stylebox_override("pressed", pressed_style)

	gallery_button.pressed.connect(_on_gallery_pressed)

	# Add between highscores and back buttons
	var vbox = $VBoxContainer
	var index = highscores_button.get_index() + 1
	vbox.add_child(gallery_button)
	vbox.move_child(gallery_button, index)


func _on_gallery_pressed() -> void:
	AudioManager.play_sfx("button")

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/gallery.tscn")
