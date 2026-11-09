extends SceneTree

const RESOLUTIONS := [Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(960, 540), Vector2i(800, 600)]
const DEPARTMENTS := ["fd", "kyc", "cs"]
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
	for frame in 3:
		await process_frame

func capture(name: String) -> void:
	if not capture_enabled:
		return
	if viewport.size != Vector2i(1152, 648) and viewport.size != Vector2i(800, 600):
		return
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png("res://../captures/%s.png" % name)

func check_label(label: Label, title: String) -> void:
	var rect := label.get_global_rect()
	check(rect.position.x >= -0.1 and rect.position.y >= -0.1, title + ": starts within viewport")
	check(rect.end.x <= viewport.size.x + 0.1 and rect.end.y <= viewport.size.y + 0.1, title + ": ends within viewport")
	check(label.get_visible_line_count() == label.get_line_count(), title + ": all text lines fit")
	check(not label.text.is_empty(), title + ": has meaningful text")

func check_department_layout(tutorial: Control, title: String) -> void:
	var heading: Label = tutorial.get_node("BackgroundPanel/StepLabel")
	var message: Label = tutorial.get_node("BackgroundPanel/MessageLabel")
	var hint: Label = tutorial.get_node("BackgroundPanel/ContinueLabel")
	for label in [heading, message, hint]:
		check_label(label, title + "/" + label.name)
	check(heading.get_global_rect().end.y <= message.get_global_rect().position.y + 1.0, title + ": heading does not overlap body")
	check(message.get_global_rect().end.y <= hint.get_global_rect().position.y + 1.0, title + ": body does not overlap hint")

func click_tutorial(tutorial: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(4, 4)
	tutorial.get_viewport().push_input(event, true)

func make_world() -> Node3D:
	var world := Node3D.new()
	viewport.add_child(world)
	var monitor := Node3D.new()
	monitor.name = "Monitor"
	world.add_child(monitor)
	var screen := Node3D.new()
	screen.name = "Screen"
	monitor.add_child(screen)
	var monitor_viewport := SubViewport.new()
	monitor_viewport.name = "SubViewport"
	screen.add_child(monitor_viewport)
	var panel := Control.new()
	panel.name = "LeftSlidingPanel"
	monitor_viewport.add_child(panel)
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	world.add_child(canvas)
	return world

func run_department(department: String, resolution: Vector2i) -> void:
	var world := make_world()
	var tutorial = load("res://scene/Tutorial/%s_tutorial.tscn" % department).instantiate()
	world.get_node("CanvasLayer").add_child(tutorial)
	var prefix := "%s_%dx%d" % [department, resolution.x, resolution.y]
	await settle()
	if department == "fd":
		check(tutorial.visible, prefix + ": disk instructions visible initially")
		click_tutorial(tutorial)
		check(not tutorial.is_typing and not tutorial.can_click, prefix + ": intro click reveals instructions without unlocking progression")
		click_tutorial(tutorial)
		check(tutorial.tutorial_step == -1, prefix + ": monitor focus is required before advancing")
		await settle()
		check_department_layout(tutorial, prefix + "_disk")
		await capture(prefix + "_disk")
	else:
		check(not tutorial.visible, prefix + ": hidden until monitor focus")
		click_tutorial(tutorial)
		check(tutorial.tutorial_step == -1, prefix + ": hidden tutorial ignores clicks")
	tutorial.screen_focused()
	await settle()
	check(tutorial.visible, prefix + ": visible after monitor focus")
	var first_text: String = tutorial.full_text
	tutorial.screen_focused()
	check(tutorial.full_text == first_text, prefix + ": repeated focus does not advance")
	click_tutorial(tutorial)
	check(not tutorial.is_typing and tutorial.tutorial_step == 0, prefix + ": first click reveals text without skipping the step")
	check(viewport.is_input_handled(), prefix + ": tutorial consumes the click")
	check(tutorial.timer.is_stopped(), prefix + ": skipping stops the letter timer")
	var step_count := 0
	while is_instance_valid(tutorial) and not tutorial.is_queued_for_deletion() and step_count < 12:
		tutorial._finish_typing()
		await settle()
		check_department_layout(tutorial, prefix + "_%d" % step_count)
		await capture(prefix + "_%d" % step_count)
		print("PAGE ", prefix, " ", step_count, " ", tutorial.get_node("BackgroundPanel/StepLabel").text)
		click_tutorial(tutorial)
		check(viewport.is_input_handled(), prefix + ": advance click is consumed")
		step_count += 1
		await process_frame
	check(step_count > 1 and step_count < 12, prefix + ": tutorial completes")
	world.queue_free()
	await process_frame

func run_help(resolution: Vector2i) -> void:
	var help = load("res://scene/tutorial_panel.tscn").instantiate()
	if help.get_script() == null:
		help.set_script(load("res://scripts/TutorialPanel.gd"))
	viewport.add_child(help)
	help.open_tutorial()
	await settle()
	for index in help.tutorials.size():
		help.current_tutorial_page = index
		help.update_tutorial_display()
		await settle()
		var title := "help_%dx%d_%d" % [resolution.x, resolution.y, index]
		check_label(help.get_node("TitleLabel"), title + "/title")
		check_label(help.get_node("ContentLabel"), title + "/content")
		check(help.get_node("ContentLabel").get_global_rect().end.y <= help.get_node("NextButton").get_global_rect().position.y - 10.0, title + ": body clears navigation")
		await capture(title)
	help.open_controls()
	await settle()
	check_label(help.get_node("ContentLabel"), "controls_%s" % resolution)
	check(help.get_node("ContentLabel").get_global_rect().end.y <= help.get_node("CloseTutorialButton").get_global_rect().position.y - 10.0, "controls_%s: body clears navigation" % resolution)
	await capture("controls_%dx%d" % [resolution.x, resolution.y])
	help.queue_free()
	await process_frame

func _run() -> void:
	viewport = SubViewport.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	for resolution in RESOLUTIONS:
		viewport.size = resolution
		for department in DEPARTMENTS:
			await run_department(department, resolution)
		await run_help(resolution)
	print("TUTORIAL_LAYOUT_REVIEW checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
