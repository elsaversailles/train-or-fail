extends Control

@onready var settings_panel: Panel = $SettingsPanel

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	settings_panel.visible = false

func _on_new_game_pressed():
	# Call our new Autoload to handle the fade and load!
	SceneTransition.change_scene("res://scene/slots_menu.tscn")

func _on_settings_pressed():
	settings_panel.visible = true

func _on_about_us_pressed():
	SceneTransition.change_scene("res://scene/about_us_panel.tscn")
	
func _on_quit_pressed():
	get_tree().quit()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_ready()
		return
