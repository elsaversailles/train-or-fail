extends Node3D

@onready var final_result_panel = $CanvasLayer2/FinalResultPanel
@onready var final_result_label = $CanvasLayer2/FinalResultPanel/FinalResultLabel
@onready var restart_button = $CanvasLayer2/FinalResultPanel/RestartButton
@onready var mainmenu_button = $CanvasLayer2/FinalResultPanel/MainmenuButton

func _ready():
	final_result_panel.visible = false
	restart_button.pressed.connect(_on_restart_button_pressed)
	mainmenu_button.pressed.connect(_on_mainmenu_button_pressed)

func show_final_result(score):
	final_result_panel.visible = true
	final_result_label.text = "Level Cleared!\n\nFinal Score: %d / 5" % score

func _on_restart_button_pressed():
	get_tree().reload_current_scene()
	

func _on_mainmenu_button_pressed():
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
