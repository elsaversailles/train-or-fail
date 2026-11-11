extends "res://.godot/desk_gifts_inspect.gd"

func _run() -> void:
	var root := Node3D.new()
	root.name = "DeskGifts"
	add_child(root)
	var entries := [
		["Bread", "minecraft_slice_of_bread.glb", Vector3(-8.75, 2.345, -11.65), Vector3(90, -15, 0), 0.72],
		["ToyCar", "low_poly_toy_car_i_kids_car_for_projects.glb", Vector3(-3.0, 2.345, -12.95), Vector3(0, 55, 0), 0.95],
		["ToyTank", "low_poly_tank.glb", Vector3(-7.55, 2.345, -14.55), Vector3(0, -20, 0), 1.0],
		["FirstAidKit", "first_aid_kit.glb", Vector3(-2.8, 2.345, -13.85), Vector3(0, -10, 0), 0.85],
		["Yarn", "ball_of_yarn.glb", Vector3(-8.55, 2.345, -10.65), Vector3(0, 15, 0), 1.0],
	]
	for entry in entries:
		var anchor := Node3D.new()
		anchor.name = entry[0]
		anchor.position = entry[2]
		root.add_child(anchor)
		anchor.owner = root
		var orientation := Node3D.new()
		orientation.name = "Orientation"
		anchor.add_child(orientation)
		orientation.owner = root
		orientation.rotation_degrees = entry[3]
		var model: Node3D = load("res://assets/ACHIEVEMETNS/" + entry[1]).instantiate()
		orientation.add_child(model)
		model.owner = root
		var box := bounds_in(orientation, anchor)
		var factor: float = entry[4] / maxf(box.size.x, maxf(box.size.y, box.size.z))
		orientation.scale = Vector3.ONE * factor
		orientation.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * factor
		print("PLACED ", anchor.name, " ", bounds_in(anchor, root))
	root.set_script(load("res://scripts/DeskGifts.gd"))
	var scene := PackedScene.new()
	var error := scene.pack(root)
	if error == OK:
		error = ResourceSaver.save(scene, "res://scene/desk_gifts.tscn")
	print("DESK GIFT SCENE SAVED: ", error_string(error))
	get_tree().quit(0 if error == OK else 1)
