extends CharacterBody3D

@export var speed : float = 5.0
@export var gravity : float = 9.8
@export var look_speed : float = 0.002

var look_rotation : Vector2
var is_paused : bool = false
var held_item = null
var is_focusing_screen = false
var screen_target_transform : Transform3D
var original_head_transform : Transform3D
var current_monitor = null

@onready var head: Node3D = $Head
@onready var camera = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/RayCast3D 
@onready var raycast = $Head/Camera3D/RayCast3D
@onready var hand_node =$Head/Camera3D/handpoint
@onready var visual_hand = $Head/Camera3D/Sketchfab_Scene
@onready var visual_char = $"."
@onready var interaction_label = get_node("/root/Main/CanvasLayer/InteractionLabel")

func _ready() -> void:
	add_to_group("player")
	capture_mouse()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	# Add this line to lock the default head position
	original_head_transform = head.transform

func set_computer_focus(target_transform, monitor_node):
	is_focusing_screen = true
	current_monitor = monitor_node # This will now work without an error
	# Do not overwrite original_head_transform here to keep your POV working
	screen_target_transform = target_transform
	
	visual_hand.visible = false
	visual_char.visible = false
	camera.size = 2.0 
	release_mouse()

func release_computer_focus():
	is_focusing_screen = false
	
	# 1. Reset head rotation to neutral before syncing variables
	head.rotation = Vector3.ZERO 
	
	# 2. Sync look variables to the parent body's current rotation
	look_rotation.y = rotation.y
	look_rotation.x = 0 # Start looking straight ahead to avoid the snap
	
	if current_monitor:
		current_monitor.set_idle_visible(true)
		current_monitor = null
		
	# 3. Restore perspective and visibility
	visual_hand.visible = true
	capture_mouse()

func _physics_process(delta: float) -> void:
	if is_focusing_screen:
		head.global_transform = head.global_transform.interpolate_with(screen_target_transform, 15 * delta)
		return 

	# Move the head back to the neck position, but don't force its rotation
	if head.transform.origin != original_head_transform.origin:
		head.transform.origin = head.transform.origin.lerp(original_head_transform.origin, 12 * delta)
		
		# Once very close, snap it to avoid tiny physics jitters
		if head.transform.origin.distance_to(original_head_transform.origin) < 0.01:
			head.transform = original_head_transform

	# 1. Apply gravity so you stay on the ground
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Get the input direction from W, A, S, D
	# These must be set up in your Input Map (Project Settings)
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# 3. Calculate direction relative to where you are looking
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Stop movement when no keys are pressed
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# 4. Move the character while handling collisions
	move_and_slide()

func _process(_delta):
	if held_item or is_focusing_screen:
		interaction_label.visible = false
		return

	if raycast.is_colliding():
		var collider = raycast.get_collider()

		# Check for the Disk itself (to pick it up)
		if collider is RigidBody3D and collider.has_method("socket_item") and not collider.is_inserted:
			interaction_label.text = "Press E to Pick Up"
			interaction_label.visible = true

		# Check for the Socket (to insert the held disk)
		elif collider is Area3D and collider.has_method("socket_item"):
			if held_item != null:
				interaction_label.text = "Press E to Insert Disk"
				interaction_label.visible = true
			else:
				interaction_label.visible = false

		elif collider.has_method("interact"):
			interaction_label.text = "Press E to Show Screen"
			interaction_label.visible = true
		else:
			interaction_label.visible = false
	else:
		interaction_label.visible = false
		
func _input(event):
	if is_focusing_screen and event.is_action_pressed("interact"):
		release_computer_focus()
		return
		
	if event.is_action_pressed("interact"):
		if held_item:
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				
				# FIX: Only try to insert if we are actually looking at a Socket
				if collider is Area3D and collider.has_method("socket_item"):
					collider.socket_item(held_item)
					held_item = null 
					return 
			
			drop_item()
		else:
			# FIX: Only try to pick up if we are looking at a Disk (RigidBody3D)
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				if collider is RigidBody3D and collider.has_method("socket_item"):
					check_for_pickup()
				else:
					check_interaction()

func check_for_pickup():
	if raycast.is_colliding():
		var collider = raycast.get_collider()

		if collider.has_method("socket_item"):
			held_item = collider
			held_item.is_held = true

			# Disable physics so it follows your hand smoothly
			if held_item is RigidBody3D:
				held_item.freeze = true
				held_item.get_node("CollisionShape3D").set_deferred("disabled", true)

			held_item.get_parent().remove_child(held_item)
			hand_node.add_child(held_item)
			held_item.transform = Transform3D.IDENTITY

func drop_item():
	if held_item:
		held_item.get_node("CollisionShape3D").set_deferred("disabled", false)
		hand_node.remove_child(held_item)
		
		# FIX: Add it to the world node, NOT the root
		# This assumes your main world scene is the parent of your player
		get_parent().add_child(held_item)

		held_item.global_position = hand_node.global_position

		if held_item is RigidBody3D:
			held_item.freeze = false
			var drop_direction = -head.global_transform.basis.z
			held_item.apply_central_impulse(drop_direction * 2.0)

		held_item.is_held = false
		held_item = null

func clear_held_item():
	# This prevents the player from "dropping" an item that is already in the wall
	held_item = null

func _unhandled_input(event: InputEvent) -> void:
	# Toggle between mouse modes with ESC
	if event.is_action_pressed("ui_cancel"): # "ui_cancel" is ESC by default
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")

	# Only allow looking and clicking if NOT paused
	if not is_paused:
		# Move screen with mouse (no cursor visible)
		if event is InputEventMouseMotion:
			rotate_look(event.relative)

		# Left click to interact
		if event.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			check_interaction()

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	is_paused = false

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	is_paused = true

func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		release_mouse()
	else:
		capture_mouse()

func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

func check_interaction():
	# Adding 'if interact_ray:' prevents the crash if the node is missing
	if interact_ray and interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		if target.has_method("interact"):
			target.interact()
	elif not interact_ray:
		push_error("RayCast3D is missing! Check your scene tree.")

func _on_socket_area_entered(area: Area3D) -> void:
	pass # Replace with function body.

func _on_socket_body_entered(body: Node3D) -> void:
	pass # Replace with function body.


func _on_load_game_pressed() -> void:
	pass # Replace with function body.


func _on_data_body_entered(body: Node) -> void:
	pass # Replace with function body.


func _on_data_body_exited(body: Node) -> void:
	pass # Replace with function body.
