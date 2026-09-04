extends CharacterBody3D

@export var speed: float = 15.0
@export var gravity: float = 9.8
@export var sensitivity: float = 0.002

var look_rotation: Vector2
var is_paused: bool = false
var held_item = null

# Computer focus system
var is_focusing_screen: bool = false
var screen_target_transform: Transform3D
var original_head_transform: Transform3D
var current_monitor = null

@onready var anim_player = $MenANDWomen/AnimationPlayer

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hand_node: Node3D = $Head/Camera3D/handpoint

# HUD references
@onready var interaction_label: Label = get_tree().current_scene.get_node("CanvasLayer/InteractionLabel")
@onready var crosshair: Control = get_tree().current_scene.get_node("CanvasLayer/Crosshair")
@onready var pause_panel: Panel = $"../PausePanel"

func _ready() -> void:
	add_to_group("player")
	capture_mouse()

	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	original_head_transform = head.transform

	update_gameplay_ui()

func _physics_process(delta: float) -> void:
	# Do nothing while paused
	if is_paused:
		return

	# Smooth camera move when focusing on computer
	if is_focusing_screen:
		head.global_transform = head.global_transform.interpolate_with(screen_target_transform, 15 * delta)
		anim_player.play("idle") 
		return

	# Return head smoothly to original position after exiting computer
	if head.transform.origin != original_head_transform.origin:
		head.transform.origin = head.transform.origin.lerp(original_head_transform.origin, 12 * delta)

		if head.transform.origin.distance_to(original_head_transform.origin) < 0.01:
			head.transform = original_head_transform

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Movement
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir != Vector2.ZERO:
		anim_player.play("walk")
	else:
		anim_player.play("idle")
		
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _process(_delta: float) -> void:
	# Hide interaction text while paused or focused on computer
	if is_paused or held_item or is_focusing_screen:
		interaction_label.visible = false
		return

	if raycast.is_colliding():
		var collider = raycast.get_collider()

		# Pick up disk
		if collider is RigidBody3D and collider.has_method("socket_item") and not collider.is_inserted:
			interaction_label.text = "Press E to Pick Up"
			interaction_label.visible = true

		# Insert disk into socket
		elif collider is Area3D and collider.has_method("socket_item"):
			if held_item != null:
				interaction_label.text = "Press E to Insert Disk"
				interaction_label.visible = true
			else:
				interaction_label.visible = false

		# Interact with monitor / interactable object
		elif collider.has_method("interact"):
			interaction_label.text = "Press E to Interact"
			interaction_label.visible = true

		else:
			interaction_label.visible = false
	else:
		interaction_label.visible = false

func _input(event: InputEvent) -> void:
	# Ignore gameplay input while paused
	if is_paused:
		return

	# E = exit computer focus
	if is_focusing_screen and event.is_action_pressed("interact"):
		release_computer_focus()
		return

	# E = normal interaction
	if event.is_action_pressed("interact"):
		if held_item:
			if raycast.is_colliding():
				var collider = raycast.get_collider()

				if collider is Area3D and collider.has_method("socket_item"):
					collider.socket_item(held_item)
					held_item = null
					return

			drop_item()
		else:
			if raycast.is_colliding():
				var collider = raycast.get_collider()

				if collider is RigidBody3D and collider.has_method("socket_item"):
					check_for_pickup()
				else:
					check_interaction()

func _unhandled_input(event: InputEvent) -> void:
	# ESC behavior
	if SceneTransition.is_transitioning:
		return
	if event.is_action_pressed("ui_cancel"):
		handle_escape()
		return

	# Mouse look only when not paused and not focusing on computer
	if not is_paused and not is_focusing_screen:
		if event is InputEventMouseMotion:
			rotate_look(event.relative)


func handle_escape() -> void: # ESC / PAUSE / COMPUTER FOCUS LOGIC
	var tutorial = get_tree().current_scene.get_node_or_null("CanvasLayer/FDTutorial")
	if tutorial and tutorial.visible:
		return

	# If on computer, ESC exits computer first
	if is_focusing_screen:
		release_computer_focus()
		return

	# Otherwise toggle pause
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	if is_focusing_screen:
		return

	is_paused = true
	pause_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	update_gameplay_ui()

func resume_game() -> void:
	is_paused = false
	pause_panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	update_gameplay_ui()

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# =========================================================
# COMPUTER FOCUS SYSTEM
# =========================================================

func set_computer_focus(target_transform: Transform3D, monitor_node) -> void:
	if is_paused:
		return

	is_focusing_screen = true
	current_monitor = monitor_node
	screen_target_transform = target_transform

	release_mouse()
	update_gameplay_ui()

func release_computer_focus() -> void:
	is_focusing_screen = false

	head.rotation = Vector3.ZERO
	look_rotation.y = rotation.y
	look_rotation.x = 0

	if current_monitor:
		current_monitor.set_idle_visible(true)
		current_monitor = null

	# Remove UI focus from monitor buttons
	get_viewport().gui_release_focus()

	capture_mouse()
	update_gameplay_ui()

# =========================================================
# HUD / GAMEPLAY UI
# =========================================================

func update_gameplay_ui() -> void:
	var show_gameplay_ui = not is_paused and not is_focusing_screen

	# Crosshair
	if crosshair:
		crosshair.visible = show_gameplay_ui

	# Interaction label
	if interaction_label:
		interaction_label.visible = false

# =========================================================
# CAMERA LOOK
# =========================================================

func rotate_look(rot_input: Vector2) -> void:
	look_rotation.x -= rot_input.y * sensitivity
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-60), deg_to_rad(40))
	look_rotation.y -= rot_input.x * sensitivity

	transform.basis = Basis()
	rotate_y(look_rotation.y)

	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)

# =========================================================
# INTERACTION SYSTEM
# =========================================================

func check_interaction() -> void:
	if interact_ray and interact_ray.is_colliding():
		var target = interact_ray.get_collider()
		if target.has_method("interact"):
			target.interact()
	elif not interact_ray:
		push_error("RayCast3D is missing! Check your scene tree.")

# =========================================================
# PICKUP SYSTEM
# =========================================================

func check_for_pickup() -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()

		if collider is RigidBody3D and collider.has_method("socket_item"):
			held_item = collider
			held_item.is_held = true

			if held_item is RigidBody3D:
				held_item.freeze = true
				held_item.get_node("CollisionShape3D").set_deferred("disabled", true)

			held_item.get_parent().remove_child(held_item)
			hand_node.add_child(held_item)
			held_item.transform = Transform3D.IDENTITY

func drop_item() -> void:
	if held_item:
		held_item.get_node("CollisionShape3D").set_deferred("disabled", false)
		hand_node.remove_child(held_item)
		get_parent().add_child(held_item)

		held_item.global_position = hand_node.global_position

		if held_item is RigidBody3D:
			held_item.freeze = false
			var drop_direction = -head.global_transform.basis.z
			held_item.apply_central_impulse(drop_direction * 2.0)

		held_item.is_held = false
		held_item = null

func clear_held_item() -> void:
	held_item = null
