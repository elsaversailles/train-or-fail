extends SceneTree

func _initialize() -> void:
	print("AUDIO_PROBE_USER_DIR=" + OS.get_user_data_dir())
	print("AUDIO_PROBE_APPDATA=" + OS.get_environment("APPDATA"))
	quit()
