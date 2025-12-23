extends Control
## ProgressionMenu - Story Mode upgrade and ability shop
## Allows purchasing upgrades and abilities with currencies

signal closed()

enum Tab { UPGRADES, ABILITIES, MASTERY }

var current_tab: Tab = Tab.UPGRADES
var current_category: String = "scoring"

const UpgradeDefs = preload("res://resources/upgrade_definitions.gd")

# Tab buttons
@onready var upgrades_tab: Button = $VBoxContainer/TabBar/UpgradesTab
@onready var abilities_tab: Button = $VBoxContainer/TabBar/AbilitiesTab
@onready var mastery_tab: Button = $VBoxContainer/TabBar/MasteryTab

# Currency display
@onready var essence_label: Label = $VBoxContainer/CurrencyBar/EssenceContainer/HBox/EssenceValue
@onready var stardust_label: Label = $VBoxContainer/CurrencyBar/StardustContainer/HBox/StardustValue
@onready var crystal_label: Label = $VBoxContainer/CurrencyBar/CrystalContainer/HBox/CrystalValue

# Content containers
@onready var content_container: VBoxContainer = $VBoxContainer/ScrollContainer/ContentContainer
@onready var category_bar: HBoxContainer = $VBoxContainer/CategoryBar
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer

# Back button
@onready var back_button: Button = $VBoxContainer/BackButton


func _ready() -> void:
	_setup_tab_buttons()
	_setup_back_button()
	_connect_progression_signals()
	_update_currency_display()
	_switch_to_tab(Tab.UPGRADES)


func _setup_tab_buttons() -> void:
	upgrades_tab.pressed.connect(func(): _switch_to_tab(Tab.UPGRADES))
	abilities_tab.pressed.connect(func(): _switch_to_tab(Tab.ABILITIES))
	mastery_tab.pressed.connect(func(): _switch_to_tab(Tab.MASTERY))


func _setup_back_button() -> void:
	back_button.pressed.connect(_on_back_pressed)


func _connect_progression_signals() -> void:
	ProgressionManager.currency_changed.connect(_on_currency_changed)
	ProgressionManager.upgrade_purchased.connect(_on_upgrade_purchased)
	ProgressionManager.ability_unlocked.connect(_on_ability_unlocked)


func _switch_to_tab(tab: Tab) -> void:
	current_tab = tab
	_highlight_active_tab()
	_update_category_bar()
	_populate_content()


func _highlight_active_tab() -> void:
	# Reset all tabs
	upgrades_tab.modulate = Color.WHITE
	abilities_tab.modulate = Color.WHITE
	mastery_tab.modulate = Color.WHITE

	# Highlight selected
	match current_tab:
		Tab.UPGRADES:
			upgrades_tab.modulate = Color(1, 0.84, 0.34)  # Golden
		Tab.ABILITIES:
			abilities_tab.modulate = Color(1, 0.84, 0.34)
		Tab.MASTERY:
			mastery_tab.modulate = Color(1, 0.84, 0.34)


func _update_category_bar() -> void:
	# Clear existing category buttons
	for child in category_bar.get_children():
		child.queue_free()

	if current_tab == Tab.UPGRADES:
		# Show upgrade category buttons
		var categories = UpgradeDefs.get_all_categories()
		for cat in categories:
			var btn = _create_category_button(cat)
			category_bar.add_child(btn)
		category_bar.visible = true
		current_category = "scoring" if current_category not in categories else current_category
	else:
		category_bar.visible = false


func _create_category_button(category: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(80, 40)
	btn.add_theme_font_size_override("font_size", 14)

	# Localization-ready category names
	var cat_names = {
		"scoring": tr("CAT_SCORING"),
		"moves": tr("CAT_MOVES"),
		"specials": tr("CAT_SPECIALS"),
		"combos": tr("CAT_COMBOS")
	}
	btn.text = cat_names.get(category, category.capitalize())

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.25, 0.3, 0.9)
	style.set_corner_radius_all(10)
	btn.add_theme_stylebox_override("normal", style)

	if category == current_category:
		btn.modulate = Color(1, 0.84, 0.34)

	btn.pressed.connect(func(): _select_category(category))

	return btn


func _select_category(category: String) -> void:
	current_category = category
	_update_category_bar()
	_populate_content()


