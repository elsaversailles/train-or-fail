extends Control

signal continue_requested

@onready var terminal_text = $Background/TerminalText
@onready var background = $Background

# --- THE PRO WAY: Exported Variable ---
# This creates a setting directly in your Godot Inspector!
# Make it smaller (e.g., 0.005) to type faster, or larger (0.05) to type slower.
@export var typing_speed: float = 0.01

# --- State Variables ---
var is_typing: bool = false
var can_continue: bool = false
var current_tween: Tween

func _ready():
	visible = false
	background.gui_input.connect(_on_background_clicked)

func display_terminal_report(score: int, current_level: int):
	var is_promoted = "Yes" if score >= 3 else "No"
	var alignment_decimal = float(score) / 5.0
	var percentage = int(alignment_decimal * 100)
	
	var report_string = """Angiloan AI Model Training Report
======================

Fraud Detection Cases: 5
Epoch: %d
Accurate Detection: %d/5
Status: Regiment Training %d/5 Done

======================
GPU Utilization: 100%%
RAM Consumed: 17GB
Model Type: Regression
Training Type: RLHF
======================

Alignment Score: %.1f (%d%%)
Promotion: %s

======================
END OF REPORT
...
...

"CLICK ANYWHERE TO CONTINUE"
█
"""
	
	# Hide all characters initially
	terminal_text.visible_characters = 0
	terminal_text.text = report_string % [
		current_level, score, current_level, alignment_decimal, percentage, is_promoted
	]
	
	visible = true
	is_typing = true
	can_continue = false
	
	var total_chars = terminal_text.get_total_character_count()
	
	# --- USING YOUR NEW VARIABLE ---
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
