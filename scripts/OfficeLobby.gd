extends Node3D

@export var day1_intro_timeline: String = "lobby_day1_intro"

func _ready() -> void:
	var current_day = int(SaveManager.current_save_data.get("current_day", 1))

	# Only trigger the intro text on Day 1
	if current_day == 1:
		handle_day1_intro()

func handle_day1_intro() -> void:
	# 1. Immediately freeze player movement before fade finishes
	var player = get_tree().get_first_node_in_group("player")
	if player and "is_in_dialogue" in player:
		player.is_in_dialogue = true

	# 2. Wait until SceneTransition finishes fading in
	if SceneTransition and SceneTransition.has_signal("transition_finished"):
		if SceneTransition.is_transitioning:
			await SceneTransition.transition_finished
	else:
		await RenderingServer.frame_post_draw
		await get_tree().create_timer(0.5).timeout

	# 3. Play the intro narration
	Dialogic.start(day1_intro_timeline)
	await Dialogic.timeline_ended

	# 4. Release player controls so they can walk toward Jordan
	if player and "is_in_dialogue" in player:
		player.is_in_dialogue = false
