extends Control
class_name WaypointMarker

@export var apartment_door: Node3D
@export var objective_label: Label # Drag your CanvasLayer/Label here in Inspector
@export var edge_padding: float = 50.0

@export_group("Offsets")
@export var npc_vertical_offset: float = 5.0
@export var door_vertical_offset: float = 1.0

# --- Distance Scaling Settings ---
@export_group("Scaling")
@export var max_scale: float = 1.0
@export var min_scale: float = 0.4
@export var close_distance: float = 4.0
@export var far_distance: float = 30.0

@onready var icon: TextureRect = $Icon

var current_target: Node3D = null
var current_vertical_offset: float = 5.0
var camera: Camera3D
var is_dialogue_active: bool = false

func _ready() -> void:
	# 1. Allow this node to continue processing even when get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	add_to_group("waypoint")
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if objective_label:
		objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.pivot_offset = Vector2(icon.size.x / 2.0, icon.size.y)
		icon.position = Vector2(-icon.size.x / 2.0, -icon.size.y)

	Dialogic.timeline_started.connect(_on_dialogue_started)
	Dialogic.timeline_ended.connect(_on_dialogue_ended)

	await get_tree().process_frame
	setup_day_target()

func set_marker_suppressed(suppressed: bool) -> void:
	is_dialogue_active = suppressed
	visible = (not suppressed) and (current_target != null)
	if objective_label:
		objective_label.visible = not suppressed

func _on_dialogue_started() -> void:
	set_marker_suppressed(true)

func _on_dialogue_ended() -> void:
	set_marker_suppressed(false)

func setup_day_target() -> void:
	var current_day: int = SaveManager.current_save_data.get("current_day", 1)
	var special_npcs = get_tree().get_nodes_in_group("special_npc")
	
	current_target = null

	for npc in special_npcs:
		var matches_day: bool = false

		if "assigned_days" in npc and current_day in npc.assigned_days:
			matches_day = true
		elif npc.get("assigned_day") == current_day:
			matches_day = true

		if matches_day:
			current_target = npc
			current_vertical_offset = npc_vertical_offset
			if not npc.story_finished.is_connected(_on_story_finished):
				npc.story_finished.connect(_on_story_finished)
			
			# Set the NPC objective text
			_update_objective_text(_get_npc_name(npc))
			break

	if current_target:
		visible = not is_dialogue_active
	else:
		target_apartment_door()

func _on_story_finished() -> void:
	target_apartment_door()

func target_apartment_door() -> void:
	if not apartment_door:
		apartment_door = get_tree().get_first_node_in_group("apartment_door")

	if apartment_door:
		current_target = apartment_door
		current_vertical_offset = door_vertical_offset
		visible = not is_dialogue_active
		
		# Set the Apartment objective text
		_update_objective_text("apartment")
	else:
		visible = false
		if objective_label:
			objective_label.text = ""

func _update_objective_text(target_name: String) -> void:
	if not objective_label:
		return

	if target_name == "apartment":
		objective_label.text = "Objective: Head to the apartment to end the day"
	else:
		objective_label.text = "Objective: Talk to %s" % target_name

func _get_npc_name(npc: Node3D) -> String:
	if "npc_name" in npc:
		return str(npc.npc_name)
	
	var raw_name: String = npc.name.to_lower()
	if "grandpa" in raw_name:
		return "Grandpa"
	elif "mark" in raw_name:
		return "Mark"
	elif "clara" in raw_name:
		return "Clara"
	elif "jericho" in raw_name:
		return "Jericho"
	return npc.name.capitalize()

func _process(_delta: float) -> void:
	# 2. Hide immediately when paused
	if get_tree().paused:
		visible = false
		if objective_label:
			objective_label.visible = false
		return

	# Hide during dialogues
	if is_dialogue_active:
		visible = false
		if objective_label:
			objective_label.visible = false
		return

	if not current_target or not is_instance_valid(current_target):
		visible = false
		return

	camera = get_viewport().get_camera_3d()
	if not camera:
		visible = false
		return

	var target_pos: Vector3
	if current_target.has_node("HeadMarker"):
		target_pos = current_target.get_node("HeadMarker").global_position
	else:
		target_pos = current_target.global_position + Vector3(0, current_vertical_offset, 0)

	var vp_rect: Rect2 = get_viewport_rect()
	var screen_center: Vector2 = vp_rect.size * 0.5

	var is_behind: bool = camera.is_position_behind(target_pos)
	var screen_pos: Vector2 = camera.unproject_position(target_pos)

	if is_behind:
		screen_pos = screen_center - (screen_pos - screen_center).normalized() * 10000.0

	var usable_rect: Rect2 = vp_rect.grow(-edge_padding)
	var is_on_screen: bool = usable_rect.has_point(screen_pos) and not is_behind

	var dist: float = camera.global_position.distance_to(target_pos)
	var t: float = clamp((dist - close_distance) / (far_distance - close_distance), 0.0, 1.0)
	var current_scale: float = lerp(max_scale, min_scale, t)

	if icon:
		icon.scale = Vector2(current_scale, current_scale)

	if is_on_screen:
		global_position = screen_pos
		if icon:
			icon.rotation = 0.0
	else:
		var direction: Vector2 = (screen_pos - screen_center).normalized()
		global_position = _get_border_clamped_position(screen_center, direction, usable_rect)
		if icon:
			icon.rotation = direction.angle() - (PI * 0.5)

	# 3. Restore visibility once unpaused and valid
	visible = true
	if objective_label:
		objective_label.visible = true

func _get_border_clamped_position(center: Vector2, dir: Vector2, rect: Rect2) -> Vector2:
	var half_size: Vector2 = rect.size * 0.5
	var slope: float = dir.y / (dir.x + 0.0001)

	var edge_point: Vector2 = Vector2.ZERO
	if abs(slope) < (half_size.y / half_size.x):
		edge_point.x = half_size.x if dir.x > 0 else -half_size.x
		edge_point.y = edge_point.x * slope
	else:
		edge_point.y = half_size.y if dir.y > 0 else -half_size.y
		edge_point.x = edge_point.y / slope

	return center + edge_point
