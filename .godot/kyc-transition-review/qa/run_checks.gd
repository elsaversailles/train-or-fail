extends Node

var root: Window

var failures: int = 0
var checks: int = 0
var game: Node
var screen: Node3D
var monitor_viewport: SubViewport

func _ready() -> void:
	root = get_tree().root
	get_tree().create_timer(20.0).timeout.connect(func(): push_error("UI validation timed out"); get_tree().quit(2))
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	root.gui_embed_subwindows = true
	game = Node.new()
	root.add_child(game)
	get_tree().current_scene = game
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)

	# Reopening settings must use the Master value even when Music differs.
	SettingsManager.master_volume = 0.37
	SettingsManager.music_volume = 0.81
	var settings = load("res://scene/settings_panel.tscn").instantiate()
	game.add_child(settings)
	check(is_equal_approx(settings.get_node("MusicControl").value, 0.37), "Settings reset Master volume from Music volume")
	check(settings.get_node("MusicControl/VolumeValue").text == "37 %", "Volume label is stale")
	settings.get_node("MusicControl").value = 0.62
	check(is_equal_approx(SettingsManager.master_volume, 0.62), "Master volume does not persist")
	check(is_equal_approx(SettingsManager.music_volume, 0.81), "Master slider changed Music settings")
	check(is_equal_approx(AudioServer.get_bus_volume_linear(AudioServer.get_bus_index("Master")), 0.62), "Master volume is not applied to audio")
	settings.free()
	settings = load("res://scene/settings_panel.tscn").instantiate()
	game.add_child(settings)
	check(is_equal_approx(settings.get_node("MusicControl").value, 0.62), "Reopened settings lost Master volume")
	settings.free()

	# The formerly unconnected Controls button must open a usable guide.
	var pause = load("res://scene/pause_panel.tscn").instantiate()
	game.add_child(pause)
	pause.show()
	pause.get_node("Controls").pressed.emit()
	var guide = pause.get_node("TutorialPanel")
	check(guide.visible and guide.get_node("TitleLabel").text == "Controls", "Controls button does not open the guide")
	check(not guide.get_node("NextButton").visible and not guide.get_node("PrevButton").visible, "Controls guide has irrelevant page buttons")
	guide.get_node("CloseTutorialButton").pressed.emit()
	check(not guide.visible, "Guide cannot close")
	pause.get_node("ReplayTutorial").pressed.emit()
	check(guide.get_node("NextButton").visible and guide.get_node("PrevButton").visible, "Tutorial navigation not restored after Controls")
	check(guide.get_node("PrevButton").disabled and not guide.get_node("NextButton").disabled, "Tutorial navigation has incorrect initial state")
	for page in range(3):
		guide.get_node("NextButton").pressed.emit()
	check(guide.get_node("NextButton").disabled, "Tutorial advances past final page")
	guide.open_controls()
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://controls-guide.png")
	pause.free()

	# Use only test saves, whose paths are redirected inside this QA project.
	var slots = load("res://scene/slots_menu.tscn").instantiate()
	game.add_child(slots)
	slots._on_slot_clicked(3)
	check(slots.delete_btn.disabled and slots.delete_btn_label.text == "Delete", "Empty slot has an unexplained blank action")
	check("empty slot 3" in slots.select_btn.tooltip_text, "Empty-slot tooltip describes the wrong action")
	SaveManager.save_game(2, SaveManager.DEFAULT_SAVE.duplicate(true))
	slots._on_slot_clicked(2)
	check(not slots.delete_btn.disabled and "Continue" in slots.select_btn.tooltip_text, "Saved-slot tooltip is not updated")
	check("cannot be undone" in slots.delete_btn.tooltip_text, "Delete tooltip omits permanence")
	SaveManager.delete_save(2)
	slots.free()

	# Recreate the monitor's forwarding setup with the actual Screen script.
	var result = Node.new()
	result.name = "ResultPanel"
	game.add_child(result)
	var monitor = Node3D.new()
	monitor.name = "Monitor"
	game.add_child(monitor)
	screen = Node3D.new()
	screen.name = "Screen"
	screen.set_script(load("res://scripts/screen.gd"))
	var quad = MeshInstance3D.new()
	quad.name = "Quad"
	quad.mesh = QuadMesh.new()
	quad.mesh.size = Vector2(2, 1)
	screen.add_child(quad)
	var area = Area3D.new()
	area.name = "Area3D"
	quad.add_child(area)
	monitor_viewport = SubViewport.new()
	monitor_viewport.name = "SubViewport"
	monitor_viewport.size = Vector2i(1152, 648)
	monitor_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	screen.add_child(monitor_viewport)
	var models = Node3D.new()
	models.name = "ModelContainer"
	monitor_viewport.add_child(models)
	monitor.add_child(screen)
	check(monitor_viewport.gui_embed_subwindows, "Monitor tooltips are not embedded")

	for scene_path in ["res://scene/screengameplays/left_sliding_panel.tscn", "res://scene/screengameplays/kyc_panel.tscn"]:
		var panel = load(scene_path).instantiate()
		monitor_viewport.add_child(panel)
		await get_tree().process_frame
		panel.open_note()
		await get_tree().create_timer(0.05).timeout
		panel.close_note()
		panel.open_note()
		await get_tree().create_timer(0.35).timeout
		check(panel.note_popup_panel.visible and panel.is_note_open, "Reopened note disappeared: " + scene_path)
		check(is_equal_approx(panel.note_popup_panel.modulate.a, 1.0), "Reopened note remained transparent: " + scene_path)
		panel.close_note()
		panel.close_note_immediately()
		await get_tree().create_timer(0.2).timeout
		check(not panel.note_popup_panel.visible and panel.note_popup_panel.scale == Vector2.ONE, "Immediate note reset was overwritten by a tween")
		if panel.has_node("IDPanel"):
			check(panel.get_node("IDPanel/ZoomIcon").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Magnifier icon blocks ID clicks")
			await check_hover(panel.get_node("LeftButton"), "kyc-tooltip.png")
			await check_hover(panel.get_node("AIRiskLabel"), "risk-tooltip.png")
		else:
			panel.position.x = -3
			await check_hover(panel.get_node("ZoomModeButton"), "fraud-tooltip.png")
		panel.free()

	var credit = load("res://scene/screengameplays/credit_scoring_panel.tscn").instantiate()
	monitor_viewport.add_child(credit)
	credit.set_process(false)
	credit.position.x = credit.open_x
	await get_tree().process_frame
	for i in range(4):
		check(not credit.get_node("Panel/TabContainer").get_tab_tooltip(i).is_empty(), "Document tab lacks help")
	await check_hover(credit.get_node("Panel/RejectButton"), "credit-tooltip.png")
	credit.free()

	# Parse every edited scene and verify all actual action controls have help.
	for scene_path in ["main_menu", "slots_menu", "settings_panel", "pause_panel", "tutorial_panel", "screengameplays/left_sliding_panel", "screengameplays/kyc_panel", "screengameplays/credit_scoring_panel"]:
		var instance = load("res://scene/" + scene_path + ".tscn").instantiate()
		for control in instance.find_children("*", "BaseButton", true, false):
			check(not control.tooltip_text.is_empty(), "Missing tooltip: " + scene_path + "/" + str(control.name))
		instance.free()
	monitor.free()
	await get_tree().process_frame
	print("UI CHECKS: %d passed, %d failed" % [checks - failures, failures])
	get_tree().quit(1 if failures else 0)

func check_hover(control: Control, capture_name: String) -> void:
	screen._on_mouse_entered()
	var point = control.get_global_rect().get_center()
	var event = InputEventMouseMotion.new()
	event.position = Vector2(17, 23)
	event.global_position = event.position
	var world_point = Vector3((point.x / 1152.0 - 0.5) * 2.0, -(point.y / 648.0 - 0.5), 0)
	screen._mouse_input_event(null, event, world_point, Vector3.FORWARD, 0)
	check(event.position == Vector2(17, 23), "Monitor mutated the original input event")
	await get_tree().create_timer(0.8).timeout
	check(monitor_viewport.gui_get_hovered_control() == control, "Mouse forwarding did not reach " + str(control.name))
	var tooltip_visible = false
	for window in monitor_viewport.get_embedded_subwindows():
		if window.visible:
			tooltip_visible = true
	check(tooltip_visible, "No visible embedded tooltip for " + str(control.name))
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		monitor_viewport.get_texture().get_image().save_png("res://" + capture_name)
	screen._on_mouse_exited()
	await get_tree().process_frame
	check(monitor_viewport.gui_get_hovered_control() == null, "Hover state stuck after leaving monitor")
	for window in monitor_viewport.get_embedded_subwindows():
		check(not window.visible, "Tooltip remained visible outside monitor")
