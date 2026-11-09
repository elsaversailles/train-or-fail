extends "res://scripts/screengameplays/applicant_review_panel.gd"

# -----------------------------
# PANEL, ZOOM & GLOW SETTINGS
# -----------------------------
var is_open = false
var panel_width = 944
@export var zoom_scale: Vector2 = Vector2(2.0, 2.0) # Adjust how much it magnifies when zoomed

@export var grip_idle_time: float = 3.0 # Seconds before grip button starts glowing
@export var grip_glow_color: Color = Color(1.6, 1.5, 0.8, 1.0) # Bright warm glow color
var grip_idle_timer: Timer
var grip_glow_tween: Tween

enum PictureMode { SWAP, ZOOM }
var current_picture_mode: PictureMode = PictureMode.SWAP
var is_zoomed: bool = false
var zoomed_button: Control = null

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
@onready var ai_risk_value_label = $AIRiskValueLabel # Match this path to your Label node in the Scene tree

# --- MODE BUTTON REFERENCES ---
@onready var swap_mode_button = $SwapModeButton
@onready var zoom_mode_button = $ZoomModeButton

# --- NOTE NODE REFERENCES ---
@onready var note_icon_button = $NoteIconButton
@onready var note_popup_panel = $NotePopupPanel
@onready var note_text_label = $NotePopupPanel/NoteTextLabel

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

var is_note_open = false
var note_tween: Tween

# -----------------------------
# READY
# -----------------------------
func _ready():
	self.visible = true # Force it to show up!
	is_open = false
	position.x = -panel_width # Ensure it starts tucked away so the grip button is clickable
	
	# --- FETCH DATA FROM AUTOLOAD ---
	applicants = Database.get_session_applicants()

	grip_button.pressed.connect(grip_pressed)
	legit_button.pressed.connect(_on_legit_pressed)
	sus_button.pressed.connect(_on_sus_pressed)
	shutdown_button.pressed.connect(_on_shutdown_pressed)
	
	# Connect pictures to the mode handler
	location_button.pressed.connect(func(): _on_picture_pressed(location_button))
	item_button.pressed.connect(func(): _on_picture_pressed(item_button))
	
	# Connect the 2 Mode Buttons
	swap_mode_button.pressed.connect(_on_swap_mode_pressed)
	zoom_mode_button.pressed.connect(_on_zoom_mode_pressed)
	
	# --- NOTE SIGNALS & SETUP ---
	note_icon_button.pressed.connect(_on_toggle_note)
	note_popup_panel.gui_input.connect(_on_note_popup_input)
	note_popup_panel.visible = false
	note_popup_panel.z_index = 10 # Keeps the popped-out note above everything
	note_icon_button.z_index = 4

	setup_review_transitions(model_container, shutdown_button)

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

	setup_grip_glow_timer()
	update_mode_buttons_visuals()
	load_applicant(current_index)

# -----------------------------
# GRIP BUTTON IDLE GLOW LOGIC
# -----------------------------
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
	if is_transitioning or review_finished:
		return
	set_panel_open(not is_open)

func set_panel_open(open: bool) -> Tween:
	is_open = open
	if not open:
		close_note_immediately()
		reset_zoom_immediately()
	stop_grip_glow(not open and not is_transitioning and not review_finished)
	return animate_panel_to(-3.0 if open else -float(panel_width))

func set_review_controls_enabled(enabled: bool) -> void:
	grip_button.disabled = not enabled
	legit_button.disabled = not enabled
	sus_button.disabled = not enabled
	note_icon_button.disabled = not enabled
	swap_mode_button.disabled = not enabled
	zoom_mode_button.disabled = not enabled
	location_button.disabled = not enabled
	item_button.disabled = not enabled

# -----------------------------
# PICTURE MODE (SWAP VS ZOOM)
# -----------------------------
func _on_swap_mode_pressed():
	current_picture_mode = PictureMode.SWAP
	if is_zoomed:
		unzoom_picture()
	update_mode_buttons_visuals()

