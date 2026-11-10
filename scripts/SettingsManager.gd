extends Node

signal graphics_settings_changed
signal audio_settings_changed

const RENDER_DISTANCE_NEAR := 0
const RENDER_DISTANCE_FAR := 1
const RENDER_DISTANCE_ULTRA_FAR := 2

const SETTINGS_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var is_fullscreen: bool = false 
var mouse_sensitivity: float = 0.002 
var enhanced_lighting: bool = true
var render_distance: int = RENDER_DISTANCE_FAR

func _ready():
	load_settings()

func save_settings():
	config.set_value("Audio", "master_volume", master_volume)
	config.set_value("Audio", "music_volume", music_volume)
	config.set_value("Audio", "sfx_volume", sfx_volume)
	config.set_value("Video", "fullscreen", is_fullscreen)
	config.set_value("Video", "enhanced_lighting", enhanced_lighting)
	config.set_value("Video", "render_distance", render_distance)
	config.set_value("Controls", "mouse_sensitivity", mouse_sensitivity)
	config.save(SETTINGS_FILE_PATH)

func load_settings():
	if config.load(SETTINGS_FILE_PATH) == OK:
		master_volume = clampf(float(config.get_value("Audio", "master_volume", 1.0)), 0.0, 1.0)
		music_volume = clampf(float(config.get_value("Audio", "music_volume", 1.0)), 0.0, 1.0)
		sfx_volume = clampf(float(config.get_value("Audio", "sfx_volume", 1.0)), 0.0, 1.0)
		is_fullscreen = config.get_value("Video", "fullscreen", false)
		enhanced_lighting = bool(config.get_value("Video", "enhanced_lighting", true))
		render_distance = clampi(int(config.get_value("Video", "render_distance", RENDER_DISTANCE_FAR)), RENDER_DISTANCE_NEAR, RENDER_DISTANCE_ULTRA_FAR)
		mouse_sensitivity = config.get_value("Controls", "mouse_sensitivity", 0.002)
	else:
		save_settings()

	apply_audio_settings()

	# Apply fullscreen setting
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func get_audio_volume(bus_name: String) -> float:
	match bus_name:
		"Master":
			return master_volume
		"Music":
			return music_volume
		"SFX":
			return sfx_volume
	return 1.0

func set_audio_volume(bus_name: String, volume: float) -> void:
	volume = clampf(volume, 0.0, 1.0)
	match bus_name:
		"Master":
			master_volume = volume
		"Music":
			music_volume = volume
		"SFX":
			sfx_volume = volume
		_:
			return
	apply_audio_settings()
	save_settings()

func apply_audio_settings() -> void:
	for bus_name in ["Master", "Music", "SFX"]:
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var volume := get_audio_volume(bus_name)
		AudioServer.set_bus_mute(bus_index, volume <= 0.0)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.0001)))
	audio_settings_changed.emit()

func set_enhanced_lighting(enabled: bool) -> void:
	if enhanced_lighting == enabled:
		return
	enhanced_lighting = enabled
	save_settings()
	graphics_settings_changed.emit()

func set_render_distance(preset: int) -> void:
	preset = clampi(preset, RENDER_DISTANCE_NEAR, RENDER_DISTANCE_ULTRA_FAR)
	if render_distance == preset:
		return
	render_distance = preset
	save_settings()
	graphics_settings_changed.emit()

func get_render_distance_meters() -> float:
	match render_distance:
		RENDER_DISTANCE_NEAR:
			return 100.0
		RENDER_DISTANCE_ULTRA_FAR:
			return 500.0
		_:
			return 200.0
