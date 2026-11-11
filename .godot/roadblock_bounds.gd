extends Node

func world_transform(node: Node3D) -> Transform3D:
	var result := node.transform
	var parent := node.get_parent()
	while parent is Node3D:
		result = parent.transform * result
		parent = parent.get_parent()
	return result

func _ready() -> void:
	var map: Node3D = load("res://scene/map.tscn").instantiate()
	for row in map.get_node("RoadBlocks").get_children():
		var bounds := AABB()
		var first := true
		for mesh in row.find_children("*", "MeshInstance3D", true, false):
			var local_transform: Transform3D = world_transform(row).affine_inverse() * world_transform(mesh)
			var mesh_bounds: AABB = local_transform * mesh.get_aabb()
			bounds = mesh_bounds if first else bounds.merge(mesh_bounds)
			first = false
		print("ROADBLOCK BOUNDS: ", row.name, " bounds=", bounds, " center=", bounds.get_center(), " bodies=", row.find_children("*", "StaticBody3D", true, false).size())
	map.free()
	get_tree().quit()
