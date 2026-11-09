extends SceneTree

const MARK_TEXT := "They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!"

func _initialize() -> void:
	_run.call_deferred()

func _snapshot(bubble: Node3D, tag: String) -> void:
	var panel: Control = bubble.get_node("SubViewport/TextBoxContainer")
	var label: Label = panel.get_node("Padding/Label")
	var viewport: SubViewport = bubble.get_node("SubViewport")
	print(tag, " panel=", panel.size, " viewport=", viewport.size, " label=", label.size, " text=", label.text.length(), " wrap=", label.autowrap_mode)

func _run() -> void:
	var packed := load("res://scene/npc_dialogue_box.tscn") as PackedScene
	var bubble := packed.instantiate() as Node3D
	root.add_child(bubble)
	bubble.letter_time = 0.001
	bubble.space_time = 0.001
	bubble.punctuation_time = 0.001
	_snapshot(bubble, "INITIAL")
	bubble.display_text(MARK_TEXT)
	for index in 8:
		await process_frame
		_snapshot(bubble, "FRAME " + str(index))
	await create_timer(3.0).timeout
	_snapshot(bubble, "COMPLETE")
	bubble.display_text("Hi")
	await create_timer(0.3).timeout
	_snapshot(bubble, "SHORT")
	bubble.display_text(MARK_TEXT)
	await create_timer(3.0).timeout
	_snapshot(bubble, "LONG AGAIN")
	quit()
