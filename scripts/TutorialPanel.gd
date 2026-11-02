extends Panel

@onready var title_label: Label = $TitleLabel
@onready var content_label: Label = $ContentLabel
@onready var next_button: Button = $NextButton
@onready var prev_button: Button = $PrevButton

var current_tutorial_page: int = 0

var tutorials: Array = [
	{
		"title": "Inserting a Floppy Disk",
		"text": "Look at the floppy disk and press E to pick it up. Look at the computer's disk drive and press E again to insert it. Wait for the green light, then look at the monitor and press E to use it. Press E or Esc to leave the computer view."
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
		"text": "Review all four document tabs, including payment history and outstanding debts. Adjust the slider to propose a credit amount from $0 to $10,000. Red Flag selects rejection with $0 credit; raise the slider to change that choice. Press Submit to confirm your evaluation."
	}
]

# A public function the pause menu can call to start the tutorial
func open_tutorial() -> void:
	current_tutorial_page = 0
	next_button.visible = true
	prev_button.visible = true
	update_tutorial_display()
	visible = true

func open_controls() -> void:
	title_label.text = "Controls"
	content_label.text = "W / A / S / D - Move\nMouse - Look around\nE - Interact, pick up, insert, or drop a disk\nE or Esc - Leave the computer view\nLeft click - Use monitor controls or advance dialogue\nEsc - Pause or resume outside the computer view"
	next_button.visible = false
	prev_button.visible = false
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
