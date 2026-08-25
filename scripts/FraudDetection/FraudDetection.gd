extends Node3D

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var final_result_panel = $ResultPanel
@onready var player = $MainChar
@onready var info_label: Label = $CanvasLayer/Label

# --- DYNAMIC TRACKING ---
var current_level: int = 1
var current_day: int = 1
var gameplay_name: String = "Fraud"

func _ready():
	final_result_panel.visible = false
	final_result_panel.continue_requested.connect(_on_terminal_clicked)
	
	# 1. Ask SaveManager what level/day we are currently playing. 
	# (If they don't exist yet, it defaults to 1).
	current_level = SaveManager.current_save_data.get("current_level", 1)
	current_day = SaveManager.current_save_data.get("current_day", 1)

	if info_label:
		info_label.text = "Fraud Detection\nLevel %d\nDay %d" % [current_level, current_day]

func show_final_result(score: int):
	# Fade out
	await SceneTransition.fade_to_black()
	
	# Pause player and show terminal
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player:
		player.is_paused = true
		
	canvas_layer.visible = false
	final_result_panel.display_terminal_report(score, current_level)
	
	# Fade back in
	SceneTransition.fade_from_black()

	# ---------------------------------------------------------
	# 2. CALCULATE THE NEXT DAY AND LEVEL
	# ---------------------------------------------------------
	var next_level = current_level
	var next_day = current_day + 1
	var next_scene_path = "res://scene/FraudDetection/FraudDetection.tscn" # It loops back to itself!
	
	# If Day 2 is finished, reset to Day 1 and go to the next Level
	if next_day > 2:
		next_day = 1
		next_level += 1

	# Format the text for the Save JSON
	var current_level_id = "%s_L%d_D%d" % [gameplay_name.to_lower(), current_level, current_day]
	var next_stage_name = "%s L%d - Day %d" % [gameplay_name, next_level, next_day]

	# ---------------------------------------------------------
	# 3. CHECK FOR PROMOTION / NEXT GAMEPLAY TYPE
	# ---------------------------------------------------------
	if next_level > 5:
		# They beat Fraud L5 D2! Send them to KYC tomorrow.
		next_scene_path = "res://scene/KnowYourCustomer/KnowYourCustomer.tscn"
		next_stage_name = "KYC L1 - Day 1"
		
		# Reset the internal trackers for the KYC script to use
		SaveManager.current_save_data["current_level"] = 1
		SaveManager.current_save_data["current_day"] = 1
	else:
		# Save the updated trackers for tomorrow's Fraud shift
		SaveManager.current_save_data["current_level"] = next_level
		SaveManager.current_save_data["current_day"] = next_day

	# 4. Save the game!
	SaveManager.auto_save_level(next_scene_path, next_stage_name, current_level_id, score)


# ---------------------------------------------------------
# TERMINAL CLICK (END OF DAY)
# ---------------------------------------------------------
func _on_terminal_clicked():
	get_tree().paused = false 
	
	# Send them to the street to start the next morning!
	# (The invisible door on the street will read the SaveManager and 
	# teleport them right back here, but as the next day!)
	SceneTransition.change_scene("res://scene/outside_world.tscn")
