extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var player = $MainChar
@onready var info_label: Label = $CanvasLayer/Label
@onready var tutorial_ui = $CanvasLayer/KYCTutorial
@onready var game_over_panel = $CanvasLayer/GameOverPanel

# --- DYNAMIC TRACKING ---
var current_level: int = 1
var current_day: int = 1
var gameplay_name: String = "KnowYourCustomer"

func _ready():
	# 1. Freeze the player instantly upon loading
	if player:
		player.is_paused = true

	if canvas_layer:
		canvas_layer.visible = true
		
	# Hide Game Over panel by default, reset alpha to 0, and connect click event
	if game_over_panel:
		game_over_panel.visible = false
		game_over_panel.modulate.a = 0.0
		game_over_panel.gui_input.connect(_on_game_over_clicked)
	
	# 2. Ask SaveManager what level/day we are currently playing
	current_level = SaveManager.current_save_data.get("current_level", 1)
	current_day = SaveManager.current_save_data.get("current_day", 1)

	if info_label:
		info_label.text = "Know Your Customer\nDay %d" % current_day
			
	if tutorial_ui:
		if current_day == 4: # Day 4 is KYC Tutorial Day
			pass 
		else:
			# Days 5 and 6 skip the tutorial instantly
			tutorial_ui.queue_free()

	# 3. Wait for the physics engine to settle before unfreezing input
	await get_tree().physics_frame
	await get_tree().physics_frame

	if player:
		# Double-check that they didn't trigger game over during load
		if not (game_over_panel and game_over_panel.visible):
			player.is_paused = false

# ==========================================
# TERMINATION LOGIC
# ==========================================

func trigger_game_over():
	# Unlock mouse and freeze player
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player:
		player.is_paused = true

	if game_over_panel:
		game_over_panel.modulate.a = 0.0
		game_over_panel.visible = true
		
		# Animate alpha from 0.0 to 1.0 over 0.8 seconds
		var tween = create_tween()
		tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_game_over_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().paused = false 
		SceneTransition.reload_scene()

# ==========================================
# END OF DAY LOGIC
# ==========================================

func show_final_result(score: int):
	# 1. Temporarily store the shift's results to read later in the apartment
	SaveManager.current_save_data["pending_score"] = score
	SaveManager.current_save_data["pending_day"] = current_day
	SaveManager.current_save_data["pending_level"] = current_level
	SaveManager.current_save_data["pending_department"] = gameplay_name

	# 2. Update save path to the outside world
	SaveManager.current_save_data["current_scene_path"] = "res://scene/outside_world.tscn"
	SaveManager.save_game(SaveManager.current_slot, SaveManager.current_save_data)

	# 3. Send player to street commute
	SceneTransition.change_scene("res://scene/outside_world.tscn")
