extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/walk-review/" + label + ".png")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1152, 768)
	var preview = load("res://scene/walk_preview.tscn").instantiate()
	root.add_child(preview)
	var animation: AnimationPlayer = preview.get_node("Character/Player/AnimationPlayer")
	animation.pause()
	animation.seek(0.0, true)
	await _capture("three-quarter")
	preview._show_side()
	for index in 4:
		animation.seek(1.08 * (0.125 + index * 0.25), true)
		await _capture("side-%d" % index)
	preview._show_front()
	animation.seek(0.0, true)
	await _capture("front")
	root.size = Vector2i(1280, 720)
	preview._yaw = 0.45
	preview._update_camera()
	await _capture("wide")
	print("WALK_VISUAL_COMPLETE")
	preview.free()
	quit()
