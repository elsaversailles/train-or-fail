extends Node3D

@onready var tutorial_label: Label = $CanvasLayer/Label

func _ready() -> void:
	# 1. Hide the tutorial label right away
	if tutorial_label:
		tutorial_label.visible = false

	# 2. Immediately lock player movement before anything renders
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if "is_in_dialogue" in player:
			player.is_in_dialogue = true
		elif "can_move" in player:
			player.can_move = false

	# 3. Wait until the scene transition fade-in is 100% finished
	if SceneTransition and SceneTransition.has_signal("transition_finished"):
		if SceneTransition.get("is_transitioning"):
			await SceneTransition.transition_finished
	else:
		# Fallback if no signal exists: wait for GPU render + brief settle buffer
		await RenderingServer.frame_post_draw
		await get_tree().create_timer(0.6).timeout

	# 4. Start arrival Dialogic only after screen is fully visible
	Dialogic.start("dock_arrival")
	await Dialogic.timeline_ended

	# 5. Display controls and unlock player movement
	if tutorial_label:
		tutorial_label.text = "Press [W, A, S, D] to walk.\nApproach Grandpa and press [E] to talk."
		tutorial_label.visible = true

	if player:
		if "is_in_dialogue" in player:
			player.is_in_dialogue = false
		elif "can_move" in player:
			player.can_move = true
