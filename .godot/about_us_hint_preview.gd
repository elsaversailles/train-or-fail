extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var about = load("res://scene/about_us_panel.tscn").instantiate()
	get_tree().root.add_child(about)
	get_tree().current_scene = about
	await get_tree().process_frame
	print("EXIT HINT DURING TYPING: ", about.get_node("ExitHint").is_visible_in_tree())
	about.current_tween.kill()
	about._on_typing_finished()
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/about-us-exit-hint.png")
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await SceneTransition.transition_finished
	print("ESC RETURNED TO: ", get_tree().current_scene.scene_file_path)
	get_tree().quit()
