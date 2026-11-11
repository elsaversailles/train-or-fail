extends "res://.godot/tutorial_waypoint_check.gd"

func _run() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var scene := await load_department("res://scene/CreditScoring/CreditScoring.tscn", 9)
	SaveManager.current_save_data["special_decisions"] = {
		"tita_elena": "legit", "jericho_santur": "legit", "mark_krazy": "legit", "nurse_clara": "legit", "grandpa": "legit"
	}
	SaveManager.current_save_data["is_grandpa_shift"] = true
	var gifts = scene.find_child("DeskGifts", true, false)
	gifts.refresh()
	var camera := Camera3D.new()
	scene.add_child(camera)
	camera.fov = 68
	camera.global_position = Vector3(-5.6, 6.0, -8.0)
	camera.look_at(Vector3(-5.8, 2.35, -13.1))
	camera.make_current()
	await frames(25)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/desk-gifts-overview.png")
	camera.global_position = Vector3(-5.8, 4.23, -10.3)
	camera.look_at(Vector3(-5.8, 2.7, -13.5))
	await frames(10)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/desk-gifts-player-view.png")
	print("DESK GIFT PREVIEW COMPLETE")
	await unload_department(scene)
	get_tree().quit()
