extends Node

var checks: int = 0
var failures: int = 0
var finished_scores: Array = []
var game_overs: int = 0
var viewport: SubViewport
var camera: Camera3D
var models: Node3D
var panel: Control

func _ready() -> void:
	get_tree().create_timer(25.0).timeout.connect(func(): push_error("KYC validation timed out"); get_tree().quit(2))
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func show_final_result(score: int) -> void:
	finished_scores.append(score)

func trigger_game_over() -> void:
	game_overs += 1

func wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func spawn_panel(count: int) -> void:
	Database.applicant_count = count
	SaveManager.current_save_data = {"current_day": 4}
	finished_scores.clear()
	game_overs = 0
	viewport = SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	add_child(viewport)
	camera = Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(4, 1, 0)
	camera.look_at(Vector3.ZERO)
	camera.make_current()
	models = Node3D.new()
	models.name = "ModelContainer"
	models.rotation.y = PI / 2.0
	viewport.add_child(models)
	panel = load("res://scene/screengameplays/kyc_panel.tscn").instantiate()
	viewport.add_child(panel)
	await get_tree().process_frame

func finish_transition() -> void:
	while panel.is_transitioning:
		await get_tree().process_frame

func test_full_shift() -> void:
	await spawn_panel(2)
	check(not panel.shutdown_button.visible, "Shutdown starts visible")
	panel.shutdown_button.pressed.emit()
	check(finished_scores.is_empty(), "Early shutdown ended the shift")
	check(panel.date_label.text == "12/7/26", "KYC date changed")
	var original_panel_position: Vector2 = panel.position
	var original_model_id: int = models.get_child(0).get_instance_id()
	panel.toggle_id_zoom()
	await wait_seconds(0.05)
	panel.toggle_id_zoom()
	await wait_seconds(0.05)
	panel.toggle_id_zoom()
	await wait_seconds(0.35)
	check(panel.is_id_zoomed and panel.id_panel.z_index == 6, "Rapid ID zoom left stale layer state")
	panel.open_note()
	models.rotation_degrees.y = 140.0
	panel.left_button.button_down.emit()
	await wait_seconds(0.05)
	var outgoing_rotation: float = models.rotation_degrees.y
	panel.legit_button.pressed.emit()
	panel.sus_button.pressed.emit()
	check(panel.current_index == 1 and panel.player_answers == ["legit"], "Duplicate click submitted another customer")
	check(panel.is_transitioning and panel.legit_button.disabled and panel.sus_button.disabled, "Decisions remain enabled during transition")
	check(panel.left_button.disabled and panel.right_button.disabled and panel.center_button.disabled, "Rotation controls remain active")
	check(not panel.is_rotating_left and not panel.is_rotating_right, "Held rotation did not stop")
	check(not panel.is_note_open and not panel.note_popup_panel.visible, "Note stayed open during handoff")
	check(not panel.is_id_zoomed and panel.id_panel.scale.is_equal_approx(Vector2.ONE), "Zoomed ID stayed enlarged during handoff")
	check(panel.id_panel.position.is_equal_approx(panel.original_id_pos), "ID did not return to its original position")
	check(panel.id_panel.mouse_filter == Control.MOUSE_FILTER_IGNORE, "ID accepts input during handoff")
	panel.toggle_id_zoom()
	panel._on_toggle_note()
	panel._on_center_pressed()
	await wait_seconds(0.2)
	check(not panel.is_id_zoomed and not panel.is_note_open, "Inspection controls reopened during handoff")
	check(is_equal_approx(models.rotation_degrees.y, outgoing_rotation), "NPC kept rotating during departure")
	check(models.global_position.dot(camera.global_basis.x) > 0.1, "Rotated customer did not exit screen-right")
	check(models.get_child(0).get_instance_id() == original_model_id, "Customer disappeared before exit completed")
	check(panel.position.is_equal_approx(original_panel_position), "Fixed KYC layout moved during handoff")
	await wait_seconds(0.4)
	check(models.get_child(0).get_instance_id() != original_model_id, "Next customer was not loaded")
	check(models.global_position.dot(camera.global_basis.x) < -0.1, "Next customer did not enter screen-left")
	check(panel.name_label.text == "Test Applicant 1", "Customer details were not updated")
	check(panel.id_panel.scale.is_equal_approx(Vector2.ONE) and panel.id_panel.z_index == 0, "Old zoom tween affected the next ID")
	await finish_transition()
	check(models.global_position.is_equal_approx(Vector3.ZERO), "New customer did not settle at the original position")
	check(is_equal_approx(models.rotation_degrees.y, 90.0), "New customer did not face forward")
	check(not panel.legit_button.disabled and not panel.right_button.disabled, "Review controls were not restored")
	check(panel.id_panel.mouse_filter == Control.MOUSE_FILTER_STOP, "ID inspection was not restored")
	check(SaveManager.current_save_data["special_decisions"]["test_0"] == "legit", "Story decision was overwritten by a duplicate click")
	panel.right_button.button_down.emit()
	await wait_seconds(0.1)
	panel.right_button.button_up.emit()
	check(models.rotation_degrees.y > 90.0, "Rotation no longer works after transition")
	panel.center_button.pressed.emit()
	check(is_equal_approx(models.rotation_degrees.y, 90.0), "Center button no longer works after transition")
	panel.sus_button.pressed.emit()
	panel.legit_button.pressed.emit()
	await wait_seconds(0.2)
	check(models.get_child_count() == 1 and models.global_position.dot(camera.global_basis.x) > 0.1, "Last customer did not slide out")
	check(not panel.shutdown_button.visible and finished_scores.is_empty(), "Shutdown appeared before final departure")
	await finish_transition()
	check(models.get_child_count() == 0, "Final customer remained visible")
	check(panel.final_score == 2 and panel.player_answers == ["legit", "sus"], "Final score or answers changed")
	check(panel.applicant_label.text == "All customers verified", "Completion label is missing")
	check(panel.shutdown_button.visible and not panel.shutdown_button.disabled, "Shutdown did not appear")
	check(not panel.id_panel.visible and not panel.name_label.visible and not panel.ai_risk_value_label.visible, "Previous customer's details remained at completion")
	check(not panel.left_button.visible and not panel.legit_button.visible, "Review controls remained at completion")
	check(finished_scores.is_empty(), "KYC ended without pressing shutdown")
	check(panel._shutdown_idle_timer.time_left > 1.9, "Reminder did not start after final exit")
	var button_home: Vector2 = panel.shutdown_button.position
	await wait_seconds(1.8)
	check(panel._shutdown_shake_tween == null and panel.shutdown_button.position.is_equal_approx(button_home), "Shutdown vibrated before two seconds")
	var moved := false
	var deadline := Time.get_ticks_msec() + 650
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		moved = moved or not panel.shutdown_button.position.is_equal_approx(button_home)
	check(moved, "Shutdown did not vibrate after two seconds")
	panel.shutdown_button.pressed.emit()
	panel.shutdown_button.pressed.emit()
	check(finished_scores == [2], "Shutdown did not submit the score exactly once")
	check(panel._shutdown_idle_timer.is_stopped() and not panel._shutdown_shake_tween.is_valid(), "Shutdown did not stop the reminder")
	check(panel.shutdown_button.position.is_equal_approx(button_home), "Shutdown did not reset button position")
	check(not panel.visible, "KYC panel remained visible after shutdown")
	viewport.free()
	await get_tree().process_frame

