extends Node

var dialog_lines: Array[String] = []
var current_line_index: int = 0
var active_bubble: Node3D = null

var is_dialog_active: bool = false
var can_advance_line: bool = false

func start_dialog(bubble_node: Node3D, lines: Array[String]):
	if is_dialog_active:
		return
		
	dialog_lines = lines
	active_bubble = bubble_node
	current_line_index = 0
	is_dialog_active = true
	
	# Connect the signal so the manager knows when the typing finishes
	if not active_bubble.finished_displaying.is_connected(_on_bubble_finished):
		active_bubble.finished_displaying.connect(_on_bubble_finished)
		
	show_text_box()

func show_text_box():
	can_advance_line = false
	active_bubble.display_text(dialog_lines[current_line_index])

func _on_bubble_finished():
	can_advance_line = true

func _unhandled_input(event):
	# Change "ui_accept" to whatever your interaction action is (like "interact" or "ui_select")
	if event.is_action_pressed("ui_accept") and is_dialog_active and can_advance_line:
		current_line_index += 1
		
		# Check if the conversation is over
		if current_line_index >= dialog_lines.size():
			is_dialog_active = false
			active_bubble.visible = false
			active_bubble.finished_displaying.disconnect(_on_bubble_finished)
		else:
			# Show the next line!
			show_text_box()
