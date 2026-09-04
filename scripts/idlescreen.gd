extends StaticBody3D # Or Area3D

@onready var idle_screen = $"."
@onready var focus_point = $Marker3D

# --- NEW: Reference your Floppy Disk! ---
# Adjust this path so it points exactly to your floppy disk node in the 3D scene
@onready var floppy_disk = $"../floppydisk"

var is_focused = false

func interact():
	if is_focused:
		return
		
	is_focused = true
	# input_ray_pickable = false # (Keep this if you were using it previously)
	
	if idle_screen:
		idle_screen.visible = false
	
	# 1. Send the monitor instance to the player to lock their camera
	get_tree().call_group("player", "set_computer_focus", focus_point.global_transform, self)

	# 2. TUTORIAL GUARDRAIL
	# Only trigger Step 2 of the tutorial if the disk is physically inserted!
	if floppy_disk and floppy_disk.is_inserted:
		
		# Try Fraud Tutorial
		var fd_tutorial = get_tree().current_scene.get_node_or_null("CanvasLayer/FDTutorial")
		if fd_tutorial and fd_tutorial.has_method("screen_focused"):
			fd_tutorial.screen_focused()
			
		# Try KYC Tutorial
		var kyc_tutorial = get_tree().current_scene.get_node_or_null("CanvasLayer/KYCTutorial")
		if kyc_tutorial and kyc_tutorial.has_method("screen_focused"):
			kyc_tutorial.screen_focused()
			
		# Try Credit Scoring Tutorial
		var cs_tutorial = get_tree().current_scene.get_node_or_null("CanvasLayer/CSTutorial")
		if cs_tutorial and cs_tutorial.has_method("screen_focused"):
			cs_tutorial.screen_focused()
			
	else:
		print("Player focused on screen, but disk is not inserted yet!")

func set_idle_visible(p_visible: bool):
	is_focused = !p_visible
	
	if idle_screen:
		idle_screen.visible = p_visible
