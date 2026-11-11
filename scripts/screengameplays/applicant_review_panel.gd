extends Control

# Shared timing keeps applicant transitions consistent across departments.
const PANEL_SLIDE_DURATION: float = 0.6
const APPLICANT_SLIDE_DURATION: float = 0.5
const APPLICANT_SLIDE_DISTANCE: float = 2.5
const SHUTDOWN_REMINDER_DELAY: float = 2.0
const MISTAKES_FOR_TERMINATION: int = 3

var is_transitioning: bool = false
var review_finished: bool = false
var mistakes: int = 0

var _panel_slide_tween: Tween
var _model_container: Node3D
var _model_home_position: Vector3
var _shutdown_button: Button
var _shutdown_idle_timer: Timer
var _shutdown_shake_tween: Tween
var _shutdown_button_home: Vector2
var _shutdown_requested: bool = false


func format_note_bullets(note: String) -> String:
	var sentence_breaks := RegEx.new()
	sentence_breaks.compile("(?<=[.!?])\\s+(?=[A-Z])")
	var lines := sentence_breaks.sub(note, "\n", true).split("\n", false)
	var bullets := PackedStringArray()
	for line in lines:
		var entry := line.strip_edges()
		if not entry.is_empty():
			bullets.append(entry if entry.begins_with("• ") else "• " + entry)
	return "\n".join(bullets)


func setup_review_transitions(container: Node3D, end_button: Button) -> void:
	_model_container = container
	_model_home_position = container.global_position
	_shutdown_button = end_button
	_shutdown_button.hide()
	_shutdown_button.disabled = true
	_shutdown_idle_timer = Timer.new()
	_shutdown_idle_timer.one_shot = true
	_shutdown_idle_timer.wait_time = SHUTDOWN_REMINDER_DELAY
	_shutdown_idle_timer.timeout.connect(_start_shutdown_reminder)
	add_child(_shutdown_idle_timer)


func animate_panel_to(target_x: float) -> Tween:
	if _panel_slide_tween and _panel_slide_tween.is_valid():
		_panel_slide_tween.kill()
	_panel_slide_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_panel_slide_tween.tween_property(self, "position:x", target_x, PANEL_SLIDE_DURATION)
	return _panel_slide_tween


func _applicant_slide_offset() -> Vector3:
	# The monitor camera is rotated, so world X is not screen-right.
	var camera := _model_container.get_viewport().get_camera_3d()
	var screen_right := camera.global_basis.x.normalized() if camera else Vector3.RIGHT
	return screen_right * APPLICANT_SLIDE_DISTANCE


func slide_applicant_out() -> void:
	if _model_container.get_child_count() > 0:
		var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(_model_container, "global_position", _model_home_position + _applicant_slide_offset(), APPLICANT_SLIDE_DURATION)
		await tween.finished
	clear_applicant_model()


func slide_applicant_in() -> void:
	if _model_container.get_child_count() == 0:
		return
	_model_container.global_position = _model_home_position - _applicant_slide_offset()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_model_container, "global_position", _model_home_position, APPLICANT_SLIDE_DURATION)
	await tween.finished


func clear_applicant_model() -> void:
	for child in _model_container.get_children():
		_model_container.remove_child(child)
		child.queue_free()
	_model_container.global_position = _model_home_position


func spawn_3d_model(model_packed_scene: PackedScene) -> void:
	clear_applicant_model()
	if not model_packed_scene:
		return
	var new_model := model_packed_scene.instantiate() as Node3D
	_model_container.add_child(new_model)
	new_model.position = Vector3.ZERO
	new_model.rotate_y(PI)

	var anim_player: AnimationPlayer = new_model.find_child("AnimationPlayer", true, false)
	if anim_player:
		if anim_player.autoplay != "":
			anim_player.play(anim_player.autoplay)
		elif anim_player.has_animation("idle"):
			anim_player.play("idle")
		elif anim_player.has_animation("Idle"):
			anim_player.play("Idle")
		elif anim_player.get_animation_list().size() > 0:
			anim_player.play(anim_player.get_animation_list()[0])


func show_shutdown_prompt() -> void:
	_shutdown_button_home = _shutdown_button.position
	_shutdown_button.show()
	_shutdown_button.disabled = false
	_shutdown_idle_timer.start()


func _start_shutdown_reminder() -> void:
	if _shutdown_requested or not review_finished or not _shutdown_button.is_visible_in_tree():
		return
	_shutdown_shake_tween = create_tween().set_loops()
	_shutdown_shake_tween.tween_property(_shutdown_button, "position:x", _shutdown_button_home.x - 4.0, 0.05)
	_shutdown_shake_tween.tween_property(_shutdown_button, "position:x", _shutdown_button_home.x + 4.0, 0.05)
	_shutdown_shake_tween.tween_property(_shutdown_button, "position:x", _shutdown_button_home.x - 3.0, 0.05)
	_shutdown_shake_tween.tween_property(_shutdown_button, "position:x", _shutdown_button_home.x + 3.0, 0.05)
	_shutdown_shake_tween.tween_property(_shutdown_button, "position:x", _shutdown_button_home.x, 0.05)
	_shutdown_shake_tween.tween_interval(0.6)


func begin_shutdown() -> bool:
	if is_transitioning or not review_finished or _shutdown_requested or not _shutdown_button.visible:
		return false
	_shutdown_requested = true
	_shutdown_button.disabled = true
	_shutdown_idle_timer.stop()
	if _shutdown_shake_tween and _shutdown_shake_tween.is_valid():
		_shutdown_shake_tween.kill()
	_shutdown_button.position = _shutdown_button_home
	return true


func shutdown_review(score: int) -> void:
	if not begin_shutdown():
		return
	hide()
	if mistakes >= MISTAKES_FOR_TERMINATION:
		get_tree().current_scene.trigger_game_over()
	else:
		get_tree().current_scene.show_final_result(score)
