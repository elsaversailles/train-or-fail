extends Control

# --- PANEL SETTINGS (RIGHT-TO-LEFT) ---
var is_open = false
var panel_width = 900
var slide_speed = 10.0
var closed_x : float
var open_x : float

var applicants_list = [] # Filled by Autoload
var current_case_index = 0
var actual_score = 1.0
var total_correct_answers = 0
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

# --- SCORING & DATA ---
const PENALTIES = {
	"fraud_sus": -0.4,
	"kyc_invalid": -0.3, # We use this when "kyc_correct" == "sus"
	"payment_bad": -0.1,
	"arrears": -0.1,
	"debt_high": -0.1
}


func _ready():
	slider.value_changed.connect(_on_slider_value_changed)
	_on_slider_value_changed(slider.value)
	
	var screen_width = get_viewport_rect().size.x
	closed_x = screen_width - 10
	open_x = screen_width - panel_width
	position.x = closed_x 
	
	reject_button.pressed.connect(_on_reject_pressed)
	

	grip_button.pressed.connect(_on_grip_pressed)
	submit_button.pressed.connect(_on_submit)
	
	# --- FETCH DATA FROM AUTOLOAD ---
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
	
	# Snap the slider back to the left, but DON'T trigger the math function
	slider.set_value_no_signal(0.0)
	
	# Change the label to show it was heavily rejected
	credit_score_label.text = "Proposed Credit: $0 (REJECTED)"

func _on_slider_value_changed(value: float):
	# 'value' is your slider's current position (0.0 to 1.0)
	
	# lerp translates that 0.0 - 1.0 into a number between 500 and 10000.
	# We use int() to chop off any messy decimals so it looks clean!
	var display_score = int(lerp(0, 10000, value))
	
	# Update the text on the screen!
	credit_score_label.text = "Proposed Credit: $" + str(display_score)

func load_applicant():
	if current_case_index >= applicants_list.size():
		finish_game()
		return

	var data = applicants_list[current_case_index]
	
	# Mapping labels using the updated keys
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

	# Calculate actual target score based on dictionary
	var score = 1.0
	if data["fraud_correct"] == "sus": score += PENALTIES.fraud_sus
	if data["kyc_correct"] == "sus": score += PENALTIES.kyc_invalid
	if data["payment"] == "bad": score += PENALTIES.payment_bad
	if data["arrears"]: score += PENALTIES.arrears
	if data["debt_ratio"] == "high": score += PENALTIES.debt_high
	actual_score = clamp(score, 0.0, 1.0)
	
	submit_button.text = "Submit Decision"
	result_label.text = "Evaluating: " + data["name"]
	
	spawn_3d_model(data["model_scene"])

func spawn_3d_model(model_packed_scene: PackedScene):
	# 1. Delete whatever 3D model is currently standing there
	for child in model_container.get_children():
		child.queue_free()
		
	# 2. Wait for a split second to ensure it's deleted before spawning the new one
	await get_tree().process_frame 
	
	# 3. Spawn the new model!
	if model_packed_scene:
		var new_model = model_packed_scene.instantiate()
		model_container.add_child(new_model)
		
		# Optional: Ensure the model spawns at the exact center (0,0,0) of the container
		new_model.position = Vector3.ZERO

func _on_submit():
	if submit_button.text == "Next Applicant" or submit_button.text == "Finish Session":
		current_case_index += 1
		if current_case_index < applicants_list.size():
			load_applicant()
		else:
			finish_game()
		return

	var player_choice = snapped(slider.value, 0.01)
	var diff = abs(player_choice - actual_score)
	
	if diff <= 0.15:
		total_correct_answers += 1
		result_label.text = "PERFECT ANALYSIS"
	else:
		result_label.text = "INCORRECT\nTarget: %.2f" % actual_score

	result_label.text += "\nRating: " + get_risk_label(player_choice)
	
	if current_case_index == applicants_list.size() - 1:
		submit_button.text = "Finish Session"
	else:
		submit_button.text = "Next Applicant"

func get_risk_label(value):
	if value < 0.20: return "Rejected (Critical Risk)"
	elif value < 0.40: return "Poor (High Risk)"
	elif value < 0.60: return "Average (Med Risk)"
	elif value < 0.80: return "Good (Low Risk)"
	else: return "Excellent (Minimal Risk)"

func finish_game():
	is_open = false 
	self.visible = false # Hide the tablet/UI so it doesn't block the screen
	
	# Pass the 'total_correct_answers' to the main scene's Result Panel
	if get_tree().current_scene.has_method("show_final_result"):
		get_tree().current_scene.show_final_result(total_correct_answers)
