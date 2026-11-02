extends Node

var level: Node3D
var viewport: SubViewport
var panel: Control
var completed_scores: Array = []

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_tree().create_timer(30.0).timeout.connect(func(): push_error("KYC preview timed out"); get_tree().quit(2))
	_run.call_deferred()

func show_final_result(score: int) -> void:
	completed_scores.append(score)

func trigger_game_over() -> void:
	push_error("Unexpected KYC preview termination")

func wait_seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://.godot/kyc-transition-review/kyc-%s.png" % label)

func submit() -> void:
	panel.submit_answer(panel.applicants[panel.current_index]["kyc_correct"])

func _run() -> void:
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data["current_day"] = 4
	level = load("res://scene/KnowYourCustomer/KnowYourCustomer.tscn").instantiate()
	level.set_script(null)
	level.get_node("MainChar").set_script(null)
	var tutorial := level.get_node("CanvasLayer/KYCTutorial")
	tutorial.set_script(null)
	tutorial.hide()
	level.get_node("CanvasLayer").hide()
	level.get_node("PausePanel").set_script(null)
	add_child(level)
	viewport = level.get_node("Monitor/Screen/SubViewport")
	panel = viewport.get_node("KYCPanel")
	panel.applicants = panel.applicants.slice(0, 2)
	panel.load_applicant(0)
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.size = Vector2(1152, 648)
	canvas.add_child(display)
	await wait_seconds(0.5)
	await capture("review")
	panel.model_container.rotation_degrees.y = 120.0
	submit()
	await wait_seconds(0.2)
	await capture("exit")
	await wait_seconds(0.55)
	await capture("entrance")
	while panel.is_transitioning:
		await get_tree().process_frame
	await capture("next")
	submit()
	while panel.is_transitioning:
		await get_tree().process_frame
	await capture("shutdown")
	await wait_seconds(2.05)
	await capture("vibrating")
	# Exercise the actual button hit area through the monitor viewport.
	var button_center: Vector2 = panel.shutdown_button.get_global_rect().get_center()
	viewport.notify_mouse_entered()
	var motion := InputEventMouseMotion.new()
	motion.position = button_center
	viewport.push_input(motion, true)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = button_center
		click.pressed = down
		viewport.push_input(click, true)
		await get_tree().process_frame
	if completed_scores != [2]:
		push_error("KYC shutdown click failed: %s" % [completed_scores])
		get_tree().quit(1)
		return
	print("Rendered actual KYC monitor flow; clicked shutdown successfully; score: ", completed_scores)
	get_tree().quit()
