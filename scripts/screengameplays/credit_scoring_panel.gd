extends Control

# --- PANEL SETTINGS (RIGHT-TO-LEFT) ---
var is_open: bool = false
var panel_width: float = 900.0
var slide_speed: float = 10.0
var closed_x: float
var open_x: float

var applicants_list: Array = []
var current_case_index: int = 0
var actual_score: float = 1.0
var total_correct_answers: int = 0
var mistakes: int = 0
var is_rejected: bool = false
var final_credit_amount: int = 0

# --- UI REFERENCES ---
@onready var grip_button = $Panel/GripButton
@onready var slider = $Panel/VSlider
@onready var submit_button = $Panel/SubmitButton
@onready var reject_button = $Panel/RejectButton
@onready var result_label = $Panel/ResultLabel
@onready var credit_score_label = $Panel/CreditscoreLabel
@onready var model_container = $"../ModelContainer"

# TabContainer references for customer documentation
@onready var general_info = $"Panel/TabContainer/General Info"
@onready var payment_history = $"Panel/TabContainer/Payment History"
@onready var arrears_tex = $"Panel/TabContainer/Arrears"
@onready var debt_ratio_tex = $"Panel/TabContainer/Debt Ratio"

func _ready():
	slider.value_changed.connect(_on_slider_value_changed)
	
	var screen_width = get_viewport_rect().size.x
	closed_x = screen_width - 10.0
	open_x = screen_width - panel_width
	position.x = closed_x
	
	reject_button.pressed.connect(_on_reject_pressed)
	grip_button.pressed.connect(_on_grip_pressed)
	submit_button.pressed.connect(_on_submit)
	
	applicants_list = Database.get_session_applicants()
	load_applicant()

func _process(delta: float):
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
	if value > 0.0:
		is_rejected = false
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

	# Retrieve target score directly from the applicant's dictionary
	actual_score = data.get("credit_correct", 0.0)
	result_label.text = "Evaluating: " + str(data.get("name", "Unknown"))
	
	spawn_3d_model(data.get("model_scene"))

func spawn_3d_model(model_packed_scene: PackedScene):
	for child in model_container.get_children():
		child.queue_free()
		
	await get_tree().process_frame
	
	if model_packed_scene:
		var new_model = model_packed_scene.instantiate()
		model_container.add_child(new_model)
		new_model.position = Vector3.ZERO

func _on_submit():
	var current_applicant = applicants_list[current_case_index]

	# 1. Calculate player selection (snapped to 0.01)
	var player_choice = 0.0 if is_rejected else snapped(slider.value, 0.01)

	# 2. Record decision for special characters based on score threshold
	if current_applicant.get("is_special", false):
		var verdict = "sus"
		if player_choice >= 0.6:
			verdict = "legit"
		elif player_choice <= 0.4:
			verdict = "sus"
		else:
			# Fallback if the slider sits between 0.41 and 0.59
			verdict = "sus"

		SaveManager.record_special_decision(current_applicant.get("id", ""), verdict)

	# 3. Grade accuracy against the target score (±0.20 margin of error)
	var diff = snapped(abs(player_choice - actual_score), 0.01)
	if diff <= 0.20:
		total_correct_answers += 1
	else:
		mistakes += 1
		if mistakes >= 3:
			submit_button.visible = false
			reject_button.visible = false
			slider.visible = false
			result_label.text = "TERMINATED"
			get_tree().current_scene.trigger_game_over()
			return

	# 4. Advance to the next applicant
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
