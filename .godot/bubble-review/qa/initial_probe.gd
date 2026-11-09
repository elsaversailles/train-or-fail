extends SceneTree

const MARK_TEXT := "They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!"
var bubble: Node3D

func _initialize() -> void:
	bubble = load("res://scene/npc_dialogue_box.tscn").instantiate()
	bubble.ready.connect(_start)
	root.add_child(bubble)

func _start() -> void:
	bubble.letter_time = 0.001
	bubble.space_time = 0.001
	bubble.punctuation_time = 0.001
	bubble.display_text(MARK_TEXT)
	_finish.call_deferred()

func _finish() -> void:
	for frame in 160:
		await process_frame
	var panel: Control = bubble.get_node("SubViewport/TextBoxContainer")
	var viewport: SubViewport = bubble.get_node("SubViewport")
	print("INITIAL_PHASE panel=", panel.size, " viewport=", viewport.size)
	quit()
