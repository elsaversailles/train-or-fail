extends Node

func _ready() -> void:
	_run.call_deferred()

func capture(path: String) -> void:
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	get_viewport().push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		get_viewport().push_input(event, true)

func _run() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	for id in SaveManager.Catalog.ENDINGS:
		SaveManager.unlock_ending(id)
	var menu = load("res://scene/main_menu.tscn").instantiate()
	add_child(menu)
	var main = menu.get_node("Main Menu")
	main._on_gallery_pressed()
	var gallery = main.get_node("EndingGallery")
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(4, 4)
	get_viewport().push_input(motion, true)
	await capture("res://.godot/ending-reset-gallery.png")
	click(gallery.reset_button)
	print("MOUSE CLICK OPENED CONFIRMATION: ", gallery.reset_confirmation.visible)
	await capture("res://.godot/ending-reset-confirmation.png")
	get_tree().root.size = Vector2i(800, 600)
	await capture("res://.godot/ending-reset-small.png")
	click(gallery.confirm_reset_button)
	print("MOUSE CLICK RESET COUNT: ", SaveManager.get_unlocked_ending_count())
	await capture("res://.godot/ending-reset-locked.png")
	print("ENDING RESET PREVIEW COMPLETE")
	get_tree().quit()
