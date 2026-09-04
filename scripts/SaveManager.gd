extends Node

# The template for a brand new game mapped to the 9-day structure
const DEFAULT_SAVE = {
	"current_scene_path": "res://scene/FraudDetection/FraudDetection.tscn",
	"stage_name": "Fraud L1 - Day 1",
	"current_day": 1, 
	"level_scores": {}, 
	"total_score": 0
}

var current_slot: int = 1
var current_save_data: Dictionary = {}

func get_save_path(slot: int) -> String:
	return "user://save_slot_" + str(slot) + ".json"

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func load_game(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK:
		current_save_data = json.data
		return json.data
	else:
		print("JSON Parse Error!")
		return {}

func save_game(slot: int, data: Dictionary):
	var path = get_save_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(data, "\t") 
	file.store_string(json_string)

func delete_save(slot: int):
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

# --- AUTO-SAVE PROGRESS (Takes 5 arguments now) ---
func auto_save_level(next_scene_path: String, next_stage_name: String, level_id: String, score: int, next_day: int):
	current_save_data["level_scores"][level_id] = score
	
	var total = 0
	for key in current_save_data["level_scores"]:
		total += current_save_data["level_scores"][key]
	current_save_data["total_score"] = total
	
	current_save_data["current_scene_path"] = next_scene_path
	current_save_data["stage_name"] = next_stage_name
	current_save_data["current_day"] = next_day
	
	save_game(current_slot, current_save_data)
