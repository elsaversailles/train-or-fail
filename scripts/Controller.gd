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

var current_zone_prompt: String = ""
var is_in_dialogue: bool = false

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hand_node: Node3D = $Head/Camera3D/handpoint

# HUD references (Safe fallback lookup)
var interaction_label: Label = null
var crosshair: Control = null
var pause_panel: Panel = null

func _ready() -> void:
	add_to_group("player")
	capture_mouse()
	
	# Safe node discovery so the player never crashes standalone scenes (like dock.tscn)
	var scene = get_tree().current_scene
	if scene:
		interaction_label = scene.get_node_or_null("CanvasLayer/InteractionLabel")
		crosshair = scene.get_node_or_null("CanvasLayer/Crosshair")
	pause_panel = get_node_or_null("../PausePanel")
	
	Dialogic.timeline_started.connect(_on_dialogic_started)
	Dialogic.timeline_ended.connect(_on_dialogic_ended)

	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	original_head_transform = head.transform

	update_gameplay_ui()

func _physics_process(delta: float) -> void:
	# Immobilize during pause or dialogue cutscenes
	if is_paused or is_in_dialogue:
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	# Smooth camera move when focusing on computer
	if is_focusing_screen:
		head.global_transform = head.global_transform.interpolate_with(screen_target_transform, 15 * delta)
		return

	# Return head smoothly to original position after exiting computer
	if head.transform.origin != original_head_transform.origin:
		head.transform.origin = head.transform.origin.lerp(original_head_transform.origin, 12 * delta)

		if head.transform.origin.distance_to(original_head_transform.origin) < 0.01:
			head.transform = original_head_transform

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()

func _process(_delta: float) -> void:
	# Hide interaction text while paused, in dialogue, or focused on computer
	if is_paused or is_focusing_screen or is_in_dialogue:
		if interaction_label:
			interaction_label.visible = false
		return

	var found_raycast_target = false

	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()

		if collider is Area3D and collider.has_method("socket_item"):
			if held_item != null and interaction_label:
				interaction_label.text = "Press E to Insert Disk"
				found_raycast_target = true

		elif held_item != null:
			pass 

		elif collider is RigidBody3D and collider.has_method("socket_item") and not collider.is_inserted:
			if interaction_label:
				interaction_label.text = "Press E to Pick Up"
				found_raycast_target = true

		elif collider.has_method("interact"):
			if interaction_label:
				interaction_label.text = "Press E to Interact"
				found_raycast_target = true

	if interaction_label:
		if found_raycast_target:
			interaction_label.visible = true
		elif current_zone_prompt != "":
			interaction_label.text = current_zone_prompt
			interaction_label.visible = true
		else:
			interaction_label.visible = false

func _input(event: InputEvent) -> void:
	# Block interaction input while paused or inside dialogue
	if is_paused or is_in_dialogue:
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
	if is_in_dialogue:
		return

	if SceneTransition.is_transitioning:
		return

	if event.is_action_pressed("ui_cancel"):
		handle_escape()
		return

	if not is_paused and not is_focusing_screen:
		if event is InputEventMouseMotion:
			rotate_look(event.relative)

func handle_escape() -> void: 
	var tutorial = get_tree().current_scene.get_node_or_null("CanvasLayer/FDTutorial")
	if tutorial and tutorial.visible:
		return
	
	if Dialogic.current_timeline != null:
		return

	if is_focusing_screen:
		release_computer_focus()
		return

	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game() -> void:
	if is_focusing_screen:
		return

	is_paused = true
	if pause_panel:
		pause_panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	update_gameplay_ui()

func resume_game() -> void:
	is_paused = false
	if pause_panel:
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

	get_viewport().gui_release_focus()

	capture_mouse()
	update_gameplay_ui()

# =========================================================
# HUD / GAMEPLAY UI
# =========================================================

func update_gameplay_ui() -> void:
	var show_gameplay_ui = not is_paused and not is_focusing_screen and not is_in_dialogue

	if crosshair:
		crosshair.visible = show_gameplay_ui

	if interaction_label:
		interaction_label.visible = false

# =========================================================
# CAMERA LOOK
# =========================================================

func rotate_look(rot_input: Vector2) -> void:
	var current_sensitivity = SettingsManager.mouse_sensitivity
	
	look_rotation.x -= rot_input.y * current_sensitivity
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-60), deg_to_rad(40))
	look_rotation.y -= rot_input.x * current_sensitivity

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
	if raycast and raycast.is_colliding():
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
	
func _on_dialogic_started() -> void:
	is_in_dialogue = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	update_gameplay_ui()

func _on_dialogic_ended() -> void:
	is_in_dialogue = false
	capture_mouse()
	update_gameplay_ui()
	
# For supervisor scene
func turn_camera_towards(target_pos: Vector3, duration: float = 0.6) -> Tween:
	var dir = (target_pos - head.global_position).normalized()
	var target_yaw = atan2(-dir.x, -dir.z)
	var target_pitch = clamp(asin(dir.y), deg_to_rad(-60), deg_to_rad(40))
	
	# Shortest angular path
	var yaw_diff = wrapf(target_yaw - look_rotation.y, -PI, PI)
	var final_yaw = look_rotation.y + yaw_diff
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	tween.tween_method(func(val: float):
		look_rotation.y = val
		transform.basis = Basis()
		rotate_y(look_rotation.y)
	, look_rotation.y, final_yaw, duration)
	
	tween.tween_method(func(val: float):
		look_rotation.x = val
		head.transform.basis = Basis()
		head.rotate_x(look_rotation.x)
	, look_rotation.x, target_pitch, duration)
	
	return tween
