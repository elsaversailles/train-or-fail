extends Node3D

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	for path in ["res://models3d/characters/M/grandpa.tscn", "res://models3d/characters/F/nurse_clara_garcia.tscn"]:
		var npc: Node3D = load(path).instantiate()
		add_child(npc)
		var rig: Skeleton3D = npc.find_child("Skeleton3D", true, false)
		var bone := rig.find_bone("hand.R")
		print("RIG ", path, " global transform ", rig.global_transform, " hand rest ", rig.get_bone_global_rest(bone))
		for child in npc.find_children("*", "MeshInstance3D", true, false):
			var mesh := child as MeshInstance3D
			print("MESH ", mesh.get_path(), " transform ", mesh.global_transform, " skeleton ", mesh.skeleton, " skin ", mesh.skin)
			if mesh.skin == null:
				continue
			for bind in mesh.skin.get_bind_count():
				if mesh.skin.get_bind_name(bind) == "hand.R" or mesh.skin.get_bind_bone(bind) == bone:
					print("HAND BIND ", bind, " ", mesh.skin.get_bind_pose(bind))
		npc.free()
	get_tree().quit()