func _populate_content() -> void:
	# Clear existing content
	for child in content_container.get_children():
		child.queue_free()

	match current_tab:
		Tab.UPGRADES:
			_populate_upgrades()
		Tab.ABILITIES:
			_populate_abilities()
		Tab.MASTERY:
			_populate_mastery()


func _populate_upgrades() -> void:
	var upgrades = UpgradeDefs.get_all_upgrades_in_category(current_category)

	for upgrade_id in upgrades:
		var item = _create_upgrade_item(current_category, upgrade_id)
		content_container.add_child(item)


func _create_upgrade_item(category: String, upgrade_id: String) -> Control:
	var definition = UpgradeDefs.get_upgrade(category, upgrade_id)
	var current_level = ProgressionManager.get_upgrade_level(category, upgrade_id)
	var max_level = definition.get("max_level", 1)
	var is_maxed = current_level >= max_level

	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(0, 100)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(15)
	container.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	container.add_child(hbox)

	# Info section
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name
	var name_label = Label.new()
	name_label.text = definition.get("name", upgrade_id)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color(1, 0.84, 0.34))
	info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = definition.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	# Level progress
	var level_label = Label.new()
	level_label.text = "Level %d / %d" % [current_level, max_level]
	level_label.add_theme_font_size_override("font_size", 16)
	if is_maxed:
		level_label.add_theme_color_override("font_color", Color(0.15, 0.87, 0.51))
	else:
		level_label.add_theme_color_override("font_color", Color.WHITE)
	info_vbox.add_child(level_label)

	# Effect preview
	var effect_label = Label.new()
	effect_label.text = definition.get("effect_description", "")
	effect_label.add_theme_font_size_override("font_size", 12)
	effect_label.add_theme_color_override("font_color", Color(0.45, 0.67, 0.95))
	info_vbox.add_child(effect_label)

	# Buy button section
	var buy_vbox = VBoxContainer.new()
	buy_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(buy_vbox)

	if is_maxed:
		var max_label = Label.new()
		max_label.text = "MAX"
		max_label.add_theme_font_size_override("font_size", 24)
		max_label.add_theme_color_override("font_color", Color(0.15, 0.87, 0.51))
		buy_vbox.add_child(max_label)
	else:
		var cost = UpgradeDefs.calculate_upgrade_cost(category, upgrade_id, current_level)
		var cost_type = definition.get("cost_type", "slime_essence")
		var can_afford = ProgressionManager.can_afford_upgrade(category, upgrade_id)

		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(100, 50)
		buy_btn.add_theme_font_size_override("font_size", 16)

		var cost_icon = "✧" if cost_type == "star_dust" else "◆"
		buy_btn.text = "%s %d" % [cost_icon, cost]

		var btn_style = StyleBoxFlat.new()
		if can_afford:
			btn_style.bg_color = Color(0.15, 0.65, 0.35, 1)
		else:
			btn_style.bg_color = Color(0.4, 0.4, 0.4, 1)
		btn_style.set_corner_radius_all(10)
		buy_btn.add_theme_stylebox_override("normal", btn_style)

		buy_btn.disabled = not can_afford
		buy_btn.pressed.connect(func(): _purchase_upgrade(category, upgrade_id))

		buy_vbox.add_child(buy_btn)

	return container


func _populate_abilities() -> void:
	var abilities = UpgradeDefs.get_all_abilities()

	for ability_id in abilities:
		var item = _create_ability_item(ability_id)
		content_container.add_child(item)


