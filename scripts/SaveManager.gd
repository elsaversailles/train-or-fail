extends Node

const Catalog := preload("res://scripts/EndingCatalog.gd")
const COLLECTION_PATH := "user://ending_collection.dat"
const CERTIFICATE_DAYS := {
	"fraud_detection": 3,
	"know_your_customer": 6,
	"credit_scoring": 9,
}

# --- ENCRYPTION CONFIGURATION ---
const SAVE_PASSWORD: String = "7654raymartangelonevincemattknitechtrainorfail4325"
const RAIN_CHANCE := 0.5
const WEATHER_RULE_VERSION := 2

# The template for a brand new game mapped to the 9-day structure
const DEFAULT_SAVE = {
	"current_scene_path": "res://scene/FraudDetection/FraudDetection.tscn",
	"stage_name": "Fraud L1 - Day 1",
	"current_day": 1, 
	"weather_day": 0,
	"weather_rain": false,
	"weather_rule_version": WEATHER_RULE_VERSION,
	"level_scores": {}, 
	"total_score": 0,
	"certificates": [],
	"special_decisions": {} # Tracks any special character verdicts: e.g. {"tita_elena": "sus", "character_2": "legit"}
}

var current_slot: int = 1
var current_save_data: Dictionary = {}
var _unlocked_endings := {}
var _collection_needs_save := false


func _ready() -> void:
	_load_collection()
	# Recover recorded IDs and any identifiable endings from pre-gallery slots.
	for slot in range(1, 4):
		var ending_id := get_completed_ending_id(read_save(slot))
		if ending_id != "" and not is_ending_unlocked(ending_id):
			_unlocked_endings[ending_id] = true
			_collection_needs_save = true
	_save_collection()


func _load_collection() -> bool:
	if not FileAccess.file_exists(COLLECTION_PATH):
		return true
	var collection := ConfigFile.new()
	if collection.load_encrypted_pass(COLLECTION_PATH, SAVE_PASSWORD) != OK:
		push_error("Could not read the ending collection.")
		return false
	for id in Catalog.ENDINGS:
		if collection.get_value("endings", id, false) == true:
			_unlocked_endings[id] = true
	return true


func is_ending_unlocked(ending_id: String) -> bool:
	return _unlocked_endings.has(ending_id)


func get_unlocked_ending_count() -> int:
	return _unlocked_endings.size()


func has_certificate(department_id: String) -> bool:
	return department_id in current_save_data.get("certificates", [])


func _update_slot_certificates(data: Dictionary) -> void:
	var completed_day := int(data.get("current_day", 1)) - 1
	# Successful shifts save their result before the apartment advances the day.
	if data.has("pending_score"):
		completed_day = maxi(completed_day, int(data.get("pending_day", 0)))
	if data.get("stage_name", "") == "Game Finished":
		completed_day = 9

	var earned: Array = data.get("certificates", [])
	for department_id in CERTIFICATE_DAYS:
		if completed_day >= CERTIFICATE_DAYS[department_id] and not earned.has(department_id):
			earned.append(department_id)
	data["certificates"] = earned


func get_completed_ending_id(data: Dictionary) -> String:
	var recorded: String = data.get("ending_id", "")
	if Catalog.ENDINGS.has(recorded):
		return recorded
	if data.get("stage_name", "") != "Game Finished":
		return ""
	if data.get("is_grandpa_shift", false) or data.get("grandpa_round_completed", false):
		return ""
	var route := Catalog.get_final_route(data)
	if route == Catalog.GRANDPA_SHIFT:
		var decisions: Dictionary = data.get("special_decisions", {})
		var verdict: String = decisions.get("grandpa", "")
		return Catalog.get_grandpa_ending(verdict) if verdict in ["legit", "sus"] else ""
	# Older saves didn't store the player's choice between stay and leave.
	return route if Catalog.ENDINGS.has(route) else ""


