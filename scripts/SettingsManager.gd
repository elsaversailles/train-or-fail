extends Node

const SETTINGS_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

var music_volume: float = 1.0 
# --- NEW: Track Fullscreen state ---
var is_fullscreen: bool = false 

func _ready():
	load_settings()

func save_settings():
	config.set_value("Audio", "music_volume", music_volume)
	
	# --- NEW: Save the fullscreen preference ---
	config.set_value("Video", "fullscreen", is_fullscreen)
	
	config.save(SETTINGS_FILE_PATH)

func load_settings():
	if config.load(SETTINGS_FILE_PATH) == OK:
		music_volume = config.get_value("Audio", "music_volume", 1.0)
		
		# --- NEW: Load fullscreen preference (default to false if not found) ---
		is_fullscreen = config.get_value("Video", "fullscreen", false)
	else:
		save_settings()
		
	# Apply the fullscreen setting instantly when the game boots up
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