func _create_ability_item(ability_id: String) -> Control:
	var definition = UpgradeDefs.get_ability(ability_id)
	var is_unlocked = ProgressionManager.is_ability_unlocked(ability_id)
	var current_level = ProgressionManager.get_ability_level(ability_id)
	var max_level = definition.get("max_level", 0)
	var is_maxed = current_level >= max_level and max_level > 0

	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(0, 110)

	var style = StyleBoxFlat.new()
	if is_unlocked:
		style.bg_color = Color(0.15, 0.2, 0.25, 0.95)
	else:
		style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(15)
	container.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	container.add_child(hbox)

	# Info section
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name
	var name_label = Label.new()
	name_label.text = definition.get("name", ability_id)
	name_label.add_theme_font_size_override("font_size", 20)
	if is_unlocked:
		name_label.add_theme_color_override("font_color", Color(0.65, 0.45, 0.95))
	else:
		name_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	info_vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.text = definition.get("description", "")
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(desc_label)

	# Uses per game
	if is_unlocked:
		var uses = definition.get("base_uses", 1) + (definition.get("upgrade_uses", 0) * current_level)
		var uses_label = Label.new()
		uses_label.text = "%d use(s) per game" % uses
		uses_label.add_theme_font_size_override("font_size", 14)
		uses_label.add_theme_color_override("font_color", Color(0.45, 0.67, 0.95))
		info_vbox.add_child(uses_label)

	# Buy/Upgrade button section
	var buy_vbox = VBoxContainer.new()
	buy_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(buy_vbox)

	if not is_unlocked:
		# Unlock button
		var unlock_cost = definition.get("unlock_cost", 0)
		var can_afford = ProgressionManager.currencies.star_dust >= unlock_cost

		var unlock_btn = Button.new()
		unlock_btn.custom_minimum_size = Vector2(100, 50)
		unlock_btn.add_theme_font_size_override("font_size", 16)
		unlock_btn.text = "✧ %d" % unlock_cost

		var btn_style = StyleBoxFlat.new()
		if can_afford:
			btn_style.bg_color = Color(0.55, 0.35, 0.85, 1)
		else:
			btn_style.bg_color = Color(0.4, 0.4, 0.4, 1)
		btn_style.set_corner_radius_all(10)
		unlock_btn.add_theme_stylebox_override("normal", btn_style)

		unlock_btn.disabled = not can_afford
		unlock_btn.pressed.connect(func(): _unlock_ability(ability_id))

		var label = Label.new()
		label.text = "UNLOCK"
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		buy_vbox.add_child(label)
		buy_vbox.add_child(unlock_btn)
	elif max_level > 0 and not is_maxed:
		# Upgrade button
		var upgrade_cost = definition.get("upgrade_cost", 0) * (current_level + 1)
		var can_afford = ProgressionManager.currencies.star_dust >= upgrade_cost

		var upgrade_btn = Button.new()
		upgrade_btn.custom_minimum_size = Vector2(100, 50)
		upgrade_btn.add_theme_font_size_override("font_size", 16)
		upgrade_btn.text = "✧ %d" % upgrade_cost

		var btn_style = StyleBoxFlat.new()
		if can_afford:
			btn_style.bg_color = Color(0.35, 0.55, 0.85, 1)
		else:
			btn_style.bg_color = Color(0.4, 0.4, 0.4, 1)
		btn_style.set_corner_radius_all(10)
		upgrade_btn.add_theme_stylebox_override("normal", btn_style)

		upgrade_btn.disabled = not can_afford
		upgrade_btn.pressed.connect(func(): _upgrade_ability(ability_id))

		var label = Label.new()
		label.text = "Lv.%d → %d" % [current_level, current_level + 1]
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		buy_vbox.add_child(label)
		buy_vbox.add_child(upgrade_btn)
	else:
		# Maxed or no upgrades
		var status_label = Label.new()
		if max_level == 0:
			status_label.text = "READY"
			status_label.add_theme_color_override("font_color", Color(0.65, 0.45, 0.95))
		else:
			status_label.text = "MAX"
			status_label.add_theme_color_override("font_color", Color(0.15, 0.87, 0.51))
		status_label.add_theme_font_size_override("font_size", 20)
		buy_vbox.add_child(status_label)

	return container


func _populate_mastery() -> void:
	var colors = ["red", "orange", "yellow", "green", "blue", "purple"]
	var color_display = {
		"red": {"name": tr("COLOR_RED"), "color": Color("#ff6b6b")},
		"orange": {"name": tr("COLOR_ORANGE"), "color": Color("#ffa502")},
		"yellow": {"name": tr("COLOR_YELLOW"), "color": Color("#feca57")},
		"green": {"name": tr("COLOR_GREEN"), "color": Color("#26de81")},
		"blue": {"name": tr("COLOR_BLUE"), "color": Color("#45aaf2")},
		"purple": {"name": tr("COLOR_PURPLE"), "color": Color("#a55eea")}
	}

	for color in colors:
		var item = _create_mastery_item(color, color_display[color])
		content_container.add_child(item)


