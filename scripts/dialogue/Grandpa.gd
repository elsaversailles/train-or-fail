extends StaticBody3D

signal story_finished

var can_talk: bool = false
var is_talking: bool = false

@export var npc_name: String = "Grandpa"
@export var assigned_day: int = 1
@export var generic_timelines: Array[String] = ["grandpa_generic_1", "grandpa_generic_2"]

func _ready() -> void:
	add_to_group("special_npc")

func interact():
	if is_talking:
		return

	var current_day: int = SaveManager.current_save_data.get("current_day", 1)

	# --- STORY DIALOGUE (Only if it's their assigned day) ---
	if current_day == assigned_day:
		if can_talk:
			is_talking = true
			face_player()
			Dialogic.start("grandpa_day" + str(assigned_day))
			await Dialogic.timeline_ended
			is_talking = false
			story_finished.emit() # Triggers the waypoint to move to the apartment

	# --- ALL OTHER DAYS: Random Everyday Dialogue ---
	else:
		if generic_timelines.size() > 0:
			is_talking = true
			face_player()
			Dialogic.start(generic_timelines.pick_random())
			await Dialogic.timeline_ended
			is_talking = false

func face_player():
	var player = get_tree().get_first_node_in_group("player")
	var root = get_parent()
	if root and player:
		var target_pos = player.global_position
		target_pos.y = root.global_position.y
		root.look_at(target_pos, Vector3.UP)
		root.rotate_y(PI)
