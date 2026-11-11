extends Node

func world_transform(node: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent is Node3D:
		result = parent.transform * result
		parent = parent.get_parent()
	return result

func _ready() -> void:
	var scene: Node = load("res://scene/office_lobby.tscn").instantiate()
	for mesh in scene.find_children("*", "MeshInstance3D", true, false):
		var path: String = str(scene.get_path_to(mesh))
		if path.begins_with("Supervisor/") or "elev" in path.to_lower() or "door" in path.to_lower():
			var bounds: AABB = world_transform(mesh) * mesh.get_aabb()
			print("LOBBY BOUNDS: ", path, " min=", bounds.position, " max=", bounds.end)
			if path == "OfficeLobby2/Elevator":
				for index in mesh.mesh.get_surface_count():
					var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(index)[Mesh.ARRAY_VERTEX]
					var surface_bounds := AABB(vertices[0], Vector3.ZERO)
					for vertex in vertices:
						surface_bounds = surface_bounds.expand(vertex)
					surface_bounds = world_transform(mesh) * surface_bounds
					var material: Material = mesh.mesh.surface_get_material(index)
					print("ELEVATOR SURFACE: ", material.resource_name if material else str(index), " min=", surface_bounds.position, " max=", surface_bounds.end)
	scene.free()
	get_tree().quit()