func test_early_shutdown_and_mistake() -> void:
	await spawn_panel(1)
	panel.sus_button.pressed.emit()
	panel.sus_button.pressed.emit()
	await finish_transition()
	check(panel.mistakes == 1 and panel.final_score == 0, "Incorrect decision was counted more than once")
	check(panel.review_finished and panel.shutdown_button.visible, "Single-customer shift did not reach shutdown")
	panel.shutdown_button.pressed.emit()
	await wait_seconds(2.2)
	check(finished_scores == [0], "Single-customer shift lost its score")
	check(panel._shutdown_shake_tween == null, "Reminder started after early shutdown")
	viewport.free()
	await get_tree().process_frame

func test_termination() -> void:
	await spawn_panel(1)
	panel.mistakes = 2
	panel.toggle_id_zoom()
	panel.open_note()
	panel.sus_button.pressed.emit()
	panel.sus_button.pressed.emit()
	await wait_seconds(0.6)
	check(game_overs == 1 and panel.current_index == 0, "Third strike failed to terminate exactly once")
	check(panel.applicant_label.text == "TERMINATED", "Game-over label changed")
	check(not panel.shutdown_button.visible and finished_scores.is_empty(), "Game over incorrectly reached shutdown")
	check(not panel.is_note_open and not panel.is_id_zoomed, "Inspection overlays remained after termination")
	check(models.global_position.is_equal_approx(Vector3.ZERO), "Terminated shift still advanced its customer")
	viewport.free()
	await get_tree().process_frame

func _run() -> void:
	await test_full_shift()
	await test_early_shutdown_and_mistake()
	await test_termination()
	print("KYC transition checks: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
