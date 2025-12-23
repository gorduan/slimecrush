extends Node
## SaveManager - Handles persistent data storage
## Saves highscores, settings, and game progress per mode/slot

const SAVE_PATH: String = "user://slimecrush_save.cfg"
const SETTINGS_SECTION: String = "settings"
const PROGRESS_SECTION: String = "progress"
const HIGHSCORES_SECTION: String = "highscores"
const ACTIVE_SECTION: String = "active"

# Game modes
const MODE_ENDLESS: String = "endless"
const MODE_SAGA: String = "saga"
const MODE_STORY: String = "story"

# Number of save slots per mode
const NUM_SLOTS: int = 3

var config: ConfigFile

# Current active mode and slot
var active_mode: String = MODE_ENDLESS
var active_slot: int = 1


func _ready() -> void:
	config = ConfigFile.new()
	load_data()


func load_data() -> void:
	var err = config.load(SAVE_PATH)
	if err != OK:
		# First time - create default save
		_create_default_save()
	else:
		# Load active mode/slot
		active_mode = config.get_value(ACTIVE_SECTION, "mode", MODE_ENDLESS)
		active_slot = config.get_value(ACTIVE_SECTION, "slot", 1)


func _create_default_save() -> void:
	# Settings
	config.set_value(SETTINGS_SECTION, "music_volume", 1.0)
	config.set_value(SETTINGS_SECTION, "sfx_volume", 1.0)
	config.set_value(SETTINGS_SECTION, "vibration", true)

	# Active slot tracking
	config.set_value(ACTIVE_SECTION, "mode", MODE_ENDLESS)
	config.set_value(ACTIVE_SECTION, "slot", 1)

	# Create empty slots for each mode
	for mode in [MODE_ENDLESS, MODE_SAGA, MODE_STORY]:
		for slot in range(1, NUM_SLOTS + 1):
			if mode == MODE_SAGA:
				_create_empty_saga_slot(slot)
			else:
				_create_empty_slot(mode, slot)

	# Initialize highscores
	for mode in [MODE_ENDLESS, MODE_SAGA, MODE_STORY]:
		for i in range(1, 4):
			config.set_value(HIGHSCORES_SECTION, "%s_%d" % [mode, i], 0)

	# Legacy progress section (for backwards compatibility)
	config.set_value(PROGRESS_SECTION, "highscore", 0)
	config.set_value(PROGRESS_SECTION, "max_level", 1)
	config.set_value(PROGRESS_SECTION, "total_matches", 0)
	config.set_value(PROGRESS_SECTION, "games_played", 0)

	save_data()


func _create_empty_slot(mode: String, slot: int) -> void:
	var section = _get_slot_section(mode, slot)
	config.set_value(section, "score", 0)
	config.set_value(section, "level", 1)
	config.set_value(section, "max_level", 1)
	config.set_value(section, "total_matches", 0)
	config.set_value(section, "games_played", 0)
	config.set_value(section, "is_empty", true)


func _create_empty_saga_slot(slot: int) -> void:
	var section = _get_slot_section(MODE_SAGA, slot)
	config.set_value(section, "level", 1)
	config.set_value(section, "seed", 0)  # Will be generated on first play
	config.set_value(section, "unlocked_colors", 1)  # Start with GREEN only
	config.set_value(section, "shuffles_used", 0)  # Shuffles used in current level
	config.set_value(section, "is_empty", true)


func _get_slot_section(mode: String, slot: int) -> String:
	return "%s_slot_%d" % [mode, slot]


func save_data() -> void:
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game data: " + str(err))


# ============ SLOT MANAGEMENT ============

func set_active_slot(mode: String, slot: int) -> void:
	active_mode = mode
	active_slot = slot
	config.set_value(ACTIVE_SECTION, "mode", mode)
	config.set_value(ACTIVE_SECTION, "slot", slot)
	save_data()


func get_active_slot() -> Dictionary:
	return {"mode": active_mode, "slot": active_slot}


func get_slot_data(mode: String, slot: int) -> Dictionary:
	var section = _get_slot_section(mode, slot)
	return {
		"score": config.get_value(section, "score", 0),
		"level": config.get_value(section, "level", 1),
		"max_level": config.get_value(section, "max_level", 1),
		"total_matches": config.get_value(section, "total_matches", 0),
		"games_played": config.get_value(section, "games_played", 0),
		"is_empty": config.get_value(section, "is_empty", true)
	}


func save_slot_data(mode: String, slot: int, data: Dictionary) -> void:
	var section = _get_slot_section(mode, slot)
	config.set_value(section, "score", data.get("score", 0))
	config.set_value(section, "level", data.get("level", 1))
	config.set_value(section, "max_level", data.get("max_level", 1))
	config.set_value(section, "total_matches", data.get("total_matches", 0))
	config.set_value(section, "games_played", data.get("games_played", 0))
	config.set_value(section, "is_empty", false)
	save_data()


