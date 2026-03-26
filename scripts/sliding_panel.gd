extends Control

# -----------------------------
# PANEL SETTINGS
# -----------------------------
var is_open = false
var panel_width = 944

# -----------------------------
# GAME DATA (5 APPLICANTS)
# -----------------------------
var applicants = [
	{
		"location": preload("res://images/applicants info/a1/a1_location.png"),
		"time": preload("res://images/applicants info/a1/a1_time.png"),
		"price": preload("res://images/applicants info/a1/a1_price.png"),
		"item": preload("res://images/applicants info/a1/a1_item.png"),
		"correct": "legit"
	},
	{
		"location": preload("res://images/applicants info/a2/a2_location.png"),
		"time": preload("res://images/applicants info/a2/a2_time.png"),
		"price": preload("res://images/applicants info/a2/a2_price.png"),
		"item": preload("res://images/applicants info/a2/a2_item.png"),
		"correct": "sus"
	},
	{
		"location": preload("res://images/applicants info/a3/a3_location.png"),
		"time": preload("res://images/applicants info/a3/a3_time.png"),
		"price": preload("res://images/applicants info/a3/a3_price.png"),
		"item": preload("res://images/applicants info/a3/a3_item.png"),
		"correct": "legit"
	},
	{
		"location": preload("res://images/applicants info/a4/a4_location.png"),
		"time": preload("res://images/applicants info/a4/a4_time.png"),
		"price": preload("res://images/applicants info/a4/a4_price.png"),
		"item": preload("res://images/applicants info/a4/a4_item.png"),
		"correct": "sus"
	},
	{
		"location": preload("res://images/applicants info/a5/a5_location.png"),
		"time": preload("res://images/applicants info/a5/a5_time.png"),
		"price": preload("res://images/applicants info/a5/a5_price.png"),
		"item": preload("res://images/applicants info/a5/a5_item.png"),
		"correct": "legit"
	}
]

# -----------------------------
# GAME TRACKING
# -----------------------------
var current_index = 0
var player_answers = []

# -----------------------------
# NODE REFERENCES
# -----------------------------
@onready var grip_button = $GripButton
@onready var legit_button = $VBoxContainer/LegitButton
@onready var sus_button = $VBoxContainer/SusButton

@onready var tab_container = $TabContainer
@onready var location_tab = $TabContainer/Location
@onready var time_tab = $TabContainer/Time
@onready var price_tab = $TabContainer/Price
@onready var item_tab = $TabContainer/Item

@onready var applicant_label = $ApplicantLabel

@onready var result_panel = $ResultPanel
@onready var result_label = $ResultPanel/ResultLabel
@onready var restart_button = $ResultPanel/RestartButton

# -----------------------------
# READY
# -----------------------------
func _ready():
	# Connect buttons
	grip_button.pressed.connect(grip_pressed)
	legit_button.pressed.connect(_on_legit_pressed)
	sus_button.pressed.connect(_on_sus_pressed)
	restart_button.pressed.connect(_on_restart_pressed)

	# Hide result panel at start
	result_panel.visible = false

	# Optional: resize tab area
	tab_container.custom_minimum_size = Vector2(600, 400)

	# Load first applicant
	load_applicant(current_index)

# -----------------------------
# PANEL SLIDE
# -----------------------------
func grip_pressed():
	slide_panel()

func slide_panel():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if is_open:
		# close → slide LEFT
		tween.tween_property(self, "position:x", -panel_width, 0.6)
	else:
		# open → slide RIGHT
		tween.tween_property(self, "position:x", -3, 0.6)
	
	is_open = !is_open

# -----------------------------
# LOAD APPLICANT
# -----------------------------
func load_applicant(index):
	var data = applicants[index]

	location_tab.texture = data["location"]
	time_tab.texture = data["time"]
	price_tab.texture = data["price"]
	item_tab.texture = data["item"]

	applicant_label.text = "Applicant %d / %d" % [index + 1, applicants.size()]

	# Always return to first tab
	tab_container.current_tab = 0

# -----------------------------
# PLAYER CHOICE
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
		show_results()

# -----------------------------
# RESULTS
# -----------------------------
func show_results():
	var score = 0

	for i in range(applicants.size()):
		if player_answers[i] == applicants[i]["correct"]:
			score += 1

	result_panel.visible = true
	result_label.text = "Game Over!\nScore: %d / %d" % [score, applicants.size()]

# -----------------------------
# RESTART
# -----------------------------
func _on_restart_pressed():
	current_index = 0
	player_answers.clear()
	result_panel.visible = false
	load_applicant(current_index)
