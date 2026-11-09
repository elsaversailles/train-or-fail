extends SceneTree

const MARK_TEXT := "They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!"
var fixtures: Array[Node3D] = []
var original_text_sizes: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _fixture() -> Node3D:
	var bubble := load("res://scene/npc_dialogue_box.tscn").instantiate() as Node3D
	root.add_child(bubble)
	bubble.letter_time = 0.001
	bubble.space_time = 0.001
	bubble.punctuation_time = 0.001
	fixtures.append(bubble)
	return bubble

func _start(bubble: Node3D, title: String) -> void:
	bubble.name = title
	bubble.display_text(MARK_TEXT)

func _run() -> void:
	_start(_fixture(), "deferred_fresh")
	var from_physics := _fixture()
	await physics_frame
	_start(from_physics, "physics_frame")
	var from_process := _fixture()
	await process_frame
	_start(from_process, "process_frame")
	var from_timer := _fixture()
	await create_timer(0.1).timeout
	_start(from_timer, "timer_timeout")
	await create_timer(3.0).timeout
	for bubble in fixtures:
		var panel: Control = bubble.get_node("SubViewport/TextBoxContainer")
		var label: Label = panel.get_node("Padding/Label")
		var viewport: SubViewport = bubble.get_node("SubViewport")
		print(bubble.name, " panel=", panel.size, " viewport=", viewport.size, " label=", label.size, " text=", label.text.length(), " wrap=", label.autowrap_mode)
	quit()
