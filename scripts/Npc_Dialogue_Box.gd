extends Node3D

@onready var container = $SubViewport/TextBoxContainer
@onready var label = $SubViewport/TextBoxContainer/Padding/Label
@onready var timer = $SubViewport/TextBoxContainer/LetterDisplayTimer
@onready var viewport = $SubViewport

const MAX_WIDTH: int = 256

var text: String = ""
var letter_index: int = 0

var letter_time: float = 0.03
var space_time: float = 0.06
var punctuation_time: float = 0.2

signal finished_displaying

func _ready():
	# self.visible = false # Temporarily comment this out!
	
	# Feed it a long sentence to test the width and the typing effect
	display_text("Hi!.. To get to your office just go straight then turn left... You will see a building named angiloan.")
func display_text(text_to_display: String):
	self.visible = true
	text = text_to_display
	
	# Reset state
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	container.custom_minimum_size = Vector2.ZERO
	label.text = text_to_display
	
	# Wait for Godot to measure the raw, single-line text
	await get_tree().process_frame
	
	# Set the X size based on the video's logic
	container.custom_minimum_size.x = min(container.size.x, MAX_WIDTH)
	
	# Force wrap if it exceeds max width
	if container.size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		await get_tree().process_frame # Wait for X resize
		await get_tree().process_frame # Wait for Y resize
		
	# Lock the Y size and adjust the 3D Viewport window
	container.custom_minimum_size.y = container.size.y
	viewport.size = container.size
	
	# Clear the text and start the typewriter effect!
	label.text = ""
	letter_index = 0
	display_letter()

func display_letter():
	label.text += text[letter_index]
	letter_index += 1
	
	if letter_index >= text.length():
		finished_displaying.emit()
		return
		
	# Check the current character to decide how long to pause
	match text[letter_index]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)

func _on_letter_display_timer_timeout():
	display_letter()
