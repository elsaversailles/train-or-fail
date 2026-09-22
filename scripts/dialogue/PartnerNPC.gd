extends StaticBody3D

# Set any number of story/ambient days to exclude (e.g., [2, 4])
@export var special_days: Array[int] = [] 
@export var generic_timelines: Array[String] = [] 
@export var model_needs_flip: bool = false 

var is_talking: bool = false

func interact():
	if is_talking:
		return

	var current_day = SaveManager.current_save_data.get("current_day", 1)

	# Exclude casual dialogue on any of their dedicated story days
	if current_day in special_days:
		return

	if generic_timelines.size() > 0:
		is_talking = true
		face_player()

		# Pick randomly between the 2 everyday dialogues
		var chosen_timeline = generic_timelines.pick_random()
		Dialogic.start(chosen_timeline)

		await Dialogic.timeline_ended
		is_talking = false

func face_player():
	var player = get_tree().get_first_node_in_group("player")
	var root = get_parent()
	if root and player:
		var target_pos = player.global_position
		target_pos.y = root.global_position.y
		root.look_at(target_pos, Vector3.UP)
		if model_needs_flip:
			root.rotate_y(PI)
