extends "res://scripts/TutorialsScript/DepartmentTutorial.gd"

@export var data_highlight_img: Texture2D
@export var slider_highlight_img: Texture2D

func _get_department_name() -> String:
	return "Credit Scoring"

func _get_pages() -> Array[Dictionary]:
	return [
		{
			"title": "Review all four documents",
			"text": "Open the assessment panel using its side handle. Read every tab before choosing a credit score.\nGeneral Info describes the customer's finances. Payment History shows how reliably they have repaid credit.",
			"image": data_highlight_img
		},
		{
			"title": "Check overdue payments and debt",
			"text": "Arrears shows overdue payments. Debt Ratio compares debt with income.\nUse these records to judge what the customer can repay. AI Risk Factor is the system's estimate; check it against the documents.",
			"image": data_highlight_img
		},
		{
			"title": "Choose a credit score",
			"text": "Use the slider to choose a score: 0 = Rejected; 0.2 = Low; 0.4 or 0.6 = Medium; 0.8 or 1.0 = High.\nProposed Credit shows the category. Adjust your selection before clicking Submit.",
			"image": slider_highlight_img
		},
		{
			"title": "Reject or submit",
			"text": "To reject the application, click the flag button or move the slider to 0. The flag turns red and Proposed Credit shows Rejected. Raising the slider clears rejection.\nClick Submit to confirm your choice and move to the next customer.",
			"image": slider_highlight_img
		},
		{
			"title": "Complete the queue",
			"text": "Review all four documents for each customer before submitting. After the last review, click Shutdown to finish your shift.\nTo reread the instructions later, leave the monitor with E and open Controls & Tutorial in the pause menu."
		}
	]
