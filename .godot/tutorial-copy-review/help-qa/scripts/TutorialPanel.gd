extends Panel

@onready var title_label: Label = $TitleLabel
@onready var content_label: Label = $ContentLabel
@onready var next_button: Button = $NextButton
@onready var prev_button: Button = $PrevButton
@onready var page_label: Label = $PageLabel

var current_tutorial_page: int = 0

var tutorials: Array = [
	{
		"title": "Start the computer",
		"text": "1. Look at the floppy disk and press E to pick it up.\n\n2. Look at the disk drive and press E to insert the disk.\n\n3. Wait for the green light, then look at the monitor and press E to use it.\n\nPress E again to leave the computer view."
	},
	{
		"title": "Fraud detection: check the evidence",
		"text": "1. Check the Location and Item pictures, Time and Price. Open the note for context.\n\n2. Use swap mode to switch pictures, or zoom mode to enlarge the larger picture.\n\n3. Click LEGIT if the evidence supports the transaction, or SUSPICIOUS if it shows fraud.\n\nYour choice is submitted immediately. AI Risk Factor is a hint; check the evidence yourself."
	},
	{
		"title": "Know Your Customer: check identity",
		"text": "1. Click the ID to enlarge it. Compare its name and photo with the customer.\n\n2. Check the expiry date against today's date on the screen. Open the note for context.\n\n3. Hold the left or right arrow to turn the customer. The center button restores the front view.\n\n4. Click LEGIT if the ID checks out, or SUSPICIOUS if you find a problem. Your choice submits immediately."
	},
	{
		"title": "Credit scoring: read the documents",
		"text": "Open all four tabs before choosing a credit amount:\n\nGeneral Info: the customer's financial background.\nPayment History: their record of repaying credit.\nArrears: payments that are overdue.\nDebt Ratio: how much income goes toward debt.\n\nUse these records to judge how much credit the customer can repay. AI Risk Factor is a hint, not a final decision."
	},
	{
		"title": "Credit scoring: choose an amount",
		"text": "1. Drag the slider to set Proposed Credit from $0 to $10,000.\n\n2. To reject the application, click Red Flag. This selects $0; raising the slider clears rejection.\n\n3. Click Submit to confirm and move to the next customer.\n\nYou can change the amount until you click Submit."
	},
	{
		"title": "Finish your shift",
		"text": "1. Review every customer in the queue.\n\n2. When all reviews are complete, click End Training in Fraud Detection or KYC, or Shutdown in Credit Scoring.\n\n3. Read your results, then follow the prompt to continue.\n\nYou can reopen this guide from the pause menu."
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
	page_label.text = "Movement and interaction"
	content_label.text = "W / A / S / D: walk.\nMouse: look around.\n\nE: interact with the object you are looking at.\nWhile holding a disk, aim at the drive and press E to insert it. Aim elsewhere and press E to drop it.\n\nE: leave the computer view.\nLeft click: use monitor controls or advance dialogue.\nEsc: pause or resume when outside the computer view."
	next_button.visible = false
	prev_button.visible = false
	visible = true

func update_tutorial_display() -> void:
	var current_data = tutorials[current_tutorial_page]
	title_label.text = current_data["title"]
	content_label.text = current_data["text"]
	page_label.text = "Guide %d of %d" % [current_tutorial_page + 1, tutorials.size()]
	
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
