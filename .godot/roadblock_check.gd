extends "res://.godot/tutorial_waypoint_check.gd"

const ROAD_TIMELINE := "res://Dialogic/Timelines/road_blocked.dtl"
var player: CharacterBody3D

func settle() -> void:
	for i in 4:
		await get_tree().physics_frame
	await frames(3)

func approach(warning: Area3D, side: float = 1.0) -> void:
	player.global_position = warning.to_global(Vector3(side * 4.3, -2.2, 0))
	await settle()

func leave() -> void:
	player.global_position = Vector3(0, 50, 0)
	await settle()

func is_road_warning() -> bool:
	return Dialogic.current_timeline != null and Dialogic.current_timeline.resource_path == ROAD_TIMELINE

func verify_and_finish(warning: Area3D, label: String) -> void:
	check(is_road_warning() and warning.has_triggered, label + " starts the road-blocked timeline")
	check(player.get("is_in_dialogue"), label + " locks player input through Dialogic")
	await Dialogic.end_timeline(true)
	await settle()
	check(not player.get("is_in_dialogue"), label + " restores player input after dialogue")
	check(Dialogic.current_timeline == null and not warning.is_processing(), label + " does not repeat while lingering")
	await leave()
	await approach(warning, -1.0)
	check(Dialogic.current_timeline == null, label + " does not repeat on re-entry from the other side")
	await leave()

func _run() -> void:
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	var map: Node3D = load("res://scene/map.tscn").instantiate()
	add_child(map)
	player = load("res://scene/character.tscn").instantiate()
	player.position = Vector3(0, 50, 0)
	player.set_physics_process(false)
	add_child(player)
	await settle()
	var warnings: Array[Area3D] = []
	for row in map.get_node("RoadBlocks").get_children():
		warnings.append(row.get_node("RoadBlockedWarning"))
	check(warnings.size() == 6, "all six rows have warning triggers")
	check(Dialogic.timeline_exists("road_blocked") and Dialogic.timeline_exists(ROAD_TIMELINE), "timeline resolves by name and by path")
	check(FileAccess.get_file_as_string(ROAD_TIMELINE).contains("find another way around"), "dialogue tells player to find another route")
	for warning in warnings:
		check(warning.collision_layer == 0 and warning.collision_mask == 3, "trigger detects both dock and outside player layers without blocking interaction rays")
		check(not warning.has_triggered and not warning.is_processing(), "trigger begins idle and unused")
		var shape: BoxShape3D = warning.get_node("CollisionShape3D").shape
		check(shape.size.z > 10.0 and shape.size.y >= 4.5, "trigger covers the row and player's height")

	# Physics overlap with an NPC must not open any dialogue.
	var npc := CharacterBody3D.new()
	var npc_collision := CollisionShape3D.new()
	var npc_shape := CapsuleShape3D.new()
	npc_shape.height = 2.0
	npc_collision.shape = npc_shape
	npc.add_child(npc_collision)
	add_child(npc)
	npc.global_position = warnings[0].global_position
	await settle()
	check(warnings[0].overlaps_body(npc), "NPC really overlaps the trigger")
	check(Dialogic.current_timeline == null and not warnings[0].has_triggered, "NPCs cannot trigger warning")
	npc.queue_free()
	player.set("is_in_dialogue", true)
	await approach(warnings[0])
	check(Dialogic.current_timeline == null and not warnings[0].has_triggered, "player dialogue lock defers warning")
	player.set("is_in_dialogue", false)
	await settle()
	await verify_and_finish(warnings[0], "row 1 / dock collision layer")

	# An existing conversation is preserved; walking away cancels the pending warning.
	Dialogic.start("elevator_warning")
	await frames()
	var existing_timeline: Resource = Dialogic.current_timeline
	await approach(warnings[1], -1.0)
	check(Dialogic.current_timeline == existing_timeline and not warnings[1].has_triggered, "road warning never replaces active dialogue")
	await leave()
	await Dialogic.end_timeline(true)
	await settle()
	check(Dialogic.current_timeline == null and not warnings[1].has_triggered, "leaving cancels warning queued during dialogue")
	await approach(warnings[1], -1.0)
	await verify_and_finish(warnings[1], "row 2")

	# A pending warning should start once another dialogue ends if still nearby.
	Dialogic.start("elevator_warning")
	await approach(warnings[2])
	check(not warnings[2].has_triggered, "row 3 waits for active dialogue")
	await Dialogic.end_timeline(true)
	await settle()
	await verify_and_finish(warnings[2], "row 3 / deferred dialogue")

	SceneTransition.is_transitioning = true
	await approach(warnings[3], -1.0)
	check(Dialogic.current_timeline == null and not warnings[3].has_triggered, "scene transition defers warning")
	SceneTransition.is_transitioning = false
	player.set("is_paused", true)
	await settle()
	check(Dialogic.current_timeline == null and not warnings[3].has_triggered, "paused player defers warning")
	player.set("is_paused", false)
	await settle()
	await verify_and_finish(warnings[3], "row 4 / resume")

	get_tree().paused = true
	player.global_position = warnings[4].to_global(Vector3(4.3, -2.2, 0))
	await frames(4)
	check(Dialogic.current_timeline == null and not warnings[4].has_triggered, "pause menu does not open warning")
	get_tree().paused = false
	await settle()
	await verify_and_finish(warnings[4], "row 5 / short row")

	player.collision_layer = 3
	await approach(warnings[5], -1.0)
	await verify_and_finish(warnings[5], "row 6 / outside collision layer")
	map.queue_free()
	await settle()
	check(Dialogic.current_timeline == null and not player.get("is_in_dialogue"), "map cleanup leaves no dialogue or movement lock")

	# New map visits get fresh warnings, with no save-file flags involved.
	map = load("res://scene/map.tscn").instantiate()
	add_child(map)
	await settle()
	var reloaded_warning: Area3D = map.get_node("RoadBlocks/road block/RoadBlockedWarning")
	check(not reloaded_warning.has_triggered, "reloading the map resets the warning")
	await approach(reloaded_warning)
	check(is_road_warning(), "warning still works after a new map visit")
	await Dialogic.end_timeline(true)
	await leave()
	SceneTransition.is_transitioning = true
	await approach(map.get_node("RoadBlocks/road block2/RoadBlockedWarning"))
	map.queue_free()
	await settle()
	SceneTransition.is_transitioning = false
	await settle()
	check(Dialogic.current_timeline == null, "unloading a pending trigger cannot open a stale warning")
	print("ROADBLOCK RESULT: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
