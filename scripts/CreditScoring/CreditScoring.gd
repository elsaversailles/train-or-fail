extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var player = $MainChar
@onready var info_label: Label = $CanvasLayer/Label
@onready var game_over_panel = $CanvasLayer/GameOverPanel

@onready var tutorial_ui = $CanvasLayer/CSTutorial
# --- DYNAMIC TRACKING ---
var current_level: int = 1
var current_day: int = 1
var gameplay_name: String = "CreditScoring"

func _ready():
	if canvas_layer:
		canvas_layer.visible = true

	# Hide Game Over panel by default and connect the click event
	if game_over_panel:
		game_over_panel.visible = false
		game_over_panel.gui_input.connect(_on_game_over_clicked)
		
	# 1. Ask SaveManager what level/day we are currently playing. 
	current_level = SaveManager.current_save_data.get("current_level", 1)
	current_day = SaveManager.current_save_data.get("current_day", 1)

	if info_label:
			info_label.text = "Credit Scoring\nDay %d" % current_day

	if tutorial_ui:
		if current_day == 7: # Day 7 is Credit Scoring Tutorial Day!
			pass # Keeps it hidden until screen_focused()
		else:
			# Days 8 and 9 skip the tutorial instantly
			tutorial_ui.queue_free()

func trigger_game_over():
	# Show the full-screen termination panel
	if game_over_panel:
		game_over_panel.visible = true
	
	# Unlock mouse and freeze player
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player:
		player.is_paused = true

func _on_game_over_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().paused = false 
		get_tree().reload_current_scene()

func show_final_result(score: int):
	# 1. Temporarily store the shift's results to read later in the apartment
	SaveManager.current_save_data["pending_score"] = score
	SaveManager.current_save_data["pending_day"] = current_day
	SaveManager.current_save_data["pending_level"] = current_level
	SaveManager.current_save_data["pending_department"] = gameplay_name

	# 2. Update the save file so if they quit, they load back into the outside world!
	SaveManager.current_save_data["current_scene_path"] = "res://scene/outside_world.tscn"
	SaveManager.save_game(SaveManager.current_slot, SaveManager.current_save_data)

	# 3. Send them to the street without advancing the day yet
	SceneTransition.change_scene("res://scene/outside_world.tscn")
