extends Node

@export var waypoint: WaypointMarker
@export var apartment_door: Node3D
@export var current_day: int = 1 # Update this from your save/global game state

var active_npc: Node3D = null

func _ready() -> void:
	current_day = SaveManager.current_save_data.get("current_day", 1)
	setup_day_objective()

func setup_day_objective() -> void:
	waypoint.clear_target()
	active_npc = _find_npc_for_day(current_day)

	if active_npc:
		var height: float = active_npc.get("waypoint_height_offset") if "waypoint_height_offset" in active_npc else 2.0
		waypoint.set_target(active_npc, height)

		# Connect dialogue signal to switch objectives
		if active_npc.has_signal("dialogue_finished"):
			if not active_npc.dialogue_finished.is_connected(_on_npc_dialogue_finished):
				active_npc.dialogue_finished.connect(_on_npc_dialogue_finished)
	else:
		# Fallback if no special NPC exists today: point directly to the apartment
		_point_to_apartment()

func _find_npc_for_day(day: int) -> Node3D:
	var npcs: Array[Node] = get_tree().get_nodes_in_group("special_npcs")
	for node in npcs:
		if node is Node3D and "active_day" in node:
			if node.active_day == day:
				return node
	return null

func _on_npc_dialogue_finished() -> void:
	# NPC is finished talking; transition waypoint to the apartment
	_point_to_apartment()

func _point_to_apartment() -> void:
	if apartment_door:
		# Use a lower offset for a door (e.g. 1.2m above floor or at the door knob/sign)
		waypoint.set_target(apartment_door, 1.2)
	else:
		waypoint.clear_target()
