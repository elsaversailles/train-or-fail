extends Node3D

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_tree().root.size = Vector2i(1000, 700)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("6e7a88")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	add_child(sun)
	var hand: Node3D = load("res://assets/hand mesh.glb").instantiate()
	add_child(hand)
	var mesh: MeshInstance3D = hand.find_child("Torso", true, false)
	print("HAND ", mesh.global_transform, " AABB ", mesh.get_aabb())
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(1.2, 1.3, 1.5)
	camera.look_at(Vector3(0, 0.3, -0.2))
	camera.current = true
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/hand-mesh-preview.png")
	get_tree().quit()
