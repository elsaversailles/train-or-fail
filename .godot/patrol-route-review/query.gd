extends SceneTree

func _initialize() -> void:
	call_deferred("inspect")

func inspect() -> void:
	var map = load("res://scene/map.tscn").instantiate()
	map.scale = Vector3.ONE * 1.1
	root.add_child(map)
	await physics_frame
	await physics_frame
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.5
	capsule.height = 3.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var output := {}
	for area in [["bakery", -85, 40, -45, -9], ["hospital", -214, -202, 70, 150], ["dealer", -170, -106, 9, 24]]:
		var blocked: Array = []
		for x in range(area[1], area[2] + 1):
			for z in range(area[3], area[4] + 1):
				query.transform = Transform3D(Basis.IDENTITY, Vector3(x, 2.7, z))
				var hits := space.intersect_shape(query, 16)
				if not hits.is_empty():
					var names: Array = []
					for hit in hits:
						names.append(str(hit.collider.get_path()) + ":" + str(hit.shape))
					blocked.append([x, z, names])
		output[area[0]] = blocked
	var file := FileAccess.open("res://.godot/patrol-route-review/blocked.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output))
	print("BLOCKED COUNTS ", output["bakery"].size(), " ", output["hospital"].size(), " ", output["dealer"].size())
	map.free()
	quit()
