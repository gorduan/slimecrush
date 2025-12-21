extends Node
## AudioManager - Handles all game audio
## Manages sound effects and background music

# Audio bus names - use Master if custom buses don't exist
const MUSIC_BUS: String = "Master"
const SFX_BUS: String = "Master"

# Sound effect players
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8
var current_sfx_index: int = 0

# Music player
var music_player: AudioStreamPlayer


func _ready() -> void:
	_setup_audio_players()
	_apply_saved_volumes()


func _setup_audio_players() -> void:
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	add_child(music_player)

	# Create pool of SFX players
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		sfx_players.append(player)


func _apply_saved_volumes() -> void:
	set_music_volume(SaveManager.get_music_volume())
	set_sfx_volume(SaveManager.get_sfx_volume())


# Play sound effect
func play_sfx(sound_name: String) -> void:
	var stream = _get_sound(sound_name)
	if stream:
		var player = sfx_players[current_sfx_index]
		player.stream = stream
		player.play()
		current_sfx_index = (current_sfx_index + 1) % max_sfx_players


# Sound library - returns AudioStream for given sound name
func _get_sound(sound_name: String) -> AudioStream:
	# Note: In a full implementation, these would load actual audio files
	# For now, we'll generate simple sounds programmatically
	match sound_name:
		"match":
			return _generate_match_sound()
		"swap":
			return _generate_swap_sound()
		"combo":
			return _generate_combo_sound()
		"special":
			return _generate_special_sound()
		"explosion":
			return _generate_explosion_sound()
		"win":
			return _generate_win_sound()
		"lose":
			return _generate_lose_sound()
		"button":
			return _generate_button_sound()
		_:
			return null


# Generate simple procedural sounds
# These are placeholder implementations - replace with actual audio files for production
func _generate_match_sound() -> AudioStream:
	return _create_simple_tone(440.0, 0.1)


func _generate_swap_sound() -> AudioStream:
	return _create_simple_tone(330.0, 0.05)


func _generate_combo_sound() -> AudioStream:
	return _create_simple_tone(660.0, 0.15)


func _generate_special_sound() -> AudioStream:
	return _create_simple_tone(880.0, 0.2)


func _generate_explosion_sound() -> AudioStream:
	return _create_simple_tone(220.0, 0.3)


func _generate_win_sound() -> AudioStream:
	return _create_simple_tone(523.25, 0.5)


func _generate_lose_sound() -> AudioStream:
	return _create_simple_tone(196.0, 0.5)


func _generate_button_sound() -> AudioStream:
	return _create_simple_tone(392.0, 0.05)


func _create_simple_tone(frequency: float, duration: float) -> AudioStreamWAV:
	# Create a simple sine wave tone
	var sample_rate: int = 44100
	var samples: int = int(sample_rate * duration)
	var audio = AudioStreamWAV.new()

	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false

	var data: PackedByteArray = PackedByteArray()
	data.resize(samples * 2)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var envelope: float = 1.0 - (float(i) / samples)  # Fade out
		var sample_value: float = sin(2.0 * PI * frequency * t) * envelope * 0.5
		var sample_int: int = int(sample_value * 32767)

		data[i * 2] = sample_int & 0xFF
		data[i * 2 + 1] = (sample_int >> 8) & 0xFF

	audio.data = data
	return audio


# Volume control
func set_music_volume(volume: float) -> void:
	var db = linear_to_db(clamp(volume, 0.0, 1.0))
	if volume <= 0:
		db = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MUSIC_BUS), db)


func set_sfx_volume(volume: float) -> void:
	var db = linear_to_db(clamp(volume, 0.0, 1.0))
	if volume <= 0:
		db = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(SFX_BUS), db)


# Music control
func play_music(_music_name: String) -> void:
	# Placeholder - add actual music loading
	pass


func stop_music() -> void:
	music_player.stop()


func pause_music() -> void:
	music_player.stream_paused = true


func resume_music() -> void:
	music_player.stream_paused = false


# Vibration (for mobile)
func vibrate(duration_ms: int = 50) -> void:
	if SaveManager.is_vibration_enabled():
		Input.vibrate_handheld(duration_ms)
