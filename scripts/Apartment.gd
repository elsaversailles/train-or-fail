extends Node3D

const Catalog := preload("res://scripts/EndingCatalog.gd")

@onready var result_panel = $ResultPanel 
@onready var player = $Player
@onready var game_finished_panel = $GameFinishedPanel
@onready var ending_texture_rect = $GameFinishedPanel/TextureRect
@onready var ending_intro = $GameFinishedPanel/EndingIntro

# Choice UI for the 27/45 score branch
@onready var choice_container = $GameFinishedPanel/ChoiceContainer
@onready var choice_survival_btn = $GameFinishedPanel/ChoiceContainer/SurvivalButton
@onready var choice_clean_exit_btn = $GameFinishedPanel/ChoiceContainer/CleanExitButton

func _ready():
	result_panel.visible = false
	
	if not result_panel.continue_requested.is_connected(_on_continue_clicked):
		result_panel.continue_requested.connect(_on_continue_clicked)
		
	if game_finished_panel:
		game_finished_panel.visible = false
		game_finished_panel.gui_input.connect(_on_game_finished_clicked)
		
	if choice_container:
		choice_container.visible = false
		if choice_survival_btn:
			choice_survival_btn.pressed.connect(_on_choose_stagnant_survival)
		if choice_clean_exit_btn:
			choice_clean_exit_btn.pressed.connect(_on_choose_clean_exit)
	
	# Check if returning from the secret Grandpa round
	if SaveManager.current_save_data.get("grandpa_round_completed", false):
		show_secret_grandpa_ending()
		return
	if int(SaveManager.current_save_data.get("current_day", 1)) > 9:
		# A resumed final review can immediately lead to the bonus shift.
		if SceneTransition.is_transitioning:
			await SceneTransition.transition_finished
		resolve_game_ending()
		return
	
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
	result_panel.visible = false
		
	var current_level = SaveManager.current_save_data.get("pending_level", 1)
	var current_day = SaveManager.current_save_data.get("pending_day", 1)
	var department = SaveManager.current_save_data.get("pending_department", "FraudDetection")
	var score = SaveManager.current_save_data.get("pending_score", 0)

	# CUMULATIVE SCORE TRACKING (Total out of 45 across 9 days)
	var accumulated_score = SaveManager.current_save_data.get("total_score", 0) + score
	SaveManager.current_save_data["total_score"] = accumulated_score

	var next_level = current_level
	var next_day = current_day + 1
	var next_scene_path = "" 
	var current_level_id = "%s_L%d_D%d" % [department.to_lower(), current_level, current_day]
	var next_stage_name = ""

	if next_day <= 3:
		next_scene_path = "res://scene/FraudDetection/FraudDetection.tscn"
		if next_day == 2:
			next_stage_name = "Fraud L2 - Day 2"
		elif next_day == 3:
			next_stage_name = "Fraud L3 - Day 3"

	elif next_day <= 6:
		next_scene_path = "res://scene/KnowYourCustomer/KnowYourCustomer.tscn"
		next_level = 2 
		if next_day == 4:
			next_stage_name = "KYC L1 - Day 4"
		elif next_day == 5:
			next_stage_name = "KYC L2 - Day 5"
		elif next_day == 6:
			next_stage_name = "KYC L3 - Day 6"

	elif next_day <= 9:
		next_scene_path = "res://scene/CreditScoring/CreditScoring.tscn" 
		next_level = 3 
		if next_day == 7:
			next_stage_name = "Credit L1 - Day 7"
		elif next_day == 8:
			next_stage_name = "Credit L2 - Day 8"
		elif next_day == 9:
			next_stage_name = "Credit L3 - Day 9"
			
	else:
		next_scene_path = "res://scene/apartment.tscn"
		next_stage_name = "Final Review"

	SaveManager.current_save_data["current_level"] = next_level
	SaveManager.current_save_data["current_day"] = next_day
	# Roll once at the end of the completed day, then persist the next day's weather.
	SaveManager.current_save_data["weather_day"] = next_day
	SaveManager.current_save_data["weather_rain"] = randf() < SaveManager.RAIN_CHANCE
	SaveManager.current_save_data["weather_rule_version"] = SaveManager.WEATHER_RULE_VERSION

	SaveManager.current_save_data.erase("pending_score")
	SaveManager.current_save_data.erase("pending_day")
	SaveManager.current_save_data.erase("pending_level")
	SaveManager.current_save_data.erase("pending_department")

	SaveManager.auto_save_level(next_scene_path, next_stage_name, current_level_id, score, next_day)
	
	if next_day > 9:
		resolve_game_ending()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		if player:
			player.is_paused = false
			
		if next_day == 4 or next_day == 7:
			SceneTransition.change_scene("res://scene/office_lobby.tscn")
		else:
			SceneTransition.change_scene("res://scene/elevator.tscn")

# ==========================================
# ENDING RESOLUTION
# ==========================================

func resolve_game_ending():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$CanvasLayer.hide()
	if player:
		player.is_paused = true
	
	var route := Catalog.get_final_route(SaveManager.current_save_data)
	if route == Catalog.GRANDPA_SHIFT:
		SaveManager.current_save_data["is_grandpa_shift"] = true
		SaveManager.save_game(SaveManager.current_slot, SaveManager.current_save_data)
		SceneTransition.change_scene("res://scene/CreditScoring/CreditScoring.tscn")
		return

	if route == Catalog.CAREER_CHOICE:
		ending_texture_rect.texture = null
		if choice_container:
			choice_container.visible = true
		game_finished_panel.visible = true
		return

	_show_ending(route)

func show_secret_grandpa_ending():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	$CanvasLayer.hide()
	if player:
		player.is_paused = true
	
	SaveManager.current_save_data.erase("grandpa_round_completed")
	_show_ending(Catalog.get_grandpa_ending(SaveManager.get_special_decision("grandpa")))

func _show_ending(ending_id: String):
	SaveManager.record_ending(ending_id)
	ending_texture_rect.texture = load(Catalog.ENDINGS[ending_id]["image"]) as Texture2D
	choice_container.visible = false
	game_finished_panel.visible = true
	ending_intro.show_ending(ending_id)

# ==========================================
# CHOICE SELECTION & EXIT
# ==========================================

func _on_choose_stagnant_survival():
	_show_ending("stagnant_survival")

func _on_choose_clean_exit():
	_show_ending("clean_exit")

func _on_game_finished_clicked(event: InputEvent):
	if ending_intro.visible:
		return
	if choice_container and choice_container.visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SceneTransition.change_scene("res://scene/main_menu.tscn")
		
