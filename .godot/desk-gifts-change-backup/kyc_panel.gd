extends "res://scripts/screengameplays/applicant_review_panel.gd"

# -----------------------------
# TRACKING & SETTINGS
# -----------------------------
var applicants = [] 
var current_index = 0
var player_answers = []
var final_score = 0

var rotation_speed: float = 150.0 
var is_rotating_left: bool = false
var is_rotating_right: bool = false

# --- ID ZOOM FEATURE ---
var is_id_zoomed: bool = false
var original_id_pos: Vector2
var zoom_scale: float = 3
var id_zoom_tween: Tween
var custom_cursor_img = preload("res://assets/cursor/cursor_magnifyingglass.svg")

# --- NOTE TRACKING ---
var is_note_open: bool = false
var note_tween: Tween

# -----------------------------
# NODE REFERENCES
# -----------------------------
@onready var applicant_label = $ApplicantLabel
@onready var name_label = $CustomerNameLabel
@onready var id_image = $IDPanel/IDImage
@onready var legit_button = $LegitButton
@onready var sus_button = $SusButton
@onready var shutdown_button = $ShutdownButton
@onready var model_container = $"../ModelContainer"

@onready var left_button = $LeftButton
@onready var center_button = $CenterButton
@onready var right_button = $RightButton

@onready var id_panel = $IDPanel 
@onready var zoom_icon: TextureRect = $IDPanel/ZoomIcon

# AI Risk Factor Label
@onready var ai_risk_value_label = $AIRiskValueLabel # Adjust path if placed under a container

# --- DATE LABEL REFERENCE ---
@onready var date_label: Label = $DateLabel

# --- NOTE NODE REFERENCES ---
@onready var note_icon_button = $NoteIconButton
@onready var note_popup_panel = $NotePopupPanel
@onready var note_text_label = $NotePopupPanel/NoteTextLabel

# -----------------------------
# READY
# -----------------------------
func _ready():
	for button in [legit_button, sus_button, left_button, center_button, right_button]:
		SoundEffects.set_button_sound(button, "")
	left_button.button_down.connect(func(): SoundEffects.play("inspect"))
	right_button.button_down.connect(func(): SoundEffects.play("inspect"))
	applicants = Database.get_session_applicants()
	
	legit_button.pressed.connect(_on_legit_pressed)
	sus_button.pressed.connect(_on_sus_pressed)
	shutdown_button.pressed.connect(_on_shutdown_pressed)
	setup_review_transitions(model_container, shutdown_button)

	left_button.button_down.connect(func(): is_rotating_left = true)
	left_button.button_up.connect(func(): is_rotating_left = false)
	right_button.button_down.connect(func(): is_rotating_right = true)
	right_button.button_up.connect(func(): is_rotating_right = false)
	center_button.pressed.connect(_on_center_pressed)

	# --- ID ZOOM FEATURE SETUP ---
	original_id_pos = id_panel.position
	id_panel.z_index = 0
	id_panel.gui_input.connect(_on_id_panel_clicked)

	# --- NOTE SIGNALS & SETUP ---
	note_icon_button.pressed.connect(_on_toggle_note)
	note_popup_panel.gui_input.connect(_on_note_popup_input)
	note_popup_panel.visible = false
	note_icon_button.z_index = 1 # Sits below zoomed ID (z_index 6)
	note_popup_panel.z_index = 10 # Popped-out note sits above everything

	update_date_label()
	load_applicant(current_index)

# -----------------------------
# DATE DISPLAY LOGIC
# -----------------------------
func update_date_label():
	if not date_label:
		return
		
	var current_day = int(SaveManager.current_save_data.get("current_day", 4))
	match current_day:
		4:
			date_label.text = "12/7/26"
		5:
			date_label.text = "12/8/26"
		6:
			date_label.text = "12/9/26"
		_:
			date_label.text = "12/7/26"

# -----------------------------
# NOTE POPUP LOGIC
# -----------------------------
func _on_toggle_note():
	if is_transitioning or review_finished:
		return
	if is_note_open:
		close_note()
	else:
		open_note()

func _on_note_popup_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close_note()

func open_note():
	stop_note_tween()
	is_note_open = true
	note_icon_button.set_pressed_no_signal(true)
	note_popup_panel.move_to_front()
	note_popup_panel.pivot_offset = note_popup_panel.size / 2.0
	note_popup_panel.scale = Vector2(0.8, 0.8)
	note_popup_panel.modulate.a = 0.0
	note_popup_panel.visible = true
	
	note_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	note_tween.parallel().tween_property(note_popup_panel, "scale", Vector2.ONE, 0.2)
	note_tween.parallel().tween_property(note_popup_panel, "modulate:a", 1.0, 0.15)

func close_note():
	stop_note_tween()
	is_note_open = false
	note_icon_button.set_pressed_no_signal(false)
	note_popup_panel.pivot_offset = note_popup_panel.size / 2.0
	
	note_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	note_tween.parallel().tween_property(note_popup_panel, "scale", Vector2(0.8, 0.8), 0.15)
	note_tween.parallel().tween_property(note_popup_panel, "modulate:a", 0.0, 0.15)
	note_tween.tween_callback(func(): note_popup_panel.visible = false)

func close_note_immediately():
	stop_note_tween()
	is_note_open = false
	note_icon_button.set_pressed_no_signal(false)
	note_popup_panel.visible = false
	note_popup_panel.scale = Vector2.ONE
	note_popup_panel.modulate.a = 1.0

func stop_note_tween() -> void:
	if note_tween and note_tween.is_valid():
		note_tween.kill()
	note_tween = null

