extends Node3D

# Used for checking if the mouse is inside the Area3D.
var is_mouse_inside = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D = null
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0

@onready var node_viewport = $SubViewport
@onready var node_quad = $Quad
@onready var node_area = $Quad/Area3D

# -----------------------------
# FINAL RESULT UI REFERENCES
# -----------------------------
@onready var final_result_panel = $"../../CanvasLayer2/FinalResultPanel"
@onready var final_result_label = $"../../CanvasLayer2/FinalResultPanel/FinalResultLabel"
@onready var restart_button = $"../../CanvasLayer2/FinalResultPanel/RestartButton"

func _ready():
	node_area.mouse_entered.connect(_mouse_entered_area)
	node_area.mouse_exited.connect(_mouse_exited_area)
	node_area.input_event.connect(_mouse_input_event)

	# Hide final result panel at start
	final_result_panel.visible = false

	# Connect restart button
	restart_button.pressed.connect(_on_restart_button_pressed)

func _mouse_entered_area():
	is_mouse_inside = true

func _mouse_exited_area():
	is_mouse_inside = false

func _unhandled_input(event):
	# Check if the event is a non-mouse/non-touch event
	for mouse_event in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(event, mouse_event):
			# If the event is a mouse/touch event, then we can ignore it here, because it will be
			# handled via Physics Picking.
			return
	node_viewport.push_input(event)

func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	var quad_mesh_size = node_quad.mesh.size

	# Event position in Area3D in world coordinate space.
	var event_pos3D = event_position

	# Current time in seconds since engine start.
	var now: float = Time.get_ticks_msec() / 1000.0

	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = node_quad.global_transform.affine_inverse() * event_pos3D

	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Convert from quad space to viewport space
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5
		event_pos2D.x *= node_viewport.size.x
		event_pos2D.y *= node_viewport.size.y

	elif last_event_pos2D != null:
		event_pos2D = last_event_pos2D

	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# Calculate relative motion
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)

	last_event_pos2D = event_pos2D
	last_event_time = now

	# Send processed event to viewport
	node_viewport.push_input(event)

# -----------------------------
# SHOW FINAL RESULT PANEL
# -----------------------------
func show_final_result(score):
	final_result_panel.visible = true
	final_result_label.text = "PC Shutdown Complete\n\nFinal Score: %d / 5" % score

# -----------------------------
# RESTART GAME
# -----------------------------
func _on_restart_button_pressed():
	get_tree().reload_current_scene()
