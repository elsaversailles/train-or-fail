extends Panel

@onready var pause_panel: Panel = $"."
@onready var settings_panel: Panel = $SettingsPanel
@onready var player = get_tree().get_first_node_in_group("player")

# --- NEW VARIABLE ---
@onready var confirm_quit_panel: Panel = $ConfirmQuitPanel

func _ready() -> void:
	pause_panel.visible = false
	settings_panel.visible = false
	
	# Hide the confirmation panel by default
	if confirm_quit_panel:
		confirm_quit_panel.visible = false

func _on_resume_pressed() -> void:
	if player:
		# Close all extra panels when resuming
		settings_panel.visible = false
		confirm_quit_panel.visible = false
		player.resume_game()

func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	settings_panel.visible = false

# --- MODIFIED: Show warning instead of instantly quitting ---
func _on_quit_pressed() -> void:
	confirm_quit_panel.visible = true

# ==========================================
# CONFIRM QUIT LOGIC
# ==========================================

func _on_main_menu_button_pressed() -> void:
	# Unpause the game engine and go to the menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_desktop_button_pressed() -> void:
	# Instantly close the entire game application
	get_tree().quit()

func _on_cancel_button_pressed() -> void:
	# Player changed their mind, just hide the warning panel
	confirm_quit_panel.visible = false
