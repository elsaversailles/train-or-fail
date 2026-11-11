extends Panel

const KEY_SMALL = preload("res://assets/ui/controls/key_small.svg")
const KEY_WIDE = preload("res://assets/ui/controls/key_wide.svg")
const MOUSE_LOOK = preload("res://assets/ui/controls/mouse_look.svg")
const MOUSE_LEFT = preload("res://assets/ui/controls/mouse_left.svg")
const GUIDE_FONT = preload("res://theme/DarumadropOne-Regular.ttf")
const INK = Color("#151c20")
const MUTED = Color("#37464e")

@onready var window: Panel = %GuideWindow
@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var page_label: Label = %PageLabel
@onready var content: VBoxContainer = %Content
@onready var content_scroll: ScrollContainer = %ContentScroll
@onready var next_button: Button = %NextButton
@onready var prev_button: Button = %PrevButton
@onready var movement_button: Button = %MovementButton
@onready var interaction_button: Button = %InteractionButton
@onready var work_guide_button: Button = %WorkGuideButton

var current_tutorial_page: int = 0
var _compact: bool = false

var tutorials: Array = [
	{
		"title": "Movement",
		"subtitle": "Explore the room and look around.",
		"rows": [
			["Move forward", "W"],
			["Move backward", "S"],
			["Move left", "A"],
			["Move right", "D"],
			["Look around", "mouse_look"]
		]
	},
	{
		"title": "Interaction",
		"subtitle": "Use objects, talk to people and work at your computer.",
		"rows": [
			["Interact / talk / use a disk", "E"],
			["Leave the computer", "E"],
			["Select / advance dialogue", "mouse_left"],
			["Open pause menu", "ESC"]
		],
		"note": "Holding a disk? Aim at the drive and press E to insert it. Aim elsewhere and press E to drop it."
	},
	{
		"title": "Start the computer",
		"subtitle": "Get your workstation ready for the shift.",
		"steps": [
			["Pick up the disk", "Look at the floppy disk and press E."],
			["Insert it into the drive", "Look at the disk drive and press E. Wait for the green light."],
			["Open the computer", "Look at the monitor and press E to use it. Press E again to leave the computer view."]
		]
	},
	{
		"title": "Check the transaction",
		"subtitle": "Fraud Detection  /  Use the evidence to make your decision.",
		"steps": [
			["Read the evidence", "Check the Location and Item pictures, Time and Price. Open Notes for context."],
			["Inspect the pictures", "Choose Swap, then click either picture to switch views. Choose Zoom, then click the larger picture to zoom in or out. Blue marks the selected mode."],
			["Make your decision", "Choose LEGIT if the evidence supports the transaction, or SUSPICIOUS if it shows fraud. Either choice submits immediately."]
		],
		"note": "AI Risk Factor is a hint. Check the evidence before deciding."
	},
	{
		"title": "Check the customer's identity",
		"subtitle": "Know Your Customer  /  Compare the person with their ID.",
		"steps": [
			["Inspect the ID", "Click the ID to enlarge it. Compare the name and photo with the customer."],
			["Check the details", "Compare the expiry date with today's date (month/day/year). Open Notes for context."],
			["View the customer", "Hold an arrow to turn the customer. The center button faces them forward."],
			["Make your decision", "Choose LEGIT for a valid identity, or SUSPICIOUS for a mismatch or invalid ID. Either choice submits immediately."]
		]
	},
	{
		"title": "Read the credit documents",
		"subtitle": "Credit Scoring  /  Open all four tabs before choosing an amount.",
		"steps": [
			["General Info", "Read the customer's financial background."],
			["Payment History", "Check their record of repaying credit."],
			["Arrears", "Look for payments that are overdue."],
			["Debt Ratio", "Check how much income goes toward debt."]
		],
		"note": "Use the records to judge what the customer can repay. AI Risk Factor is only a hint."
	},
	{
		"title": "Choose a credit amount",
		"subtitle": "Credit Scoring  /  Set the amount, then confirm your decision.",
		"steps": [
			["Set Proposed Credit", "Drag the slider to choose an amount from $0 to $10,000."],
			["Reject when needed", "Click the flag to reject. It turns red and selects $0. Raising the slider clears rejection."],
			["Submit your decision", "Click Submit to confirm and move to the next customer. You can change the amount until you submit."]
		]
	},
	{
		"title": "Finish your shift",
		"subtitle": "Complete the queue, then head home for your results.",
		"steps": [
			["Review every customer", "Finish all customers in the queue."],
			["End the session", "Click End Training in Fraud Detection or KYC. In Credit Scoring, click Shutdown."],
			["Return home", "If you pass the shift, follow the waypoint home. Your results appear at the apartment."]
		],
		"note": "Three mistakes fail the shift. Finish with fewer than three to continue."
	}
]

