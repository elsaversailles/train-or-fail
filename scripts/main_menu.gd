extends Control

@onready var buttons: Control = $Buttons
@onready var settings_panel: Panel = $SettingsPanel
	

func _ready():
	# This ensures the cursor is visible for the menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	buttons.visible = true
	settings_panel.visible = false

func _on_new_game_pressed():
	# This removes the menu and loads a brand  new 'main.tscn'
	get_tree().change_scene_to_file("res://scene/main.tscn")

func _on_settings_pressed():
	# Settings
	buttons.visible = false
	settings_panel.visible = true

func _on_about_us_pressed():
	
	print("Created for IT Capstone Project")

func _on_quit_pressed():
	get_tree().quit()
	
func _unhandled_input(event: InputEvent) -> void:
	# ESC = return to menu
	if event.is_action_pressed("ui_cancel"):
		_ready()
		return
