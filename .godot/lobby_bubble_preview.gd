extends "res://.godot/tutorial_waypoint_check.gd"

func _run() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data["current_day"] = 4
	var scene: Node3D = load("res://scene/office_lobby.tscn").instantiate()
	scene.get_node("TriggerSupervisor").has_triggered = true
	scene.get_node("Player").set_physics_process(false)
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await frames()
	var supervisor: Node3D = scene.get_node("Supervisor")
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.global_position = supervisor.global_position + Vector3(7, 4.2, 5)
	camera.look_at(supervisor.global_position + Vector3(0, 3.1, 0))
	camera.make_current()
	var bubble = scene.get_node("Supervisor/NPCDialogueBox")
	bubble.letter_time = 0.001
	bubble.space_time = 0.001
	bubble.punctuation_time = 0.001
	bubble.display_text("You’re the new hire?, cmere talk to me.")
	await bubble.finished_displaying
	await frames(10)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/lobby-bubble-visible.png")
	print("BUBBLE VISIBLE / MARKER VISIBLE: ", bubble.visible, " / ", scene.get_node("CanvasLayer/Exclamation").visible)
	bubble.hide()
	await frames(10)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/lobby-bubble-closed.png")
	print("BUBBLE CLOSED / MARKER VISIBLE: ", not bubble.visible, " / ", scene.get_node("CanvasLayer/Exclamation").visible)
	await unload_department(scene)
	get_tree().quit()
