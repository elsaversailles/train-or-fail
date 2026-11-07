extends Node

var world: Node3D
var camera: Camera3D

func _ready() -> void:
	_run.call_deferred()

func _capture(label: String) -> void:
	for frame in 8:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://.godot/outdoor-patrol-visual/" + label + ".png")
	print("CAPTURE ", label)

func _view(target: Node3D, offset: Vector3) -> void:
	camera.global_position = target.global_position + offset
	camera.look_at(target.global_position + Vector3(0, 2.0, 0))

func _run() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1152, 648)
	AudioServer.set_bus_mute(0, true)
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data["current_day"] = 3
	SaveManager.current_save_data["weather_day"] = 3
	SaveManager.current_save_data["weather_rain"] = false
	SaveManager.current_save_data["special_decisions"] = {"tita_elena": "legit", "nurse_clara": "legit", "jericho_santur": "legit"}
	world = load("res://scene/outside_world.tscn").instantiate()
	world.set_script(null)
	world.get_node("Player").set_script(null)
	for area in world.find_children("*", "Area3D", true, false):
		area.monitoring = false
	add_child(world)
	world.get_node("CanvasLayer").hide()
	world.get_node("PausePanel").hide()
	camera = Camera3D.new()
	camera.fov = 62.0
	camera.far = 300.0
	world.add_child(camera)
	camera.make_current()
	get_viewport().msaa_3d = Viewport.MSAA_4X
	await get_tree().process_frame
	await get_tree().process_frame
	for patrol in world.find_children("OutdoorNpcPatrol", "Node", true, false):
		patrol.set_physics_process(false)
		patrol._physics_process(0.25)
	var grandpa: Node3D = world.get_node("FraudDetection/Grandpa")
	_view(grandpa, Vector3(10, 6, 14))
	await _capture("grandpa-walking")
	var clara: Node3D = world.get_node("CreditScoring/Nurse Clara")
	_view(clara, Vector3(9, 6, 12))
	await _capture("clara-walking")
	var mark: Node3D = world.get_node("FraudDetection/Mark Krazy")
	_view(mark, Vector3(8, 5, 11))
	await _capture("mark-walking")
	var player: Node3D = world.get_node("Player")
	player.global_position = mark.global_position + Vector3(6, 0, 3)
	mark.get_node("OutdoorNpcPatrol").begin_interaction(player)
	await _capture("mark-facing-player")
	SaveManager.current_save_data["current_day"] = 1
	for patrol in world.find_children("OutdoorNpcPatrol", "Node", true, false):
		patrol._apply_day(1)
	_view(grandpa, Vector3(9, 5, 12))
	await _capture("grandpa-story-day")
	print("OUTDOOR_PATROL_VISUAL_COMPLETE")
	get_tree().quit()
