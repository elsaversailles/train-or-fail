extends Control

@onready var message_label = $BackgroundPanel/MessageLabel
@onready var highlight_image = $BackgroundPanel/HighlightImage
@onready var backgroundtuts: Panel = $BackgroundPanel/Background
@onready var timer = $BackgroundPanel/LetterDisplayTimer

# Assign your images in the Godot Inspector
@export var data_highlight_img: Texture2D
@export var button_highlight_img: Texture2D

@onready var background = $"../../Monitor/Screen/SubViewport/LeftSlidingPanel"

var tutorial_step: int = 1
var can_click: bool = false
var is_typing: bool = false

# --- TYPING VARIABLES ---
var full_text: String = ""
var letter_index: int = 0
var letter_time: float = 0.03
var space_time: float = 0.06
var punctuation_time: float = 0.2

func _ready():
	timer.timeout.connect(_on_letter_display_timer_timeout)
	start_tutorial()

func start_tutorial():
	visible = true
	can_click = false 
	backgroundtuts.visible = false
	highlight_image.visible = false
	
	# Make sure the main game UI is hidden while they are walking around
	if background:
		background.visible = false
		
	start_typing("Hey there, rookie! I'm your digital assistant, and today I'll be teaching you how to train our AI. Let's start by getting some data into the system. Grab that floppy disk, slide it into the drive, and hit 'E' on the monitor to boot it up!")

func screen_focused():
	if tutorial_step == 1:
		tutorial_step = 2
		can_click = true # Unlocks clicking for the rest of the tutorial
		
		# Turns on the actual game UI!
		if background:
			background.visible = true
			
		backgroundtuts.visible = true
		highlight_image.visible = true
		highlight_image.texture = data_highlight_img
		
		start_typing("Perfect! Now take a good look at the screen. This is where you'll inspect all the customer data we pulled for you.\n(Click anywhere to continue)")

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
			advance_tutorial()

func advance_tutorial():
	if tutorial_step == 2:
		tutorial_step = 3
		highlight_image.texture = button_highlight_img
		start_typing("Here comes the fun part! After reviewing their info, you have to make a call. Hit 'LEGIT' if they check out, or 'SUSPICIOUS' if something smells fishy. Be careful, your choices matter!\n(Click anywhere to continue)")
		
	elif tutorial_step == 3:
		tutorial_step = 4
		backgroundtuts.visible = false
		highlight_image.visible = false 
		start_typing("You've got the hang of it! You're on your own from here. Good luck out there!\n(Click anywhere to continue)")
		
	elif tutorial_step == 4:
		queue_free()
