extends Node

# The template for a brand new game
const DEFAULT_SAVE = {
	"current_scene_path": "res://scene/FraudDetection/Level1/FraudDetectionLevel1-1.tscn",
	"stage_name": "Fraud L1 - Day 1",
	"level_scores": {}, 
	"total_score": 0
}

var current_slot: int = 1
var current_save_data: Dictionary = {}

# Gets the file path for a specific slot (1, 2, or 3)
func get_save_path(slot: int) -> String:
	return "user://save_slot_" + str(slot) + ".json"

# --- CHECK IF SAVE EXISTS ---
func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

# --- LOAD GAME ---
func load_game(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		return json.data
	else:
		print("JSON Parse Error!")
		return {}

# --- SAVE GAME ---
func save_game(slot: int, data: Dictionary):
	var path = get_save_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	# The "\t" makes the JSON readable in a text editor!
	var json_string = JSON.stringify(data, "\t") 
	file.store_string(json_string)

# --- DELETE SAVE ---
func delete_save(slot: int):
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

# --- AUTO-SAVE PROGRESS (Called at the end of a level) ---
func auto_save_level(next_scene_path: String, next_stage_name: String, level_id: String, score: int):
	# 1. Update the score for this specific level (e.g., "fraud_L1_D1")
	current_save_data["level_scores"][level_id] = score
	
	# 2. Recalculate total score
	var total = 0
	for key in current_save_data["level_scores"]:
		total += current_save_data["level_scores"][key]
	current_save_data["total_score"] = total
	
	# 3. Update the path for the NEXT time they load the game
	current_save_data["current_scene_path"] = next_scene_path
	current_save_data["stage_name"] = next_stage_name
	
	# 4. Save to the file
	save_game(current_slot, current_save_data)