func _ready() -> void:
	# Keep the shared monitor-button theme unchanged.
	theme = theme.duplicate()
	theme.default_font = GUIDE_FONT
	theme.default_font_size = 20
	theme.set_color("font_color", "Label", INK)
	resized.connect(_layout_guide)
	movement_button.pressed.connect(_select_page.bind(0))
	interaction_button.pressed.connect(_select_page.bind(1))
	work_guide_button.pressed.connect(_open_work_section)
	next_button.pressed.connect(_on_next_button_pressed)
	prev_button.pressed.connect(_on_prev_button_pressed)
	%CloseTutorialButton.pressed.connect(_on_close_tutorial_button_pressed)
	_layout_guide()

func _layout_guide() -> void:
	if not is_node_ready():
		return
	window.size = Vector2(minf(size.x - 32.0, 1040.0), minf(size.y - 32.0, 720.0))
	window.position = (size - window.size) * 0.5
	_compact = window.size.x < 820.0 or window.size.y < 570.0
	title_label.add_theme_font_size_override("font_size", 26 if _compact else 32)
	subtitle_label.add_theme_font_size_override("font_size", 17 if _compact else 19)
	%BackHint.visible = window.size.x >= 850.0
	update_tutorial_display()

func open_tutorial() -> void:
	_select_page(2)
	show()
	work_guide_button.grab_focus()

func open_controls() -> void:
	_select_page(0)
	show()
	movement_button.grab_focus()

func _select_page(page: int) -> void:
	current_tutorial_page = clampi(page, 0, tutorials.size() - 1)
	update_tutorial_display()

func _open_work_section() -> void:
	_select_page(maxi(current_tutorial_page, 2))

func update_tutorial_display() -> void:
	if not is_node_ready():
		return
	current_tutorial_page = clampi(current_tutorial_page, 0, tutorials.size() - 1)
	var data: Dictionary = tutorials[current_tutorial_page]
	title_label.text = data["title"]
	subtitle_label.text = data["subtitle"]
	page_label.text = ("Controls %d / 2" % [current_tutorial_page + 1]) if current_tutorial_page < 2 else ("Guide %d / 6" % [current_tutorial_page - 1])
	prev_button.disabled = current_tutorial_page == 0
	next_button.disabled = current_tutorial_page == tutorials.size() - 1
	movement_button.set_pressed_no_signal(current_tutorial_page == 0)
	interaction_button.set_pressed_no_signal(current_tutorial_page == 1)
	work_guide_button.set_pressed_no_signal(current_tutorial_page >= 2)
	_sync_focus_navigation()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	content.add_theme_constant_override("separation", 0 if data.has("rows") else 10)
	if data.has("rows"):
		_add_table_header()
		var rows: Array = data["rows"]
		for index in rows.size():
			_add_control_row(rows[index][0], rows[index][1], index)
	else:
		var steps: Array = data["steps"]
		for index in steps.size():
			_add_step(index + 1, steps[index][0], steps[index][1])
	if data.has("note"):
		_add_note(data["note"])
	content_scroll.scroll_vertical = 0

func _sync_focus_navigation() -> void:
	# The pause menu stays visible behind this overlay, so keep focus inside it.
	var tabs: Array[Button] = [movement_button, interaction_button, work_guide_button]
	var footer: Array[Button] = []
	for button: Button in [prev_button, next_button, %CloseTutorialButton]:
		if not button.disabled:
			footer.append(button)
	var buttons: Array[Button] = []
	buttons.append_array(tabs)
	buttons.append_array(footer)
	for index in buttons.size():
		var button := buttons[index]
		button.focus_next = button.get_path_to(buttons[(index + 1) % buttons.size()])
		button.focus_previous = button.get_path_to(buttons[(index - 1 + buttons.size()) % buttons.size()])
	for row: Array in [tabs, footer]:
		var other_row: Array = footer if row == tabs else tabs
		for index in row.size():
			var button: Button = row[index]
			button.focus_neighbor_left = button.get_path_to(row[(index - 1 + row.size()) % row.size()])
			button.focus_neighbor_right = button.get_path_to(row[(index + 1) % row.size()])
			button.focus_neighbor_top = button.get_path_to(other_row[mini(index, other_row.size() - 1)])
			button.focus_neighbor_bottom = button.focus_neighbor_top
	var focused := get_viewport().gui_get_focus_owner()
	if focused == prev_button and prev_button.disabled:
		next_button.grab_focus()
	elif focused == next_button and next_button.disabled:
		prev_button.grab_focus()

