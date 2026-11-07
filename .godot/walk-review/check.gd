extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var character = load("res://animation/adrian_walk_test.tscn").instantiate()
	root.add_child(character)
	var player: AnimationPlayer = character.get_node("Player/AnimationPlayer")
	var skeleton: Skeleton3D = character.get_node("Player/Skeleton3D")
	check(player.autoplay == "walking/walk", "Preview should autoplay walking/walk")
	check(player.has_animation("idle"), "Preview retains idle")
	check(player.has_animation("walking/walk"), "Preview has walk library")
	var walk := player.get_animation("walking/walk")
	check(walk.loop_mode == Animation.LOOP_LINEAR, "Walk loops")
	for track in walk.get_track_count():
		var path := walk.track_get_path(track)
		check(path.get_concatenated_names() == "Skeleton3D", "Track targets Skeleton3D")
		check(skeleton.find_bone(path.get_concatenated_subnames()) >= 0, "Track bone exists: " + str(path))
		var count := walk.track_get_key_count(track)
		check(walk.track_get_key_value(track, 0).is_equal_approx(walk.track_get_key_value(track, count - 1)), "Loop matches at boundary: " + str(path))
	player.play("walking/walk")
	var lowest := INF
	var highest_support := -INF
	var minimum_foot_z := INF
	var maximum_foot_z := -INF
	for frame in 241:
		player.seek(walk.length * float(frame % 240) / 240.0, true)
		skeleton.force_update_all_bone_transforms()
		var support := INF
		for side in ["L", "R"]:
			for bone_name in ["heel.02." + side, "toe." + side]:
				var point := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin
				lowest = minf(lowest, point.y)
				support = minf(support, point.y)
			var foot_pos := skeleton.get_bone_global_pose(skeleton.find_bone("foot." + side)).origin
			minimum_foot_z = minf(minimum_foot_z, foot_pos.z)
			maximum_foot_z = maxf(maximum_foot_z, foot_pos.z)
		highest_support = maxf(highest_support, support)
	check(lowest >= -0.003, "Sole markers stay above floor, minimum=" + str(lowest))
	check(highest_support <= 0.003, "At least one foot stays planted, maximum=" + str(highest_support))
	check(maximum_foot_z - minimum_foot_z > 1.0, "Feet have alternating stride")
	check(character.position.is_equal_approx(Vector3.ZERO), "In-place walk does not drift")
	var original = load("res://models3d/characters/M/adrian_santos.tscn").instantiate()
	root.add_child(original)
	var original_player: AnimationPlayer = original.get_node("Player/AnimationPlayer")
	check(original_player.autoplay == "idle", "Original still autoplays idle")
	check(not original_player.has_animation("walking/walk"), "Walk library isolated from original")
	print("WALK_CHECK tracks=", walk.get_track_count(), " duration=", walk.length, " min_sole_y=", lowest, " max_support_y=", highest_support, " stride_z=", maximum_foot_z - minimum_foot_z, " failures=", failures)
	original.free()
	character.free()
	var preview = load("res://scene/walk_preview.tscn").instantiate()
	root.add_child(preview)
	var preview_player: AnimationPlayer = preview.get_node("Character/Player/AnimationPlayer")
	check(preview_player.is_playing(), "Preview starts playing")
	preview.get_node("Interface/UI/Controls/Content/Playback/PauseButton").pressed.emit()
	check(not preview_player.is_playing(), "Pause button pauses")
	preview_player.seek(0.43, true)
	preview.get_node("Interface/UI/Controls/Content/Playback/ResetButton").pressed.emit()
	check(is_zero_approx(preview_player.current_animation_position), "Restart resets playback")
	check(not preview_player.is_playing(), "Restart respects pause")
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	space.pressed = true
	preview._unhandled_input(space)
	check(preview_player.is_playing(), "Space resumes")
	var slider: HSlider = preview.get_node("Interface/UI/Controls/Content/Playback/SpeedSlider")
	slider.value = 0.25
	check(is_equal_approx(preview_player.speed_scale, 0.25), "Speed slider sets slow playback")
	slider.value = 1.5
	check(is_equal_approx(preview_player.speed_scale, 1.5), "Speed slider sets fast playback")
	preview.get_node("Interface/UI/Views/SideButton").pressed.emit()
	check(preview.get_node("Camera3D").position.x > 3.0, "Side camera button works")
	preview.get_node("Interface/UI/Views/FrontButton").pressed.emit()
	check(is_zero_approx(preview.get_node("Camera3D").position.x), "Front camera button works")
	print("WALK_PREVIEW_CONTROLS failures=", failures)
	preview.free()
	quit(0 if failures.is_empty() else 1)
