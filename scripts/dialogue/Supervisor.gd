extends StaticBody3D

@export var objective_label: Label
@export var model_needs_flip: bool = true

var can_talk: bool = false
var is_talking: bool = false
var has_completed_dialogue: bool = false

func _ready() -> void:
	add_to_group("supervisor")
	
	# Auto-locate the objective label in the UI if not manually dragged in Inspector
	if not objective_label:
		objective_label = get_tree().current_scene.find_child("ObjectiveLabel", true, false)

	# Set the initial objective based on the current day
	var current_day = int(SaveManager.current_save_data.get("current_day", 1))
	if current_day in [1, 4, 7]:
		set_objective_text("Talk to supervisor")
	else:
		set_objective_text("Enter in elevator")

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
		on_dialogue_finished()

	# Day 4: KYC introduction
	elif current_day == 4:
		is_talking = true
		face_player()
		Dialogic.start("supervisor_day4")
		await Dialogic.timeline_ended
		on_dialogue_finished()

	# Day 7: Credit Scoring introduction
	elif current_day == 7:
		is_talking = true
		face_player()
		Dialogic.start("supervisor_day7")
		await Dialogic.timeline_ended
		on_dialogue_finished()

func on_dialogue_finished() -> void:
	is_talking = false
	has_completed_dialogue = true
	set_objective_text("Enter in elevator")

func set_objective_text(new_text: String) -> void:
	if objective_label:
		objective_label.text = new_text

func face_player():
	var player = get_tree().get_first_node_in_group("player")
	var root = get_parent()
	if root and player:
		var target_pos = player.global_position
		target_pos.y = root.global_position.y
		root.look_at(target_pos, Vector3.UP)
		if model_needs_flip:
			root.rotate_y(PI)
