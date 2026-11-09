extends "res://scripts/TutorialsScript/DepartmentTutorial.gd"

@export var data_highlight_img: Texture2D
@export var slider_highlight_img: Texture2D

func _get_department_name() -> String:
	return "Credit Scoring"

func _get_pages() -> Array[Dictionary]:
	return [
		{
			"title": "Review all four documents",
			"text": "Open the assessment panel using its side handle. Read every tab before choosing a credit amount.\nGeneral Info describes the customer's finances. Payment History shows how reliably they have repaid credit.",
			"image": data_highlight_img
		},
		{
			"title": "Check overdue payments and debt",
			"text": "Arrears shows overdue payments. Debt Ratio compares debt with income.\nUse these records to judge what the customer can repay. AI Risk Factor is the system's estimate; check it against the documents.",
			"image": data_highlight_img
		},
		{
			"title": "Choose a credit amount",
			"text": "Drag the credit slider to choose an amount from $0 to $10,000. Watch Proposed Credit to see your selection.\nYou can adjust it as often as needed before clicking Submit.",
			"image": slider_highlight_img
		},
		{
			"title": "Reject or submit",
			"text": "To reject the application, click the flag button. It turns red and selects $0 credit. Raising the slider clears rejection.\nClick Submit to confirm your choice and move to the next customer.",
			"image": slider_highlight_img
		},
		{
			"title": "Complete the queue",
			"text": "Review all four documents for each customer before submitting. After the last review, click Shutdown to finish your shift.\nTo reread the instructions later, leave the monitor with E and open Tutorial in the pause menu."
		}
	]
