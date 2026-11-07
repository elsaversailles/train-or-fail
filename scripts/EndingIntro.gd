extends Control

signal continued

const CARD_SIZE := Vector2(1152, 648)
const Catalog := preload("res://scripts/EndingCatalog.gd")

@onready var card: Control = $Card
@onready var title_label: Label = $Card/Center/Content/Title
@onready var description_label: Label = $Card/Center/Content/Description

var continue_enabled: bool = true


func _ready() -> void:
	resized.connect(_fit_card)
	_fit_card()


func show_ending(ending_id: String) -> void:
	var ending := Catalog.get_presentation(ending_id)
	if ending.is_empty():
		push_error("Unknown ending: %s" % ending_id)
		return
	title_label.text = ending["title"]
	description_label.text = ending["description"]
	continue_enabled = true
	show()
	grab_focus()


func _fit_card() -> void:
	# Keep both the decorative border and the centered text inside any aspect ratio.
	var fit: float = minf(size.x / CARD_SIZE.x, size.y / CARD_SIZE.y)
	card.size = CARD_SIZE
	card.scale = Vector2.ONE * fit
	card.position = (size - CARD_SIZE * fit) * 0.5


func _gui_input(event: InputEvent) -> void:
	var clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var accepted := event.is_action_pressed("ui_accept") and not event.is_echo()
	if not clicked and not accepted:
		return
	# Consume this event before hiding so it cannot also exit or retry the game.
	accept_event()
	if not continue_enabled:
		return
	continue_enabled = false
	release_focus()
	hide()
	continued.emit()
