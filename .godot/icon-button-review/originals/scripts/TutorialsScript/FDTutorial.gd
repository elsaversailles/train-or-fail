extends "res://scripts/TutorialsScript/DepartmentTutorial.gd"

@export var data_highlight_img: Texture2D
@export var button_highlight_img: Texture2D

func _ready() -> void:
	super._ready()
	start_tutorial()

func start_tutorial() -> void:
	visible = true
	step_label.text = "Getting started: Load the customer disk"
	start_typing("1. Look at the floppy disk and press E to pick it up.\n2. Aim at the disk drive and press E to insert it.\n3. Wait for the green light. Look at the monitor and press E.")

func _get_department_name() -> String:
	return "Fraud Detection"

func _get_pages() -> Array[Dictionary]:
	return [
		{
			"title": "Check the transaction",
			"text": "Open the review panel using its side handle. Check the Location and Item pictures, then read the Time and Price.\nDecide whether these details make sense together.",
			"image": data_highlight_img
		},
		{
			"title": "Inspect the pictures",
			"text": "Click the two-arrow icon for swap mode, then click either picture to switch views.\nClick the magnifying glass for zoom mode, then click the larger picture to zoom in or out.",
			"image": data_highlight_img
		},
		{
			"title": "Read the customer's note",
			"text": "Click the note icon for extra context. Click the open note to close it.\nAI Risk Factor is the system's estimate. Check it against the evidence before deciding.",
			"image": data_highlight_img
		},
		{
			"title": "Submit your decision",
			"text": "Choose LEGIT when the evidence supports the transaction. Choose SUSPICIOUS when the evidence points to fraud.\nEither button submits immediately and brings in the next customer.",
			"image": button_highlight_img
		},
		{
			"title": "Complete the queue",
			"text": "Review each customer using the same checks. After the last customer, click End Training to finish your shift.\nTo reread the instructions later, leave the monitor with E and open Tutorial in the pause menu."
		}
	]
