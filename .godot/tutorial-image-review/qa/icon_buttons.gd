extends SceneTree

var viewport: SubViewport

func _initialize() -> void:
	root.position = Vector2i(-32000, -32000)
	_run.call_deferred()

func mark(control: Control) -> Panel:
	var outline := Panel.new()
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = Color(1.0, 0.68, 0.1)
	style.set_border_width_all(4)
	style.set_corner_radius_all(6)
	outline.add_theme_stylebox_override("panel", style)
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(outline)
	var rect := control.get_global_rect().grow(5.0)
	outline.position = rect.position
	outline.size = rect.size
	outline.z_index = 100
	return outline

func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://../captures/%s.png" % name)
	print("CAPTURE ", name)


func move_pointer(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	viewport.push_input(event, true)

func click(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	move_pointer(position)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.global_position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		viewport.push_input(event, true)

func confirm(condition: bool, description: String) -> void:
	if not condition:
		push_error("BUTTON_SMOKE: " + description)
		quit(1)
	print("BUTTON_SMOKE passed: ", description)

func preview_buttons(panel: Control, mode: String) -> void:
	if mode == "cs":
		return
	await capture(mode + "_normal")
	if mode == "fd":
		var zoom: Button = panel.get_node("ZoomModeButton")
		var swap: Button = panel.get_node("SwapModeButton")
		confirm(swap.button_pressed and not zoom.button_pressed, "Swap is selected initially")
		move_pointer(zoom.get_global_rect().get_center())
		await capture("fd_zoom_hover")
		click(zoom)
		confirm(zoom.button_pressed and not swap.button_pressed, "Zoom click selects only Zoom")
		await capture("fd_zoom_selected")
		click(zoom)
		confirm(zoom.button_pressed, "Clicking the selected mode keeps it selected")
		click(swap)
		confirm(swap.button_pressed and not zoom.button_pressed, "Swap click restores Swap")
	var notes: Button = panel.get_node("NoteIconButton")
	click(notes)
	await create_timer(0.25).timeout
	confirm(panel.is_note_open and notes.button_pressed, mode + " Notes click opens popup and presses button")
	await capture(mode + "_notes_open")
	click(panel.get_node("NotePopupPanel"))
	await create_timer(0.2).timeout
	confirm(not panel.is_note_open and not notes.button_pressed, mode + " popup click clears Notes pressed state")
	click(notes)
	panel.load_applicant(0)
	confirm(not panel.is_note_open and not notes.button_pressed, mode + " next applicant resets Notes")
	if mode == "fd":
		panel.set_review_controls_enabled(false)
		await capture("fd_disabled")
		panel.set_review_controls_enabled(true)
	move_pointer(Vector2(1100, 20))
	notes.release_focus()
	if mode == "fd":
		panel.get_node("SwapModeButton").release_focus()
		panel.get_node("ZoomModeButton").release_focus()

func _run() -> void:
	for mode in ["fd", "kyc", "cs"]:
		root.get_node("Database").mode = mode
		viewport = SubViewport.new()
		viewport.size = Vector2i(1152, 648)
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color(0.8, 0.84, 0.86)
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.8
		viewport.add_child(environment)
		var camera := Camera3D.new()
		camera.transform = Transform3D(Basis(Vector3(-4.371139e-08, 0, -1), Vector3(0, 1, 0), Vector3(1, 0, -4.371139e-08)), Vector3(33.75235, 18.186012, -0.067971945))
		viewport.add_child(camera)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-35, -45, 0)
		light.light_energy = 1.0
		viewport.add_child(light)
		var model_container := Node3D.new()
		model_container.name = "ModelContainer"
		model_container.transform = Transform3D(Basis(Vector3(-4.371139e-08, 0, 1), Vector3(0, 1, 0), Vector3(-1, 0, -4.371139e-08)), Vector3(34.32083, 16.516174, -0.087307215))
		viewport.add_child(model_container)
		if mode == "kyc":
			camera.position = model_container.position + Vector3(-3.0, 1.3, 0.0)
			camera.look_at(model_container.position + Vector3(0.0, 1.3, 0.0))
			camera.fov = 35.0
		var scene_name: String = {"fd": "left_sliding_panel", "kyc": "kyc_panel", "cs": "credit_scoring_panel"}[mode]
		var panel = load("res://scene/screengameplays/%s.tscn" % scene_name).instantiate()
		viewport.add_child(panel)
		await process_frame
		if mode != "kyc":
			await panel.set_panel_open(true).finished
			panel.stop_grip_glow()
		if mode == "cs":
			panel.slider.value = 1.0
		await create_timer(0.2).timeout
		await preview_buttons(panel, mode)
		var data_nodes: Array
		var button_nodes: Array
		match mode:
			"fd":
				data_nodes = ["LocationTextureButton", "ItemTextureButton", "TimeValueLabel", "PriceValueLabel", "NoteIconButton", "SwapModeButton", "ZoomModeButton"]
				button_nodes = ["ButtonPanel/LegitButton", "ButtonPanel/SusButton"]
			"kyc":
				data_nodes = ["IDPanel", "DateLabel", "CustomerNameLabel", "NoteIconButton"]
				button_nodes = ["LegitButton", "SusButton", "LeftButton", "CenterButton", "RightButton"]
			_:
				data_nodes = ["Panel/TabContainer"]
				button_nodes = ["Panel/VSlider", "Panel/SubmitButton", "Panel/RejectButton"]
		var outlines: Array[Panel] = []
		for node_path in data_nodes:
			outlines.append(mark(panel.get_node(node_path)))
		await capture(mode + "_data")
		for outline in outlines:
			outline.queue_free()
		outlines.clear()
		await process_frame
		for node_path in button_nodes:
			outlines.append(mark(panel.get_node(node_path)))
		await capture(mode + "_buttons")
		viewport.queue_free()
		await process_frame
	print("TUTORIAL_IMAGES_COMPLETE")
	quit()
