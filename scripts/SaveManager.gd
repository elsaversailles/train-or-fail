extends Node

# The template for a brand new game mapped to the 9-day structure
const DEFAULT_SAVE = {
	"current_scene_path": "res://scene/FraudDetection/FraudDetection.tscn",
	"stage_name": "Fraud L1 - Day 1",
	"current_day": 1, 
	"level_scores": {}, 
	"total_score": 0,
	"special_decisions": {} # Tracks any special character verdicts: e.g. {"tita_elena": "sus", "character_2": "legit"}
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
		
		# Migration fallback: ensure special_decisions exists in older save files
		if not current_save_data.has("special_decisions"):
			current_save_data["special_decisions"] = {}
			
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

# --- AUTO-SAVE PROGRESS ---
func auto_save_level(next_scene_path: String, next_stage_name: String, level_id: String, score: int, next_day: int):
	# Developer safety net for direct F6 scene playtesting
	if current_save_data.is_empty():
		current_save_data = DEFAULT_SAVE.duplicate(true)

	current_save_data["level_scores"][level_id] = score
	
	var total = 0
	for key in current_save_data["level_scores"]:
		total += current_save_data["level_scores"][key]
	current_save_data["total_score"] = total
	
	current_save_data["current_scene_path"] = next_scene_path
	current_save_data["stage_name"] = next_stage_name
	current_save_data["current_day"] = next_day
	
	save_game(current_slot, current_save_data)

# ==========================================
# SPECIAL CHARACTER STORY HELPERS
# ==========================================

# Records the verdict for any story character and immediately writes to disk
func record_special_decision(character_id: String, decision: String):
	if current_save_data.is_empty():
		current_save_data = DEFAULT_SAVE.duplicate(true)
		
	if not current_save_data.has("special_decisions"):
		current_save_data["special_decisions"] = {}
		
	current_save_data["special_decisions"][character_id] = decision
	save_game(current_slot, current_save_data)
	print("Saved story decision for [%s]: %s" % [character_id, decision])

# Retrieves the decision for a character (returns "" if not encountered yet)
func get_special_decision(character_id: String) -> String:
	var decisions = current_save_data.get("special_decisions", {})
	return decisions.get(character_id, "")

# Checks if every character in an ID list received a specific target decision
func are_all_specials_marked(character_ids: Array[String], target_decision: String) -> bool:
	var decisions = current_save_data.get("special_decisions", {})
	for char_id in character_ids:
		if decisions.get(char_id, "") != target_decision:
			return false
	return true
