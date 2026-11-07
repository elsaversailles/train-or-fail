extends SceneTree

func _initialize() -> void:
	call_deferred("inspect")

func inspect() -> void:
	var character = load("res://models3d/characters/M/adrian_santos.tscn").instantiate()
	root.add_child(character)
	var skeleton: Skeleton3D = character.get_node("Player/Skeleton3D")
	var player: AnimationPlayer = character.get_node("Player/AnimationPlayer")
	player.stop()
	print("CHARACTER ", character.transform, " SKELETON ", skeleton.global_transform)
	for i in skeleton.get_bone_count():
		print(i, " ", skeleton.get_bone_name(i), " parent=", skeleton.get_bone_parent(i), " rest=", skeleton.get_bone_rest(i), " pose=", skeleton.get_bone_pose(i), " global=", skeleton.get_bone_global_rest(i))
	var idle: Animation = player.get_animation("idle")
	ResourceSaver.save(idle, "res://.godot/walk-review/idle.tres")
	print("IDLE TRACKS ", idle.get_track_count(), " LENGTH ", idle.length)
	quit()
