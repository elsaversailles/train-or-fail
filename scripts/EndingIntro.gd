extends Control

signal continued

const CARD_SIZE := Vector2(1152, 648)
const ENDINGS := {
	"algorithm_reformer": {
		"title": "Algorithm Reformer",
		"description": "Your exceptional performance and ethical auditing force Maypaya Financial to re-evaluate their risk criteria, establishing you as a key asset who bridges ethics and efficiency."
	},
	"another_cog_in_the_machine": {
		"title": "Another Cog in the Machine",
		"description": "You are officially an average employee. You retain your analyst position with a modest annual cost-of-living raise.\n\nWalking home, you see a neighborhood of compromises—half the storefronts are bustling, while the other half are boarded up. You survived the system, but you didn't change it."
	},
	"cold_efficiency": {
		"title": "Cold Efficiency",
		"description": "You prioritized the company's algorithm over human empathy. You step into a spacious upper-management office with a view, but the city below feels hollow."
	},
	"conflict_of_interest": {
		"title": "Conflict of Interest",
		"description": "Management flags the unauthorized approval. You are stripped of your analyst title and reassigned to low-level administrative duty, but Lolo’s business stays alive."
	},
	"stagnant_survival": {
		"title": "Stagnant Survival",
		"description": "You stay employed at Maypaya, but corporate locks your salary, freezes promotion paths, and assigns you to endless routine data entry in a secluded corner."
	},
	"terminated": {
		"title": "Terminated",
		"description": "Excessive evaluation errors result in immediate termination for incompetence before you can make any lasting impact on the business or the community."
	},
	"clean_exit": {
		"title": "The Clean Exit",
		"description": "Rejecting the corporate grind, you hand over your badge and leave Maypaya behind to seek a fresh start, entering the job market with empty hands but a clear conscience."
	}
}

@onready var card: Control = $Card
@onready var title_label: Label = $Card/Center/Content/Title
@onready var description_label: Label = $Card/Center/Content/Description

var continue_enabled: bool = true


func _ready() -> void:
	resized.connect(_fit_card)
	_fit_card()


func show_ending(ending_id: String) -> void:
	if not ENDINGS.has(ending_id):
		push_error("Unknown ending: %s" % ending_id)
		return
	var ending: Dictionary = ENDINGS[ending_id]
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
