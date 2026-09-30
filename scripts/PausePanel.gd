extends Panel

@onready var pause_panel: Panel = $"."
@onready var settings_panel: Panel = $SettingsPanel
@onready var player = get_tree().get_first_node_in_group("player")
@onready var confirm_quit_panel: Panel = $ConfirmQuitPanel

# Reference the instantiated TutorialPanel scene
@onready var tutorial_panel: Panel = $TutorialPanel

func _ready() -> void:
	pause_panel.visible = false
	settings_panel.visible = false
	
	if confirm_quit_panel:
		confirm_quit_panel.visible = false
		
	if tutorial_panel:
		tutorial_panel.visible = false

func _on_resume_pressed() -> void:
	if player:
		settings_panel.visible = false
		confirm_quit_panel.visible = false
		if tutorial_panel:
			tutorial_panel.visible = false
		player.resume_game()

func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	settings_panel.visible = false

func _on_quit_pressed() -> void:
	confirm_quit_panel.visible = true
	
func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")

func _on_desktop_button_pressed() -> void:
	get_tree().quit()

func _on_cancel_button_pressed() -> void:
	confirm_quit_panel.visible = false

func _on_reset_game_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

# --- Call the Tutorial Scene ---
func _on_replay_tutorial_pressed() -> void:
	settings_panel.visible = false
	confirm_quit_panel.visible = false
	
	# Trigger the function inside your new separate scene
	tutorial_panel.open_tutorial()
