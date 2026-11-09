extends SceneTree

const RESOLUTIONS := [Vector2i(1152,648), Vector2i(1280,720), Vector2i(1024,768), Vector2i(960,540), Vector2i(800,600)]
var checks := 0
var failures: Array[String] = []
var capture_enabled := false
var viewport: SubViewport

func _initialize() -> void:
	root.position = Vector2i(-32000, -32000)
	capture_enabled = "--capture" in OS.get_cmdline_user_args()
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition and message not in failures:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame in 5:
		await process_frame

func named(guide: Control, node_name: String) -> Node:
	return guide.find_child(node_name, true, false)

func click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	for is_pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.pressed = is_pressed
		viewport.push_input(event, true)
	await settle()

func escape() -> void:
	for is_pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.physical_keycode = KEY_ESCAPE
		event.pressed = is_pressed
		viewport.push_input(event, true)
	await settle()

func capture(name: String) -> void:
	if not capture_enabled or viewport.size not in [Vector2i(1152,648), Vector2i(800,600)]:
		return
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://captures/%s.png" % name)
	check(result == OK, name + ": screenshot saved")

func inside(rect: Rect2, bounds: Rect2) -> bool:
	return rect.position.x >= bounds.position.x - 1 and rect.position.y >= bounds.position.y - 1 and rect.end.x <= bounds.end.x + 1 and rect.end.y <= bounds.end.y + 1

func inspect_page(guide: Control, prefix: String) -> void:
	var bounds := Rect2(Vector2.ZERO, viewport.size)
	var window: Control = named(guide, "GuideWindow")
	var scroll: ScrollContainer = named(guide, "ContentScroll")
	var content: Control = named(guide, "Content")
	check(inside(window.get_global_rect(), bounds), prefix + ": window fits viewport")
	check(inside(scroll.get_global_rect(), window.get_global_rect()), prefix + ": scroll area fits window")
	check(content.size.x <= scroll.size.x + 1, prefix + ": content has no horizontal overflow")
	for name in ["TitleLabel", "SubtitleLabel"]:
		var label: Label = named(guide, name)
		check(not label.text.strip_edges().is_empty(), prefix + "/" + name + ": has text")
		check(inside(label.get_global_rect(), window.get_global_rect()), prefix + "/" + name + ": fits window")
		check(label.get_line_count() == label.get_visible_line_count(), prefix + "/" + name + ": all text lines fit")
	for name in ["MovementButton", "InteractionButton", "WorkGuideButton", "PrevButton", "NextButton", "CloseTutorialButton"]:
		var button: Button = named(guide, name)
		check(inside(button.get_global_rect(), window.get_global_rect()), prefix + "/" + name + ": fits window")
		check(button.visible, prefix + "/" + name + ": visible")
	for name in ["PrevButton", "NextButton", "CloseTutorialButton"]:
		var button: Button = named(guide, name)
		check(scroll.get_global_rect().end.y <= button.get_global_rect().position.y + 1, prefix + "/" + name + ": footer clears scrolling content")
	check(not content.get_children().is_empty(), prefix + ": page contains instructions")
	for item in content.find_children("*", "Label", true, false):
		var label := item as Label
		check(label.get_line_count() == label.get_visible_line_count(), prefix + "/" + str(label.get_path()) + ": instruction text fits its label")
		check(label.get_global_rect().position.x >= content.get_global_rect().position.x - 1 and label.get_global_rect().end.x <= content.get_global_rect().end.x + 1, prefix + "/" + str(label.get_path()) + ": instruction text fits content width")
	for item in content.find_children("*", "TextureRect", true, false):
		check(item.texture != null, prefix + ": icon texture loaded")
		check(item.mouse_filter == Control.MOUSE_FILTER_IGNORE, prefix + ": icon does not intercept clicks")
	if guide.current_tutorial_page < 2:
		var expected_icons := 5 if guide.current_tutorial_page == 0 else 4
		check(content.find_children("*", "TextureRect", true, false).size() == expected_icons, prefix + ": each control row has an icon")
	print("PAGE ", prefix, " title=", named(guide, "TitleLabel").text, " content=", content.size, " scroll=", scroll.size)

func run_resolution(resolution: Vector2i) -> void:
	viewport.size = resolution
	var parent := Control.new()
	parent.name = "PausedFixture"
	parent.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	parent.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(parent)
	var guide = load("res://scene/tutorial_panel.tscn").instantiate()
	if guide.get_script() == null:
		guide.set_script(load("res://scripts/TutorialPanel.gd"))
	parent.add_child(guide)
	await settle()
	var prefix := "%dx%d" % [resolution.x, resolution.y]
	check(paused, prefix + ": fixture starts paused")
	check(guide.can_process(), prefix + ": guide processes while paused")
	check(guide.tutorials.size() == 8, prefix + ": eight guide pages")
	guide.open_tutorial()
	await settle()
	check(guide.visible and guide.current_tutorial_page == 2, prefix + ": work guide opens first work page")
	guide.open_controls()
	await settle()
	check(guide.visible and guide.current_tutorial_page == 0, prefix + ": controls open Movement")
	check(named(guide, "PrevButton").disabled, prefix + ": previous disabled on first page")
	for index in guide.tutorials.size():
		check(guide.current_tutorial_page == index, prefix + ": next navigates to page %d while paused" % index)
		inspect_page(guide, prefix + "_%d" % index)
		await capture(prefix + "_%d" % index)
		var page_scroll: ScrollContainer = named(guide, "ContentScroll")
		var page_content: Control = named(guide, "Content")
		if page_content.size.y > page_scroll.size.y + 1:
			page_scroll.scroll_vertical = 10000
			await settle()
			check(page_scroll.scroll_vertical > 0, prefix + ": overflow on page%d can scroll" % index)
			check(page_content.get_global_rect().end.y <= page_scroll.get_global_rect().end.y + 1, prefix + ": bottom of page%d is reachable" % index)
			await capture(prefix + "_%d_bottom" % index)
		check(paused, prefix + ": page %d keeps tree paused" % index)
		if index < guide.tutorials.size() - 1:
			await click(named(guide, "NextButton"))
	check(named(guide, "NextButton").disabled, prefix + ": next disabled on last page")
	await click(named(guide, "PrevButton"))
	check(guide.current_tutorial_page == 6 and paused, prefix + ": previous works while paused")
	await click(named(guide, "MovementButton"))
	check(guide.current_tutorial_page == 0 and paused, prefix + ": Movement tab works while paused")
	await click(named(guide, "InteractionButton"))
	check(guide.current_tutorial_page == 1 and paused, prefix + ": Interaction tab works while paused")
	await click(named(guide, "WorkGuideButton"))
	check(guide.current_tutorial_page >= 2 and paused, prefix + ": Work guide tab works while paused")
	var scroll: ScrollContainer = named(guide, "ContentScroll")
	scroll.scroll_vertical = 10000
	await settle()
	await click(named(guide, "CloseTutorialButton"))
	check(not guide.visible and paused, prefix + ": close returns to pause without resuming")
	guide.open_controls()
	await settle()
	await escape()
	check(not guide.visible and paused, prefix + ": Escape returns to pause without resuming")
	parent.queue_free()
	await settle()

func _run() -> void:
	viewport = SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	viewport.handle_input_locally = true
	root.add_child(viewport)
	paused = true
	for resolution in RESOLUTIONS:
		await run_resolution(resolution)
	print("PAUSE_GUIDE_REVIEW checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
