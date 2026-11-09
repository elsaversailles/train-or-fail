extends SceneTree

const MARK_TEXT := "They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!"
var bubble: Node3D

func _initialize() -> void:
	root.position = Vector2i(-32000, -32000)
	_run.call_deferred()

func _capture(filename: String) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = bubble.get_node("SubViewport")
	var captured: Image = viewport.get_texture().get_image()
	captured.save_png("res://../" + filename + ".png")
	print("CAPTURE ", filename, " ", captured.get_size())

func _run() -> void:
	bubble = load("res://scene/npc_dialogue_box.tscn").instantiate()
	root.add_child(bubble)
	bubble.get_node("SubViewport").render_target_update_mode = SubViewport.UPDATE_ALWAYS
	bubble.letter_time = 0.001
	bubble.space_time = 0.001
	bubble.punctuation_time = 0.001
	bubble.display_text(MARK_TEXT)
	while bubble.get_node("SubViewport/TextBoxContainer/Padding/Label").visible_characters < 4:
		await process_frame
	bubble.timer.stop()
	await _capture("fixed-partial")
	bubble.timer.start(0.001)
	await bubble.finished_displaying
	await _capture("fixed-long")
	bubble.display_text("Hi")
	await bubble.finished_displaying
	await _capture("fixed-short")
	quit()
