extends SceneTree

func _initialize() -> void:
	call_deferred("inspect")

func inspect() -> void:
	var map = load("res://scene/map.tscn").instantiate()
	map.scale = Vector3.ONE * 1.1
	root.add_child(map)
	for body_name in ["Collisions", "dock"]:
		for collider in map.get_node(body_name).get_children():
			if collider is CollisionShape3D and collider.shape is BoxShape3D:
				var bounds: AABB = collider.global_transform * AABB(-collider.shape.size * 0.5, collider.shape.size)
				print("COLLIDER ", body_name, "/", collider.name, " ", bounds)
	var output: Array = []
	var triangles: Array = []
	for node in map.find_children("*", "MeshInstance3D", true, false):
		var materials: Array[String] = []
		var is_sidewalk := false
		for i in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(i)
			var name := str(material.resource_name) + " " + material.resource_path if material else "none"
			materials.append(name)
			if "SIDEWALK" in name.to_upper() or "WALK" in name.to_upper():
				is_sidewalk = true
				var arrays: Array = node.mesh.surface_get_arrays(i)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var count := indices.size() if not indices.is_empty() else vertices.size()
				for triangle in range(0, count, 3):
					var points: Array = []
					for corner in 3:
						var index := indices[triangle + corner] if not indices.is_empty() else triangle + corner
						var v: Vector3 = node.global_transform * vertices[index]
						points.append(v)
					var normal: Vector3 = (points[1] - points[0]).cross(points[2] - points[0]).normalized()
					if absf(normal.y) > 0.9 and points[0].y < 1.0:
						triangles.append({"name": str(node.name), "material": name, "points": [[points[0].x, points[0].y, points[0].z], [points[1].x, points[1].y, points[1].z], [points[2].x, points[2].y, points[2].z]]})
		var bounds: AABB = node.global_transform * node.get_aabb()
		var item := {"name": str(node.get_path()), "position": str(bounds.position), "end": str(bounds.end), "materials": materials}
		output.append(item)
		if is_sidewalk:
			print("SIDEWALK ", item)
	var file := FileAccess.open("res://.godot/patrol-route-review/geometry.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(output, "  "))
	var triangle_file := FileAccess.open("res://.godot/patrol-route-review/triangles.json", FileAccess.WRITE)
	triangle_file.store_string(JSON.stringify(triangles))
	print("EXPORTED TRIANGLES ", triangles.size())
	map.free()
	quit()
