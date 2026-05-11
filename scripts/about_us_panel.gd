extends Panel

@onready var scroll_container = $ScrollContainer
@onready var label = $ScrollContainer/Label

# Adjust this to change typing speed (smaller = faster)
@export var typing_speed: float = 0.02 

var current_tween: Tween
var is_typing: bool = false

var about_us_text = """Train or Fail

Made with ♥

Raymart De Guzman (Programmer)
Matt Kevin Chavaz (Art Direction)
Angelo Mabignay (Quality Assurance)
Vince Austria (Project Manager)


STI San Jose del Monte Capstone Project

==========================================
Content Disclaimer: Characters, events, and names shown in this game are fictional. Any similarities are purely coincidental. Moreover, the technologies and processes shown in this game are generalized for learning and entertainment purposes. This game does not aim to infringe upon any proprietary processes or systems.
"""

func _ready():
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	
	# Listen for clicks so the player can skip the typing
	gui_input.connect(_on_panel_clicked)
	
	# --- THE NEW ADDITION ---
	# Automatically start typing as soon as the scene loads!
	start_typing()

# ... (Keep your start_typing and _on_typing_finished functions exactly the same!) ...

# ==========================================
# INPUT LOGIC
# ==========================================

func start_typing():
	label.text = about_us_text
	label.visible_characters = 0
	is_typing = true
	
	# Ensure scrollbar stays hidden while typing
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	# Reset scroll position to the very top
	scroll_container.scroll_vertical = 0 
	
	var total_chars = label.get_total_character_count()
	var total_duration = total_chars * typing_speed
	
	if current_tween:
		current_tween.kill()
		
	current_tween = create_tween()
	current_tween.tween_property(label, "visible_characters", total_chars, total_duration)
	current_tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	label.visible_characters = -1 # Show all text
	
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER

func _on_panel_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# If they click while it's typing, instantly skip to the end!
		if is_typing:
			if current_tween:
				current_tween.kill()
			_on_typing_finished()
func _unhandled_input(event: InputEvent) -> void:
	# "ui_cancel" is automatically bound to the Escape key in Godot!
	if event.is_action_pressed("ui_cancel"):
		# Fade out and go back to the Main Menu
		# (Make sure this path perfectly matches your main menu scene file!)
		SceneTransition.change_scene("res://scene/main_menu.tscn")
