extends Node

var checks := 0
var failures: Array[String] = []
var grip_errors: Dictionary = {}
var sample_counts: Dictionary = {}

func _ready() -> void:
	get_tree().create_timer(90).timeout.connect(func(): push_error("UMBRELLA TEST TIMED OUT"); get_tree().quit(1))
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("UMBRELLA CHECK: " + message)

func frames(count: int = 3) -> void:
	for i in count:
		await get_tree().process_frame

func physics_frames(count: int = 3) -> void:
	for i in count:
		await get_tree().physics_frame

func load_city(rainy: bool, day: int) -> Node3D:
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data["current_day"] = day
	SaveManager.current_save_data["weather_day"] = day
	SaveManager.current_save_data["weather_rain"] = rainy
	var city: Node3D = load("res://scene/outside_world.tscn").instantiate()
	# Skip only the arrival monologue; retain the real weather, NPCs and patrols.
	city.set_script(null)
	for area in city.find_children("*", "Area3D", true, false):
		area.monitoring = false
	get_tree().root.add_child(city)
	get_tree().current_scene = city
	city.get_node("Player").set_physics_process(false)
	await physics_frames()
	await frames()
	return city

func unload_city(city: Node3D) -> void:
	get_tree().current_scene = self
	city.queue_free()
	await frames(5)

func sample_grip(rig: Skeleton3D, umbrella: Node3D, key: String) -> void:
	if not rig.is_visible_in_tree():
		return
	var pose: Transform3D = rig.get_bone_global_pose(umbrella._hand)
	var palm := rig.to_global(pose * (umbrella.GRIP.GRIP_CENTER * umbrella._rig_scale))
	var grip: Vector3 = umbrella._umbrella.to_global(umbrella.HANDLE_GRIP)
	grip_errors[key] = maxf(grip_errors.get(key, 0.0), palm.distance_to(grip))
	sample_counts[key] = sample_counts.get(key, 0) + 1

func _run() -> void:
	if "--capture-only" in OS.get_cmdline_user_args():
		await capture_city()
		return
	var city := await load_city(true, 5)
	var weather = city.get_node("CityAtmosphere")
	check(not city.get_node("Player/Head/Camera3D").has_node("PlayerRainUmbrella"), "player umbrella removed in rain")
	check(city.get_node("Player").find_children("*", "MeshInstance3D", true, false).is_empty(), "player has no visible hand or body mesh")
	check(weather._rainy and weather._rain != null and weather._rain.emitting, "actual rainy weather active")
	var npcs := get_tree().get_nodes_in_group("outdoor_npcs")
	check(npcs.size() == 9, "all nine outdoor NPCs registered")
	for npc in npcs:
		var rig: Skeleton3D = npc.find_child("Skeleton3D", true, false)
		var umbrella = rig.get_node_or_null("RainUmbrella")
		check(umbrella != null and umbrella._umbrella != null and umbrella.active, str(npc.name) + " has a working umbrella")
		if umbrella == null:
			continue
		check(umbrella._umbrella.find_children("*", "CollisionObject3D", true, false).is_empty(), "umbrella does not block interaction rays or movement")
		rig.skeleton_updated.connect(sample_grip.bind(rig, umbrella, str(npc.name)))
		var canopy: Vector3 = umbrella._umbrella.to_global(Vector3(0, 2.2746, 0))
		var head := rig.to_global(rig.get_bone_global_pose(rig.find_bone("spine.006")).origin)
		check(canopy.y > head.y + 0.5, str(npc.name) + " canopy clears head")
		check(umbrella._umbrella.global_basis.y.normalized().dot(Vector3.UP) > 0.999, "umbrella stays upright")
		check_grip_mesh(npc, umbrella)
	weather._give_npcs_umbrellas()
	check(city.find_children("RainUmbrella", "SkeletonModifier3D", true, false).size() == 9, "repeated setup does not duplicate umbrellas")
	var grandpa = city.get_node("FraudDetection/Grandpa")
	var patrol = grandpa.get_node("OutdoorNpcPatrol")
	var start: Vector3 = grandpa.global_position
	await physics_frames(45)
	check(grandpa.global_position.distance_to(start) > 0.1, "NPC patrol moves with umbrella")
	check(patrol._active_animation == &"outdoor/walk", "walk animation remains active")
	var body = grandpa.get_node("StaticBody3D")
	check(body.can_interact(), "NPC remains available for conversation")
	body.interact()
	await frames(5)
	check(Dialogic.current_timeline != null and patrol._interacting, "real conversation starts and pauses patrol")
	start = grandpa.global_position
	await physics_frames(20)
	check(grandpa.global_position.distance_to(start) < 0.001, "conversation keeps NPC stationary")
	check(patrol._active_animation == &"outdoor/idle", "idle animation works with umbrella")
	await Dialogic.end_timeline(true)
	await frames(3)
	check(not patrol._interacting, "conversation resumes patrol")
	await physics_frames(40)
	check(grandpa.global_position.distance_to(start) > 0.1, "NPC continues walking after conversation")
	for npc in npcs:
		check(sample_counts.get(str(npc.name), 0) > 0, "sampled final animated pose for " + str(npc.name))
		check(grip_errors.get(str(npc.name), 999.0) < 0.001, "umbrella stays in palm while animated: " + str(npc.name))
	grandpa.hide()
	await frames()
	check(not grandpa.find_child("Umbrella", true, false).is_visible_in_tree(), "hidden story NPC also hides umbrella")
	grandpa.show()
	await frames()
	check(grandpa.find_child("Umbrella", true, false).is_visible_in_tree(), "visible NPC restores umbrella")
	check(grip_errors["Grandpa"] < 0.001, "hand alignment restored after showing NPC")
	await unload_city(city)
	check(get_tree().get_nodes_in_group("outdoor_npcs").is_empty(), "scene exit cleans NPC umbrellas")

	city = await load_city(false, 6)
	check(not city.get_node("CityAtmosphere")._rainy, "actual dry weather active")
	city.get_node("CityAtmosphere")._give_npcs_umbrellas()
	check(city.find_children("RainUmbrella", "SkeletonModifier3D", true, false).is_empty(), "dry visit has no umbrellas or arm overrides")
	for npc in get_tree().get_nodes_in_group("outdoor_npcs"):
		for mesh in npc.find_children("*", "MeshInstance3D", true, false):
			check(not mesh.mesh.resource_path.is_empty(), "dry weather uses original mesh: " + str(npc.name) + "/" + str(mesh.name))
	await unload_city(city)
	city = await load_city(true, 1)
	check(city.find_children("RainUmbrella", "SkeletonModifier3D", true, false).size() == 9, "rainy reload recreates exactly one umbrella per NPC")
	grandpa = city.get_node("FraudDetection/Grandpa")
	check(grandpa.get_node("OutdoorNpcPatrol")._story_locked, "story-day NPC remains at authored position")
	check(grandpa.find_child("Umbrella", true, false).is_visible_in_tree(), "stationary story-day NPC holds umbrella")
	await unload_city(city)
	var indoor: Node3D = load("res://models3d/characters/M/grandpa.tscn").instantiate()
	add_child(indoor)
	await frames()
	check(indoor.find_children("RainUmbrella", "SkeletonModifier3D", true, false).is_empty(), "shared indoor character scene remains unchanged")
	indoor.queue_free()
	print("UMBRELLA CHECKS: %d passed, %d failed" % [checks - failures.size(), failures.size()])
	print("MAX GRIP ERRORS: ", grip_errors)
	get_tree().quit(0 if failures.is_empty() else 1)

