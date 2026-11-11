extends "res://.godot/tutorial_waypoint_check.gd"

func _run() -> void:
	get_tree().root.size = Vector2i(1152, 720)
	for day in range(1, 11):
		SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
		SaveManager.current_save_data["current_day"] = day
		var scene: Node = load("res://scene/office_lobby.tscn").instantiate()
		# Keep this test on the objective flow instead of the timed approach bubble.
		scene.get_node("TriggerSupervisor").has_triggered = true
		scene.get_node("Player").set_physics_process(false)
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene
		await frames(4)
		var marker = scene.get_node("CanvasLayer/Exclamation")
		var supervisor = scene.get_node("Supervisor/StaticBody3D")
		var elevator = scene.get_node("ElevetorDoor/WaypointAnchor")
		var objective = scene.get_node("CanvasLayer/Label")
		if day == 1:
			check(Dialogic.current_timeline != null and not marker.visible, "lobby introduction hides marker")
			await Dialogic.end_timeline(true)
			await frames()
		if day in [1, 4, 7]:
			check(marker.current_target == scene.get_node("Supervisor") and marker.visible, "day %d starts above supervisor" % day)
			check(marker.icon.texture.resource_path == "res://images/Exclamation.png", "day %d supervisor uses exclamation" % day)
			check(is_equal_approx(marker.current_vertical_offset, 4.8), "day %d preserves raised head clearance" % day)
			check(objective.text == "Talk to supervisor", "day %d supervisor objective matches marker" % day)
			var bubble = scene.get_node("Supervisor/NPCDialogueBox")
			check(marker.supervisor_bubble == bubble, "day %d marker tracks supervisor bubble" % day)
			bubble.visibility_changed.connect(func():
				if bubble.visible and marker.current_target == marker.target_override:
					check(not marker.visible, "day %d bubble hides marker immediately, before another frame" % day)
			)
			bubble.letter_time = 0.001
			bubble.space_time = 0.001
			bubble.punctuation_time = 0.001
			var trigger = scene.get_node("TriggerSupervisor")
			trigger.has_triggered = false
			trigger._on_body_entered(scene.get_node("Player"))
			await frames()
			check(bubble.visible and not marker.visible, "day %d callout hides exclamation while typing" % day)
			check(objective.visible, "day %d callout retains objective text" % day)
			get_tree().paused = true
			await frames()
			check(not marker.visible, "day %d paused callout does not reveal marker" % day)
			get_tree().paused = false
			await frames()
			check(not marker.visible, "day %d resumed callout keeps marker hidden" % day)
			await bubble.finished_displaying
			await frames()
			check(bubble.visible and not marker.visible, "day %d marker stays hidden while finished text is held" % day)
			await get_tree().create_timer(3.1).timeout
			await frames()
			check(not bubble.visible and marker.visible and supervisor.can_talk, "day %d marker returns when callout finishes" % day)
			supervisor.can_talk = true
			supervisor.interact()
			await frames()
			check(Dialogic.current_timeline != null and not marker.visible, "day %d actual supervisor dialogue hides marker" % day)
			check(not supervisor.has_completed_dialogue and marker.current_target != elevator, "day %d does not switch before conversation finishes" % day)
			await Dialogic.end_timeline(true)
			await frames()
			check(supervisor.has_completed_dialogue, "day %d real dialogue completion unlocks elevator" % day)
		else:
			check(not supervisor.has_completed_dialogue, "day %d skips optional supervisor conversation" % day)
		check(marker.current_target == elevator and marker.visible, "day %d guides to elevator when available" % day)
		var supervisor_bubble = scene.get_node("Supervisor/NPCDialogueBox")
		supervisor_bubble.show()
		await frames()
		check(marker.visible and marker.current_target == elevator, "day %d supervisor bubble cannot hide elevator waypoint" % day)
		supervisor_bubble.hide()
		check(marker.icon.texture.resource_path == "res://images/waypoint.png", "day %d elevator uses waypoint" % day)
		check(objective.text == "Enter in elevator", "day %d elevator objective matches marker" % day)
		var blue_marker: Node3D = scene.get_node("ElevetorDoor/Node3D")
		var clearance: Vector3 = elevator.global_position - blue_marker.global_position
		check(clearance.y > 0.2 and clearance.y < 1.5 and Vector2(clearance.x, clearance.z).length() < 0.1, "day %d waypoint sits just above the blue floor marker" % day)
		check(marker.mouse_filter == Control.MOUSE_FILTER_IGNORE and marker.icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "day %d marker cannot block interactions" % day)
		marker.setup_day_target()
		await frames()
		check(marker.current_target == elevator, "day %d refreshing cannot restore completed supervisor objective" % day)
		if day == 1:
			get_tree().paused = true
			await frames()
			check(not marker.visible, "pause hides lobby marker")
			get_tree().paused = false
			await frames()
			check(marker.visible and marker.current_target == elevator, "resume retains elevator target")
		await unload_department(scene)
	print("LOBBY BUBBLE RESULT: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
