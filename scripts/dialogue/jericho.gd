extends StaticBody3D

var can_talk: bool = false
var is_talking: bool = false

@export var generic_timelines: Array[String] = ["jericho_generic_1", "jericho_generic_2"]

func interact():
	if is_talking:
		return

	var current_day = SaveManager.current_save_data.get("current_day", 1)

	# --- DAY 8: Dealership Loan Monologue ---
	if current_day == 8:
		if can_talk:
			is_talking = true
			face_player()
			Dialogic.start("jericho_monologue")
			await Dialogic.timeline_ended
			is_talking = false

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