func _on_zoom_mode_pressed():
	current_picture_mode = PictureMode.ZOOM
	update_mode_buttons_visuals()

func update_mode_buttons_visuals():
	swap_mode_button.set_pressed_no_signal(current_picture_mode == PictureMode.SWAP)
	zoom_mode_button.set_pressed_no_signal(current_picture_mode == PictureMode.ZOOM)

func _on_picture_pressed(clicked_button: Control):
	if current_picture_mode == PictureMode.SWAP:
		if is_zoomed:
			unzoom_picture()
			return
		_on_swap_images()
	elif current_picture_mode == PictureMode.ZOOM:
		# Only allow zooming if the clicked picture is the larger one
		if is_larger_picture(clicked_button):
			if is_zoomed and zoomed_button == clicked_button:
				unzoom_picture()
			else:
				zoom_picture_at_click(clicked_button)

func is_larger_picture(button: Control) -> bool:
	var other_button = item_button if button == location_button else location_button
	var button_area = button.size.x * button.size.y
	var other_area = other_button.size.x * other_button.size.y
	if not is_equal_approx(button_area, other_area):
		return button_area > other_area
	return button.z_index >= other_button.z_index

func get_panel_center() -> Vector2:
	if size.x > 100.0 and size.y > 100.0:
		return size / 2.0
	return Vector2(panel_width / 2.0, get_viewport_rect().size.y / 2.0)

func get_current_slot_position(button: Control) -> Vector2:
	if button == location_button:
		return item_original_position if images_swapped else location_original_position
	else:
		return location_original_position if images_swapped else item_original_position

func zoom_picture_at_click(button: Control):
	is_zoomed = true
	zoomed_button = button
	button.z_index = 6 # Place above other UI elements while zoomed
	
	# 1. Get exact local point where the player clicked on the picture
	var click_pos: Vector2 = button.get_local_mouse_position().clamp(Vector2.ZERO, button.size)
	
	# 2. Set pivot_offset to the clicked point
	button.pivot_offset = click_pos
	
	# 3. Calculate target position so the clicked point lands at the center of the panel
	var panel_center: Vector2 = get_panel_center()
	var target_position: Vector2 = panel_center - click_pos
	
	# 4. Smoothly move to center and zoom in at the clicked point
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button, "scale", zoom_scale, 0.25)
	tween.parallel().tween_property(button, "position", target_position, 0.25)