func _label(text_value: String, font_size: int, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _style(color: Color, padding: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _control_width() -> float:
	return 192.0 if _compact else 236.0

func _add_table_header() -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 5)
	var row := HBoxContainer.new()
	var action := _label("ACTION", 15, MUTED)
	action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(action)
	var key := _label("KEY / MOUSE", 15, MUTED)
	key.custom_minimum_size.x = _control_width()
	row.add_child(key)
	margin.add_child(row)
	content.add_child(margin)

func _add_control_row(action: String, input_name: String, index: int) -> void:
	var panel := PanelContainer.new()
	var style := _style(Color("#bbc2c5") if index % 2 == 0 else Color("#b2babf"), 16)
	style.content_margin_top = 6 if _compact else 5
	style.content_margin_bottom = 6 if _compact else 5
	style.border_width_bottom = 1
	style.border_color = Color("#939fa5")
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.y = 52 if _compact else 62
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := _label(action, 20 if _compact else 23)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	var inputs := HBoxContainer.new()
	inputs.custom_minimum_size.x = _control_width()
	inputs.add_theme_constant_override("separation", 12)
	inputs.alignment = BoxContainer.ALIGNMENT_BEGIN
	var icon_size: float = 40.0 if _compact else 52.0
	if input_name.begins_with("mouse_"):
		var icon := TextureRect.new()
		icon.texture = MOUSE_LOOK if input_name == "mouse_look" else MOUSE_LEFT
		icon.custom_minimum_size = Vector2(icon_size, icon_size)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inputs.add_child(icon)
		inputs.add_child(_label("Move mouse" if input_name == "mouse_look" else "Left click", 18 if _compact else 20))
	else:
		inputs.add_child(_keycap(input_name, icon_size))
	row.add_child(inputs)
	panel.add_child(row)
	content.add_child(panel)

func _keycap(key_text: String, height: float) -> Control:
	var cap := Control.new()
	var wide := key_text.length() > 1
	cap.custom_minimum_size = Vector2(height * (1.625 if wide else 1.0), height)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.texture = KEY_WIDE if wide else KEY_SMALL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap.add_child(icon)
	var label := _label(key_text, int(height * 0.44), Color("#080b0d"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_top = -height * 0.11
	label.offset_bottom = -height * 0.11
	cap.add_child(label)
	return cap

func _add_step(number: int, heading: String, body: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color("#c4c9cb"), 14))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var badge := PanelContainer.new()
	var badge_style := _style(Color("#35464f"), 0)
	badge_style.content_margin_top = 0
	badge_style.content_margin_bottom = 0
	badge.add_theme_stylebox_override("panel", badge_style)
	badge.custom_minimum_size = Vector2(32, 32)
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var number_label := _label(str(number), 22, Color("#f6f4ec"))
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(number_label)
	row.add_child(badge)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	var heading_label := _label(heading, 21 if _compact else 23)
	heading_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(heading_label)
	var body_label := _label(body, 18 if _compact else 20, MUTED)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(body_label)
	row.add_child(copy)
	panel.add_child(row)
	content.add_child(panel)

func _add_note(message: String) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	var panel := PanelContainer.new()
	var style := _style(Color("#d4d5cd"), 12)
	style.border_width_left = 4
	style.border_color = Color("#687c87")
	panel.add_theme_stylebox_override("panel", style)
	var label := _label(message, 17 if _compact else 19, MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	margin.add_child(panel)
	content.add_child(margin)

func _on_next_button_pressed() -> void:
	_select_page(current_tutorial_page + 1)

func _on_prev_button_pressed() -> void:
	_select_page(current_tutorial_page - 1)

func _on_close_tutorial_button_pressed() -> void:
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_close_tutorial_button_pressed()
		get_viewport().set_input_as_handled()
