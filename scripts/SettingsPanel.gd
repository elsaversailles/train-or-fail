extends Panel

@onready var settings_panel: Panel = $"."
@onready var music_slider = $MusicControl
@onready var volume_value = $MusicControl/VolumeValue

# --- NEW: Reference your CheckBox ---
@onready var fullscreen_checkbox = $FullscreenCheckbox # Adjust this path if you put it inside a folder/VBoxContainer!

func _ready() -> void:
	# 1. When the panel opens, snap the slider to whatever the saved volume is!
	music_slider.value = SettingsManager.music_volume
	
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	_on_music_slider_value_changed(music_slider.value)
	
	# --- NEW: Setup Fullscreen Checkbox ---
	# Check if the game is already in fullscreen and snap the checkbox to match
	var current_mode = DisplayServer.window_get_mode()
	fullscreen_checkbox.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	
	# Connect the signal via code
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

# --- NEW: Fullscreen Logic ---
func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		# Set to Full Screen [00:00:15]
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN) 
	else:
		# Set to Windowed [00:00:20]
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) 
		
	# Save the preference to your hard drive so the game remembers it!
	SettingsManager.is_fullscreen = toggled_on
	SettingsManager.save_settings()


func _on_music_slider_value_changed(value: float):
	var music_value = int(value * 100)
	
	# Update the label for volume on the screen
	volume_value.text = str(music_value) + " %"
	
	# 2. Update the global variable
	SettingsManager.music_volume = value
	
	# 3. Save it to the hard drive immediately!
	SettingsManager.save_settings()

func _on_back_button_pressed() -> void:
	settings_panel.visible = false
