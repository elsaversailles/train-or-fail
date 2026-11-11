extends Control

@onready var message_label: Label = $BackgroundPanel/MessageLabel
@onready var step_label: Label = $BackgroundPanel/StepLabel
@onready var continue_label: Label = $BackgroundPanel/ContinueLabel
@onready var highlight_image: TextureRect = $BackgroundPanel/HighlightImage
@onready var backgroundtuts: Panel = $BackgroundPanel/Background
@onready var timer: Timer = $BackgroundPanel/LetterDisplayTimer

var tutorial_step: int = -1
var can_click: bool = false
var is_typing: bool = false
var full_text: String = ""
var letter_index: int = 0
var letter_time: float = 0.03
var space_time: float = 0.04
var punctuation_time: float = 0.12
var pages: Array[Dictionary] = []

func _ready() -> void:
	visible = false
	backgroundtuts.hide()
	highlight_image.hide()
	message_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	timer.timeout.connect(display_letter)
	pages = _get_pages()
	resized.connect(_update_text_size)
	_update_text_size()

func _update_text_size() -> void:
	# The text panel occupies the bottom quarter at every window size.
	# Scale its padding and typography together so all three instruction lines fit.
	var ui_scale := clampf(minf(size.x / 1152.0, size.y / 720.0), 0.5, 1.5)
	message_label.add_theme_font_size_override("font_size", roundi(20.0 * ui_scale))
	step_label.add_theme_font_size_override("font_size", roundi(22.0 * ui_scale))
	continue_label.add_theme_font_size_override("font_size", roundi(16.0 * ui_scale))
	for label in [message_label, step_label, continue_label]:
		label.offset_left = 40.0 * ui_scale
		label.offset_right = -40.0 * ui_scale
	step_label.offset_top = 10.0 * ui_scale
	step_label.offset_bottom = 40.0 * ui_scale
	message_label.offset_top = 44.0 * ui_scale
	message_label.offset_bottom = -40.0 * ui_scale
	continue_label.offset_top = -36.0 * ui_scale
	continue_label.offset_bottom = -12.0 * ui_scale
	var text_box: Control = $BackgroundPanel/TextBoxContainer
	text_box.offset_left = 16.0 * ui_scale
	text_box.offset_right = -16.0 * ui_scale
	text_box.offset_bottom = -8.0 * ui_scale

func _get_pages() -> Array[Dictionary]:
	return []

func _get_department_name() -> String:
	return "Tutorial"

# The monitor calls this only after the disk has been inserted.
func screen_focused() -> void:
	if tutorial_step >= 0 or pages.is_empty():
		return
	tutorial_step = 0
	can_click = true
	visible = true
	_show_page()

func _show_page() -> void:
	var page: Dictionary = pages[tutorial_step]
	step_label.text = "%s | %d / %d: %s" % [
		_get_department_name(), tutorial_step + 1, pages.size(), page["title"]
	]
	highlight_image.texture = page.get("image")
	highlight_image.visible = highlight_image.texture != null
	backgroundtuts.visible = highlight_image.visible
	start_typing(page["text"])

func start_typing(text_to_display: String) -> void:
	timer.stop()
	full_text = text_to_display
	letter_index = 0
	# Keep the complete text laid out so words do not move as letters appear.
	message_label.text = full_text
	message_label.visible_characters = 0
	is_typing = not full_text.is_empty()
	_update_continue_hint()
	if is_typing:
		display_letter()

func display_letter() -> void:
	if not is_typing:
		return
	letter_index += 1
	message_label.visible_characters = letter_index
	if letter_index >= full_text.length():
		_finish_typing()
		return
	match full_text[letter_index - 1]:
		"!", ".", ",", "?", ":":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)

func _finish_typing() -> void:
	timer.stop()
	letter_index = full_text.length()
	message_label.visible_characters = -1
	is_typing = false
	_update_continue_hint()

func _update_continue_hint() -> void:
	if is_typing:
		continue_label.text = "Left click to show the full message."
	elif not can_click:
		continue_label.text = "Follow these steps. The tutorial continues when you open the monitor."
	elif tutorial_step == pages.size() - 1:
		continue_label.text = "Left click to finish the tutorial and start reviewing."
	else:
		continue_label.text = "Left click for the next step."

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_typing:
			_finish_typing()
		elif can_click:
			advance_tutorial()
		else:
			return
		# A tutorial click must not also submit a decision on the monitor behind it.
		get_viewport().set_input_as_handled()

func advance_tutorial() -> void:
	if not can_click:
		return
	if is_typing:
		_finish_typing()
		return
	tutorial_step += 1
	if tutorial_step >= pages.size():
		can_click = false
		timer.stop()
		queue_free()
	else:
		_show_page()
