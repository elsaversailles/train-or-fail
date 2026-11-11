extends "res://scripts/screengameplays/applicant_review_panel.gd"

# --- PANEL SETTINGS (RIGHT-TO-LEFT) ---
var is_open: bool = false
var panel_width: float = 900.0
var closed_x: float
var open_x: float

# --- GRIP BUTTON GLOW SETTINGS ---
@export var grip_idle_time: float = 3.0 # Seconds before grip button starts glowing
@export var grip_glow_color: Color = Color(1.6, 1.5, 0.8, 1.0) # Bright warm glow color
var grip_idle_timer: Timer
var grip_glow_tween: Tween

var applicants_list: Array = []
var current_case_index: int = 0
var actual_score: float = 1.0
var total_correct_answers: int = 0
var is_rejected: bool = false
var final_credit_amount: int = 0

# --- UI REFERENCES ---
@onready var grip_button = $Panel/GripButton
@onready var slider = $Panel/VSlider
@onready var submit_button = $Panel/SubmitButton
@onready var reject_button = $Panel/RejectButton
@onready var shutdown_button = $Panel/ShutdownButton
@onready var result_label = $Panel/ResultLabel
@onready var credit_score_label = $Panel/CreditscoreLabel
@onready var ai_risk_value_label = $Panel/AIRiskValueLabel
@onready var model_container = $"../ModelContainer"

# TabContainer references for customer documentation
@onready var general_info = $"Panel/TabContainer/General Info"
@onready var payment_history = $"Panel/TabContainer/Payment History"
@onready var arrears_tex = $"Panel/TabContainer/Arrears"
@onready var debt_ratio_tex = $"Panel/TabContainer/Debt Ratio"

func _ready():
	SoundEffects.set_button_sound(submit_button, "")
	slider.value_changed.connect(_on_slider_value_changed)
	var documents: TabContainer = $Panel/TabContainer
	documents.set_tab_tooltip(0, "Review the applicant's general information.")
	documents.set_tab_tooltip(1, "Review the applicant's previous payments.")
	documents.set_tab_tooltip(2, "Review overdue payments and outstanding arrears.")
	documents.set_tab_tooltip(3, "Review how the applicant's debt compares with income.")
	
	var screen_width = get_viewport_rect().size.x
	closed_x = screen_width - 10.0
	open_x = screen_width - panel_width
	position.x = closed_x
	
	reject_button.pressed.connect(_on_reject_pressed)
	grip_button.pressed.connect(_on_grip_pressed)
	submit_button.pressed.connect(_on_submit)
	shutdown_button.pressed.connect(_on_shutdown_pressed)
	setup_review_transitions(model_container, shutdown_button)
	
	setup_grip_glow_timer()
	
	applicants_list = Database.get_session_applicants()
	load_applicant()

# ==========================================
# GRIP BUTTON IDLE GLOW LOGIC
# ==========================================

func setup_grip_glow_timer():
	grip_idle_timer = Timer.new()
	grip_idle_timer.wait_time = grip_idle_time
	grip_idle_timer.one_shot = true
	grip_idle_timer.timeout.connect(_on_grip_idle_timeout)
	add_child(grip_idle_timer)
	grip_idle_timer.start()

func _on_grip_idle_timeout():
	# Only glow if the panel is closed
	if not is_open and not is_transitioning and not review_finished:
		start_grip_glow()

func start_grip_glow():
	if grip_glow_tween and grip_glow_tween.is_valid():
		grip_glow_tween.kill()
		
	grip_button.pivot_offset = grip_button.size / 2.0
	grip_glow_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	grip_glow_tween.tween_property(grip_button, "self_modulate", grip_glow_color, 0.55)
	grip_glow_tween.parallel().tween_property(grip_button, "scale", Vector2(1.08, 1.08), 0.55)
	grip_glow_tween.tween_property(grip_button, "self_modulate", Color.WHITE, 0.55)
	grip_glow_tween.parallel().tween_property(grip_button, "scale", Vector2.ONE, 0.55)

func stop_grip_glow(restart_timer: bool = false):
	if grip_glow_tween and grip_glow_tween.is_valid():
		grip_glow_tween.kill()
	grip_button.self_modulate = Color.WHITE
	grip_button.scale = Vector2.ONE
	
	if grip_idle_timer:
		if restart_timer:
			grip_idle_timer.start(grip_idle_time)
		else:
			grip_idle_timer.stop()

