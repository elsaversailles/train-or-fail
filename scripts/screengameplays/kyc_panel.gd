extends Control

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
var zoom_scale: float = 3 # Change this to make it bigger/smaller when clicked

# -----------------------------
# NODE REFERENCES
# -----------------------------
@onready var applicant_label = $ApplicantLabel
@onready var name_label = $CustomerNameLabel
@onready var id_image = $IDPanel/IDImage
@onready var legit_button = $LegitButton
@onready var sus_button = $SusButton
@onready var model_container = $"../ModelContainer"

@onready var left_button = $LeftButton
@onready var center_button = $CenterButton
@onready var right_button = $RightButton

# --- NEW: Reference the panel itself, not just the image ---
@onready var id_panel = $IDPanel 

# -----------------------------
# READY
# -----------------------------
func _ready():
	applicants = Database.get_session_applicants()
	
	legit_button.pressed.connect(_on_legit_pressed)
	sus_button.pressed.connect(_on_sus_pressed)

	left_button.button_down.connect(func(): is_rotating_left = true)
	left_button.button_up.connect(func(): is_rotating_left = false)
	right_button.button_down.connect(func(): is_rotating_right = true)
	right_button.button_up.connect(func(): is_rotating_right = false)
	center_button.pressed.connect(_on_center_pressed)

	# --- ID ZOOM FEATURE SETUP ---
	# Save where the ID starts so we can put it back later
	original_id_pos = id_panel.position
	# Listen for clicks on the ID panel
	id_panel.gui_input.connect(_on_id_panel_clicked)

	load_applicant(current_index)


# -----------------------------
# ID ZOOM LOGIC
# -----------------------------
func _on_id_panel_clicked(event: InputEvent):
	# Check if it's a left mouse button click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_id_zoom()

func toggle_id_zoom():
	is_id_zoomed = !is_id_zoomed
	
	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	if is_id_zoomed:
		id_panel.move_to_front()
		
		# --- YOUR HARDCODED NUMBERS ---
		# Tweak these two numbers until it lands perfectly in the middle!
		# X is left/right, Y is up/down.
		var target_pos = Vector2(200, 70) 
		
		tween.tween_property(id_panel, "position", target_pos, 0.3)
		tween.tween_property(id_panel, "scale", Vector2(zoom_scale, zoom_scale), 0.3)
	else:
		tween.tween_property(id_panel, "position", original_id_pos, 0.3)
		tween.tween_property(id_panel, "scale", Vector2(1, 1), 0.3)


# -----------------------------
# CONTINUOUS ROTATION LOGIC
# -----------------------------
func _process(delta):
	if is_rotating_left:
		model_container.rotation_degrees.y -= rotation_speed * delta
	elif is_rotating_right:
		model_container.rotation_degrees.y += rotation_speed * delta
		
	model_container.rotation_degrees.y = clamp(model_container.rotation_degrees.y, 0, 180)

func _on_center_pressed():
	model_container.rotation_degrees.y = 90

# -----------------------------
# GAME LOOP
# -----------------------------
func load_applicant(index):
	var data = applicants[index]

	applicant_label.text = "Customer %d / %d" % [index + 1, applicants.size()]
	name_label.text = data["name"]
	id_image.texture = data["id_image"]
	
	spawn_3d_model(data["model_scene"])
	
	model_container.rotation_degrees.y = 90
	is_rotating_left = false
	is_rotating_right = false
	
	# --- ID ZOOM RESET ---
	# If they load the next person while the ID is zoomed, snap it back safely!
	if is_id_zoomed:
		is_id_zoomed = false
		id_panel.scale = Vector2(1, 1)
		id_panel.position = original_id_pos

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

func spawn_3d_model(model_packed_scene: PackedScene):
	for child in model_container.get_children():
		child.queue_free()
		
	await get_tree().process_frame 
	
	if model_packed_scene:
		var new_model = model_packed_scene.instantiate()
		model_container.add_child(new_model)
		new_model.position = Vector3.ZERO

func finish_game():
	final_score = 0
	for i in range(applicants.size()):
		if player_answers[i] == applicants[i]["kyc_correct"]:
			final_score += 1

	applicant_label.text = "All customers verified"
	legit_button.visible = false
	sus_button.visible = false
	show_result()

func show_result():
	get_tree().current_scene.show_final_result(final_score)
