extends StaticBody3D

# Set any number of story/ambient days to exclude (e.g., [2, 4])
@export var special_days: Array[int] = [] 
@export var generic_timelines: Array[String] = [] 
@export var model_needs_flip: bool = false 

var is_talking: bool = false

func interact():
	if is_talking or Dialogic.current_timeline != null:
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
		_resume_patrol()

func face_player():
	var player = get_tree().get_first_node_in_group("player")
	var root = get_parent()
	var patrol = root.get_node_or_null("OutdoorNpcPatrol") if root else null
	if patrol and patrol.has_method("begin_interaction"):
		patrol.begin_interaction(player)
		return
	if root and player:
		var target_pos = player.global_position
		target_pos.y = root.global_position.y
		if root.global_position.distance_squared_to(target_pos) < 0.0001:
			return
		root.look_at(target_pos, Vector3.UP)
		if model_needs_flip:
			root.rotate_y(PI)

func _resume_patrol() -> void:
	var patrol = get_parent().get_node_or_null("OutdoorNpcPatrol")
	if patrol and patrol.has_method("end_interaction"):
		patrol.end_interaction()
