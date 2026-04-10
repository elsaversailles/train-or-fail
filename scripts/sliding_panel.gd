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
		"location": preload("res://images/applicants info/day1/a1/a1_location.png"),
		"item": preload("res://images/applicants info/day1/a1/a1_item.jpg"),
		"time": "11:45 AM",
		"price": "₱1,550",
		"correct": "legit"
	},
	{
		"location": preload("res://images/applicants info/day1/a2/a2_location.png"),
		"item": preload("res://images/applicants info/day1/a2/a2_item.png"),
		"time": "3:12 AM",
		"price": "₱450,000",
		"correct": "sus"
	},
	{
		"location": preload("res://images/applicants info/day1/a3/a3_location.png"),
		"item": preload("res://images/applicants info/day1/a3/a3_item.jpg"),
		"time": "8:30 AM",
		"price": "₱210",
		"correct": "legit"
	},
	{
		"location": preload("res://images/applicants info/day1/a4/a4_location.png"),
		"item": preload("res://images/applicants info/day1/a4/a4_item.jpg"),
		"time": "2:22 AM",
		"price": "₱25,000",
		"correct": "sus"
	},
	{
		"location": preload("res://images/applicants info/day1/a5/a5_location.png"),
		"item": preload("res://images/applicants info/day1/a5/a5_item.png"),
		"time": "5:30 PM",
		"price": "₱3,200",
		"correct": "legit"
	}
]

# -----------------------------
# GAME TRACKING
# -----------------------------
var current_index = 0
var player_answers = []
var final_score = 0

# -----------------------------
# NODE REFERENCES
# -----------------------------
@onready var grip_button = $ButtonPanel/GripButton
@onready var legit_button = $ButtonPanel/LegitButton
@onready var sus_button = $ButtonPanel/SusButton
@onready var shutdown_button = $ButtonPanel/ShutdownButton

@onready var applicant_label = $ApplicantLabel
@onready var location_label = $LocationLabel
@onready var item_label = $ItemLabel
@onready var location_button = $LocationTextureButton
@onready var item_button = $ItemTextureButton
@onready var time_value_label = $TimeValueLabel
@onready var price_value_label = $PriceValueLabel

# -----------------------------
# ORIGINAL POSITIONS / SIZES FOR SWAP
# -----------------------------
var location_original_position: Vector2
var item_original_position: Vector2

var location_original_size: Vector2
var item_original_size: Vector2

var location_label_original_position: Vector2
var item_label_original_position: Vector2

var images_swapped = false

# -----------------------------
# READY
# -----------------------------
func _ready():
	# Connect buttons
	grip_button.pressed.connect(grip_pressed)
	legit_button.pressed.connect(_on_legit_pressed)
	sus_button.pressed.connect(_on_sus_pressed)
	shutdown_button.pressed.connect(_on_shutdown_pressed)

	# Connect image clicks
	location_button.pressed.connect(_on_swap_images)
	item_button.pressed.connect(_on_swap_images)

	# Hide shutdown at start
	shutdown_button.visible = false

	# Save original positions
	location_original_position = location_button.position
	item_original_position = item_button.position

	# Save original sizes
	location_original_size = location_button.size
	item_original_size = item_button.size

	# Save label positions
	location_label_original_position = location_label.position
	item_label_original_position = item_label.position

	# Default layer order:
	# Item is small at start -> should be on top
	location_button.z_index = 1
	item_button.z_index = 2
	location_label.z_index = 1
	item_label.z_index = 2

	# Load first applicant
	load_applicant(current_index)

# -----------------------------
# PANEL SLIDE
# -----------------------------
func grip_pressed():
	var main = get_tree().current_scene
	
	if main.has_node("MainChar"):
		var player = main.get_node("MainChar")
		if not player.is_focusing_screen:
			return

	slide_panel()

func slide_panel():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if is_open:
		# Close panel
		tween.tween_property(self, "position:x", -panel_width, 0.6)
	else:
		# Open panel
		tween.tween_property(self, "position:x", -3, 0.6)

	is_open = !is_open

# -----------------------------
# LOAD APPLICANT
# -----------------------------
func load_applicant(index):
	var data = applicants[index]

	# Set applicant images
	location_button.texture_normal = data["location"]
	item_button.texture_normal = data["item"]

	# Set text values
	time_value_label.text = str(data["time"])
	price_value_label.text = str(data["price"])

	# Applicant progress text
	applicant_label.text = "Applicant %d / %d" % [index + 1, applicants.size()]

	# Reset image layout
	reset_image_positions()

# -----------------------------
# SWAP IMAGE + LABEL + SIZE + LAYER
# -----------------------------
func _on_swap_images():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	if not images_swapped:
		# When swapped:
		# Location becomes SMALL -> should be ON TOP
		# Item becomes BIG -> should be BEHIND
		location_button.z_index = 2
		item_button.z_index = 1
		location_label.z_index = 2
		item_label.z_index = 1

		# Swap image positions
		tween.parallel().tween_property(location_button, "position", item_original_position, 0.3)
		tween.parallel().tween_property(item_button, "position", location_original_position, 0.3)

		# Swap image sizes
		tween.parallel().tween_property(location_button, "size", item_original_size, 0.3)
		tween.parallel().tween_property(item_button, "size", location_original_size, 0.3)

		# Swap label positions
		tween.parallel().tween_property(location_label, "position", item_label_original_position, 0.3)
		tween.parallel().tween_property(item_label, "position", location_label_original_position, 0.3)

	else:
		# Return to normal:
		# Item is SMALL -> should be ON TOP
		# Location is BIG -> should be BEHIND
		location_button.z_index = 1
		item_button.z_index = 2
		location_label.z_index = 1
		item_label.z_index = 2

		# Return image positions
		tween.parallel().tween_property(location_button, "position", location_original_position, 0.3)
		tween.parallel().tween_property(item_button, "position", item_original_position, 0.3)

		# Return image sizes
		tween.parallel().tween_property(location_button, "size", location_original_size, 0.3)
		tween.parallel().tween_property(item_button, "size", item_original_size, 0.3)

		# Return label positions
		tween.parallel().tween_property(location_label, "position", location_label_original_position, 0.3)
		tween.parallel().tween_property(item_label, "position", item_label_original_position, 0.3)

	images_swapped = !images_swapped

func reset_image_positions():
	# Reset image positions
	location_button.position = location_original_position
	item_button.position = item_original_position

	# Reset image sizes
	location_button.size = location_original_size
	item_button.size = item_original_size

	# Reset label positions
	location_label.position = location_label_original_position
	item_label.position = item_label_original_position

	# Reset layer order
	location_button.z_index = 1
	item_button.z_index = 2
	location_label.z_index = 1
	item_label.z_index = 2

	images_swapped = false

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
		finish_applicants()

# -----------------------------
# AFTER 5TH APPLICANT
# -----------------------------
func finish_applicants():
	final_score = 0

	for i in range(applicants.size()):
		if player_answers[i] == applicants[i]["correct"]:
			final_score += 1

	applicant_label.text = "All applicants reviewed"

	legit_button.visible = false
	sus_button.visible = false
	shutdown_button.visible = true

# -----------------------------
# SHUTDOWN BUTTON
# -----------------------------
func _on_shutdown_pressed():
	get_tree().current_scene.show_final_result(final_score)
	self.visible = false
