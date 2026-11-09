extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	var panel = load("res://scene/tutorial_panel.tscn").instantiate()
	panel.set_script(load("res://scripts/TutorialPanel.gd"))
	root.add_child(panel)
	for resolution in [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(800, 600)]:
		root.size = resolution
		await process_frame
		panel.open_tutorial()
		for page in range(panel.tutorials.size() + 1):
			if page == panel.tutorials.size():
				panel.open_controls()
			else:
				panel.current_tutorial_page = page
				panel.update_tutorial_display()
			await process_frame
			await process_frame
			var content: Label = panel.get_node("ContentLabel")
			var next_button: Button = panel.get_node("NextButton")
			var footer_top: float = next_button.position.y
			if content.position.y + content.get_minimum_size().y > footer_top - 12:
				failures += 1
				push_error("HELP_OVERFLOW %s page=%s content_end=%s footer=%s" % [resolution, page, content.position.y + content.get_minimum_size().y, footer_top])
			if DisplayServer.get_name() != "headless" and resolution == Vector2i(1152, 648):
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://../help-%d.png" % page)
		print("HELP_LAYOUT ", resolution, " pages=", panel.tutorials.size() + 1)
	print("HELP_LAYOUT failures=", failures)
	quit(1 if failures else 0)