func _create_mastery_item(color: String, display_data: Dictionary) -> Control:
	var current_level = ProgressionManager.get_color_mastery_level(color)
	var max_level = 5
	var is_maxed = current_level >= max_level

	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(0, 100)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(15)
	style.border_color = display_data.color
	style.set_border_width_all(2)
	container.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 15)
	container.add_child(hbox)

	# Color indicator
	var color_rect = ColorRect.new()
	color_rect.custom_minimum_size = Vector2(50, 50)
	color_rect.color = display_data.color
	hbox.add_child(color_rect)

	# Info section
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name
	var name_label = Label.new()
	name_label.text = "%s Mastery" % display_data.name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", display_data.color)
	info_vbox.add_child(name_label)

	# Level stars
	var stars_label = Label.new()
	var stars_text = ""
	for i in range(max_level):
		if i < current_level:
			stars_text += "★ "
		else:
			stars_text += "☆ "
	stars_label.text = stars_text
	stars_label.add_theme_font_size_override("font_size", 18)
	stars_label.add_theme_color_override("font_color", Color(1, 0.84, 0.34))
	info_vbox.add_child(stars_label)

	# Current effect
	var effect_texts = [
		"+10% points",
		"+5% essence",
		"5% Match-3 bonus",
		"+25% special damage",
		"More spawns"
	]
	if current_level > 0:
		var effect_label = Label.new()
		effect_label.text = "Current: " + effect_texts[current_level - 1]
		effect_label.add_theme_font_size_override("font_size", 12)
		effect_label.add_theme_color_override("font_color", Color(0.45, 0.67, 0.95))
		info_vbox.add_child(effect_label)

	# Buy button section
	var buy_vbox = VBoxContainer.new()
	buy_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(buy_vbox)

	if is_maxed:
		var max_label = Label.new()
		max_label.text = "MAX"
		max_label.add_theme_font_size_override("font_size", 24)
		max_label.add_theme_color_override("font_color", Color(0.15, 0.87, 0.51))
		buy_vbox.add_child(max_label)
	else:
		var cost = UpgradeDefs.get_color_mastery_cost(current_level + 1)
		var crystals = ProgressionManager.currencies.color_crystals.get(color, 0)
		var can_afford = crystals >= cost

		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(100, 50)
		buy_btn.add_theme_font_size_override("font_size", 16)
		buy_btn.text = "💎 %d" % cost

		var btn_style = StyleBoxFlat.new()
		if can_afford:
			btn_style.bg_color = display_data.color.darkened(0.3)
		else:
			btn_style.bg_color = Color(0.4, 0.4, 0.4, 1)
		btn_style.set_corner_radius_all(10)
		buy_btn.add_theme_stylebox_override("normal", btn_style)

		buy_btn.disabled = not can_afford
		buy_btn.pressed.connect(func(): _purchase_mastery(color))

		var label = Label.new()
		label.text = "%d/%d crystals" % [crystals, cost]
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		buy_vbox.add_child(buy_btn)
		buy_vbox.add_child(label)

	return container


func _update_currency_display() -> void:
	essence_label.text = str(ProgressionManager.currencies.slime_essence)
	stardust_label.text = str(ProgressionManager.currencies.star_dust)

	# Show total color crystals
	var total_crystals = 0
	for color in ProgressionManager.currencies.color_crystals:
		total_crystals += ProgressionManager.currencies.color_crystals[color]
	crystal_label.text = str(total_crystals)


# Purchase handlers
func _purchase_upgrade(category: String, upgrade_id: String) -> void:
	if ProgressionManager.purchase_upgrade(category, upgrade_id):
		AudioManager.play_sfx("button")
		_populate_content()  # Refresh display


func _unlock_ability(ability_id: String) -> void:
	if ProgressionManager.unlock_ability(ability_id):
		AudioManager.play_sfx("button")
		_populate_content()


func _upgrade_ability(ability_id: String) -> void:
	if ProgressionManager.upgrade_ability(ability_id):
		AudioManager.play_sfx("button")
		_populate_content()


func _purchase_mastery(color: String) -> void:
	if ProgressionManager.purchase_color_mastery(color):
		AudioManager.play_sfx("button")
		_populate_content()


# Signal handlers
func _on_currency_changed(_currency: String, _new_amount: int) -> void:
	_update_currency_display()


func _on_upgrade_purchased(_category: String, _upgrade_id: String, _new_level: int) -> void:
	_update_currency_display()


func _on_ability_unlocked(_ability_id: String) -> void:
	_update_currency_display()


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button")
	closed.emit()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	queue_free()
