extends HSlider

@export var audio_bus_name: String
var audio_bus_id

func _ready() -> void:
	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)
	
	# Snap to saved master volume if this is the master slider
	if audio_bus_name == "Master":
		value = SettingsManager.master_volume
		_on_value_changed(value)

func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)
	
	if audio_bus_name == "Master":
		SettingsManager.master_volume = value
		SettingsManager.save_settings()
