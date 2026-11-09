extends Node3D

@onready var container: MarginContainer = $SubViewport/TextBoxContainer
@onready var padding: MarginContainer = $SubViewport/TextBoxContainer/Padding
@onready var label: Label = $SubViewport/TextBoxContainer/Padding/Label
@onready var timer: Timer = $SubViewport/TextBoxContainer/LetterDisplayTimer
@onready var viewport: SubViewport = $SubViewport

const MAX_WIDTH: int = 256

var text: String = ""
var letter_index: int = 0

var letter_time: float = 0.03
var space_time: float = 0.06
var punctuation_time: float = 0.2

var _display_request: int = 0
var _is_typing: bool = false

signal finished_displaying

func _ready() -> void:
	visible = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Revealing letters must not change the full message's wrapping or size.
	label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	container.resized.connect(_sync_viewport_size)

func display_text(text_to_display: String) -> void:
	_display_request += 1
	timer.stop()
	_is_typing = false
	visible = false
	text = text_to_display
	letter_index = 0
	label.visible_characters = 0
	label.text = text_to_display

	# Measure the label directly: container.size may still belong to the previous
	# line (or the scene's initial 43x43 rectangle) until deferred layout runs.
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	container.custom_minimum_size = Vector2.ZERO
	var margins := Vector2.ZERO
	for margin_container: MarginContainer in [container, padding]:
		margins.x += margin_container.get_theme_constant("margin_left") + margin_container.get_theme_constant("margin_right")
		margins.y += margin_container.get_theme_constant("margin_top") + margin_container.get_theme_constant("margin_bottom")
	var background_minimum: Vector2 = $SubViewport/TextBoxContainer/NinePatchRect.get_combined_minimum_size()
	var bubble_width := minf(MAX_WIDTH, maxf(background_minimum.x, ceilf(label.get_minimum_size().x + margins.x)))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = Vector2(maxf(1.0, bubble_width - margins.x), 0.0)
	var bubble_height := maxf(background_minimum.y, ceilf(label.get_minimum_size().y + margins.y))
	# Invalidate ancestor minimum-size caches before shrinking a reused bubble.
	padding.update_minimum_size()
	container.update_minimum_size()
	container.custom_minimum_size = Vector2(bubble_width, bubble_height)
	container.size = container.custom_minimum_size
	_sync_viewport_size()
	# Callers attach their finished_displaying await after display_text returns.
	_begin_display.call_deferred(_display_request)

func _sync_viewport_size() -> void:
	# Follow any later container layout, instead of freezing a stale viewport size.
	viewport.size = Vector2i(maxi(2, ceili(container.size.x)), maxi(2, ceili(container.size.y)))

func _begin_display(request: int) -> void:
	if request != _display_request:
		return
	if text.is_empty():
		finished_displaying.emit()
		return
	visible = true
	_is_typing = true
	display_letter()

func display_letter() -> void:
	if not _is_typing:
		return
	letter_index += 1
	label.visible_characters = letter_index

	if letter_index >= text.length():
		_is_typing = false
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

func _on_letter_display_timer_timeout() -> void:
	display_letter()
