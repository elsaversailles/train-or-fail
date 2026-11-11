extends Node

var failures: Array[String] = []
var checks := 0

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("WAYPOINT CHECK: " + message)

func frames(count: int = 3) -> void:
	for i in count:
		await get_tree().process_frame

func load_department(path: String, day: int) -> Node:
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data["current_day"] = day
	var scene: Node = load(path).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await get_tree().physics_frame
	await get_tree().physics_frame
	await frames()
	scene.get_node("MainChar").set_physics_process(false)
	return scene

func unload_department(scene: Node) -> void:
	get_tree().current_scene = self
	scene.queue_free()
	await frames()

func aim_at(player: Node, target: Vector3) -> void:
	player.camera.look_at(target)
	await get_tree().physics_frame
	player.raycast.force_raycast_update()

func _run() -> void:
	get_tree().root.size = Vector2i(1152, 720)
	var fd_path := "res://scene/FraudDetection/FraudDetection.tscn"
	var scene := await load_department(fd_path, 1)
	var marker = scene.get_node("CanvasLayer/TutorialWaypoint")
	var tutorial = scene.get_node("CanvasLayer/FDTutorial")
	var player = scene.get_node("MainChar")
	var disk = scene.get_node("floppydisk")
	var cartridge = scene.get_node("socket/FloppyCartridge")
	var socket = scene.get_node("socket")
	var monitor = scene.get_node("Monitor")
	check(marker.current_target == disk and marker.visible, "FD starts on the floppy disk")
	check(marker.icon.texture.resource_path == "res://images/waypoint.png", "uses the outdoor waypoint artwork")
	check(marker.mouse_filter == Control.MOUSE_FILTER_IGNORE and marker.icon.mouse_filter == Control.MOUSE_FILTER_IGNORE, "marker does not intercept input")
	check(marker.current_vertical_offset > 0.0, "marker is above the target")

	player.global_position = Vector3(-6.5, 0.2, -9.0)
	await aim_at(player, disk.global_position)
	check(player.raycast.get_collider() == disk, "pickup ray reaches the floppy disk")
	player.check_for_pickup()
	await frames()
	check(player.held_item == disk and marker.current_target == cartridge, "pickup moves waypoint to cartridge")
	player.drop_item()
	await frames()
	check(marker.current_target == disk, "dropping the disk restores its waypoint")
	await aim_at(player, disk.global_position)
	player.check_for_pickup()
	await frames()
	check(player.held_item == disk and marker.current_target == cartridge, "picking disk back up restores cartridge waypoint")
	await aim_at(player, socket.get_node("CollisionShape3D").global_position)
	check(player.raycast.get_collider() == socket, "insert ray reaches cartridge")
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	player._input(interact)
	await frames()
	check(disk.is_inserted and player.held_item == null, "actual interaction inserts the disk")
	check(marker.current_target == cartridge, "cartridge stays marked during insertion")
	await get_tree().create_timer(2.2).timeout
	await frames()
	check(marker.current_target == monitor and marker.visible, "green light moves waypoint above monitor")
	check(disk.led_green.material_override.emission_enabled, "monitor waypoint waits for green light")

	get_tree().paused = true
	await frames()
	check(not marker.visible, "waypoint hides while paused")
	get_tree().paused = false
	await frames()
	check(marker.visible, "waypoint returns after pause")
	player.is_in_dialogue = true
	await frames()
	check(not marker.visible, "waypoint hides during dialogue")
	player.is_in_dialogue = false
	await frames()
	check(marker.visible, "waypoint returns after dialogue")

	scene.get_node("IdleScreen").interact()
	await frames()
	check(tutorial.tutorial_step == 0 and not marker.visible, "opening desktop starts tutorial and hides waypoint")
	player.release_computer_focus()
	await frames()
	check(not marker.visible, "waypoint stays hidden once instructions start")
	for i in tutorial.pages.size():
		tutorial._finish_typing()
		tutorial.advance_tutorial()
	await frames()
	check(not is_instance_valid(tutorial) and not marker.visible, "completed tutorial leaves no waypoint")
	await unload_department(scene)

	for department in [
		["res://scene/KnowYourCustomer/KnowYourCustomer.tscn", 4, "KYCTutorial"],
		["res://scene/CreditScoring/CreditScoring.tscn", 7, "CSTutorial"]
	]:
		scene = await load_department(department[0], department[1])
		marker = scene.get_node("CanvasLayer/TutorialWaypoint")
		tutorial = scene.get_node("CanvasLayer/" + department[2])
		player = scene.get_node("MainChar")
		monitor = scene.get_node("Monitor")
		check(marker.current_target == monitor and marker.visible, department[2] + " has a monitor-only waypoint even while tutorial UI is hidden")
		scene.get_node("IdleScreen").interact()
		await frames()
		check(not marker.visible and tutorial.tutorial_step == -1, department[2] + " hides waypoint on premature focus without starting tutorial")
		player.release_computer_focus()
		await frames()
		check(marker.current_target == monitor and marker.visible, department[2] + " restores waypoint after premature focus")
		disk = scene.get_node("floppydisk")
		socket = scene.get_node("socket")
		socket.socket_item(disk)
		await get_tree().create_timer(2.2).timeout
		scene.get_node("IdleScreen").interact()
		await frames()
		check(tutorial.tutorial_step == 0 and not marker.visible, department[2] + " opening loaded monitor starts tutorial and clears waypoint")
		await unload_department(scene)

	for department in [[fd_path, 2], [fd_path, 3], ["res://scene/KnowYourCustomer/KnowYourCustomer.tscn", 5], ["res://scene/KnowYourCustomer/KnowYourCustomer.tscn", 6], ["res://scene/CreditScoring/CreditScoring.tscn", 8], ["res://scene/CreditScoring/CreditScoring.tscn", 9], ["res://scene/CreditScoring/CreditScoring.tscn", 10]]:
		scene = await load_department(department[0], department[1])
		marker = scene.get_node("CanvasLayer/TutorialWaypoint")
		check(not marker.visible and marker.current_target == null, "no tutorial waypoint on day " + str(department[1]))
		await unload_department(scene)

	print("WAYPOINT RESULT: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
