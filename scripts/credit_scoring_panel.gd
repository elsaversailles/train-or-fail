extends Control

# --- PANEL SETTINGS (RIGHT-TO-LEFT) ---
var is_open = false
var panel_width = 900
var slide_speed = 10.0
var closed_x : float
var open_x : float

# --- SCORING & DATA ---
const PENALTIES = {
	"fraud_sus": -0.5,
	"kyc_invalid": -0.4,
	"payment_bad": -0.2,
	"arrears": -0.2,
	"debt_high": -0.2
}

var current_case_index = 0
var actual_score = 1.0
var total_correct_answers = 0

var applicants_list = [
	{"name": "Elias Thorne", "fraud": "legit", "kyc": "valid", "payment": "good", "arrears": false, "debt_ratio": "low", "img": "res://images/applicants info/day1/a1/a1_item.jpg"},
	{"name": "Linda Miller", "fraud": "legit", "kyc": "valid", "payment": "good", "arrears": false, "debt_ratio": "high", "img": "res://images/applicants info/day1/a1/a1_item.jpg"},
	{"name": "Sarah Jenkins", "fraud": "legit", "kyc": "valid", "payment": "bad", "arrears": true, "debt_ratio": "low", "img": "res://images/applicants info/day1/a1/a1_item.jpg"},
	{"name": "Charlie Brown", "fraud": "legit", "kyc": "not_valid", "payment": "good", "arrears": false, "debt_ratio": "high", "img": "res://images/applicants info/day1/a1/a1_item.jpg"},
	{"name": "Marcus Vane", "fraud": "sus", "kyc": "not_valid", "payment": "bad", "arrears": true, "debt_ratio": "high", "img": "res://images/applicants info/day1/a1/a1_item.jpg"}
]

# --- UI REFERENCES ---
@onready var grip_button = $Panel/GripButton
@onready var slider = $Panel/VSlider
@onready var submit_button = $Panel/SubmitButton
@onready var result_label = $Panel/ResultLabel
@onready var fraud_label = $Panel/FraudDetectionLabel
@onready var kyc_label = $Panel/KYCLabel

@onready var general_info = $Panel/TabContainer/GeneralInfo
@onready var payment_history = $Panel/TabContainer/PaymentHistory
@onready var arrears_tex = $Panel/TabContainer/Arrears
@onready var debt_ratio_tex = $Panel/TabContainer/DebtRatio

func _ready():
	var screen_width = get_viewport_rect().size.x
	
	# Adjust the '+ 40' to move it right. 
	# Use '+ 100' if you want it almost entirely gone.
	# Use '+ 0' if you want the panel edge to touch the screen edge.
	closed_x = screen_width - 10
	
	open_x = screen_width - panel_width
	position.x = closed_x 

	grip_button.pressed.connect(_on_grip_pressed)
	submit_button.pressed.connect(_on_submit)
	load_applicant()

func _process(delta):
	var target_x = open_x if is_open else closed_x
	position.x = lerp(position.x, target_x, slide_speed * delta)

func _on_grip_pressed():
	is_open = !is_open

func load_applicant():
	if current_case_index >= applicants_list.size():
		finish_game()
		return

	var data = applicants_list[current_case_index]
	
	fraud_label.text = "Fraud: " + data.fraud.to_upper()
	fraud_label.modulate = Color.RED if data.fraud == "sus" else Color.GREEN
	kyc_label.text = "KYC: " + data.kyc.to_upper()
	kyc_label.modulate = Color.RED if data.kyc == "not_valid" else Color.GREEN

	var tex = load(data.img)
	if tex:
		general_info.texture = tex
		payment_history.texture = tex
		arrears_tex.texture = tex
		debt_ratio_tex.texture = tex

	var score = 1.0
	if data.fraud == "sus": score += PENALTIES.fraud_sus
	if data.kyc == "not_valid": score += PENALTIES.kyc_invalid
	if data.payment == "bad": score += PENALTIES.payment_bad
	if data.arrears: score += PENALTIES.arrears
	if data.debt_ratio == "high": score += PENALTIES.debt_high
	actual_score = clamp(score, 0.0, 1.0)
	
	submit_button.text = "Submit Decision"
	result_label.text = "Evaluating: " + data.name

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
	if value <= 0.20: return "Rejected (Critical Risk)"
	elif value <= 0.40: return "Poor (High Risk)"
	elif value <= 0.60: return "Average (Med Risk)"
	elif value <= 0.80: return "Good (Low Risk)"
	else: return "Excellent (Minimal Risk)"

func finish_game():
	is_open = false 
	get_tree().change_scene_to_file("res://scene/CreditScoring/CreditScoring1-2.tscn")
