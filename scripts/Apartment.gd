extends Node3D

@onready var result_panel = $ResultPanel 
@onready var player = $Player

# --- NEW: Reference to your ending panel ---
@onready var game_finished_panel = $GameFinishedPanel

func _ready():
	result_panel.visible = false
	
	if not result_panel.continue_requested.is_connected(_on_continue_clicked):
		result_panel.continue_requested.connect(_on_continue_clicked)
		
	# Hide the ending panel by default and connect the click event
	if game_finished_panel:
		game_finished_panel.visible = false
		game_finished_panel.gui_input.connect(_on_game_finished_clicked)
	
	if SaveManager.current_save_data.has("pending_score"):
		await get_tree().create_timer(1.0).timeout
		show_daily_results()

func show_daily_results():
	var score = SaveManager.current_save_data.get("pending_score", 0)
	var current_day = SaveManager.current_save_data.get("pending_day", 1)
	var current_level = SaveManager.current_save_data.get("pending_level", 1)
	var gameplay_name = SaveManager.current_save_data.get("pending_department", "FraudDetection")
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if player:
		player.is_paused = true
		
	result_panel.visible = true
	result_panel.display_terminal_report(gameplay_name, current_level, current_day, score)

func _on_continue_clicked():
	# 1. Hide the daily result UI
	result_panel.visible = false
		
	# 2. Retrieve pending data for calculation
	var current_level = SaveManager.current_save_data.get("pending_level", 1)
	var current_day = SaveManager.current_save_data.get("pending_day", 1)
	var department = SaveManager.current_save_data.get("pending_department", "FraudDetection")
	var score = SaveManager.current_save_data.get("pending_score", 0)

	# 3. CALCULATE PROGRESSION
	var next_level = current_level
	var next_day = current_day + 1
	var next_scene_path = "" 
	var current_level_id = "%s_L%d_D%d" % [department.to_lower(), current_level, current_day]
	var next_stage_name = ""

	# --- FRAUD DETECTION (Days 1 - 3) ---
	if next_day <= 3:
		next_scene_path = "res://scene/FraudDetection/FraudDetection.tscn"
		if next_day == 2:
			next_stage_name = "Fraud L2 - Day 2"
		elif next_day == 3:
			next_stage_name = "Fraud L3 - Day 3"

	# --- KNOW YOUR CUSTOMER (Days 4 - 6) ---
	elif next_day <= 6:
		next_scene_path = "res://scene/KnowYourCustomer/KnowYourCustomer.tscn"
		next_level = 2 
		if next_day == 4:
			next_stage_name = "KYC L1 - Day 4"
		elif next_day == 5:
			next_stage_name = "KYC L2 - Day 5"
		elif next_day == 6:
			next_stage_name = "KYC L3 - Day 6"

	# --- CREDIT SCORING (Days 7 - 9) ---
	elif next_day <= 9:
		next_scene_path = "res://scene/CreditScoring/CreditScoring.tscn" 
		next_level = 3 
		if next_day == 7:
			next_stage_name = "Credit L1 - Day 7"
		elif next_day == 8:
			next_stage_name = "Credit L2 - Day 8"
		elif next_day == 9:
			next_stage_name = "Credit L3 - Day 9"
			
	# --- END OF GAME (Day 10+) ---
	else:
		next_scene_path = "res://scene/main_menu.tscn" 
		next_stage_name = "Game Finished"

	# Apply new stats
	SaveManager.current_save_data["current_level"] = next_level
	SaveManager.current_save_data["current_day"] = next_day

	# 4. Erase pending data so this doesn't accidentally run twice
	SaveManager.current_save_data.erase("pending_score")
	SaveManager.current_save_data.erase("pending_day")
	SaveManager.current_save_data.erase("pending_level")
	SaveManager.current_save_data.erase("pending_department")

	# 5. OFFICIALLY SAVE THE NEXT LEVEL!
	SaveManager.auto_save_level(next_scene_path, next_stage_name, current_level_id, score, next_day)
	
	# 6. ROUTE THE PLAYER
	if next_day > 9:
		# Show the Game Finished panel! Keep mouse visible.
		if game_finished_panel:
			game_finished_panel.visible = true
	else:
		# Unpause player and continue to the next morning
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if player:
			player.is_paused = false
			
		if next_day == 4 or next_day == 7:
			SceneTransition.change_scene("res://scene/office_lobby.tscn")
		else:
			SceneTransition.change_scene("res://scene/elevator.tscn")

# ==========================================
# END OF GAME LOGIC
# ==========================================
func _on_game_finished_clicked(event: InputEvent):
	# Listen for a left mouse click anywhere on the Game Finished panel
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SceneTransition.change_scene("res://scene/main_menu.tscn")
