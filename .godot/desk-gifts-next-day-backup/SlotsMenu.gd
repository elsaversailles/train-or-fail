extends Control

const EMPTY_SLOT_TEXTURE = preload("res://images/MainMenu/SlotsMenu/Slots.png")
const SAVED_SLOT_TEXTURE = preload("res://images/MainMenu/SlotsMenu/Slots_Green.png")
const DELETING_SLOT_TEXTURE = preload("res://images/MainMenu/SlotsMenu/Slots_Red.png")
const DELETE_FEEDBACK_SECONDS: float = 2.0

@onready var slot_1: TextureButton = $Panel/SlotButton1
@onready var slot_2: TextureButton = $Panel/SlotButton2
@onready var slot_3: TextureButton = $Panel/SlotButton3
@onready var selection_aura = $Panel/SelectionAura

@onready var select_btn: TextureButton = $Panel/SelectButton
@onready var delete_btn: TextureButton = $Panel/DeleteButton

# Reference the child Labels inside SelectButton and DeleteButton
@onready var select_btn_label: Label = $Panel/SelectButton/Label
@onready var delete_btn_label: Label = $Panel/DeleteButton/Label

@onready var confirmation_overlay: ColorRect = $DeleteConfirmation
@onready var confirmation_title: Label = $DeleteConfirmation/Dialog/Title
@onready var confirm_delete_btn: Button = $DeleteConfirmation/Dialog/DeleteButton
@onready var cancel_delete_btn: Button = $DeleteConfirmation/Dialog/CancelButton

