extends Control

func _ready():
	# This ensures the cursor is visible for the menu
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_new_game_pressed():
	# Change "res://main.tscn" to the actual path of your first level
	get_tree().change_scene_to_file("res://scene/main.tscn")


func _on_load_game_pressed():
	# This is where you will later implement your Save/Load system
	print("Loading saved state...")

func _on_settings_pressed():
	# Typically opens a sub-menu for Audio, Graphics, etc.
	print("Opening Settings...")

func _on_about_us_pressed():
	# Show credits or project information
	print("Created for IT Capstone Project")

func _on_quit_pressed():
	# Closes the game application
	get_tree().quit()
