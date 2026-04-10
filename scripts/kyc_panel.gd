extends Control

# -----------------------------
# DATA (5 APPLICANTS)
# -----------------------------
var applicants = [
	{
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"name": "Alicia Cruz",
		"correct": "legit"
	},
	{
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"name": "Anna Reyes",
		"correct": "sus"
	},
	{
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"name": "Rosa Dela Torre",
		"correct": "legit"
	},
	{
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"name": "Aponilaryo Limaga",
		"correct": "sus"
	},
	{
		"id_image": preload("res://images/applicants info/day1/a2/a2_id.png"),
		"name": "Carmen Bautista",
		"correct": "legit"
	}
]

# -----------------------------
# TRACKING
# -----------------------------
var current_index = 0
var player_answers = []
var final_score = 0

# -----------------------------
# NODE REFERENCES
# -----------------------------
@onready var applicant_label = $ApplicantLabel
@onready var name_label = $CustomerNameLabel

@onready var id_image = $IDPanel/IDImage
@onready var legit_button = $LegitButton
@onready var sus_button = $SusButton

# -----------------------------
# READY
# -----------------------------
func _ready():
	legit_button.pressed.connect(_on_legit_pressed)
	sus_button.pressed.connect(_on_sus_pressed)

	load_applicant(current_index)

# -----------------------------
# LOAD APPLICANT
# -----------------------------
func load_applicant(index):
	var data = applicants[index]

	applicant_label.text = "Customer %d / %d" % [index + 1, applicants.size()]
	name_label.text = data["name"]

	# Set ID image
	id_image.texture = data["id_image"]


# -----------------------------
# PLAYER INPUT
# -----------------------------
func _on_legit_pressed():
	submit_answer("legit")

func _on_sus_pressed():
	submit_answer("sus")

func submit_answer(answer):
	player_answers.append(answer)
	current_index += 1

	if current_index < applicants.size():
		load_applicant(current_index)
	else:
		finish_game()

# -----------------------------
# FINISH
# -----------------------------
func finish_game():
	final_score = 0

	for i in range(applicants.size()):
		if player_answers[i] == applicants[i]["correct"]:
			final_score += 1

	applicant_label.text = "All customers verified"

	legit_button.visible = false
	sus_button.visible = false

	show_result()

# -----------------------------
# RESULT
# -----------------------------
func show_result():
	get_tree().current_scene.show_final_result(final_score)
