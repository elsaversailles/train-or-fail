extends SceneTree

const MARK_TEXT := "They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!"
const BubbleScene = preload("res://scene/npc_dialogue_box.tscn")

var failures: Array[String] = []
var checks := 0
var completions: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition and not message in failures:
		failures.append(message)
		push_error(message)

func fixture(parent: Node = root) -> Node3D:
	var bubble := BubbleScene.instantiate() as Node3D
	parent.add_child(bubble)
	bubble.letter_time = 0.001
	bubble.space_time = 0.001
	bubble.punctuation_time = 0.001
	var id := bubble.get_instance_id()
	completions[id] = 0
	bubble.finished_displaying.connect(func(): completions[id] += 1)
	return bubble

func assert_bounds(bubble: Node3D, title: String) -> void:
	var viewport: SubViewport = bubble.get_node("SubViewport")
	var panel: Control = bubble.get_node("SubViewport/TextBoxContainer")
	var label: Label = panel.get_node("Padding/Label")
	check(panel.size.x <= 256.01, title + ": width cap")
	check(Vector2(viewport.size).x + 0.01 >= panel.size.x and Vector2(viewport.size).y + 0.01 >= panel.size.y, title + ": viewport covers panel")
	check(label.get_global_rect().end.x <= viewport.size.x + 0.01 and label.get_global_rect().end.y <= viewport.size.y + 0.01, title + ": viewport covers label")
	check(label.size.y + 0.01 >= label.get_minimum_size().y, title + ": label has full text height")
	check(label.get_visible_line_count() == label.get_line_count(), title + ": no clipped lines")

func run_message(bubble: Node3D, message: String, title: String) -> void:
	var id := bubble.get_instance_id()
	var count: int = completions[id]
	var panel: Control = bubble.get_node("SubViewport/TextBoxContainer")
	var label: Label = panel.get_node("Padding/Label")
	bubble.display_text(message)
	check(completions[id] == count, title + ": completion is asynchronous")
	var initial_panel_size := panel.size
	var initial_label_rect := Rect2()
	var initial_line_count := -1
	var frame_count := 0
	while completions[id] == count and frame_count < 1000:
		if bubble.visible:
			if initial_line_count < 0:
				initial_label_rect = label.get_global_rect()
				initial_line_count = label.get_line_count()
			assert_bounds(bubble, title)
			check(panel.size.is_equal_approx(initial_panel_size), title + ": stable panel while typing")
			check(label.get_global_rect().is_equal_approx(initial_label_rect), title + ": stable label while typing")
			check(label.get_line_count() == initial_line_count, title + ": stable text wrapping while typing")
		await process_frame
		frame_count += 1
	check(completions[id] == count + 1, title + ": exactly one completion")
	check(label.text == message, title + ": final text matches")
	if not message.is_empty():
		assert_bounds(bubble, title)
		check(label.visible_characters < 0 or label.visible_characters >= message.length(), title + ": all characters revealed")
	print("CASE ", title, " viewport=", bubble.get_node("SubViewport").size, " lines=", label.get_line_count(), " frames=", frame_count)

func _run() -> void:
	var bubble := fixture()
	await run_message(bubble, MARK_TEXT, "fresh Mark line")
	await run_message(bubble, "Hi", "reuse short line")
	await run_message(bubble, MARK_TEXT, "reuse long line")
	await run_message(bubble, "", "empty line")
	await run_message(bubble, "!", "single character")
	await run_message(bubble, "First row.\nSecond row.\nThird row.", "explicit newlines")
	await run_message(bubble, "ABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZABCDEFGHIJKLMNOPQRSTUVWXYZ", "unbroken token")
	await run_message(bubble, "I know it’s a risk, but this neighborhood really needs a local, low-cost community clinic.", "Unicode punctuation")
	var id := bubble.get_instance_id()
	var count: int = completions[id]
	bubble.display_text(MARK_TEXT)
	bubble.display_text("Replacement")
	for frame in 40:
		await process_frame
	check(completions[id] == count + 1, "same-frame replacement emits once")
	check(bubble.get_node("SubViewport/TextBoxContainer/Padding/Label").text == "Replacement", "same-frame replacement keeps latest text")
	count = completions[id]
	bubble.display_text(MARK_TEXT)
	for frame in 6:
		await process_frame
	bubble.display_text("New")
	for frame in 40:
		await process_frame
	check(completions[id] == count + 1, "mid-typing replacement emits once")
	check(bubble.get_node("SubViewport/TextBoxContainer/Padding/Label").text == "New", "mid-typing replacement keeps latest text")
	assert_bounds(bubble, "replacement bounds")
	var nested := SubViewport.new()
	nested.size = Vector2i(640, 480)
	root.add_child(nested)
	var nested_bubble := fixture(nested)
	await run_message(nested_bubble, MARK_TEXT, "nested viewport fresh line")
	print("BUBBLE_REGRESSION checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
