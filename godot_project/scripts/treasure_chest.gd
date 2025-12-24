extends Control
class_name TreasureChest
## TreasureChest - Animated treasure chest popup that reveals gallery images

signal chest_completed

const ALL_IMAGES: Array = [1, 2, 3, 4, 5, 6]
const CARD_SIZE: Vector2 = Vector2(180, 240)
const CARD_SPACING: float = 200.0

var milestone: int = 0
var selected_images: Array = []
var cards: Array[TextureRect] = []
var chest_opened: bool = false
var image_viewer_open: bool = false

@onready var background: ColorRect = $Background
@onready var chest_container: Control = $ChestContainer
@onready var chest_sprite: TextureRect = $ChestContainer/ChestSprite
@onready var tap_label: Label = $ChestContainer/TapLabel
@onready var cards_container: Control = $CardsContainer
@onready var continue_button: Button = $ContinueButton
@onready var image_viewer: Control = $ImageViewer
@onready var viewer_image: TextureRect = $ImageViewer/ViewerImage
@onready var viewer_close: Button = $ImageViewer/CloseButton


func _ready() -> void:
	# Initial state
	background.modulate.a = 0.0
	chest_container.scale = Vector2.ZERO
	cards_container.visible = false
	continue_button.visible = false
	image_viewer.visible = false

	# Connect signals
	continue_button.pressed.connect(_on_continue_pressed)
	viewer_close.pressed.connect(_close_image_viewer)

	# Make chest clickable
	chest_sprite.gui_input.connect(_on_chest_input)

	# Select which images to reveal
	selected_images = _get_random_new_images()

	# Start entrance animation
	_animate_entrance()


func _get_random_new_images() -> Array:
	var unlocked = SaveManager.get_unlocked_images()
	var available: Array = []

	for img_id in ALL_IMAGES:
		if not img_id in unlocked:
			available.append(img_id)

	# If 3 or fewer available, return all
	if available.size() <= 3:
		return available

	# Otherwise pick 3 random ones
	available.shuffle()
	return available.slice(0, 3)


func _animate_entrance() -> void:
	# Fade in background
	var tween = create_tween()
	tween.tween_property(background, "modulate:a", 1.0, 0.3)

	await get_tree().create_timer(0.2).timeout

	# Chest zoom in with bounce
	var chest_tween = create_tween()
	chest_tween.tween_property(chest_container, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT)
	chest_tween.tween_property(chest_container, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_IN_OUT)

	await chest_tween.finished

	# Shake effect
	_shake_chest()

	# Play sound
	AudioManager.play_sfx("combo")
	AudioManager.vibrate(100)


func _shake_chest() -> void:
	var shake_tween = create_tween()
	for i in range(3):
		shake_tween.tween_property(chest_container, "rotation_degrees", 5.0, 0.05)
		shake_tween.tween_property(chest_container, "rotation_degrees", -5.0, 0.1)
		shake_tween.tween_property(chest_container, "rotation_degrees", 0.0, 0.05)


func _on_chest_input(event: InputEvent) -> void:
	if chest_opened:
		return

	var is_tap = false
	if event is InputEventMouseButton:
		is_tap = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	elif event is InputEventScreenTouch:
		is_tap = event.pressed

	if is_tap:
		_open_chest()


func _open_chest() -> void:
	chest_opened = true
	tap_label.visible = false

	# Play open sound
	AudioManager.play_sfx("special")
	AudioManager.vibrate(200)

	# Animate chest opening (scale pulse)
	var open_tween = create_tween()
	open_tween.tween_property(chest_container, "scale", Vector2(1.3, 1.3), 0.2)
	open_tween.tween_property(chest_container, "scale", Vector2(0.8, 0.8), 0.3)
	open_tween.tween_property(chest_container, "modulate:a", 0.3, 0.2)

	await open_tween.finished

	# Show cards container
	cards_container.visible = true

	# Create and animate cards
	await _create_and_animate_cards()

	# Save unlocked images
	SaveManager.unlock_images(selected_images)
	SaveManager.claim_chest_milestone(milestone)

	# Show continue button
	continue_button.visible = true
	continue_button.modulate.a = 0.0
	var btn_tween = create_tween()
	btn_tween.tween_property(continue_button, "modulate:a", 1.0, 0.3)


func _create_and_animate_cards() -> void:
	var center = cards_container.size / 2
	var num_cards = selected_images.size()

	# Calculate starting positions (all cards start at center)
	var start_pos = center - CARD_SIZE / 2

	# Calculate end positions (spread horizontally)
	var total_width = (num_cards - 1) * CARD_SPACING
	var start_x = center.x - total_width / 2 - CARD_SIZE.x / 2

	for i in range(num_cards):
		var img_id = selected_images[i]

		# Create card
		var card = TextureRect.new()
		card.custom_minimum_size = CARD_SIZE
		card.size = CARD_SIZE
		card.position = start_pos
		card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		card.pivot_offset = CARD_SIZE / 2
		card.scale = Vector2.ZERO
		card.rotation_degrees = randf_range(-30, 30)

		# Load image
		var img_path = "res://assets/gallery/%d.png" % img_id
		var texture = load(img_path)
		if texture:
			card.texture = texture

		# Make clickable
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.gui_input.connect(_on_card_input.bind(img_id))

		# Style - add border
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE
		style.set_border_width_all(4)
		style.border_color = Color(1, 0.84, 0.34)  # Golden
		style.set_corner_radius_all(8)

		cards_container.add_child(card)
		cards.append(card)

		# Animate card flying out
		var end_x = start_x + i * CARD_SPACING
		var end_pos = Vector2(end_x, center.y - CARD_SIZE.y / 2 - 30)

		await get_tree().create_timer(0.15).timeout

		var card_tween = create_tween()
		card_tween.set_parallel(true)
		card_tween.tween_property(card, "position", end_pos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		card_tween.tween_property(card, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)
		card_tween.tween_property(card, "rotation_degrees", 0.0, 0.3)

		AudioManager.play_sfx("button")


func _on_card_input(event: InputEvent, img_id: int) -> void:
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


func _on_continue_pressed() -> void:
	AudioManager.play_sfx("button")

	# Fade out everything
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	chest_completed.emit()
	queue_free()
