extends Control

# --- PANEL SETTINGS (RIGHT-TO-LEFT) ---
var is_open = false
var panel_width = 900
var slide_speed = 10.0
var closed_x : float
var open_x : float

var applicants_list = [] 
var current_case_index = 0
var actual_score = 1.0
var total_correct_answers = 0
var mistakes = 0 # --- NEW: Tracks player mistakes ---
var is_rejected: bool = false
var final_credit_amount = 500

# --- UI REFERENCES ---
@onready var grip_button = $Panel/GripButton
@onready var slider = $Panel/VSlider
@onready var submit_button = $Panel/SubmitButton
@onready var reject_button = $Panel/RejectButton
@onready var result_label = $Panel/ResultLabel
@onready var fraud_label = $Panel/FraudDetectionLabel
@onready var kyc_label = $Panel/KYCLabel
@onready var model_container = $"../ModelContainer"
@onready var credit_score_label = $Panel/CreditscoreLabel

@onready var general_info = $"Panel/TabContainer/General Info"
@onready var payment_history = $"Panel/TabContainer/Payment History"
@onready var arrears_tex = $Panel/TabContainer/Arrears
@onready var debt_ratio_tex = $"Panel/TabContainer/Debt Ratio"

func _ready():
	slider.value_changed.connect(_on_slider_value_changed)
	
	var screen_width = get_viewport_rect().size.x
	closed_x = screen_width - 10
	open_x = screen_width - panel_width
	position.x = closed_x 
	
	reject_button.pressed.connect(_on_reject_pressed)
	grip_button.pressed.connect(_on_grip_pressed)
	submit_button.pressed.connect(_on_submit)
	
	applicants_list = Database.get_session_applicants()
	
	load_applicant()

func _process(delta):
	var target_x = open_x if is_open else closed_x
	position.x = lerp(position.x, target_x, slide_speed * delta)

func _on_grip_pressed():
	is_open = !is_open

func _on_reject_pressed():
	is_rejected = true
	final_credit_amount = 0
	slider.set_value_no_signal(0.0)
	credit_score_label.text = "Proposed Credit: $0 (REJECTED)"

func _on_slider_value_changed(value: float):
	var display_score = int(lerp(0, 10000, value))
	credit_score_label.text = "Proposed Credit: $" + str(display_score)

# ==========================================
# STREAMLINED GAME LOOP
# ==========================================

func load_applicant():
	if current_case_index >= applicants_list.size():
		finish_game()
		return

	# Reset the UI for the new person
	slider.value = 0.0
	is_rejected = false
	credit_score_label.text = "Proposed Credit: $0"
	
	var data = applicants_list[current_case_index]
	
	fraud_label.text = "Fraud Detection: " + data["fraud_correct"].to_upper()
	fraud_label.modulate = Color.RED if data["fraud_correct"] == "sus" else Color.GREEN
	
	kyc_label.text = "KYC: " + ("INVALID" if data["kyc_correct"] == "sus" else "VALID")
	kyc_label.modulate = Color.RED if data["kyc_correct"] == "sus" else Color.GREEN

	var tex = data["credit_img"]
	if tex:
		general_info.texture = tex
		payment_history.texture = tex
		arrears_tex.texture = tex
		debt_ratio_tex.texture = tex

	# --- NEW: Grab the target score straight from the database! ---
	actual_score = data["credit_correct"]
	
	result_label.text = "Evaluating: " + data["name"]
	spawn_3d_model(data["model_scene"])

func spawn_3d_model(model_packed_scene: PackedScene):
	for child in model_container.get_children():
		child.queue_free()
		
	await get_tree().process_frame 
	
	if model_packed_scene:
		var new_model = model_packed_scene.instantiate()
		model_container.add_child(new_model)
		new_model.position = Vector3.ZERO

func _on_submit():
	# 1. Instantly grade the player's choice
	var player_choice = snapped(slider.value, 0.01)
	var diff = snapped(abs(player_choice - actual_score), 0.01)
	# --- NEW: Margin of Error set to exactly 0.20 ---
	if diff <= 0.20:
		total_correct_answers += 1
	else:
		# --- Mistake Tracker ---
		mistakes += 1
		if mistakes >= 3:
			submit_button.visible = false
			reject_button.visible = false
			slider.visible = false
			result_label.text = "TERMINATED"
			get_tree().current_scene.trigger_game_over()
			return # Stop loading the next applicant

	# 2. Immediately move to the next person!
	current_case_index += 1
	if current_case_index < applicants_list.size():
		load_applicant()
	else:
		finish_game()

func finish_game():
	is_open = false 
	self.visible = false 
	
	if get_tree().current_scene.has_method("show_final_result"):
		get_tree().current_scene.show_final_result(total_correct_answers)
