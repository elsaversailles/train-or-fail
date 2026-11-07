extends SceneTree

func _initialize() -> void:
	call_deferred("inspect")

func inspect() -> void:
	var map = load("res://scene/map.tscn").instantiate()
	map.scale = Vector3.ONE * 1.1
	root.add_child(map)
	await physics_frame
	await physics_frame
	var routes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://.godot/patrol-route-review/candidates.json"))
	var space: PhysicsDirectSpaceState3D = root.world_3d.direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 1.0
	capsule.height = 3.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var failed := {}
	for name in routes:
		var errors: Array = []
		var count := 0
		var total := 0.0
		for segment in routes[name].size() - 1:
			var a := Vector3(routes[name][segment][0], routes[name][segment][1], routes[name][segment][2])
			var b := Vector3(routes[name][segment + 1][0], routes[name][segment + 1][1], routes[name][segment + 1][2])
			total += a.distance_to(b)
			var steps := ceili(a.distance_to(b) / 0.15)
			for i in steps + 1:
				var point := a.lerp(b, float(i) / steps)
				query.transform = Transform3D(Basis.IDENTITY, point + Vector3(0,2.7,0))
				var hits := space.intersect_shape(query, 16)
				count += 1
				if not hits.is_empty():
					var names: Array = []
					for hit in hits:
						var path := str(hit.collider.get_path())
						if path not in names:
							names.append(path)
					errors.append([point.x, point.y, point.z, names])
		failed[name] = errors
		print(name, " length=", total, " samples=", count, " blocked=", errors.size(), " examples=", errors.slice(0, 3))
	var file := FileAccess.open("res://.godot/patrol-route-review/failed.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(failed))
	map.free()
	quit()
