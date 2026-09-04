extends Control

signal continue_requested

@onready var terminal_text = $Background/TerminalText
@onready var background = $Background

# --- THE PRO WAY: Exported Variable ---
@export var typing_speed: float = 0.01

# --- State Variables ---
var is_typing: bool = false
var can_continue: bool = false
var current_tween: Tween

func _ready():
	visible = false
	background.gui_input.connect(_on_background_clicked)

# --- UPDATED FUNCTION SIGNATURE ---
# Now it specifically asks for the Gameplay Name, Level, Day, and Score!
func display_terminal_report(gameplay_name: String, level: int, day: int, score: int):
	
	# The triple quotes let us draw a clean ASCII box to make it lively!
	var report_string = """> UPLOADING DAILY METRICS...
> ANALYZING OPERATIVE PERFORMANCE...

===================================
  GAMEPLAY : %s
  LEVEL    : %d
  DAY      : %d
===================================
  SCORE    : %d / 5
===================================

> DATA SYNC COMPLETE.
> [CLICK ANYWHERE TO CONTINUE]
█
"""
	
	# Hide all characters initially
	terminal_text.visible_characters = 0
	
	# Fill in the placeholders with our 4 variables
	terminal_text.text = report_string % [
		gameplay_name, level, day, score
	]
	
	visible = true
	is_typing = true
	can_continue = false
	
	var total_chars = terminal_text.get_total_character_count()
	var total_duration = total_chars * typing_speed
	
	# Create a Tween to animate the typing
	if current_tween:
		current_tween.kill() 
	
	current_tween = create_tween()
	current_tween.tween_property(terminal_text, "visible_characters", total_chars, total_duration)
	current_tween.finished.connect(_on_typing_finished)

func _on_typing_finished():
	is_typing = false
	can_continue = true
	terminal_text.visible_characters = -1 

func _on_background_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_typing:
			if current_tween:
				current_tween.kill() 
			_on_typing_finished()    
		elif can_continue:
			can_continue = false 
			continue_requested.emit()