func _on_grip_pressed():
	if is_transitioning or review_finished:
		return
	set_panel_open(not is_open)

func set_panel_open(open: bool) -> Tween:
	is_open = open
	stop_grip_glow(not open and not is_transitioning and not review_finished)
	return animate_panel_to(open_x if open else closed_x)

func set_review_controls_enabled(enabled: bool) -> void:
	grip_button.disabled = not enabled
	submit_button.disabled = not enabled
	reject_button.disabled = not enabled
	slider.editable = enabled

func _on_reject_pressed():
	if is_transitioning or review_finished:
		return
	is_rejected = true
	final_credit_amount = 0
	slider.set_value_no_signal(0.0)
	credit_score_label.text = "Proposed Credit: $0 (REJECTED)"
	reject_button.button_pressed = true

func _on_slider_value_changed(value: float):
	if is_transitioning or review_finished:
		return
	if value > 0.0:
		is_rejected = false
		reject_button.button_pressed = false

	var display_score = int(lerp(0, 10000, value))
	credit_score_label.text = "Proposed Credit: $" + str(display_score)

# ==========================================
# APPLICANT EVALUATION LOOP
# ==========================================

func load_applicant():
	if current_case_index >= applicants_list.size():
		finish_game()
		return

	# Reset selection state
	slider.set_value_no_signal(0.0)
	is_rejected = false
	reject_button.button_pressed = false
	credit_score_label.text = "Proposed Credit: $0"

	var data = applicants_list[current_case_index]

	# Assign document textures to each tab
	if data.has("general_info_img") and data["general_info_img"]:
		general_info.texture = data["general_info_img"]
	if data.has("payment_history_img") and data["payment_history_img"]:
		payment_history.texture = data["payment_history_img"]
	if data.has("arrears_img") and data["arrears_img"]:
		arrears_tex.texture = data["arrears_img"]
	if data.has("debt_ratio_img") and data["debt_ratio_img"]:
		debt_ratio_tex.texture = data["debt_ratio_img"]

	# Retrieve target score and AI risk factor
	actual_score = data.get("credit_correct", 0.0)
	result_label.text = "Evaluating: " + str(data.get("name", "Unknown"))
	ai_risk_value_label.text = str(data.get("ai_risk_factor", "N/A"))
	
	spawn_3d_model(data.get("model_scene"))

func _on_submit():
	if is_transitioning or review_finished or current_case_index >= applicants_list.size():
		return
	is_transitioning = true
	set_review_controls_enabled(false)
	var current_applicant = applicants_list[current_case_index]

	# 1. Calculate player selection (snapped to 0.01)
	var player_choice = 0.0 if is_rejected else snapped(slider.value, 0.01)
	SoundEffects.play("accepted" if player_choice > 0.0 else "rejected")

	# 2. Record decision for special characters based on score threshold
	if current_applicant.get("is_special", false):
		var verdict = "sus"
		if player_choice >= 0.6:
			verdict = "legit"
		elif player_choice <= 0.4:
			verdict = "sus"
		else:
			verdict = "sus"

		SaveManager.record_special_decision(current_applicant.get("id", ""), verdict)

	# 3. Grade accuracy against the target score (±0.20 margin of error)
	var diff = snapped(abs(player_choice - actual_score), 0.01)
	if diff <= 0.20:
		total_correct_answers += 1
	else:
		mistakes += 1

	# 4. Advance to the next applicant
	current_case_index += 1
	await set_panel_open(false).finished
	await slide_applicant_out()
	if current_case_index < applicants_list.size():
		load_applicant()
		await slide_applicant_in()
		await set_panel_open(true).finished
		is_transitioning = false
		set_review_controls_enabled(true)
	else:
		await finish_game()

func finish_game():
	review_finished = true
	is_transitioning = true
	set_review_controls_enabled(false)
	stop_grip_glow(false)
	submit_button.hide()
	reject_button.hide()
	slider.hide()
	$Panel/Label.hide()
	$Panel/TabContainer.hide()
	$Panel/AIRiskLabel.hide()
	ai_risk_value_label.hide()
	credit_score_label.hide()
	result_label.text = "All applicants reviewed"
	await set_panel_open(true).finished
	is_transitioning = false
	show_shutdown_prompt()

func _on_shutdown_pressed():
	shutdown_review(total_correct_answers)
