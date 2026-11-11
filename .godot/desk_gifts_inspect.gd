extends Node3D

func _ready() -> void:
	_run.call_deferred()

func bounds_in(node: Node3D, relative_to: Node3D) -> AABB:
	var result := AABB()
	var found := false
	for candidate in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		var box := relative_to.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		result = result.merge(box) if found else box
		found = true
	return result

func _run() -> void:
	var office: Node3D = load("res://models3d/map/office.tscn").instantiate()
	add_child(office)
	print("OFFICE TRANSFORM ", office.global_transform)
	await get_tree().physics_frame
	await get_tree().physics_frame
	for z in [-14.5, -13.5, -12.5, -11.5, -10.5]:
		var heights := []
		for x in [-9.0, -8.0, -7.0, -6.0, -5.0, -4.0, -3.0, -2.5]:
			var query := PhysicsRayQueryParameters3D.create(Vector3(x, 4.5, z), Vector3(x, 0, z))
			var hit := get_world_3d().direct_space_state.intersect_ray(query)
			heights.append(snappedf(hit.position.y, 0.001) if not hit.is_empty() else -1)
		print("DESK HEIGHTS Z=", z, " ", heights)
	for candidate in office.find_children("*", "MeshInstance3D", true, false):
		var mesh := candidate as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		if box.position.x < -2 and box.end.x > -10 and box.position.z < -10 and box.end.z > -16 and box.position.y < 3.5:
			print("DESK AREA ", mesh.name, " ", box)
	office.queue_free()
	for filename in ["minecraft_slice_of_bread.glb", "low_poly_toy_car_i_kids_car_for_projects.glb", "low_poly_tank.glb", "first_aid_kit.glb", "ball_of_yarn.glb"]:
		var item: Node3D = load("res://assets/ACHIEVEMETNS/" + filename).instantiate()
		add_child(item)
		print("GIFT ", filename, " ", bounds_in(item, self))
		item.queue_free()
	get_tree().quit()
