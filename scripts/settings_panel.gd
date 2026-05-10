extends Panel

@onready var settings_panel: Panel = $"."
@onready var music_slider = $MusicControl
@onready var volume_value = $MusicControl/VolumeValue

func _ready() -> void:
	# 1. When the panel opens, snap the slider to whatever the saved volume is!
	music_slider.value = SettingsManager.music_volume
	
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	_on_music_slider_value_changed(music_slider.value)

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
