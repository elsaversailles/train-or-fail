extends StaticBody3D

var can_talk: bool = false
var is_talking: bool = false

@export var mark_bubble: Node3D
@export var generic_timelines: Array[String] = ["mark_generic_1", "mark_generic_2"]

func interact():
	if is_talking:
		return

	var current_day = SaveManager.current_save_data.get("current_day", 1)

	# --- DAY 2: Post-Cashier Chat ---
	if current_day == 2:
		if can_talk:
			is_talking = true
			face_player()
			Dialogic.start("mark_day2")
			await Dialogic.timeline_ended
			is_talking = false

	# --- DAY 4: ID Crisis Speech ---
	elif current_day == 4:
		is_talking = true
		face_player()
		if mark_bubble:
			mark_bubble.display_text("They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!")
			await mark_bubble.finished_displaying
			await get_tree().create_timer(3.0).timeout
			mark_bubble.visible = false

		Dialogic.start("mark_day4")
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
