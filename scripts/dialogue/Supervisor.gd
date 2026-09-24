extends StaticBody3D

var can_talk: bool = false
var is_talking: bool = false
@export var model_needs_flip: bool = true

func interact():
	var current_day = int(SaveManager.current_save_data.get("current_day", 1))

	if not can_talk or is_talking:
		return

	# Day 1: General orientation
	if current_day == 1:
		is_talking = true
		face_player()
		Dialogic.start("supervisor_day1")
		await Dialogic.timeline_ended
		is_talking = false

	# Day 4: KYC introduction
	elif current_day == 4:
		is_talking = true
		face_player()
		Dialogic.start("supervisor_day4")
		await Dialogic.timeline_ended
		is_talking = false

	# Day 7: Credit Scoring introduction
	elif current_day == 7:
		is_talking = true
		face_player()
		Dialogic.start("supervisor_day7")
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
