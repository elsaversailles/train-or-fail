extends Control

# --- ORIGINAL VARIABLES ---
@onready var settings_panel: Panel = $SettingsPanel

# --- SAVE SYSTEM VARIABLES ---
@onready var slots_container = $Slots/Panel
@onready var slot_1 = $Slots/Panel/SlotButton1
@onready var slot_2 = $Slots/Panel/SlotButton2
@onready var slot_3 = $Slots/Panel/SlotButton3

@onready var info_label = $Slots/Panel/SlotInfoLabel
@onready var select_btn = $Slots/Panel/SelectButton
@onready var delete_btn = $Slots/Panel/DeleteButton

var selected_slot: int = 1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	settings_panel.visible = false
	slots_container.visible = false
	
	slot_1.pressed.connect(func(): _on_slot_clicked(1))
	slot_2.pressed.connect(func(): _on_slot_clicked(2))
	slot_3.pressed.connect(func(): _on_slot_clicked(3))
	
	select_btn.pressed.connect(_on_select_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	
	select_btn.visible = false
	delete_btn.visible = false
	info_label.text = "Please select a slot."
	
	refresh_slot_names()

func _on_new_game_pressed():
	slots_container.visible = true

func _on_settings_pressed():
	settings_panel.visible = true

func _on_about_us_pressed():
	print("Created for IT Capstone Project")

func _on_quit_pressed():
	get_tree().quit()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_ready()
		return

# ==========================================
# SAVE SYSTEM LOGIC
# ==========================================

func refresh_slot_names():
	update_button_text(slot_1, 1)
	update_button_text(slot_2, 2)
	update_button_text(slot_3, 3)

func update_button_text(btn: Button, slot: int):
	if SaveManager.save_exists(slot):
		var data = SaveManager.load_game(slot)
		# Looks for "stage_name", if it's an old save it falls back to "Saved Game"
		var stage = data.get("stage_name", "Saved Game")
		btn.text = "Slot %d - %s" % [slot, stage]
	else:
		btn.text = "Slot %d - Empty" % slot

func _on_slot_clicked(slot: int):
	selected_slot = slot
	select_btn.visible = true
	delete_btn.visible = true
	
	if SaveManager.save_exists(slot):
		var data = SaveManager.load_game(slot)
		var stage = data.get("stage_name", "Saved Game")
		info_label.text = "Stage: %s\nTotal Score: %d" % [stage, data.get("total_score", 0)]
		select_btn.text = "Load Game"
		delete_btn.disabled = false 
	else:
		info_label.text = "No saved data.\nStart a new career?"
		select_btn.text = "New Game"
		delete_btn.disabled = true 

func _on_select_pressed():
	SaveManager.current_slot = selected_slot
	
	if SaveManager.save_exists(selected_slot):
		# LOAD EXISTING
		SaveManager.current_save_data = SaveManager.load_game(selected_slot)
	else:
		# START NEW
		SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
		SaveManager.save_game(selected_slot, SaveManager.current_save_data)
		
	# --- THE FIX: Load exactly the scene path saved in the JSON ---
	var scene_to_load = SaveManager.current_save_data.get("current_scene_path", "res://scene/FraudDetection/Level1/FraudDetectionLevel1-1.tscn")
	
	# --- THE SAFETY NET ---
	# If the path is empty or broken, force Level 1 so the game doesn't crash!
	if scene_to_load == "" or scene_to_load == "res://":
		scene_to_load = "res://scene/FraudDetection/Level1/FraudDetectionLevel1-1.tscn"
		print("Warning: Save file had a broken path. Safe-loading Level 1.")
		
	get_tree().change_scene_to_file(scene_to_load)

func _on_delete_pressed():
	SaveManager.delete_save(selected_slot)
	select_btn.visible = false
	delete_btn.visible = false
	info_label.text = "Slot deleted."
	refresh_slot_names()
