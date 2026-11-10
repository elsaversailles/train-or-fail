extends SceneTree


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	root.size = Vector2i(1152, 648)
	root.content_scale_size = Vector2i(1152, 648)
	var error := change_scene_to_file("res://scene/main_menu.tscn")
	if error != OK:
		push_error("Could not load preview menu: %s" % error)
		quit(1)
		return
	await scene_changed
	current_scene.get_node("Main Menu/SettingsPanel").show()
	for frame in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var save_error := image.save_png("res://.godot/audio-review/settings.png")
	print("SETTINGS_PREVIEW_SAVED ", save_error, " ", image.get_size())
	quit(save_error)
