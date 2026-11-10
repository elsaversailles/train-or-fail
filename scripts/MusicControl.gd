extends HSlider

@export_enum("Master", "Music", "SFX") var audio_bus_name: String = "Master"

@onready var volume_label: Label = $VolumeValue

func _ready() -> void:
	SettingsManager.audio_settings_changed.connect(_sync_saved_volume)
	_sync_saved_volume()
	value_changed.connect(_on_value_changed)

func _sync_saved_volume() -> void:
	set_value_no_signal(SettingsManager.get_audio_volume(audio_bus_name))
	volume_label.text = "%d %%" % roundi(value * 100.0)

func _on_value_changed(new_value: float) -> void:
	SettingsManager.set_audio_volume(audio_bus_name, new_value)
