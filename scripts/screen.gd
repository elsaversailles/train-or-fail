extends Node3D

# --- Configuration ---
@onready var node_viewport = $SubViewport
@onready var node_quad = $Quad
@onready var node_area = $Quad/Area3D

<<<<<<< Updated upstream
# -----------------------------
# FINAL RESULT UI REFERENCES
# -----------------------------
@onready var final_result_panel = $"../../ResultPanel/FinalResultPanel"
@onready var final_result_label = $"../../ResultPanel/FinalResultPanel/FinalResultLabel"
@onready var restart_button = $"../../ResultPanel/FinalResultPanel/RestartButton"
=======
# --- UI References ---
@onready var final_result_panel = $"../../ResultPanel/FinalResultPanel"
@onready var final_result_label = $"../../ResultPanel/FinalResultPanel/FinalResultLabel"
@onready var restart_button = $"../../ResultPanel/FinalResultPanel/RestartButton"

# --- State ---
var is_mouse_inside = false
var last_event_pos2D = null
var last_event_time: float = -1.0
>>>>>>> Stashed changes

func _ready():
	node_area.mouse_entered.connect(func(): is_mouse_inside = true)
	node_area.mouse_exited.connect(func(): is_mouse_inside = false)
	node_area.input_event.connect(_mouse_input_event)

	final_result_panel.visible = false
	restart_button.pressed.connect(_on_restart_button_pressed)

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

func show_final_result(score):
	final_result_panel.visible = true
	final_result_label.text = "PC Shutdown Complete\n\nFinal Score: %d / 5" % score

func _on_restart_button_pressed():
	# Stop input immediately to prevent errors during reload
	set_process_input(false)
	get_tree().reload_current_scene()
