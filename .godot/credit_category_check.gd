extends Node

var checks := 0
var failures: Array[String] = []
var panel: Control

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("CREDIT CATEGORY CHECK: " + message)

func frames(count: int = 3) -> void:
	for i in count:
		await get_tree().process_frame

func _run() -> void:
	get_tree().root.size = Vector2i(1152, 648)
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data["current_day"] = 7
	var background := ColorRect.new()
	background.color = Color("cdd7dd")
	background.size = Vector2(1152, 648)
	add_child(background)
	var container := Node3D.new()
	container.name = "ModelContainer"
	add_child(container)
	panel = load("res://scene/screengameplays/credit_scoring_panel.tscn").instantiate()
	add_child(panel)
	await frames()
	panel.clear_applicant_model()
	panel.stop_grip_glow(false)
	if "--capture-only" in OS.get_cmdline_user_args():
		await capture_examples()
		return

	check(not panel.has_node("Panel/Label"), "old dollar range label removed")
	check(panel.slider.min_value == 0.0 and panel.slider.max_value == 1.0 and is_equal_approx(panel.slider.step, 0.2), "slider retains six positions")
	check_selection(0.0, "Rejected")
	await panel.set_panel_open(true).finished
	var values := [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
	var categories := ["Rejected", "Low", "Medium", "Medium", "High", "High"]
	for index in values.size():
		panel.slider.value = values[index]
		await frames(1)
		check_selection(values[index], categories[index])
		var label_rect: Rect2 = panel.credit_score_label.get_global_rect()
		var docs_rect: Rect2 = panel.get_node("Panel/TabContainer").get_global_rect()
		check(not label_rect.intersects(docs_rect), "category fits left column at %s" % values[index])
		var font: Font = panel.credit_score_label.get_theme_font("font")
		var text_width := font.get_string_size(panel.credit_score_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, panel.credit_score_label.get_theme_font_size("font_size")).x
		check(text_width <= label_rect.size.x, "category text fits at %s" % values[index])

	panel.reject_button.button_pressed = true
	panel.reject_button.pressed.emit()
	check_selection(0.0, "Rejected")
	panel.reject_button.button_pressed = false
	panel.reject_button.pressed.emit()
	check_selection(0.0, "Rejected")
	panel.slider.value = 0.4
	check_selection(0.4, "Medium")
	panel.slider.value = 0.0
	check_selection(0.0, "Rejected")

	panel.applicants_list.clear()
	for value in values:
		panel.applicants_list.append({"name": "Category check", "credit_correct": value})
	panel.applicants_list.append({"name": "Outside tolerance", "credit_correct": 0.4})
	panel.applicants_list.append({"name": "Within tolerance", "credit_correct": 0.6})
	panel.applicants_list.append({"name": "Special low", "id": "category_low_test", "credit_correct": 0.4, "is_special": true})
	panel.applicants_list.append({"name": "Special high", "id": "category_high_test", "credit_correct": 0.6, "is_special": true})
	panel.current_case_index = 0
	panel.total_correct_answers = 0
	panel.mistakes = 0
	panel.load_applicant()
	var submissions := values + [0.8, 0.4, 0.4, 0.6]
	for index in submissions.size():
		check_selection(0.0, "Rejected")
		panel.slider.value = submissions[index]
		await panel._on_submit()
		check(panel.current_case_index == index + 1, "submission advances exactly one applicant")
		if index < submissions.size() - 1:
			check(not panel.is_transitioning and not panel.submit_button.disabled and panel.slider.editable, "next applicant controls enabled")
	check(panel.total_correct_answers == 9 and panel.mistakes == 1, "grading and tolerance unchanged")
	check(SaveManager.current_save_data["special_decisions"].get("category_low_test") == "sus", "special score 0.4 still records sus")
	check(SaveManager.current_save_data["special_decisions"].get("category_high_test") == "legit", "special score 0.6 still records legit")
	check(panel.review_finished and not panel.is_transitioning, "queue finishes without removed-label errors")
	check(panel.shutdown_button.visible and not panel.shutdown_button.disabled, "shutdown enabled at end")
	check(not panel.credit_score_label.visible and not panel.slider.visible and not panel.submit_button.visible, "assessment controls hidden at end")
	await panel._on_submit()
	check(panel.current_case_index == submissions.size(), "submission ignored after completion")
	print("CREDIT CATEGORY CHECKS: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)

func check_selection(value: float, category: String) -> void:
	check(is_equal_approx(panel.slider.value, value), "slider value %s" % value)
	check(panel.credit_score_label.text == "Proposed Credit: " + category, "display category " + category)
	check(panel.is_rejected == (value == 0.0), "rejection matches zero selection")
	check(panel.reject_button.button_pressed == (value == 0.0), "flag matches zero selection")

func capture_examples() -> void:
	panel.applicants_list = [Database.credit_applicants[0].duplicate()]
	panel.applicants_list[0]["model_scene"] = null
	panel.current_case_index = 0
	panel.load_applicant()
	await panel.set_panel_open(true).finished
	await frames()
	await capture("res://.godot/credit-rejected-preview.png")
	panel.slider.value = 0.4
	await capture("res://.godot/credit-medium-preview.png")
	panel.slider.value = 1.0
	var highlights := Control.new()
	highlights.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(highlights)
	for target in [panel.slider, panel.submit_button, panel.reject_button]:
		add_highlight(highlights, target.get_global_rect().grow(5))
	await capture("res://images/TutorialsIMG/CREDITSCORING/CS_button_highlight_img.png")
	for child in highlights.get_children():
		highlights.remove_child(child)
		child.queue_free()
	add_highlight(highlights, panel.get_node("Panel/TabContainer").get_global_rect().grow(5))
	await capture("res://images/TutorialsIMG/CREDITSCORING/CS_data_highlight_img.png")
	print("CREDIT CATEGORY CAPTURES: updated both tutorial screenshots and two category previews")
	get_tree().quit()

func add_highlight(parent: Control, rect: Rect2) -> void:
	var outline := Panel.new()
	outline.position = rect.position
	outline.size = rect.size
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color("ff9400")
	style.set_border_width_all(3)
	outline.add_theme_stylebox_override("panel", style)
	parent.add_child(outline)

func capture(path: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	var capture_image := get_viewport().get_texture().get_image()
	var error := capture_image.save_png(path)
	if error != OK:
		push_error("Capture failed: " + path)
		get_tree().quit(1)