func record_ending(ending_id: String) -> void:
	if not Catalog.ENDINGS.has(ending_id):
		return
	# Termination is collectible, but the player can still retry the failed shift.
	if ending_id == "terminated":
		unlock_ending(ending_id)
		return
	current_save_data["ending_id"] = ending_id
	current_save_data["stage_name"] = "Game Finished"
	save_game(current_slot, current_save_data)
	preserve_slot_ending(current_save_data)


# Replay and deletion must preserve a slot's ending if its first profile write failed.
func preserve_slot_ending(data: Dictionary) -> bool:
	var ending_id := get_completed_ending_id(data)
	if ending_id == "":
		return true
	return unlock_ending(ending_id)


func unlock_ending(ending_id: String) -> bool:
	if not Catalog.ENDINGS.has(ending_id):
		return false
	if not is_ending_unlocked(ending_id):
		_unlocked_endings[ending_id] = true
		_collection_needs_save = true
	return _save_collection()


func _save_collection() -> bool:
	if not _collection_needs_save:
		return true
	# Merge with the stored profile and keep it intact if it cannot be read.
	if not _load_collection():
		return false
	var collection := ConfigFile.new()
	for id in _unlocked_endings:
		collection.set_value("endings", id, true)
	# Replace the old collection only after the new one is completely written.
	var temp_path := "%s.%d.tmp" % [COLLECTION_PATH, OS.get_process_id()]
	var error := collection.save_encrypted_pass(temp_path, SAVE_PASSWORD)
	if error == OK:
		error = DirAccess.rename_absolute(temp_path, COLLECTION_PATH)
	if error != OK:
		push_error("Could not save the ending collection: " + error_string(error))
		return false
	_collection_needs_save = false
	return true

# Saved as .dat so players cannot edit it with a standard text editor
func get_save_path(slot: int) -> String:
	return "user://save_slot_" + str(slot) + ".dat"

func save_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_weather_rain_for_day(day: int) -> bool:
	if current_save_data.is_empty():
		current_save_data = DEFAULT_SAVE.duplicate(true)
	if current_save_data.get("weather_rule_version", 0) != WEATHER_RULE_VERSION or current_save_data.get("weather_day", 0) != day:
		current_save_data["weather_day"] = day
		current_save_data["weather_rain"] = randf() < RAIN_CHANCE
		current_save_data["weather_rule_version"] = WEATHER_RULE_VERSION
		if save_exists(current_slot):
			save_game(current_slot, current_save_data)
	return bool(current_save_data.get("weather_rain", false))

# --- ENCRYPTED LOAD GAME ---
func load_game(slot: int) -> Dictionary:
	current_slot = slot
	current_save_data = read_save(slot)
	return current_save_data

func read_save(slot: int) -> Dictionary:
	var path = get_save_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	# Open the file using AES encryption password
	var file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, SAVE_PASSWORD)
	if not file:
		print("Error: Could not open or decrypt save file at: ", path)
		return {}

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	
	if error == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		
		# Migration fallback: ensure special_decisions exists in older save files
		if not data.has("special_decisions"):
			data["special_decisions"] = {}
		_update_slot_certificates(data)
			
		return data
	else:
		print("JSON Parse Error during decrypted read!")
		return {}

# --- ENCRYPTED SAVE GAME ---
func save_game(slot: int, data: Dictionary) -> bool:
	_update_slot_certificates(data)
	var path = get_save_path(slot)
	var temp_path := "%s.%d.tmp" % [path, OS.get_process_id()]
	var file = FileAccess.open_encrypted_with_pass(temp_path, FileAccess.WRITE, SAVE_PASSWORD)
	if not file:
		print("Error: Failed to create encrypted save file at: ", path)
		return false

	if not file.store_string(JSON.stringify(data)):
		return false
	file.close()
	return DirAccess.rename_absolute(temp_path, path) == OK

func delete_save(slot: int) -> bool:
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		if not preserve_slot_ending(read_save(slot)):
			return false
		if DirAccess.remove_absolute(path) != OK:
			return false
	if current_slot == slot:
		current_save_data = {}
	return true

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
