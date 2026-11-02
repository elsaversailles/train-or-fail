extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1152, 648)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var intro = load("res://scene/ending_intro.tscn").instantiate()
	viewport.add_child(intro)
	for ending_id in intro.ENDINGS:
		intro.show_ending(ending_id)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://.godot/ending-review/%s.png" % ending_id)
		print("LAYOUT ", ending_id, " title=", intro.title_label.get_global_rect(), " body=", intro.description_label.get_global_rect())
	for resolution in [Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		viewport.size = resolution
		intro.show_ending("another_cog_in_the_machine")
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://.godot/ending-review/cog_%dx%d.png" % [resolution.x, resolution.y])
		print("RESOLUTION ", resolution, " card=", intro.card.get_global_rect(), " content=", intro.get_node("Card/Center/Content").size)
	print("VISUAL_REVIEW_COMPLETE")
	quit()
