extends "res://scripts/Exclamation.gd"

@export var supervisor: StaticBody3D
@export var elevator: Marker3D

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
