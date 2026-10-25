extends Node

signal graphics_settings_changed

const RENDER_DISTANCE_NEAR := 0
const RENDER_DISTANCE_FAR := 1
const RENDER_DISTANCE_ULTRA_FAR := 2

const SETTINGS_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var master_volume: float = 1.0 # --- NEW ---
var music_volume: float = 1.0 
var is_fullscreen: bool = false 
var mouse_sensitivity: float = 0.002 
var enhanced_lighting: bool = true
var render_distance: int = RENDER_DISTANCE_FAR

func _ready():
	load_settings()

func save_settings():
	config.set_value("Audio", "master_volume", master_volume) # --- NEW ---
	config.set_value("Audio", "music_volume", music_volume)
	config.set_value("Video", "fullscreen", is_fullscreen)
	config.set_value("Video", "enhanced_lighting", enhanced_lighting)
	config.set_value("Video", "render_distance", render_distance)
	config.set_value("Controls", "mouse_sensitivity", mouse_sensitivity)
	config.save(SETTINGS_FILE_PATH)

func load_settings():
	if config.load(SETTINGS_FILE_PATH) == OK:
		master_volume = config.get_value("Audio", "master_volume", 1.0) # --- NEW ---
		music_volume = config.get_value("Audio", "music_volume", 1.0)
		is_fullscreen = config.get_value("Video", "fullscreen", false)
		enhanced_lighting = bool(config.get_value("Video", "enhanced_lighting", true))
		render_distance = clampi(int(config.get_value("Video", "render_distance", RENDER_DISTANCE_FAR)), RENDER_DISTANCE_NEAR, RENDER_DISTANCE_ULTRA_FAR)
		mouse_sensitivity = config.get_value("Controls", "mouse_sensitivity", 0.002)
	else:
		save_settings()
		
	# Apply fullscreen setting
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

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
