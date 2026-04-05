extends Panel

@onready var pause_panel: Panel = $"."
@onready var settings_panel: Panel = $SettingsPanel
@onready var player = get_tree().get_first_node_in_group("player")

func _ready() -> void:
	pause_panel.visible = false
	settings_panel.visible = false

func _on_resume_pressed() -> void:
	if player:
		settings_panel.visible = false
		player.resume_game()

func _on_settings_pressed() -> void:
	settings_panel.visible = true

func _on_close_settings_pressed() -> void:
	settings_panel.visible = false

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
