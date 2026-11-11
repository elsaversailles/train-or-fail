extends "res://scripts/Exclamation.gd"

@export var supervisor: StaticBody3D
@export var supervisor_bubble: Node3D
@export var elevator: Marker3D

func _ready() -> void:
	if is_instance_valid(supervisor_bubble):
		supervisor_bubble.visibility_changed.connect(_update_callout_visibility)
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	_update_callout_visibility()

func _update_callout_visibility() -> void:
	# The callout uses its own speech bubble, outside the Dialogic timeline.
	if current_target == target_override and is_instance_valid(supervisor_bubble) and supervisor_bubble.is_visible_in_tree():
		hide()

func setup_day_target() -> void:
	var current_day := int(SaveManager.current_save_data.get("current_day", 1))
	if current_day in [1, 4, 7] and is_instance_valid(supervisor) and not supervisor.get("has_completed_dialogue"):
		current_target = target_override
		current_vertical_offset = npc_vertical_offset
		icon.texture = EXCLAMATION_TEXTURE
		visible = is_instance_valid(current_target) and not is_dialogue_active
	else:
		target_elevator()

func target_elevator() -> void:
	current_target = elevator
	current_vertical_offset = 0.0
	icon.texture = WAYPOINT_TEXTURE
	visible = is_instance_valid(current_target) and not is_dialogue_active
