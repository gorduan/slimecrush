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
	for mode in [MODE_ENDLESS, MODE_STORY]:
		for slot in range(1, NUM_SLOTS + 1):
			_create_empty_slot(mode, slot)

	# Initialize highscores
	for mode in [MODE_ENDLESS, MODE_STORY]:
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
	_create_empty_slot(mode, slot)
	save_data()


func is_slot_empty(mode: String, slot: int) -> bool:
	var section = _get_slot_section(mode, slot)
	return config.get_value(section, "is_empty", true)


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
	return get_slot_data(active_mode, active_slot)


func save_current_slot_data(data: Dictionary) -> void:
	save_slot_data(active_mode, active_slot, data)


# ============ LEGACY FUNCTIONS (for backwards compatibility) ============

func get_highscore() -> int:
	# Return highest score from current mode's highscores
	var scores = get_highscores(active_mode)
	return scores[0] if scores.size() > 0 else 0


func save_highscore(score: int) -> void:
	add_highscore(active_mode, score)


func get_max_level() -> int:
	var data = get_current_slot_data()
	return data.get("max_level", 1)


func unlock_level(level: int) -> void:
	var data = get_current_slot_data()
	if level > data.get("max_level", 1):
		data["max_level"] = level
		save_current_slot_data(data)


func get_total_matches() -> int:
	var data = get_current_slot_data()
	return data.get("total_matches", 0)


func add_matches(count: int) -> void:
	var data = get_current_slot_data()
	data["total_matches"] = data.get("total_matches", 0) + count
	save_current_slot_data(data)


func get_games_played() -> int:
	var data = get_current_slot_data()
	return data.get("games_played", 0)


func increment_games_played() -> void:
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
