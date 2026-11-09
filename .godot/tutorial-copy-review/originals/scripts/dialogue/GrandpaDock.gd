extends StaticBody3D

@export var timeline_name: String = "grandpa_dock"
@export var model_needs_flip: bool = true
@export var next_scene_path: String = "res://scene/office_lobby.tscn"

var is_talking: bool = false

func interact() -> void:
	if is_talking:
		return

	is_talking = true

	# 1. Hide the controls tutorial prompt
	var tutorial_label = get_tree().current_scene.find_child("TutorialLabel", true, false)
	if tutorial_label:
		tutorial_label.visible = false

	# 2. Rotate Grandpa toward the player
	face_player()

	# 3. Start the Dialogic timeline
	Dialogic.start(timeline_name)

	# 4. Wait until the entire timeline closes before switching scenes
	await Dialogic.timeline_ended

	# 5. Brief transition delay
	await get_tree().create_timer(0.3).timeout

	# 6. Fade to the office lobby
	SceneTransition.change_scene(next_scene_path)

func face_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var root = get_parent()
	if root and player:
		var target_pos = player.global_position
		target_pos.y = root.global_position.y
		root.look_at(target_pos, Vector3.UP)
		if model_needs_flip:
			root.rotate_y(PI)
