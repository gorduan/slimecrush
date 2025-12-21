extends Node
## SaveManager - Handles persistent data storage
## Saves highscores, settings, and game progress

const SAVE_PATH: String = "user://slimecrush_save.cfg"
const SETTINGS_SECTION: String = "settings"
const PROGRESS_SECTION: String = "progress"

var config: ConfigFile


func _ready() -> void:
	config = ConfigFile.new()
	load_data()


func load_data() -> void:
	var err = config.load(SAVE_PATH)
	if err != OK:
		# First time - create default save
		_create_default_save()


func _create_default_save() -> void:
	# Settings
	config.set_value(SETTINGS_SECTION, "music_volume", 1.0)
	config.set_value(SETTINGS_SECTION, "sfx_volume", 1.0)
	config.set_value(SETTINGS_SECTION, "vibration", true)

	# Progress
	config.set_value(PROGRESS_SECTION, "highscore", 0)
	config.set_value(PROGRESS_SECTION, "max_level", 1)
	config.set_value(PROGRESS_SECTION, "total_matches", 0)
	config.set_value(PROGRESS_SECTION, "games_played", 0)

	save_data()


func save_data() -> void:
	var err = config.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game data: " + str(err))


# Highscore functions
func get_highscore() -> int:
	return config.get_value(PROGRESS_SECTION, "highscore", 0)


func save_highscore(score: int) -> void:
	var current_highscore = get_highscore()
	if score > current_highscore:
		config.set_value(PROGRESS_SECTION, "highscore", score)
		save_data()


# Level progress
func get_max_level() -> int:
	return config.get_value(PROGRESS_SECTION, "max_level", 1)


func unlock_level(level: int) -> void:
	var current_max = get_max_level()
	if level > current_max:
		config.set_value(PROGRESS_SECTION, "max_level", level)
		save_data()


# Statistics
func get_total_matches() -> int:
	return config.get_value(PROGRESS_SECTION, "total_matches", 0)


func add_matches(count: int) -> void:
	var total = get_total_matches() + count
	config.set_value(PROGRESS_SECTION, "total_matches", total)
	save_data()


func get_games_played() -> int:
	return config.get_value(PROGRESS_SECTION, "games_played", 0)


func increment_games_played() -> void:
	var games = get_games_played() + 1
	config.set_value(PROGRESS_SECTION, "games_played", games)
	save_data()


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
