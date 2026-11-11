extends SceneTree

func _initialize() -> void:
	for method in ClassDB.class_get_method_list("SkeletonModifier3D", true):
		print("MODIFIER METHOD ", method)
	for path in ["res://models3d/characters/M/grandpa.tscn", "res://models3d/characters/F/nurse_clara_garcia.tscn", "res://models3d/characters/M/mark_krazy.tscn"]:
		var character = load(path).instantiate()
		root.add_child(character)
		var skeleton: Skeleton3D = character.find_child("Skeleton3D", true, false)
		var animation: AnimationPlayer = character.find_child("AnimationPlayer", true, false)
		animation.play("idle")
		animation.advance(0)
		print("CHARACTER ", path, " root ", character.transform, " skeleton ", skeleton.global_transform)
		for bone in skeleton.get_bone_count():
			print(bone, " ", skeleton.get_bone_name(bone), " parent=", skeleton.get_bone_parent(bone), " global=", skeleton.get_bone_global_pose(bone).origin, " local=", skeleton.get_bone_rest(bone).origin)
		character.free()
	quit()
