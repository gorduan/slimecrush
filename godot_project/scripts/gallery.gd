extends Control
class_name Gallery
## Gallery - Display unlocked images in a grid

const ALL_IMAGES: Array = [1, 2, 3, 4, 5, 6]
const THUMBNAIL_SIZE: Vector2 = Vector2(200, 150)
const GRID_COLUMNS: int = 2

var image_buttons: Array[Control] = []
var image_viewer_open: bool = false

@onready var back_button: Button = $TopBar/BackButton
@onready var title_label: Label = $TopBar/Title
@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var image_viewer: Control = $ImageViewer
@onready var viewer_image: TextureRect = $ImageViewer/ViewerImage
@onready var viewer_close: Button = $ImageViewer/CloseButton
@onready var counter_label: Label = $TopBar/CounterLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	viewer_close.pressed.connect(_close_image_viewer)
	image_viewer.visible = false

	_setup_grid()
	_update_counter()


func _setup_grid() -> void:
	grid_container.columns = GRID_COLUMNS

	var unlocked = SaveManager.get_unlocked_images()

	for img_id in ALL_IMAGES:
		var is_unlocked = img_id in unlocked
		var container = _create_image_slot(img_id, is_unlocked)
		grid_container.add_child(container)
		image_buttons.append(container)


func _create_image_slot(img_id: int, is_unlocked: bool) -> Control:
	var container = Control.new()
	container.custom_minimum_size = THUMBNAIL_SIZE + Vector2(20, 20)

	# Background panel
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 5
	panel.offset_top = 5
	panel.offset_right = -5
	panel.offset_bottom = -5

	var style = StyleBoxFlat.new()
	style.set_corner_radius_all(12)

	if is_unlocked:
		style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
		style.border_color = Color(1, 0.84, 0.34, 0.8)  # Golden
	else:
		style.bg_color = Color(0.15, 0.15, 0.18, 0.9)
		style.border_color = Color(0.3, 0.3, 0.35, 0.5)

	style.set_border_width_all(3)
	panel.add_theme_stylebox_override("panel", style)
	container.add_child(panel)

	if is_unlocked:
		# Show thumbnail
		var thumb = TextureRect.new()
		thumb.set_anchors_preset(Control.PRESET_FULL_RECT)
		thumb.offset_left = 10
		thumb.offset_top = 10
		thumb.offset_right = -10
		thumb.offset_bottom = -10
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

		var img_path = "res://assets/gallery/%d.png" % img_id
		var texture = load(img_path)
		if texture:
			thumb.texture = texture

		thumb.mouse_filter = Control.MOUSE_FILTER_STOP
		thumb.gui_input.connect(_on_image_input.bind(img_id))

		container.add_child(thumb)
	else:
		# Show lock icon
		var lock_label = Label.new()
		lock_label.set_anchors_preset(Control.PRESET_CENTER)
		lock_label.text = "?"
		lock_label.add_theme_font_size_override("font_size", 48)
		lock_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		container.add_child(lock_label)

		# Number label
		var num_label = Label.new()
		num_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		num_label.offset_top = -30
		num_label.text = "Bild %d" % img_id
		num_label.add_theme_font_size_override("font_size", 14)
		num_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(num_label)

	return container


func _update_counter() -> void:
	var unlocked = SaveManager.get_unlocked_images()
	counter_label.text = "%d / 6" % unlocked.size()


func _on_image_input(event: InputEvent, img_id: int) -> void:
	if image_viewer_open:
		return

	var is_tap = false
	if event is InputEventMouseButton:
		is_tap = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		is_tap = event.pressed

	if is_tap:
		_show_image_viewer(img_id)


func _show_image_viewer(img_id: int) -> void:
	image_viewer_open = true

	# Load full image
	var img_path = "res://assets/gallery/%d.png" % img_id
	var texture = load(img_path)
	if texture:
		viewer_image.texture = texture

	# Show viewer with fade
	image_viewer.visible = true
	image_viewer.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(image_viewer, "modulate:a", 1.0, 0.2)

	AudioManager.play_sfx("button")


func _close_image_viewer() -> void:
	var tween = create_tween()
	tween.tween_property(image_viewer, "modulate:a", 0.0, 0.2)
	await tween.finished

	image_viewer.visible = false
	image_viewer_open = false

	AudioManager.play_sfx("button")


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	get_tree().change_scene_to_file("res://scenes/mode_selection.tscn")
