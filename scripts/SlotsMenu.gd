extends Control

# Adjust paths if your layout changed slightly when moving it!
@onready var slot_1 = $Panel/SlotButton1
@onready var slot_2 = $Panel/SlotButton2
@onready var slot_3 = $Panel/SlotButton3

@onready var info_label = $Panel/SlotInfoLabel
@onready var select_btn = $Panel/SelectButton
@onready var delete_btn = $Panel/DeleteButton

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
	info_label.text = "Please select a slot."
	
	refresh_slot_names()

func refresh_slot_names():
	update_button_text(slot_1, 1)
	update_button_text(slot_2, 2)
	update_button_text(slot_3, 3)

func update_button_text(btn: Button, slot: int):
	if SaveManager.save_exists(slot):
		var data = SaveManager.load_game(slot)
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
	# 1. Tell the SaveManager which slot we picked
	SaveManager.current_slot = selected_slot
	
	# 2. Check if the slot is completely empty
	if not SaveManager.save_exists(selected_slot):
		# It's a New Game! Copy the default template and save it to the hard drive
		SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
		SaveManager.save_game(selected_slot, SaveManager.current_save_data)
	else:
		# It's an Existing Game! Load their progress into memory
		SaveManager.current_save_data = SaveManager.load_game(selected_slot)
	
	# 3. No matter if it is Day 1 or Day 5, everyone starts their morning on the street!
	SceneTransition.change_scene("res://scene/outside_world.tscn")

func _on_delete_pressed():
	SaveManager.delete_save(selected_slot)
	select_btn.visible = false
	delete_btn.visible = false
	info_label.text = "Slot deleted."
	refresh_slot_names()

func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel" is automatically bound to the Escape key in Godot!
	if event.is_action_pressed("ui_cancel"):
		# Fade out and go back to the Main Menu
		# (Make sure this path perfectly matches your main menu scene file!)
		SceneTransition.change_scene("res://scene/main_menu.tscn")

func _on_try_pressed() -> void:
	SceneTransition.change_scene("res://scene/outside_world.tscn")
