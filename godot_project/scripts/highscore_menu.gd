extends Control
## Highscore Menu - Shows top scores for each game mode

const MODE_ENDLESS = SaveManager.MODE_ENDLESS
const MODE_STORY = SaveManager.MODE_STORY

var selected_mode: String = MODE_ENDLESS

@onready var endless_tab: Button = $VBoxContainer/TabButtons/EndlessTab
@onready var story_tab: Button = $VBoxContainer/TabButtons/StoryTab
@onready var scores_container: VBoxContainer = $VBoxContainer/ScoresContainer
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	endless_tab.pressed.connect(func(): _select_mode(MODE_ENDLESS))
	story_tab.pressed.connect(func(): _select_mode(MODE_STORY))
	back_button.pressed.connect(_on_back_pressed)

	_highlight_selected_tab()
	_update_scores_display()


func _select_mode(mode: String) -> void:
	selected_mode = mode
	_highlight_selected_tab()
	_update_scores_display()


func _highlight_selected_tab() -> void:
	endless_tab.modulate = Color.WHITE
	story_tab.modulate = Color.WHITE

	if selected_mode == MODE_ENDLESS:
		endless_tab.modulate = Color(1, 0.84, 0.34)
	else:
		story_tab.modulate = Color(1, 0.84, 0.34)


func _update_scores_display() -> void:
	# Clear existing
	for child in scores_container.get_children():
		child.queue_free()

	var scores = SaveManager.get_highscores(selected_mode)

	for i in range(scores.size()):
		var score = scores[i]
		var rank = i + 1

		var row = _create_score_row(rank, score)
		scores_container.add_child(row)

	# If no scores yet
	if scores.size() == 0 or scores[0] == 0:
		var empty_label = Label.new()
		empty_label.text = "Noch keine Highscores"
		empty_label.add_theme_font_size_override("font_size", 24)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scores_container.add_child(empty_label)


func _create_score_row(rank: int, score: int) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)

	# Rank
	var rank_label = Label.new()
	rank_label.custom_minimum_size = Vector2(60, 0)
	rank_label.add_theme_font_size_override("font_size", 32)

	match rank:
		1:
			rank_label.text = "🥇"
			rank_label.add_theme_color_override("font_color", Color(1, 0.84, 0.0))
		2:
			rank_label.text = "🥈"
			rank_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		3:
			rank_label.text = "🥉"
			rank_label.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))

	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(rank_label)

	# Score
	var score_label = Label.new()
	score_label.custom_minimum_size = Vector2(200, 0)
	score_label.add_theme_font_size_override("font_size", 36)

	if score > 0:
		score_label.text = "%d" % score
		score_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		score_label.text = "---"
		score_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))

	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(score_label)

	return row


func _on_back_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/mode_selection.tscn")
