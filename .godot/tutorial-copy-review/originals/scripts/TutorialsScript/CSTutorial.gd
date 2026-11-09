extends Control

@onready var message_label = $BackgroundPanel/MessageLabel
@onready var highlight_image = $BackgroundPanel/HighlightImage
@onready var timer = $BackgroundPanel/LetterDisplayTimer
@onready var backgroundtuts: Panel = $BackgroundPanel/Background

# Assign your Credit Scoring highlight images in the Inspector
@export var data_highlight_img: Texture2D
@export var slider_highlight_img: Texture2D

var tutorial_step: int = 1
var can_click: bool = false
var is_typing: bool = false

# --- TYPING VARIABLES FROM YOUR BUBBLE CHAT ---
var full_text: String = ""
var letter_index: int = 0
var letter_time: float = 0.03
var space_time: float = 0.06
var punctuation_time: float = 0.2

func _ready():
	self.visible = false
	can_click = false
	backgroundtuts.visible = false
	timer.timeout.connect(_on_letter_display_timer_timeout)

# Triggered when the player inserts the disk and presses 'E'
func screen_focused():
	if tutorial_step == 1:
		tutorial_step = 2
		self.visible = true 
		can_click = true 
		
		if highlight_image and data_highlight_img:
			backgroundtuts.visible = true
			highlight_image.visible = true
			highlight_image.texture = data_highlight_img
			
		start_typing("Welcome to the Credit Scoring department! The data you need to review is now different again.\n(Click anywhere to continue)")

# --- THE TYPING EFFECT LOGIC ---
func start_typing(text_to_display: String):
	full_text = text_to_display
	message_label.text = ""
	letter_index = 0
	is_typing = true
	display_letter()

func display_letter():
	message_label.text += full_text[letter_index]
	letter_index += 1
	
	if letter_index >= full_text.length():
		is_typing = false
		return
		
	# Check the character we just typed to decide how long to pause
	match full_text[letter_index - 1]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)

func _on_letter_display_timer_timeout():
	display_letter()

# --- INPUT AND PROGRESSION ---
func _input(event: InputEvent):
	if can_click and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_typing:
			# If they click while it's typing, instantly show all the text!
			timer.stop()
			message_label.text = full_text
			is_typing = false
		else:
			# If it's done typing, move to the next tutorial step
			advance_tutorial()

func advance_tutorial():
	if tutorial_step == 2:
		tutorial_step = 3
		if highlight_image and slider_highlight_img:
			highlight_image.texture = slider_highlight_img
			
		start_typing("See that slider on the left? That's the proposed credit amount. You have the power to adjust it up or down based on their risk before you lock in your submission. Don't be afraid to hit 'Red Flag' if they're a lost cause!\n(Click anywhere to continue)")
		
	elif tutorial_step == 3:
		tutorial_step = 4
		if highlight_image:
			highlight_image.visible = false 
			backgroundtuts.visible = false
			
		start_typing("That's all for your Credit Scoring training. You can now continue on your own. Good luck.\n(Click anywhere to continue)")
		
	elif tutorial_step == 4:
		queue_free()
