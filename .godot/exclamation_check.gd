extends "res://.godot/tutorial_waypoint_check.gd"

class TestNpc extends Node3D:
	signal story_finished
	var assigned_days: Array[int] = [1, 4, 7]
	var npc_name := "Test NPC"

func has_icon(marker: Control, path: String) -> bool:
	return marker.get_node("Icon").texture.resource_path == path

func check_scene_wiring(path: String, target_property: String, target_path: NodePath) -> void:
	var scene: Node = load(path).instantiate()
	var marker := scene.get_node_or_null("CanvasLayer/Exclamation")
	check(marker != null, path + " contains a marker named Exclamation")
	if marker:
		check(marker.scene_file_path == "res://scene/exclamation.tscn", path + " uses reusable Exclamation scene")
		check(marker.get(target_property) == scene.get_node(target_path), path + " retains its objective target")
		check(has_icon(marker, "res://images/Exclamation.png"), path + " uses the supplied image")
	check(not scene.has_node("CanvasLayer/WaypointMarker"), path + " has no duplicate old marker")
	scene.free()

func _run() -> void:
	var exclamation_path := "res://images/Exclamation.png"
	var waypoint_path := "res://images/waypoint.png"
	get_tree().root.size = Vector2i(1152, 720)
	SaveManager.current_save_data = {"current_day": 1}
	var world := Node3D.new()
	add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 2, 5)
	camera.current = true
	var npc := TestNpc.new()
	world.add_child(npc)
	npc.position = Vector3(0, 0, -3)
	npc.add_to_group("special_npc")
	var head := Marker3D.new()
	head.name = "HeadMarker"
	npc.add_child(head)
	head.position.y = 2.2
	var door := Node3D.new()
	world.add_child(door)
	door.position = Vector3(3, 0, -3)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var objective := Label.new()
	canvas.add_child(objective)
	var marker = load("res://scene/exclamation.tscn").instantiate()
	marker.apartment_door = door
	marker.objective_label = objective
	canvas.add_child(marker)
	await frames()
	check(marker.name == "Exclamation", "reusable marker is named Exclamation")
	check(marker.current_target == npc and has_icon(marker, exclamation_path), "daily person uses exclamation")
	check(marker.visible and objective.text == "Objective: Talk to Test NPC", "person objective and marker display together")
	check(marker.global_position.distance_to(camera.unproject_position(head.global_position)) < 0.01, "exclamation anchors above the person's head")
	check(marker.mouse_filter == Control.MOUSE_FILTER_IGNORE and marker.icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "exclamation does not intercept input")
	check(marker.is_in_group("waypoint"), "existing dialogue group still controls exclamation")
	get_tree().call_group("waypoint", "set_marker_suppressed", true)
	await frames()
	check(not marker.visible, "dialogue hides exclamation")
	npc.story_finished.emit()
	await frames()
	check(marker.current_target == door and has_icon(marker, waypoint_path), "finishing conversation changes to a door waypoint")
	check(not marker.visible, "door marker remains hidden until dialogue finishes")
	get_tree().call_group("waypoint", "set_marker_suppressed", false)
	await frames()
	check(marker.visible and objective.text.contains("apartment"), "door waypoint and objective return after dialogue")
	check(is_equal_approx(marker.current_vertical_offset, marker.door_vertical_offset), "door uses its existing height")
	get_tree().paused = true
	await frames()
	check(not marker.visible, "pause hides door waypoint")
	get_tree().paused = false
	await frames()
	check(marker.visible and has_icon(marker, waypoint_path), "resume retains door waypoint")
	marker.setup_day_target()
	await frames()
	check(marker.current_target == npc and has_icon(marker, exclamation_path), "a new person objective restores exclamation")
	SaveManager.current_save_data["current_day"] = 3
	marker.setup_day_target()
	await frames()
	check(marker.current_target == door and has_icon(marker, waypoint_path), "a day without a person goes directly to a door waypoint")
	marker.target_override = npc
	marker.setup_day_target()
	await frames()
	check(marker.current_target == npc and has_icon(marker, exclamation_path), "direct person target uses exclamation like Grandpa at the dock")
	marker.target_override = door
	marker.setup_day_target()
	await frames()
	check(has_icon(marker, waypoint_path), "direct apartment-door target also uses waypoint")
	marker.target_override = null
	marker.apartment_door = null
	marker.current_target = null
	marker.setup_day_target()
	await frames()
	check(not marker.visible, "missing objective leaves no stray marker")
	var waypoint = load("res://scene/waypoint_marker.tscn").instantiate()
	check(has_icon(waypoint, waypoint_path), "base waypoint still uses original artwork for items and doors")
	check(marker.bounce_height == waypoint.bounce_height and marker.bounce_speed == waypoint.bounce_speed, "exclamation preserves waypoint animation")
	waypoint.free()
	check_scene_wiring("res://scene/dock.tscn", "target_override", ^"Grandpa")
	check_scene_wiring("res://scene/outside_world.tscn", "apartment_door", ^"OfficeDoor/Node3D")
	print("EXCLAMATION RESULT: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
