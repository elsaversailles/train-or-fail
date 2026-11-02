extends Node

var failures: int = 0
var checks: int = 0
var finished_scores: Array = []
var game_overs: int = 0
var viewport: SubViewport
var models: Node3D
var camera: Camera3D
var panel: Control
var is_credit: bool

func _ready() -> void:
	get_tree().create_timer(55.0).timeout.connect(func(): push_error("Transition checks timed out"); get_tree().quit(2))
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(("Credit: " if is_credit else "Fraud: ") + message)

func show_final_result(score: int) -> void:
	finished_scores.append(score)

func trigger_game_over() -> void:
	game_overs += 1

func wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func spawn_panel(count: int) -> void:
	Database.applicant_count = count
	SaveManager.decisions.clear()
	SaveManager.current_save_data.clear()
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
	var path := "res://scene/screengameplays/credit_scoring_panel.tscn" if is_credit else "res://scene/screengameplays/left_sliding_panel.tscn"
	panel = load(path).instantiate()
	viewport.add_child(panel)
	await get_tree().process_frame
	await panel.set_panel_open(true).finished

func submit(correct: bool = true) -> void:
	if is_credit:
		if correct and panel.actual_score == 0.0:
			panel.reject_button.pressed.emit()
		else:
			panel.slider.value = panel.actual_score if correct else 0.0
		panel.submit_button.pressed.emit()
	else:
		var answer: String = panel.applicants[panel.current_index]["fraud_correct"]
		if not correct:
			answer = "sus" if answer == "legit" else "legit"
		if answer == "legit":
			panel.legit_button.pressed.emit()
		else:
			panel.sus_button.pressed.emit()

func attempt_duplicate() -> void:
	if is_credit:
		panel.submit_button.pressed.emit()
	else:
		panel.legit_button.pressed.emit()

func index() -> int:
	return panel.current_case_index if is_credit else panel.current_index

func closed_x() -> float:
	return panel.closed_x if is_credit else -float(panel.panel_width)

func test_full_shift() -> void:
	await spawn_panel(2)
	var old_model_id := models.get_child(0).get_instance_id()
	panel.shutdown_button.pressed.emit()
	check(finished_scores.is_empty(), "Shutdown ran before the last applicant")
	submit()
	attempt_duplicate()
	panel.grip_button.pressed.emit()
	check(index() == 1 and panel.is_transitioning, "Double-click advanced more than one applicant")
	check(panel.grip_button.disabled, "Grip can interrupt the transition")
	await wait_seconds(0.3)
	check(models.global_position.is_equal_approx(Vector3.ZERO), "NPC moved before panel closed")
	check(models.get_child(0).get_instance_id() == old_model_id, "Old NPC was removed before its exit")
	check(not is_equal_approx(panel.position.x, closed_x()), "Panel did not animate its close")
	await wait_seconds(0.5)
	check(is_equal_approx(panel.position.x, closed_x()), "Panel did not close completely")
	check(models.global_position.dot(camera.global_basis.x) > 0.1, "Outgoing NPC did not slide screen-right")
	await wait_seconds(0.4)
	check(models.get_child(0).get_instance_id() != old_model_id, "Next NPC was never loaded")
	check(models.global_position.dot(camera.global_basis.x) < -0.1, "New NPC did not enter from screen-left")
	while panel.is_transitioning:
		await get_tree().process_frame
	check(models.global_position.is_equal_approx(Vector3.ZERO), "Next NPC did not settle at its original position")
	check(not panel.is_open and not panel.grip_button.disabled, "Next applicant did not restore the closed panel's grip")
	check(not panel.shutdown_button.visible, "Shutdown appeared before the final applicant")
	check(SaveManager.decisions == [["test_0", "legit"]], "Special decision was not recorded exactly once")
	await panel.set_panel_open(true).finished
	submit()
	attempt_duplicate()
	check(index() == 2, "Last applicant was submitted more than once")
	await wait_seconds(0.3)
	check(models.get_child_count() == 1 and models.global_position.is_equal_approx(Vector3.ZERO), "Final NPC exited before the panel closed")
	await wait_seconds(0.5)
	check(models.global_position.dot(camera.global_basis.x) > 0.1, "Final NPC did not exit to the right")
	check(not panel.shutdown_button.visible, "Shutdown appeared during NPC exit")
	await wait_seconds(0.4)
	check(models.get_child_count() == 0, "Last NPC remained on screen")
	check(panel.is_open and panel.is_transitioning, "Panel did not reopen after final exit")
	check(not panel.shutdown_button.visible, "Shutdown appeared before panel finished opening")
	while panel.is_transitioning:
		await get_tree().process_frame
	check(panel.shutdown_button.visible and not panel.shutdown_button.disabled, "Shutdown was not revealed and enabled")
	check(finished_scores.is_empty(), "Shift ended without pressing shutdown")
	check(panel.review_finished and panel._shutdown_idle_timer.time_left > 1.9, "Shutdown reminder did not start on reveal")
	var button_home: Vector2 = panel.shutdown_button.position
	await wait_seconds(1.8)
	check(panel.shutdown_button.position.is_equal_approx(button_home) and panel._shutdown_shake_tween == null, "Shutdown vibrated before two seconds")
	var moved := false
	for frame in range(50):
		await get_tree().process_frame
		moved = moved or not panel.shutdown_button.position.is_equal_approx(button_home)
	check(moved, "Shutdown did not vibrate after two seconds")
	panel.shutdown_button.pressed.emit()
	panel.shutdown_button.pressed.emit()
	check(finished_scores == [2], "Shutdown did not report the score exactly once")
	check(panel._shutdown_idle_timer.is_stopped(), "Shutdown left reminder timer running")
	check(not panel._shutdown_shake_tween.is_valid(), "Shutdown left vibration running")
	check(panel.shutdown_button.position.is_equal_approx(button_home), "Shutdown failed to reset button position")
	viewport.free()
	await get_tree().process_frame

func test_early_shutdown() -> void:
	await spawn_panel(1)
	submit()
	while panel.is_transitioning:
		await get_tree().process_frame
	panel.shutdown_button.pressed.emit()
	await wait_seconds(2.2)
	check(finished_scores == [1], "Single-applicant shift did not wait for shutdown")
	check(panel._shutdown_shake_tween == null, "Vibration started after early shutdown")
	viewport.free()
	await get_tree().process_frame

func test_termination() -> void:
	await spawn_panel(1)
	panel.mistakes = 2
	submit(false)
	attempt_duplicate()
	check(game_overs == 1 and index() == 0, "Third strike failed to terminate exactly once")
	check(not panel.shutdown_button.visible and finished_scores.is_empty(), "Termination incorrectly showed shutdown")
	viewport.free()
	await get_tree().process_frame

func _run() -> void:
	for credit in [false, true]:
		is_credit = credit
		await test_full_shift()
		await test_early_shutdown()
		await test_termination()
	print("Applicant transition checks: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
