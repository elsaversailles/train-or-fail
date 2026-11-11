extends "res://.godot/tutorial_waypoint_check.gd"

func _run() -> void:
	var scene := await load_department("res://scene/FraudDetection/FraudDetection.tscn", 1)
	for target_path in ["floppydisk", "socket/FloppyCartridge", "Monitor"]:
		var target: Node3D = scene.get_node(target_path)
		var highest := -INF
		for child in target.find_children("*", "MeshInstance3D", true, false):
			if target_path == "Monitor" and str(target.get_path_to(child)).begins_with("Screen/"):
				continue
			var bounds: AABB = child.global_transform * child.get_aabb()
			highest = maxf(highest, bounds.end.y)
		print("WAYPOINT BOUNDS: ", target_path, " origin=", target.global_position, " top=", highest, " relative_top=", highest - target.global_position.y)
	await unload_department(scene)
	get_tree().quit()
