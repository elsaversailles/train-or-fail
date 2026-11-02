extends Node

var level: Node3D
var viewport: SubViewport
var panel: Control
var display: TextureRect
var completed_scores: Array = []
var mode: String

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_tree().create_timer(55.0).timeout.connect(func(): push_error("Preview timed out"); get_tree().quit(2))
	_run.call_deferred()

func show_final_result(score: int) -> void:
	completed_scores.append(score)

func trigger_game_over() -> void:
	push_error("Unexpected preview termination")

func wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.godot/applicant-transition-review/%s-%s.png" % [mode, label])

func submit() -> void:
	if mode == "fraud":
		panel.submit_answer(panel.applicants[panel.current_index]["fraud_correct"])
	else:
		panel.slider.value = panel.actual_score
		panel._on_submit()

func _run() -> void:
	for credit in [false, true]:
		mode = "credit" if credit else "fraud"
		SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
		SaveManager.current_save_data["current_day"] = 7 if credit else 1
		var scene_path := "res://scene/CreditScoring/CreditScoring.tscn" if credit else "res://scene/FraudDetection/FraudDetection.tscn"
		level = load(scene_path).instantiate()
		level.set_script(null)
		level.get_node("MainChar").set_script(null)
		var tutorial := level.get_node("CanvasLayer/CSTutorial" if credit else "CanvasLayer/FDTutorial")
		tutorial.set_script(null)
		tutorial.hide()
		level.get_node("CanvasLayer").hide()
		level.get_node("PausePanel").set_script(null)
		add_child(level)
		viewport = level.get_node("Monitor/Screen/SubViewport")
		panel = viewport.get_node("CreditScoringPanel" if credit else "LeftSlidingPanel")
		panel.show()
		if credit:
			panel.applicants_list = panel.applicants_list.slice(0, 2)
		else:
			panel.applicants = panel.applicants.slice(0, 2)
		var canvas := CanvasLayer.new()
		canvas.layer = 100
		add_child(canvas)
		display = TextureRect.new()
		display.texture = viewport.get_texture()
		display.size = Vector2(1152, 648)
		canvas.add_child(display)
		await wait_seconds(0.5)
		await capture("initial")
		await panel.set_panel_open(true).finished
		await capture("review")
		submit()
		await wait_seconds(0.7)
		await capture("exit")
		await wait_seconds(0.6)
		await capture("entrance")
		while panel.is_transitioning:
			await get_tree().process_frame
		await capture("next")
		await panel.set_panel_open(true).finished
		submit()
		while panel.is_transitioning:
			await get_tree().process_frame
		await capture("shutdown")
		await wait_seconds(2.05)
		await capture("vibrating")
		panel.shutdown_button.pressed.emit()
		level.free()
		canvas.free()
		await get_tree().process_frame
	print("Rendered actual Fraud Detection and Credit Scoring monitor flows; shutdown scores: ", completed_scores)
	get_tree().quit()
