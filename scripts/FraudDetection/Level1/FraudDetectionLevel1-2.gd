extends Node3D

@onready var final_result_panel = $ResultPanel/FinalResultPanel
@onready var final_result_label = $ResultPanel/FinalResultPanel/FinalResultLabel
@onready var restart_button = $ResultPanel/FinalResultPanel/RestartButton
@onready var nextgame_button = $ResultPanel/FinalResultPanel/NextgameButton
@onready var mainmenu_button = $ResultPanel/FinalResultPanel/MainmenuButton
@onready var player = $MainChar



func _ready():
	final_result_panel.visible = false
	
	restart_button.pressed.connect(_on_restart_button_pressed)
	mainmenu_button.pressed.connect(_on_mainmenu_button_pressed)
	nextgame_button.pressed.connect(_on_nextgame_button_pressed)
	
func show_final_result(score: int):
	final_result_panel.visible = true
	final_result_label.text = "Level Cleared!\n\nFinal Score: %d / 5" % score
	
	# Unlock mouse so player can click buttons
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Stop player movement/look
	if player:
		player.is_paused = true

func _on_restart_button_pressed():
	pass

func _on_mainmenu_button_pressed():
	get_tree().change_scene_to_file("res://scene/main_menu.tscn")
	
func _on_nextgame_button_pressed():
	get_tree().change_scene_to_file("res://scene/FraudDetection/Level2/FraudDetectionLevel2-1.tscn")
