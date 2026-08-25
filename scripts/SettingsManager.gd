extends Node

const SETTINGS_FILE_PATH = "user://settings.cfg"
var config = ConfigFile.new()

# The variable that will hold your current volume
var music_volume: float = 1.0 # Default is 1.0 (100%)

func _ready():
	load_settings()

func save_settings():
	# Store the value under the category "Audio", with the key "music_volume"
	config.set_value("Audio", "music_volume", music_volume)
	config.save(SETTINGS_FILE_PATH)

func load_settings():
	# Check if the file exists and loads successfully
	if config.load(SETTINGS_FILE_PATH) == OK:
		# Get the saved value (the 1.0 at the end is a fallback if it fails)
		music_volume = config.get_value("Audio", "music_volume", 1.0)
	else:
		# If no file exists (first time playing), create one with the defaults
		save_settings()
