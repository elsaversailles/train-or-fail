extends Control

@onready var slot_1: TextureButton = $Panel/SlotButton1
@onready var slot_2: TextureButton = $Panel/SlotButton2
@onready var slot_3: TextureButton = $Panel/SlotButton3

@onready var select_btn: TextureButton = $Panel/SelectButton
@onready var delete_btn: TextureButton = $Panel/DeleteButton

# Reference the child Labels inside SelectButton and DeleteButton
@onready var select_btn_label: Label = $Panel/SelectButton/Label
@onready var delete_btn_label: Label = $Panel/DeleteButton/Label

var selected_slot: int = 1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	slot_1.pressed.connect(func(): _on_slot_clicked(1))
	slot_2.pressed.connect(func(): _on_slot_clicked(2))
	slot_3.pressed.connect(func(): _on_slot_clicked(3))
	select_btn.pressed.connect(_on_select_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	select_btn.visible = false
	delete_btn.visible = false
	refresh_slot_names()

func refresh_slot_names():
	update_button_text(slot_1, 1)
	update_button_text(slot_2, 2)
	update_button_text(slot_3, 3)

func update_button_text(btn: TextureButton, slot: int):
	var title_label: Label = btn.get_node("SlotTitleLabel")
	var stage_label: Label = btn.get_node("StageLabel")
	var score_label: Label = btn.get_node("ScoreLabel")
	title_label.text = "Slot %d" % slot
	if SaveManager.save_exists(slot):
		var data = SaveManager.load_game(slot)
		stage_label.text = "Stage: " + format_slot_stage(str(data.get("stage_name", "Saved Game")))
		score_label.text = "Total Score: %d" % int(data.get("total_score", 0))
		btn.tooltip_text = "Select slot %d to continue or delete this saved career." % slot
	else:
		stage_label.text = "Stage: Empty"
		score_label.text = "Total Score: 0"
		btn.tooltip_text = "Select empty slot %d to start a new career." % slot

func format_slot_stage(stage: String) -> String:
	var department = stage.get_slice(" - ", 0)
	if department.begins_with("Fraud L"):
		stage = stage.replace(department, "Fraud Detection")
	elif department.begins_with("KYC L"):
		stage = stage.replace(department, "KYC")
	elif department.begins_with("Credit L"):
		stage = stage.replace(department, "Credit Scoring")
	return stage.replace(" - ", " -\n")

func _on_slot_clicked(slot: int):
	selected_slot = slot
	select_btn.visible = true
	delete_btn.visible = true
	if SaveManager.save_exists(slot):
		select_btn_label.text = "Load Game"
		select_btn.tooltip_text = "Continue the saved career in slot %d." % slot
		delete_btn_label.text = "Delete"
		delete_btn.tooltip_text = "Permanently delete the save in slot %d.\nThis cannot be undone." % slot
		delete_btn.disabled = false 
	else:
		select_btn_label.text = "New Game"
		select_btn.tooltip_text = "Start a new career in empty slot %d." % slot
		delete_btn_label.text = "Delete"
		delete_btn.tooltip_text = "This slot is empty. There is no save to delete."
		delete_btn.disabled = true 

func _on_select_pressed():
	# 1. Tell the SaveManager which slot we picked
	SaveManager.current_slot = selected_slot
	# 2. Check if the slot is completely empty
	if not SaveManager.save_exists(selected_slot):
		# It's a New Game! Copy the default template and save it to the hard drive
		SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
		SaveManager.save_game(selected_slot, SaveManager.current_save_data)
		# Go to the Boat intro scene first! (Adjust path if needed)
		SceneTransition.change_scene("res://scene/boat.tscn")
		return
	else:
		# It's an Existing Game! Load their progress into memory
		SaveManager.current_save_data = SaveManager.load_game(selected_slot)
	
	# 3. ROUTE THE PLAYER BASED ON THE DAY (For Loaded Games)
	var current_day = SaveManager.current_save_data.get("current_day", 1)
	if current_day == 1 or current_day == 4 or current_day == 7:
		SceneTransition.change_scene("res://scene/office_lobby.tscn")
	else:
		SceneTransition.change_scene("res://scene/elevator.tscn")

func _on_delete_pressed():
	SaveManager.delete_save(selected_slot)
	select_btn.visible = false
	delete_btn.visible = false
	refresh_slot_names()

func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel" is automatically bound to the Escape key in Godot!
	if event.is_action_pressed("ui_cancel"):
		# Fade out and go back to the Main Menu
		# (Make sure this path perfectly matches your main menu scene file!)
		SceneTransition.change_scene("res://scene/main_menu.tscn")