func capture_city() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var city := await load_city(true, 1)
	var npc: Node3D = city.get_node("FraudDetection/Grandpa")
	var player = city.get_node("Player")
	var forward := npc.global_basis.z.normalized()
	player.global_position = npc.global_position + forward * 9.0
	player.camera.look_at(npc.global_position + Vector3(0, 3.4, 0))
	await get_tree().create_timer(0.75).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/umbrella-city-preview.png")
	print("RAINY CITY CAPTURE COMPLETE")
	await unload_city(city)
	get_tree().quit()

func check_grip_mesh(npc: Node3D, umbrella: Node3D) -> void:
	var template: Node3D = load(npc.scene_file_path).instantiate()
	var changed_vertices := 0
	var unaffected_vertices_match := true
	var valid_data := true
	var topology_valid := true
	var materials_preserved := true
	var hands_refined := false
	for original in template.find_children("*", "MeshInstance3D", true, false):
		var actual: MeshInstance3D = npc.get_node(template.get_path_to(original))
		if actual.mesh == original.mesh:
			continue
		var bind: int = umbrella.GRIP._find_hand_bind(original.skin, &"hand.R", umbrella._hand)
		var to_hand: Transform3D = original.skin.get_bind_pose(bind)
		for surface in original.mesh.get_surface_count():
			var source: Array = original.mesh.surface_get_arrays(surface)
			var modified: Array = actual.mesh.surface_get_arrays(surface)
			var source_vertices: PackedVector3Array = source[Mesh.ARRAY_VERTEX]
			var vertices: PackedVector3Array = modified[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = modified[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = modified[Mesh.ARRAY_INDEX]
			materials_preserved = materials_preserved and actual.mesh.surface_get_material(surface) == original.mesh.surface_get_material(surface)
			hands_refined = hands_refined or vertices.size() > source_vertices.size()
			for index in indices:
				topology_valid = topology_valid and index >= 0 and index < vertices.size()
			for vertex in vertices.size():
				valid_data = valid_data and vertices[vertex].is_finite() and normals[vertex].is_finite() and normals[vertex].length() > 0.95
			for vertex in source_vertices.size():
				var weight: float = umbrella.GRIP._hand_weight(source, vertex, bind)
				var hand_point: Vector3 = (to_hand * source_vertices[vertex]) / umbrella._rig_scale
				var moved := source_vertices[vertex].distance_to(vertices[vertex]) > 0.00001
				if moved:
					changed_vertices += 1
					unaffected_vertices_match = unaffected_vertices_match and weight >= 0.5 and hand_point.y > umbrella.GRIP.KNUCKLE
	check(changed_vertices >= 8, str(npc.name) + " has curled finger vertices")
	check(unaffected_vertices_match, str(npc.name) + " keeps wrist, left hand and other body vertices unchanged")
	check(hands_refined and topology_valid, str(npc.name) + " grip has valid refined topology")
	check(valid_data, str(npc.name) + " grip positions and normals remain valid")
	check(materials_preserved, str(npc.name) + " preserves skin and outline materials")
	template.free()
