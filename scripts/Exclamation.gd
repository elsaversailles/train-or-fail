extends "res://scripts/WaypointMarker.gd"

const EXCLAMATION_TEXTURE: Texture2D = preload("res://images/Exclamation.png")
const WAYPOINT_TEXTURE: Texture2D = preload("res://images/waypoint.png")

func setup_day_target() -> void:
	super.setup_day_target()
	if is_instance_valid(current_target) and current_target != apartment_door:
		icon.texture = EXCLAMATION_TEXTURE
	else:
		icon.texture = WAYPOINT_TEXTURE

func target_apartment_door() -> void:
	super.target_apartment_door()
	# A completed conversation changes the objective from a person to a door.
	icon.texture = WAYPOINT_TEXTURE