func unzoom_picture():
	if zoomed_button == null:
		is_zoomed = false
		return
		
	var button_to_restore = zoomed_button
	var home_pos = get_current_slot_position(button_to_restore)
	is_zoomed = false
	zoomed_button = null
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(button_to_restore, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(button_to_restore, "position", home_pos, 0.2)
	tween.tween_callback(restore_z_indices)

func reset_zoom_immediately():
	is_zoomed = false
	zoomed_button = null
	location_button.scale = Vector2.ONE
	item_button.scale = Vector2.ONE
	location_button.position = get_current_slot_position(location_button)
	item_button.position = get_current_slot_position(item_button)
	restore_z_indices()

func restore_z_indices():
	if images_swapped:
		location_button.z_index = 2
		item_button.z_index = 1
		location_label.z_index = 2
		item_label.z_index = 1
	else:
		location_button.z_index = 1
		item_button.z_index = 2
		location_label.z_index = 1
		item_label.z_index = 2

# -----------------------------
# NOTE POPUP LOGIC
# -----------------------------
func _on_toggle_note():
	if is_note_open:
		close_note()
	else:
		open_note()

func _on_note_popup_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		close_note()

func open_note():
	stop_note_tween()
	is_note_open = true
	note_icon_button.set_pressed_no_signal(true)
	note_popup_panel.pivot_offset = note_popup_panel.size / 2.0
	note_popup_panel.scale = Vector2(0.8, 0.8)
	note_popup_panel.modulate.a = 0.0
	note_popup_panel.visible = true
	
	note_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	note_tween.parallel().tween_property(note_popup_panel, "scale", Vector2.ONE, 0.2)
	note_tween.parallel().tween_property(note_popup_panel, "modulate:a", 1.0, 0.15)

func close_note():
	stop_note_tween()
	is_note_open = false
	note_icon_button.set_pressed_no_signal(false)
	note_popup_panel.pivot_offset = note_popup_panel.size / 2.0
	
	note_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	note_tween.parallel().tween_property(note_popup_panel, "scale", Vector2(0.8, 0.8), 0.15)
	note_tween.parallel().tween_property(note_popup_panel, "modulate:a", 0.0, 0.15)
	note_tween.tween_callback(func(): note_popup_panel.visible = false)

func close_note_immediately():
	stop_note_tween()
	is_note_open = false
	note_icon_button.set_pressed_no_signal(false)
	note_popup_panel.visible = false
	note_popup_panel.scale = Vector2.ONE
	note_popup_panel.modulate.a = 1.0

func stop_note_tween() -> void:
	if note_tween and note_tween.is_valid():
		note_tween.kill()
	note_tween = null

# -----------------------------
# LOAD APPLICANT
# -----------------------------
func load_applicant(index):
	var data = applicants[index]

	location_button.texture_normal = data["location"]
	item_button.texture_normal = data["item"]
	time_value_label.text = str(data["time"])
	price_value_label.text = str(data["price"])
	ai_risk_value_label.text = str(data.get("ai_risk_factor", "N/A"))
	applicant_label.text = "Applicant %d / %d" % [index + 1, applicants.size()]
	
	# Load applicant's note text and make sure the popup starts closed
	note_text_label.text = str(data.get("note", "No additional notes for this applicant."))
	close_note_immediately()

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
	images_swapped = false
	reset_zoom_immediately()
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

# -----------------------------
# PLAYER CHOICE
# -----------------------------
func _on_legit_pressed():
	submit_answer("legit")

func _on_sus_pressed():
	submit_answer("sus")

func submit_answer(answer):
	if is_transitioning or review_finished or current_index >= applicants.size():
		return
	is_transitioning = true
	set_review_controls_enabled(false)
	var current_applicant = applicants[current_index]

	# Check if this character is a special story applicant and record the choice
	if current_applicant.get("is_special", false):
		var char_id = current_applicant.get("id", "")
		if not SaveManager.current_save_data.has("special_decisions"):
			SaveManager.current_save_data["special_decisions"] = {}
		SaveManager.current_save_data["special_decisions"][char_id] = answer

	var correct_answer = current_applicant["fraud_correct"]
	if answer != correct_answer:
		mistakes += 1

	player_answers.append(answer)
	if current_applicant.get("is_special", false):
		SaveManager.record_special_decision(current_applicant.get("id", ""), answer)
	current_index += 1

	await set_panel_open(false).finished
	await slide_applicant_out()
	if current_index < applicants.size():
		load_applicant(current_index)
		await slide_applicant_in()
		is_transitioning = false
		set_review_controls_enabled(true)
		stop_grip_glow(true)
	else:
		await finish_applicants()

# -----------------------------
# AFTER THE LAST APPLICANT
# -----------------------------
func finish_applicants():
	review_finished = true
	final_score = 0
	for i in range(player_answers.size()):
		if player_answers[i] == applicants[i]["fraud_correct"]:
			final_score += 1

	stop_grip_glow(false)
	close_note_immediately()
	reset_zoom_immediately()
	note_icon_button.visible = false
	swap_mode_button.visible = false
	zoom_mode_button.visible = false
	applicant_label.text = "All applicants reviewed"
	legit_button.visible = false
	sus_button.visible = false
	await set_panel_open(true).finished
	is_transitioning = false
	show_shutdown_prompt()

func _on_shutdown_pressed():
	shutdown_review(final_score)