var selected_slot: int = 1
var deleting_slots: Array[int] = []
var pending_delete_slot: int = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	for button in [slot_1, slot_2, slot_3, select_btn, confirm_delete_btn]:
		SoundEffects.set_button_sound(button, "")
	slot_1.pressed.connect(func(): _on_slot_clicked(1))
	slot_2.pressed.connect(func(): _on_slot_clicked(2))
	slot_3.pressed.connect(func(): _on_slot_clicked(3))
	select_btn.pressed.connect(_on_select_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	confirm_delete_btn.pressed.connect(_on_confirm_delete_pressed)
	cancel_delete_btn.pressed.connect(_on_cancel_delete_pressed)
	confirmation_overlay.hide()
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
	btn.disabled = deleting_slots.has(slot)
	if btn.disabled:
		btn.texture_normal = DELETING_SLOT_TEXTURE
		btn.texture_disabled = DELETING_SLOT_TEXTURE
		stage_label.text = "Deleting.."
		score_label.text = ""
		btn.tooltip_text = "Deleting the save in slot %d." % slot
	elif SaveManager.save_exists(slot):
		btn.texture_normal = SAVED_SLOT_TEXTURE
		var data = SaveManager.read_save(slot)
		stage_label.text = "Stage: " + format_slot_stage(str(data.get("stage_name", "Saved Game")))
		score_label.text = "Total Score: %d" % int(data.get("total_score", 0))
		if SaveManager.get_completed_ending_id(data) != "":
			btn.tooltip_text = "Select slot %d to play again from Day 1." % slot
		else:
			btn.tooltip_text = "Select slot %d to continue or delete this saved career." % slot
	else:
		btn.texture_normal = EMPTY_SLOT_TEXTURE
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
	if confirmation_overlay.visible or deleting_slots.has(slot):
		return
	SoundEffects.play("slot")
	selected_slot = slot
	selection_aura.follow_slot([slot_1, slot_2, slot_3][slot - 1])
	select_btn.visible = true
	delete_btn.visible = true
	if SaveManager.save_exists(slot):
		var data = SaveManager.read_save(slot)
		if SaveManager.get_completed_ending_id(data) != "":
			select_btn_label.text = "Replay"
			select_btn.tooltip_text = "Start from Day 1 in slot %d with your certificates and collected endings." % slot
		else:
			select_btn_label.text = "Load Game"
			select_btn.tooltip_text = "Continue the saved career in slot %d." % slot
		delete_btn_label.text = "Delete"
		delete_btn.tooltip_text = "Permanently delete slot %d and its training certificates." % slot
		delete_btn.disabled = false 
	else:
		select_btn_label.text = "New Game"
		select_btn.tooltip_text = "Start a new career in empty slot %d." % slot
		delete_btn_label.text = "Delete"
		delete_btn.tooltip_text = "This slot is empty. There is no save to delete."
		delete_btn.disabled = true 

func _on_select_pressed():
	if SceneTransition.is_transitioning or confirmation_overlay.visible or deleting_slots.has(selected_slot):
		return
	var has_save := SaveManager.save_exists(selected_slot)
	var data := SaveManager.load_game(selected_slot)
	if has_save and data.is_empty():
		return
	if not has_save or SaveManager.get_completed_ending_id(data) != "":
		if has_save and not SaveManager.preserve_slot_ending(data):
			_show_slot_error(selected_slot, "Couldn't save gallery progress. Try Replay again.")
			return
		var fresh_run := SaveManager.DEFAULT_SAVE.duplicate(true)
		if has_save:
			fresh_run["certificates"] = data["certificates"].duplicate()
		if not SaveManager.save_game(selected_slot, fresh_run):
			_show_slot_error(selected_slot, "Couldn't start the new save. Try again.")
			return
		SaveManager.current_save_data = fresh_run
		SoundEffects.play("new_game")
		SceneTransition.change_scene("res://scene/boat.tscn")
		return

	SoundEffects.play("load_game")
	var current_day := int(data.get("current_day", 1))
	if data.get("is_grandpa_shift", false):
		SceneTransition.change_scene("res://scene/CreditScoring/CreditScoring.tscn")
	elif current_day > 9:
		SceneTransition.change_scene("res://scene/apartment.tscn")
	elif current_day in [1, 4, 7]:
		SceneTransition.change_scene("res://scene/office_lobby.tscn")
	else:
		SceneTransition.change_scene("res://scene/elevator.tscn")

func _on_delete_pressed():
	if confirmation_overlay.visible or deleting_slots.has(selected_slot) or not SaveManager.save_exists(selected_slot):
		return
	pending_delete_slot = selected_slot
	confirmation_title.text = "Delete Slot %d?" % pending_delete_slot
	confirmation_overlay.show()
	cancel_delete_btn.grab_focus()

func _on_cancel_delete_pressed():
	if not confirmation_overlay.visible:
		return
	pending_delete_slot = 0
	confirmation_overlay.hide()
	delete_btn.grab_focus()

func _on_confirm_delete_pressed():
	if not confirmation_overlay.visible or pending_delete_slot == 0:
		return
	# Delete only the slot named in the confirmation, even if selection changes.
	var deleted_slot: int = pending_delete_slot
	pending_delete_slot = 0
	confirmation_overlay.hide()
	if deleting_slots.has(deleted_slot) or not SaveManager.save_exists(deleted_slot):
		refresh_slot_names()
		_on_slot_clicked(selected_slot)
		return
	if not SaveManager.delete_save(deleted_slot):
		_show_slot_error(deleted_slot, "Couldn't delete this save. Try again.")
		return
	SoundEffects.play("delete")
	deleting_slots.append(deleted_slot)
	selection_aura.clear()
	select_btn.visible = false
	delete_btn.visible = false
	refresh_slot_names()
	await get_tree().create_timer(DELETE_FEEDBACK_SECONDS, true, false, true).timeout
	deleting_slots.erase(deleted_slot)
	refresh_slot_names()

func _show_slot_error(slot: int, message: String) -> void:
	var button: TextureButton = [slot_1, slot_2, slot_3][slot - 1]
	button.get_node("StageLabel").text = message
	button.tooltip_text = message

func _input(event: InputEvent) -> void:
	if confirmation_overlay.visible and event.is_action_pressed("ui_cancel"):
		_on_cancel_delete_pressed()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel" is automatically bound to the Escape key in Godot!
	if event.is_action_pressed("ui_cancel"):
		# Fade out and go back to the Main Menu
		# (Make sure this path perfectly matches your main menu scene file!)
		SceneTransition.change_scene("res://scene/main_menu.tscn")
