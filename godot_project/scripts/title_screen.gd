extends Control
## Title Screen - First screen shown on app start
## Tap anywhere to continue to mode selection

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var tap_label: Label = $CenterContainer/VBoxContainer/TapLabel

var pulse_tween: Tween


func _ready() -> void:
	_start_pulse_animation()


func _start_pulse_animation() -> void:
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(tap_label, "modulate:a", 0.3, 0.8)
	pulse_tween.tween_property(tap_label, "modulate:a", 1.0, 0.8)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_go_to_mode_selection()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_mode_selection()


func _go_to_mode_selection() -> void:
	if pulse_tween:
		pulse_tween.kill()

	# Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/mode_selection.tscn")