func delete_slot(mode: String, slot: int) -> void:
	if mode == MODE_SAGA:
		_create_empty_saga_slot(slot)
	elif mode == MODE_STORY:
		_reset_story_slot(slot)
	else:
		_create_empty_slot(mode, slot)
	save_data()


func _reset_story_slot(slot: int) -> void:
	var section = _get_story_section_for_slot(slot)
	# Remove all story progression keys for this slot
	if config.has_section(section):
		for key in config.get_section_keys(section):
			config.set_value(section, key, null)


func is_slot_empty(mode: String, slot: int) -> bool:
	if mode == MODE_STORY:
		# Story mode checks completed_levels
		var story_section = _get_story_section_for_slot(slot)
		var completed_str = config.get_value(story_section, "completed_levels", "")
		return completed_str == "" or completed_str == null
	var slot_section = _get_slot_section(mode, slot)
	return config.get_value(slot_section, "is_empty", true)


# ============ HIGHSCORES ============

func get_highscores(mode: String) -> Array[int]:
	var scores: Array[int] = []
	for i in range(1, 4):
		var score = config.get_value(HIGHSCORES_SECTION, "%s_%d" % [mode, i], 0)
		scores.append(score)
	return scores


func add_highscore(mode: String, score: int) -> bool:
	var scores = get_highscores(mode)
	scores.append(score)
	scores.sort()
	scores.reverse()  # Highest first

	# Keep only top 3
	var is_new_highscore = score >= scores[0] if scores.size() > 0 else true

	for i in range(min(3, scores.size())):
		config.set_value(HIGHSCORES_SECTION, "%s_%d" % [mode, i + 1], scores[i])

	save_data()
	return is_new_highscore


# ============ CURRENT SLOT SHORTCUTS ============

func get_current_slot_data() -> Dictionary:
	if active_mode == MODE_SAGA:
		return get_saga_slot_data(active_slot)
	return get_slot_data(active_mode, active_slot)


func save_current_slot_data(data: Dictionary) -> void:
	if active_mode == MODE_SAGA:
		save_saga_slot_data(active_slot, data)
	else:
		save_slot_data(active_mode, active_slot, data)


# ============ LEGACY FUNCTIONS (for backwards compatibility) ============

func get_highscore() -> int:
	# Return highest score from current mode's highscores
	var scores = get_highscores(active_mode)
	return scores[0] if scores.size() > 0 else 0


func save_highscore(score: int) -> void:
	add_highscore(active_mode, score)


func get_max_level() -> int:
	if active_mode == MODE_SAGA:
		return get_saga_level()  # Saga uses current level as max
	var data = get_current_slot_data()
	return data.get("max_level", 1)


func unlock_level(level: int) -> void:
	if active_mode == MODE_SAGA:
		return  # Saga mode handles levels differently
	var data = get_current_slot_data()
	if level > data.get("max_level", 1):
		data["max_level"] = level
		save_current_slot_data(data)


func get_total_matches() -> int:
	if active_mode == MODE_SAGA:
		return 0  # Saga mode doesn't track total matches
	var data = get_current_slot_data()
	return data.get("total_matches", 0)


func add_matches(count: int) -> void:
	if active_mode == MODE_SAGA:
		return  # Saga mode doesn't track total matches
	var data = get_current_slot_data()
	data["total_matches"] = data.get("total_matches", 0) + count
	save_current_slot_data(data)


func get_games_played() -> int:
	if active_mode == MODE_SAGA:
		return 0  # Saga mode doesn't track games played
	var data = get_current_slot_data()
	return data.get("games_played", 0)


func increment_games_played() -> void:
	if active_mode == MODE_SAGA:
		return  # Saga mode doesn't track games played
	var data = get_current_slot_data()
	data["games_played"] = data.get("games_played", 0) + 1
	save_current_slot_data(data)


# Settings
func get_music_volume() -> float:
	return config.get_value(SETTINGS_SECTION, "music_volume", 1.0)


func set_music_volume(volume: float) -> void:
	config.set_value(SETTINGS_SECTION, "music_volume", clamp(volume, 0.0, 1.0))
	save_data()


func get_sfx_volume() -> float:
	return config.get_value(SETTINGS_SECTION, "sfx_volume", 1.0)


func set_sfx_volume(volume: float) -> void:
	config.set_value(SETTINGS_SECTION, "sfx_volume", clamp(volume, 0.0, 1.0))
	save_data()


func is_vibration_enabled() -> bool:
	return config.get_value(SETTINGS_SECTION, "vibration", true)


