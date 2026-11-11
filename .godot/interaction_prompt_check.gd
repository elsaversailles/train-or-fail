extends "res://.godot/tutorial_waypoint_check.gd"

class PlainInteractable extends StaticBody3D:
	var interactions := 0
	func interact() -> void:
		interactions += 1

var player: CharacterBody3D
var fixture: Node3D
var hud: Label

func mount_npc(body: StaticBody3D) -> void:
	if body.get_parent():
		body.get_parent().remove_child(body)
	fixture = Node3D.new()
	fixture.position = Vector3(0, 0, -5)
	add_child(fixture)
	body.transform = Transform3D.IDENTITY
	if not body.has_node("CollisionShape3D"):
		var collision := CollisionShape3D.new()
		collision.name = "CollisionShape3D"
		var shape := CapsuleShape3D.new()
		shape.height = 3.0
		collision.shape = shape
		collision.position.y = 1.5
		body.add_child(collision)
	fixture.add_child(body)
	await aim_at(player, body.get_node("CollisionShape3D").global_position)
	await frames()
	check(player.raycast.get_collider() == body, "ray hits the tested NPC")

func unmount_npc() -> void:
	fixture.queue_free()
	await get_tree().physics_frame
	await frames()

func expect_prompt(expected: bool, message: String) -> void:
	player.raycast.force_raycast_update()
	player._process(0.0)
	check(hud.visible == expected, message)
	if expected:
		check(hud.text == "Press E to Interact", message + " has correct text")
	else:
		player.check_interaction()
		check(Dialogic.current_timeline == null, message + " does not start a conversation")

func _run() -> void:
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	add_child(canvas)
	hud = Label.new()
	hud.name = "InteractionLabel"
	canvas.add_child(hud)
	player = load("res://scene/character.tscn").instantiate()
	player.set_physics_process(false)
	add_child(player)
	var outdoor: Node = load("res://scene/outside_world.tscn").instantiate()

	# These are the actual scene instances/configurations, including the pictured partner NPCs.
	for path in ["FraudDetection/Assistant", "FraudDetection/Cashier", "CreditScoring/Supplier", "CreditScoring/Joice"]:
		var npc = outdoor.get_node(path + "/StaticBody3D")
		await mount_npc(npc)
		for day in range(1, 11):
			SaveManager.current_save_data["current_day"] = day
			expect_prompt(day not in npc.special_days, "%s day %d prompt matches available conversation" % [path, day])
		SaveManager.current_save_data["current_day"] = 10
		npc.is_talking = true
		expect_prompt(false, path + " hides prompt while already speaking")
		npc.is_talking = false
		player.check_interaction()
		await frames()
		check(Dialogic.current_timeline != null and player.get("is_in_dialogue"), path + " still starts available dialogue through E interaction")
		check(not npc.can_interact(), path + " unavailable during live dialogue")
		await Dialogic.end_timeline(true)
		await frames()
		expect_prompt(true, path + " becomes available again after conversation")
		npc.generic_timelines.clear()
		expect_prompt(false, path + " hides prompt when no dialogue is configured")
		player.current_zone_prompt = "Press E to Enter"
		player._process(0.0)
		check(hud.visible and hud.text == "Press E to Enter", "door zone prompt remains available near an unavailable NPC")
		player.current_zone_prompt = ""
		await unmount_npc()

	for data in [["FraudDetection/Grandpa", 1], ["CreditScoring/Nurse Clara", 7], ["CreditScoring/Prof_ Jericho Santur", 8]]:
		var npc = outdoor.get_node(data[0] + "/StaticBody3D")
		await mount_npc(npc)
		SaveManager.current_save_data["current_day"] = data[1]
		npc.can_talk = false
		expect_prompt(false, data[0] + " stays hidden until story conversation unlocks")
		npc.can_talk = true
		expect_prompt(true, data[0] + " appears immediately after story conversation unlocks")
		npc.can_talk = false
		SaveManager.current_save_data["current_day"] = 10
		expect_prompt(true, data[0] + " permits generic conversation on other days without story unlock")
		npc.generic_timelines.clear()
		expect_prompt(false, data[0] + " hides when no generic conversation exists")
		await unmount_npc()

	var mark = outdoor.get_node("FraudDetection/Mark Krazy/StaticBody3D")
	await mount_npc(mark)
	SaveManager.current_save_data["current_day"] = 2
	mark.can_talk = false
	expect_prompt(false, "Mark waits for cashier conversation on day 2")
	mark.can_talk = true
	expect_prompt(true, "Mark unlocks after cashier conversation on day 2")
	mark.can_talk = false
	SaveManager.current_save_data["current_day"] = 4
	expect_prompt(true, "Mark's day 4 speech remains available without day 2 unlock")
	SaveManager.current_save_data["current_day"] = 3
	expect_prompt(true, "Mark's generic conversation remains available")
	await unmount_npc()
	outdoor.free()

	var supervisor = load("res://scripts/dialogue/Supervisor.gd").new()
	var objective := Label.new()
	canvas.add_child(objective)
	supervisor.objective_label = objective
	await mount_npc(supervisor)
	for day in range(1, 11):
		SaveManager.current_save_data["current_day"] = day
		supervisor.can_talk = false
		expect_prompt(false, "supervisor day %d stays hidden before callout finishes" % day)
		supervisor.can_talk = true
		expect_prompt(day in [1, 4, 7], "supervisor day %d only advertises a real conversation" % day)
	await unmount_npc()

	var grandpa = load("res://scripts/dialogue/GrandpaDock.gd").new()
	await mount_npc(grandpa)
	expect_prompt(true, "dock Grandpa retains interaction prompt")
	grandpa.is_talking = true
	expect_prompt(false, "dock Grandpa hides prompt during conversation/transition")
	grandpa.is_talking = false
	grandpa.timeline_name = ""
	expect_prompt(false, "dock Grandpa hides prompt without a timeline")
	await unmount_npc()

	var plain := PlainInteractable.new()
	await mount_npc(plain)
	expect_prompt(true, "ordinary interactables keep their prompt without NPC-specific availability")
	player.check_interaction()
	check(plain.interactions == 1, "ordinary interactables still receive E action")
	await unmount_npc()
	print("INTERACTION PROMPT RESULT: %d checks; %d failures" % [checks, failures.size()])
	get_tree().quit(0 if failures.is_empty() else 1)
