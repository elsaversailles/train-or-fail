extends Panel

@onready var settings_panel: Panel = $"."
@onready var music_slider = $MusicControl
@onready var volume_value = $MusicControl/VolumeValue

@onready var fullscreen_checkbox = $FullscreenCheckbox
@onready var lighting_checkbox: CheckBox = $LightingCheckbox
@onready var distance_option: OptionButton = $RenderDistanceOption

# --- NEW: Reference your Sensitivity Slider and Label ---
@onready var sensitivity_slider = $Sensitivity # Adjust this node path to match your scene tree!
@onready var sensitivity_value = $Sensitivity/SensValue # Optional: if you have a label showing the value

func _ready() -> void:
	lighting_checkbox.set_pressed_no_signal(SettingsManager.enhanced_lighting)
	lighting_checkbox.toggled.connect(_on_lighting_toggled)
	distance_option.clear()
	distance_option.add_item("Near (100 m)", SettingsManager.RENDER_DISTANCE_NEAR)
	distance_option.add_item("Far (200 m)", SettingsManager.RENDER_DISTANCE_FAR)
	distance_option.add_item("Ultra Far (500 m)", SettingsManager.RENDER_DISTANCE_ULTRA_FAR)
	distance_option.select(SettingsManager.render_distance)
	distance_option.item_selected.connect(_on_render_distance_selected)
	# 1. When the panel opens, snap the slider to whatever the saved volume is!
	music_slider.value = SettingsManager.music_volume
	
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	_on_music_slider_value_changed(music_slider.value)
	
	# --- Setup Fullscreen Checkbox ---
	var current_mode = DisplayServer.window_get_mode()
	fullscreen_checkbox.button_pressed = (current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)

	# --- NEW: Setup Sensitivity Slider ---
	if sensitivity_slider:
		sensitivity_slider.min_value = 0.0005
		sensitivity_slider.max_value = 0.01
		sensitivity_slider.step = 0.0001
		sensitivity_slider.value = SettingsManager.mouse_sensitivity
		sensitivity_slider.value_changed.connect(_on_sensitivity_slider_value_changed)
		
		# Optional initial display update for label
		if sensitivity_value:
			sensitivity_value.text = str(snapped(SettingsManager.mouse_sensitivity * 1000, 0.1))

# --- Fullscreen Logic ---
func _on_fullscreen_toggled(toggled_on: bool):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN) 
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED) 
		
	SettingsManager.is_fullscreen = toggled_on
	SettingsManager.save_settings()

func _on_lighting_toggled(enabled: bool) -> void:
	SettingsManager.set_enhanced_lighting(enabled)

func _on_render_distance_selected(index: int) -> void:
	SettingsManager.set_render_distance(distance_option.get_item_id(index))

func _on_music_slider_value_changed(value: float):
	var music_value = int(value * 100)
	volume_value.text = str(music_value) + " %"
	SettingsManager.music_volume = value
	SettingsManager.save_settings()

# --- NEW: Sensitivity Slider Logic ---
func _on_sensitivity_slider_value_changed(value: float):
	# 1. Update the global variable
	SettingsManager.mouse_sensitivity = value
	
	# 2. Optional: update an on-screen text label if you have one
	if sensitivity_value:
		sensitivity_value.text = str(snapped(value * 1000, 0.1))
	
	# 3. Save instantly to the hard drive
	SettingsManager.save_settings()

func _on_back_button_pressed() -> void:
	settings_panel.visible = false