func set_vibration(enabled: bool) -> void:
	config.set_value(SETTINGS_SECTION, "vibration", enabled)
	save_data()


# Reset all data
func reset_all_data() -> void:
	_create_default_save()


# ============ SAGA MODE FUNCTIONS ============

func get_saga_slot_data(slot: int) -> Dictionary:
	var section = _get_slot_section(MODE_SAGA, slot)
	return {
		"level": config.get_value(section, "level", 1),
		"seed": config.get_value(section, "seed", 0),
		"unlocked_colors": config.get_value(section, "unlocked_colors", 1),
		"shuffles_used": config.get_value(section, "shuffles_used", 0),
		"is_empty": config.get_value(section, "is_empty", true)
	}


func save_saga_slot_data(slot: int, data: Dictionary) -> void:
	var section = _get_slot_section(MODE_SAGA, slot)
	config.set_value(section, "level", data.get("level", 1))
	config.set_value(section, "seed", data.get("seed", 0))
	config.set_value(section, "unlocked_colors", data.get("unlocked_colors", 1))
	config.set_value(section, "shuffles_used", data.get("shuffles_used", 0))
	config.set_value(section, "is_empty", false)
	save_data()


func get_current_saga_data() -> Dictionary:
	return get_saga_slot_data(active_slot)


func save_current_saga_data(data: Dictionary) -> void:
	save_saga_slot_data(active_slot, data)


func get_saga_level() -> int:
	var data = get_current_saga_data()
	return data.get("level", 1)


func set_saga_level(level: int) -> void:
	var data = get_current_saga_data()
	data["level"] = level
	# Update unlocked colors based on level (1 color per 10 levels, max 6)
	data["unlocked_colors"] = mini(1 + int((level - 1) / 10), 6)
	data["shuffles_used"] = 0  # Reset shuffles for new level
	save_current_saga_data(data)


func get_saga_seed() -> int:
	var data = get_current_saga_data()
	var current_seed = data.get("seed", 0)
	if current_seed == 0:
		# Generate new seed based on slot and level for determinism
		current_seed = hash(str(active_slot) + "_" + str(data.get("level", 1)))
		data["seed"] = current_seed
		save_current_saga_data(data)
	return current_seed


func get_saga_unlocked_colors() -> int:
	var data = get_current_saga_data()
	return data.get("unlocked_colors", 1)


func get_saga_shuffles_remaining() -> int:
	var data = get_current_saga_data()
	return 3 - data.get("shuffles_used", 0)


func use_saga_shuffle() -> bool:
	var data = get_current_saga_data()
	var used = data.get("shuffles_used", 0)
	if used < 3:
		data["shuffles_used"] = used + 1
		save_current_saga_data(data)
		return true  # Shuffle allowed
	return false  # No shuffles remaining


func reset_saga_shuffles() -> void:
	var data = get_current_saga_data()
	data["shuffles_used"] = 0
	save_current_saga_data(data)


func advance_saga_level() -> void:
	var data = get_current_saga_data()
	var new_level = data.get("level", 1) + 1
	data["level"] = new_level
	# Update unlocked colors (1 color per 10 levels, max 6)
	data["unlocked_colors"] = mini(1 + int((new_level - 1) / 10), 6)
	# Generate new seed for new level
	data["seed"] = hash(str(active_slot) + "_" + str(new_level))
	data["shuffles_used"] = 0
	save_current_saga_data(data)


func is_saga_mode() -> bool:
	return active_mode == MODE_SAGA


func is_story_mode() -> bool:
	return active_mode == MODE_STORY


# ============ STORY MODE PROGRESSION ============

# Returns the section name for the current story slot
func _get_story_section() -> String:
	return "story_slot_%d" % active_slot


# Returns the section name for a specific story slot
func _get_story_section_for_slot(slot: int) -> String:
	return "story_slot_%d" % slot


