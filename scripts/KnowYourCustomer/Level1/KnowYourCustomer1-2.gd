extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

# main panel now
@onready var final_result_panel = $ResultPanel
@onready var player = $MainChar

# Added this so the Terminal knows what "Epoch" to display
@export var current_level_number: int = 1

# For save game
@export_file("*.tscn") var next_scene_path: String
@export var next_stage_name: String
@export var current_level_id: String

func _ready():
	final_result_panel.visible = false
	
	# Connect the single click signal from your new terminal script
	final_result_panel.continue_requested.connect(_on_terminal_clicked)
	
func show_final_result(score: int):
	canvas_layer.visible = false
	
	# Tell the terminal script to format and display the text
	final_result_panel.display_terminal_report(score, current_level_number)

	# Grabs whatever typed in the Inspector
	SaveManager.auto_save_level(
		next_scene_path, 
		next_stage_name, 
		current_level_id, 
		score
	)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player:
		player.is_paused = true

	# Unlock mouse so player can click buttons
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Stop player movement/look
	if player:
		player.is_paused = true

# Replaced the 3 old button functions with this single terminal click function
func _on_terminal_clicked():
	get_tree().paused = false 
	
	# Uses your Inspector variable to safely load the next scene!
	if next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("ERROR: You forgot to set the Next Scene Path in the Inspector!")
