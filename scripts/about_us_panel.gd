extends Panel

@onready var scroll_container = $ScrollContainer

@onready var label = $ScrollContainer/Label

@export var typing_speed: float = 0.02 

var current_tween: Tween
var is_typing: bool = false

var about_us_text = """[font_size=18]Train or Fail

Made with ♥

Raymart De Guzman (Programmer)
Matt Kevin Chabas (Art Direction)
John Angelo Mabingnay (Quality Assurance)
Vince Bernard Austria (Project Manager)


STI San Jose del Monte Capstone Project

==========================================[/font_size]
[font_size=12]Content Disclaimer: Characters, events, and names shown in this game are fictional. Any similarities are purely coincidental. Moreover, the technologies and processes shown in this game are generalized for learning and entertainment purposes. This game does not aim to infringe upon any proprietary processes or systems.[/font_size]
"""

func _ready():
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	start_typing()

func start_typing():
	label.text = about_us_text
	
	label.visible_ratio = 0.0
	is_typing = true
	
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

	scroll_container.scroll_vertical = 0 
	
	var total_chars = label.get_parsed_text().length()
	var total_duration = total_chars * typing_speed
	
	if current_tween:
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(label, "visible_ratio", 1.0, total_duration)
	current_tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	label.visible_ratio = 1.0 
	
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER


func _input(event: InputEvent) -> void:
	
	# click anyhwere to skip
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_typing:
			if current_tween:
				current_tween.kill()
			_on_typing_finished()
			

	if event.is_action_pressed("ui_cancel"):
		SceneTransition.change_scene("res://scene/main_menu.tscn")
