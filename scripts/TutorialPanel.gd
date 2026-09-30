extends Panel

@onready var title_label: Label = $TitleLabel
@onready var content_label: Label = $ContentLabel
@onready var next_button: Button = $NextButton
@onready var prev_button: Button = $PrevButton

var current_tutorial_page: int = 0

var tutorials: Array = [
	{
		"title": "Inserting a Floppy Disk",
		"text": "To load the required data, click and drag the floppy disk from your desk and drop it onto the computer's disk drive."
	},
	{
		"title": "Fraud Detection",
		"text": "Review the transaction logs on your monitor. Compare the transaction locations and amounts against the customer's normal behavior. If you spot an anomaly, click the 'Sus' button. If the transaction is safe, click 'Legit'."
	},
	{
		"title": "KYC (Know Your Customer)",
		"text": "Examine the provided ID documents and verify they match the customer's system profile. Check the expiration date and portrait. Click the 'Legit' button if valid, or the 'Sus' button if you find discrepancies."
	},
	{
		"title": "Credit Scoring",
		"text": "Analyze the customer's payment history and outstanding debts. Use the financial data to evaluate their risk level. Adjust the slider between 0 and 1 to reflect their creditworthiness, then submit your evaluation."
	}
]

# A public function the pause menu can call to start the tutorial
func open_tutorial() -> void:
	current_tutorial_page = 0
	update_tutorial_display()
	visible = true

func update_tutorial_display() -> void:
	var current_data = tutorials[current_tutorial_page]
	title_label.text = current_data["title"]
	content_label.text = current_data["text"]
	
	prev_button.disabled = (current_tutorial_page == 0)
	next_button.disabled = (current_tutorial_page == tutorials.size() - 1)

func _on_next_button_pressed() -> void:
	if current_tutorial_page < tutorials.size() - 1:
		current_tutorial_page += 1
		update_tutorial_display()

func _on_prev_button_pressed() -> void:
	if current_tutorial_page > 0:
		current_tutorial_page -= 1
		update_tutorial_display()

func _on_close_tutorial_button_pressed() -> void:
	visible = false
