extends Node

const SETTINGS_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var master_volume: float = 1.0 # --- NEW ---
var music_volume: float = 1.0 
var is_fullscreen: bool = false 
var mouse_sensitivity: float = 0.002 

func _ready():
	load_settings()

func save_settings():
	config.set_value("Audio", "master_volume", master_volume) # --- NEW ---
	config.set_value("Audio", "music_volume", music_volume)
	config.set_value("Video", "fullscreen", is_fullscreen)
	config.set_value("Controls", "mouse_sensitivity", mouse_sensitivity)
	config.save(SETTINGS_FILE_PATH)

func load_settings():
	if config.load(SETTINGS_FILE_PATH) == OK:
		master_volume = config.get_value("Audio", "master_volume", 1.0) # --- NEW ---
		music_volume = config.get_value("Audio", "music_volume", 1.0)
		is_fullscreen = config.get_value("Video", "fullscreen", false)
		mouse_sensitivity = config.get_value("Controls", "mouse_sensitivity", 0.002)
	else:
		save_settings()
		
	# Apply fullscreen setting
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
