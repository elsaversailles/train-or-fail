extends Node3D

const HELD_UMBRELLA := preload("res://scripts/RainUmbrella.gd")

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_tree().root.size = Vector2i(1280, 720)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("7c8b99")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color.WHITE
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.3
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = PlaneMesh.new()
	floor_mesh.mesh.size = Vector2(100, 100)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("63747e")
	floor_mesh.material_override = material
	add_child(floor_mesh)
	var paths := ["res://models3d/characters/M/grandpa.tscn", "res://models3d/characters/F/nurse_clara_garcia.tscn", "res://models3d/characters/M/mark_krazy.tscn"]
	var grips: Array[Node3D] = []
	for index in paths.size():
		var npc: Node3D = load(paths[index]).instantiate()
		npc.scale = Vector3.ONE * 2.7
		npc.position.x = float(index - 1) * 5.2
		add_child(npc)
		var rig: Skeleton3D = npc.find_child("Skeleton3D", true, false)
		var umbrella := HELD_UMBRELLA.new()
		umbrella.name = "RainUmbrella"
		rig.add_child(umbrella)
		grips.append(umbrella)
		print("PREVIEW ", npc.name, " rig scale ", rig.global_basis.get_scale(), " height ", rig.get_bone_global_rest(6).origin.y * rig.global_basis.get_scale().y)
	var camera := Camera3D.new()
	add_child(camera)
	camera.fov = 40
	camera.position = Vector3(2, 4.5, 14)
	camera.look_at(Vector3(0, 3.1, 0))
	camera.current = true
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/umbrella-front-preview.png")
	camera.position = Vector3(-8, 4.5, 10)
	camera.look_at(Vector3(-4, 3.2, 0))
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/umbrella-grip-preview.png")
	for index in grips.size():
		var prop := grips[index].get_node("Umbrella") as Node3D
		var grip := prop.to_global(HELD_UMBRELLA.HANDLE_GRIP)
		for side in [-1, 1]:
			camera.position = grip + Vector3(0.6 * side, 0.35, 0.75)
			camera.look_at(grip)
			camera.fov = 30
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://.godot/grip-detail-%d-%d.png" % [index, side])
	print("UMBRELLA PREVIEW COMPLETE")
	get_tree().quit()
