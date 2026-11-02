extends Node3D

# --- Configuration ---
@onready var node_viewport = $SubViewport
@onready var node_quad = $Quad
@onready var node_area = $Quad/Area3D

# --- UI References ---
# We only need to reference the main panel now!
@onready var final_result_panel = $"../../ResultPanel"

# --- State ---
var is_mouse_inside = false
var last_event_pos2D = null
var last_event_time: float = -1.0

func _ready():
	node_area.mouse_entered.connect(func(): is_mouse_inside = true)
	node_area.mouse_exited.connect(func(): is_mouse_inside = false)
	node_area.input_event.connect(_mouse_input_event)

func _unhandled_input(event):
	# Guard: Don't process if deleting or if it's a mouse event (handled by physics picking)
	if not is_inside_tree() or not node_viewport: return
	
	if event is InputEventMouse:
		return
		
	node_viewport.push_input(event)

func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	# CRITICAL FIX: Ensure viewport is still valid and in tree before processing
	if not is_inside_tree() or not node_viewport or not node_viewport.is_inside_tree():
		return

	var now: float = Time.get_ticks_msec() / 1000.0
	var quad_mesh_size = node_quad.mesh.size

	# 1. Coordinate Conversion (3D World -> 3D Local -> 2D Viewport)
	var event_pos3D = node_quad.global_transform.affine_inverse() * event_position
	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)
		# Normalize and scale to viewport pixels
		event_pos2D.x = (event_pos2D.x / quad_mesh_size.x) + 0.5
		event_pos2D.y = (event_pos2D.y / quad_mesh_size.y) + 0.5
		event_pos2D *= Vector2(node_viewport.size)
	elif last_event_pos2D != null:
		event_pos2D = last_event_pos2D

	# 2. Update Event Data
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# 3. Calculate Physics Motion
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		if last_event_pos2D != null:
			event.relative = event_pos2D - last_event_pos2D
			var dt = now - last_event_time
			event.velocity = event.relative / dt if dt > 0 else Vector2.ZERO
		else:
			event.relative = Vector2.ZERO

	last_event_pos2D = event_pos2D
	last_event_time = now

	# 4. Final Push
	node_viewport.push_input(event)


# ==========================================
# RESULT PANEL TRIGGER (Optional)
# ==========================================

# NOTE: If your Main Level script is already handling the "show_final_result" 
# logic, you actually don't even need this function here anymore! 
# But I left it safely mapped to your new Terminal system just in case your 
# game architecture relies on the monitor triggering the screen.
func show_final_result(score: int, epoch: int = 1):
	if final_result_panel.has_method("display_terminal_report"):
		final_result_panel.display_terminal_report(score, epoch)
	else:
		print("Warning: The ResultPanel doesn't have the terminal script attached!")
