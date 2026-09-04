extends Control

# -----------------------------
# PANEL SETTINGS
# -----------------------------
var is_open = false
var panel_width = 944

# -----------------------------
# GAME TRACKING
# -----------------------------
var applicants = [] # Now empty! Gets filled by the Database
var current_index = 0
var player_answers = []
var final_score = 0

# -----------------------------
# NODE REFERENCES
# -----------------------------
@onready var button_panel: Panel = $ButtonPanel/Panel
@onready var grip_button = $ButtonPanel/GripButton
@onready var legit_button = $ButtonPanel/LegitButton
@onready var sus_button = $ButtonPanel/SusButton
@onready var shutdown_button = $ButtonPanel/ShutdownButton
@onready var model_container = $"../ModelContainer"

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

var mistakes = 0

# -----------------------------
# READY
# -----------------------------
func _ready():
	# --- 1. CRITICAL DAY 2 FIXES ---
	self.visible = true # Force it to show up!
	is_open = false
	position.x = -panel_width # Ensure it starts tucked away so the grip button is clickable
	
	# --- FETCH DATA FROM AUTOLOAD ---
	applicants = Database.get_session_applicants()

	grip_button.pressed.connect(grip_pressed)
	legit_button.pressed.connect(_on_legit_pressed)
	sus_button.pressed.connect(_on_sus_pressed)
	shutdown_button.pressed.connect(_on_shutdown_pressed)
	location_button.pressed.connect(_on_swap_images)
	item_button.pressed.connect(_on_swap_images)

	shutdown_button.visible = false

	location_original_position = location_button.position
	item_original_position = item_button.position
	location_original_size = location_button.size
	item_original_size = item_button.size
	location_label_original_position = location_label.position
	item_label_original_position = item_label.position

	location_button.z_index = 1
	item_button.z_index = 2
	location_label.z_index = 1
	item_label.z_index = 2

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
		tween.tween_property(self, "position:x", -panel_width, 0.6)
	else:
		tween.tween_property(self, "position:x", -3, 0.6)
	is_open = !is_open

# -----------------------------
# LOAD APPLICANT
# -----------------------------
func load_applicant(index):
	var data = applicants[index]

	location_button.texture_normal = data["location"]
	item_button.texture_normal = data["item"]
	time_value_label.text = str(data["time"])
	price_value_label.text = str(data["price"])
	applicant_label.text = "Applicant %d / %d" % [index + 1, applicants.size()]

	reset_image_positions()
	
	spawn_3d_model(data["model_scene"])

# -----------------------------
# SWAP IMAGE LOGIC
# -----------------------------
func _on_swap_images():
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not images_swapped:
		location_button.z_index = 2
		item_button.z_index = 1
		location_label.z_index = 2
		item_label.z_index = 1

		tween.parallel().tween_property(location_button, "position", item_original_position, 0.3)
		tween.parallel().tween_property(item_button, "position", location_original_position, 0.3)
		tween.parallel().tween_property(location_button, "size", item_original_size, 0.3)
		tween.parallel().tween_property(item_button, "size", location_original_size, 0.3)
		tween.parallel().tween_property(location_label, "position", item_label_original_position, 0.3)
		tween.parallel().tween_property(item_label, "position", location_label_original_position, 0.3)
	else:
		location_button.z_index = 1
		item_button.z_index = 2
		location_label.z_index = 1
		item_label.z_index = 2

		tween.parallel().tween_property(location_button, "position", location_original_position, 0.3)
		tween.parallel().tween_property(item_button, "position", item_original_position, 0.3)
		tween.parallel().tween_property(location_button, "size", location_original_size, 0.3)
		tween.parallel().tween_property(item_button, "size", item_original_size, 0.3)
		tween.parallel().tween_property(location_label, "position", location_label_original_position, 0.3)
		tween.parallel().tween_property(item_label, "position", item_label_original_position, 0.3)
	images_swapped = !images_swapped

func reset_image_positions():
	location_button.position = location_original_position
	item_button.position = item_original_position
	location_button.size = location_original_size
	item_button.size = item_original_size
	location_label.position = location_label_original_position
	item_label.position = item_label_original_position

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
	# 1. Check for a mistake immediately
	var correct_answer = applicants[current_index]["fraud_correct"]
	if answer != correct_answer:
		mistakes += 1
		
		# 2. If they hit 3 strikes, tell the main 3D scene to end the game!
		if mistakes >= 3:
			button_panel.visible = false
			applicant_label.text = "TERMINATED"
			get_tree().current_scene.trigger_game_over()
			return # Stop loading the next applicant

	# 3. If they survive, continue as normal
	player_answers.append(answer)
	current_index += 1

	if current_index < applicants.size():
		load_applicant(current_index)
	else:
		finish_applicants()

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

# -----------------------------
# AFTER 5TH APPLICANT
# -----------------------------
func finish_applicants():
	final_score = 0
	for i in range(applicants.size()):
		# Updated to match the database key
		if player_answers[i] == applicants[i]["fraud_correct"]:
			final_score += 1

	applicant_label.text = "All applicants reviewed"
	legit_button.visible = false
	sus_button.visible = false
	button_panel.visible = false
	shutdown_button.visible = true

func _on_shutdown_pressed():
	get_tree().current_scene.show_final_result(final_score)
	self.visible = false
