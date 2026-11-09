extends "res://scripts/TutorialsScript/DepartmentTutorial.gd"

@export var data_highlight_img: Texture2D
@export var button_highlight_img: Texture2D

func _get_department_name() -> String:
	return "Know Your Customer"

func _get_pages() -> Array[Dictionary]:
	return [
		{
			"title": "Read the ID",
			"text": "KYC means Know Your Customer. Your job is to check the customer's identity.\nClick the ID to enlarge it. Compare its name and photo with the customer. Click the ID again to restore its size.",
			"image": data_highlight_img
		},
		{
			"title": "Compare the face and dates",
			"text": "Hold an arrow to turn the customer; the center button faces them forward.\nCompare the face with the ID photo. Check expiry against today's date (month/day/year).",
			"image": data_highlight_img
		},
		{
			"title": "Read the supporting information",
			"text": "Click the note icon to read extra information about this customer. Click the note to close it.\nUse the ID, face, dates and notes together. AI Risk Factor is only the system's estimate.",
			"image": data_highlight_img
		},
		{
			"title": "Submit your decision",
			"text": "Choose LEGIT if the identity checks out. Choose SUSPICIOUS if the evidence shows an invalid ID or an identity mismatch.\nEither button submits immediately and brings in the next customer.",
			"image": button_highlight_img
		},
		{
			"title": "Complete the queue",
			"text": "Repeat these checks for every customer. After the last review, click End Training to finish your shift.\nTo reread the instructions later, leave the monitor with E and open Tutorial in the pause menu."
		}
	]
