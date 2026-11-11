extends StaticBody3D

signal story_finished

var can_talk: bool = false
var is_talking: bool = false

# Mark participates in multiple story days
@export var assigned_days: Array[int] = [2, 4]
@export var npc_name: String = "Mark"
@export var mark_bubble: Node3D
@export var generic_timelines: Array[String] = ["mark_generic_1", "mark_generic_2"]

func _ready() -> void:
	add_to_group("special_npc")

func can_interact() -> bool:
	if is_talking or Dialogic.current_timeline != null:
		return false
	var current_day: int = SaveManager.current_save_data.get("current_day", 1)
	if current_day == 2:
		return can_talk
	if current_day == 4:
		return true
	return not generic_timelines.is_empty()

func interact():
	if not can_interact():
		return

	var current_day: int = SaveManager.current_save_data.get("current_day", 1)

	# --- DAY 2: Post-Cashier Chat ---
	if current_day == 2:
		if can_talk:
			is_talking = true
			face_player()
			Dialogic.start("mark_day2")
			await Dialogic.timeline_ended
			is_talking = false
			_resume_patrol()
			story_finished.emit() # Moves waypoint to apartment door

	# --- DAY 4: ID Crisis Speech ---
	elif current_day == 4:
		is_talking = true
		face_player()

		# Hide the waypoint while Mark's overhead bubble is speaking
		if mark_bubble:
			get_tree().call_group("waypoint", "set_marker_suppressed", true)
			mark_bubble.display_text("They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!")
			await mark_bubble.finished_displaying
			await get_tree().create_timer(3.0).timeout
			mark_bubble.visible = false

		# Start Dialogic dialogue
		Dialogic.start("mark_day4")
		await Dialogic.timeline_ended
		is_talking = false
		_resume_patrol()
		story_finished.emit() # Moves waypoint to apartment door

	# --- ALL OTHER DAYS: Random Everyday Dialogue ---
	else:
		if generic_timelines.size() > 0:
			is_talking = true
			face_player()
			Dialogic.start(generic_timelines.pick_random())
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
		root.rotate_y(PI)

func _resume_patrol() -> void:
	var patrol = get_parent().get_node_or_null("OutdoorNpcPatrol")
	if patrol and patrol.has_method("end_interaction"):
		patrol.end_interaction()