func save_story_progression(data: Dictionary) -> void:
	var section = _get_story_section()

	# Save currencies
	if data.has("currencies"):
		var currencies = data.currencies
		config.set_value(section, "slime_essence", currencies.get("slime_essence", 0))
		config.set_value(section, "star_dust", currencies.get("star_dust", 0))

		# Save color crystals
		var crystals = currencies.get("color_crystals", {})
		for color in ["red", "orange", "yellow", "green", "blue", "purple"]:
			config.set_value(section, "crystal_" + color, crystals.get(color, 0))

	# Save upgrades
	if data.has("upgrades"):
		for category in data.upgrades.keys():
			for upgrade_id in data.upgrades[category].keys():
				var key = "upgrade_%s_%s" % [category, upgrade_id]
				config.set_value(section, key, data.upgrades[category][upgrade_id])

	# Save abilities
	if data.has("abilities"):
		for ability_id in data.abilities.keys():
			var ability = data.abilities[ability_id]
			config.set_value(section, "ability_%s_unlocked" % ability_id, ability.get("unlocked", false))
			config.set_value(section, "ability_%s_level" % ability_id, ability.get("level", 0))

	# Save color mastery
	if data.has("color_mastery"):
		for color in data.color_mastery.keys():
			config.set_value(section, "mastery_" + color, data.color_mastery[color])

	# Save campaign progress
	if data.has("campaign"):
		var campaign = data.campaign
		config.set_value(section, "current_chapter", campaign.get("current_chapter", 1))
		config.set_value(section, "current_level", campaign.get("current_level", 1))

		# Save completed levels as comma-separated string
		var completed = campaign.get("completed_levels", [])
		config.set_value(section, "completed_levels", ",".join(completed))

		# Save level stars as JSON
		var stars = campaign.get("level_stars", {})
		config.set_value(section, "level_stars", JSON.stringify(stars))

	save_data()


func load_story_progression() -> Dictionary:
	var section = _get_story_section()

	var data = {
		"currencies": {
			"slime_essence": config.get_value(section, "slime_essence", 0),
			"star_dust": config.get_value(section, "star_dust", 0),
			"color_crystals": {}
		},
		"upgrades": {},
		"abilities": {},
		"color_mastery": {},
		"campaign": {}
	}

	# Load color crystals
	for color in ["red", "orange", "yellow", "green", "blue", "purple"]:
		data.currencies.color_crystals[color] = config.get_value(section, "crystal_" + color, 0)

	# Load upgrades
	var categories = ["scoring", "moves", "specials", "combos"]
	var upgrade_keys = {
		"scoring": ["point_boost", "color_mastery_red", "color_mastery_orange", "color_mastery_yellow",
					"color_mastery_green", "color_mastery_blue", "color_mastery_purple",
					"match_4_bonus", "match_5_bonus", "special_bonus"],
		"moves": ["starting_moves", "move_saver", "emergency_moves"],
		"specials": ["striped_chance", "wrapped_chance", "color_bomb_chance", "striped_power", "wrapped_power"],
		"combos": ["combo_multiplier", "cascade_boost", "chain_reaction"]
	}

	for category in categories:
		data.upgrades[category] = {}
		for upgrade_id in upgrade_keys[category]:
			var key = "upgrade_%s_%s" % [category, upgrade_id]
			data.upgrades[category][upgrade_id] = config.get_value(section, key, 0)

	# Load abilities
	var ability_ids = ["slime_swap", "color_burst", "row_sweep", "column_sweep",
					   "shuffle_plus", "time_freeze", "color_transform", "special_spawner"]
	for ability_id in ability_ids:
		data.abilities[ability_id] = {
			"unlocked": config.get_value(section, "ability_%s_unlocked" % ability_id, false),
			"level": config.get_value(section, "ability_%s_level" % ability_id, 0)
		}

	# Load color mastery
	for color in ["red", "orange", "yellow", "green", "blue", "purple"]:
		data.color_mastery[color] = config.get_value(section, "mastery_" + color, 0)

	# Load campaign
	data.campaign = {
		"current_chapter": config.get_value(section, "current_chapter", 1),
		"current_level": config.get_value(section, "current_level", 1),
		"completed_levels": [],
		"level_stars": {}
	}

	# Parse completed levels
	var completed_str = config.get_value(section, "completed_levels", "")
	if completed_str != "":
		data.campaign.completed_levels = completed_str.split(",")

	# Parse level stars from JSON
	var stars_json = config.get_value(section, "level_stars", "{}")
	var stars_parsed = JSON.parse_string(stars_json)
	if stars_parsed != null:
		data.campaign.level_stars = stars_parsed

	return data


func load_story_progression_for_slot(slot: int) -> Dictionary:
	# Load progression for a specific slot (used by mode selection display)
	var section = _get_story_section_for_slot(slot)

	var data = {
		"currencies": {
			"slime_essence": config.get_value(section, "slime_essence", 0),
			"star_dust": config.get_value(section, "star_dust", 0),
			"color_crystals": {}
		},
		"campaign": {
			"current_chapter": config.get_value(section, "current_chapter", 1),
			"current_level": config.get_value(section, "current_level", 1),
			"completed_levels": []
		}
	}

	# Parse completed levels
	var completed_str = config.get_value(section, "completed_levels", "")
	if completed_str != "":
		data.campaign.completed_levels = completed_str.split(",")

	return data


func reset_story_progression() -> void:
	var section = _get_story_section()
	# Remove all story progression keys for current slot
	if config.has_section(section):
		for key in config.get_section_keys(section):
			config.set_value(section, key, null)
	save_data()