# -----------------------------
# ID ZOOM LOGIC
# -----------------------------
func _on_id_panel_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_id_zoom()

func toggle_id_zoom():
	if is_transitioning or review_finished:
		return
	if id_zoom_tween and id_zoom_tween.is_valid():
		id_zoom_tween.kill()
	is_id_zoomed = !is_id_zoomed
	
	id_zoom_tween = create_tween().set_parallel(true)
	id_zoom_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if is_id_zoomed:
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		id_panel.z_index = 6 # Forces zoomed ID above NoteIconButton and other UI buttons
		id_panel.move_to_front()
		zoom_icon.visible = false
		var target_pos = Vector2(200, 70) 
		
		id_zoom_tween.tween_property(id_panel, "position", target_pos, 0.3)
		id_zoom_tween.tween_property(id_panel, "scale", Vector2(zoom_scale, zoom_scale), 0.3)
	else:
		Input.set_custom_mouse_cursor(custom_cursor_img, Input.CURSOR_ARROW, Vector2(0, 0))
		zoom_icon.visible = true
		id_zoom_tween.tween_property(id_panel, "position", original_id_pos, 0.3)
		id_zoom_tween.tween_property(id_panel, "scale", Vector2.ONE, 0.3)
		id_zoom_tween.chain().tween_callback(func(): id_panel.z_index = 0)

func reset_id_zoom_immediately() -> void:
	if id_zoom_tween and id_zoom_tween.is_valid():
		id_zoom_tween.kill()
	id_zoom_tween = null
	is_id_zoomed = false
	id_panel.z_index = 0
	id_panel.scale = Vector2.ONE
	id_panel.position = original_id_pos
	zoom_icon.visible = true
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)

func set_review_controls_enabled(enabled: bool) -> void:
	for button in [legit_button, sus_button, left_button, center_button, right_button, note_icon_button]:
		button.disabled = not enabled
	id_panel.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if not enabled:
		is_rotating_left = false
		is_rotating_right = false

# -----------------------------
# CONTINUOUS ROTATION LOGIC
# -----------------------------
func _process(delta):
	if is_transitioning or review_finished:
		return
	if is_rotating_left:
		model_container.rotation_degrees.y -= rotation_speed * delta
	elif is_rotating_right:
		model_container.rotation_degrees.y += rotation_speed * delta
		
	model_container.rotation_degrees.y = clamp(model_container.rotation_degrees.y, 0, 180)

func _on_center_pressed():
	if is_transitioning or review_finished:
		return
	SoundEffects.play("inspect")
	model_container.rotation_degrees.y = 90

# -----------------------------
# GAME LOOP
# -----------------------------
func load_applicant(index):
	var data = applicants[index]

	applicant_label.text = "Customer %d / %d" % [index + 1, applicants.size()]
	name_label.text = data["name"]
	id_image.texture = data["id_image"]
	ai_risk_value_label.text = str(data.get("ai_risk_factor", "N/A"))
	
	# Load KYC note (checks "kyc_note" first for shared characters like Mark Krazy, then "note")
	var applicant_note = data.get("kyc_note", data.get("note", "No additional notes for this customer."))
	note_text_label.text = format_note_bullets(str(applicant_note))
	close_note_immediately()
	
	spawn_3d_model(data["model_scene"])
	
	model_container.rotation_degrees.y = 90
	is_rotating_left = false
	is_rotating_right = false
	
	reset_id_zoom_immediately()

func _on_legit_pressed():
	submit_answer("legit")

func _on_sus_pressed():
	submit_answer("sus")

func submit_answer(answer):
	if is_transitioning or review_finished or current_index >= applicants.size():
		return
	SoundEffects.play("accepted" if answer == "legit" else "rejected")
	is_transitioning = true
	set_review_controls_enabled(false)
	close_note_immediately()
	reset_id_zoom_immediately()
	var current_applicant = applicants[current_index]

	# Record special story applicant decisions (e.g., Mark Krazy on Day 5)
	if current_applicant.get("is_special", false):
		var char_id = current_applicant.get("id", "")
		if not SaveManager.current_save_data.has("special_decisions"):
			SaveManager.current_save_data["special_decisions"] = {}
		SaveManager.current_save_data["special_decisions"][char_id] = answer

	var correct_answer = current_applicant["kyc_correct"]
	if answer != correct_answer:
		mistakes += 1

	player_answers.append(answer)
	current_index += 1

	await slide_applicant_out()
	if current_index < applicants.size():
		load_applicant(current_index)
		await slide_applicant_in()
		is_transitioning = false
		set_review_controls_enabled(true)
	else:
		finish_game()

func finish_game():
	review_finished = true
	set_review_controls_enabled(false)
	final_score = 0
	for i in range(player_answers.size()):
		if player_answers[i] == applicants[i]["kyc_correct"]:
			final_score += 1

	close_note_immediately()
	reset_id_zoom_immediately()
	for control in [legit_button, sus_button, left_button, center_button, right_button, note_icon_button, id_panel, name_label, ai_risk_value_label, $AIRiskLabel]:
		control.hide()
	applicant_label.text = "All customers verified"
	is_transitioning = false
	show_shutdown_prompt()

func _on_shutdown_pressed():
	shutdown_review(final_score)

func _on_id_panel_mouse_entered() -> void:
	if not is_id_zoomed and not is_transitioning and not review_finished:
		Input.set_custom_mouse_cursor(custom_cursor_img, Input.CURSOR_ARROW, Vector2(0, 0))

func _on_id_panel_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
