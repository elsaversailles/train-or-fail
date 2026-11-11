extends "res://.godot/tutorial_waypoint_check.gd"

const DEPARTMENTS := [
	"res://scene/FraudDetection/FraudDetection.tscn",
	"res://scene/KnowYourCustomer/KnowYourCustomer.tscn",
	"res://scene/CreditScoring/CreditScoring.tscn",
]
const MAPPING := {"Bread": "tita_elena", "ToyCar": "jericho_santur", "ToyTank": "mark_krazy", "FirstAidKit": "nurse_clara"}

func bounds(gift: Node3D) -> AABB:
	var result := AABB()
	var found := false
	for mesh in gift.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		result = result.merge(box) if found else box
		found = true
	return result

func check_geometry(scene: Node, gifts: Node3D) -> void:
	check(gifts.find_children("*", "CollisionObject3D", true, false).is_empty(), "Gifts do not block movement or interaction rays")
	for gift in gifts.get_children():
		var box := bounds(gift)
		check(is_equal_approx(box.position.y, 2.345), str(gift.name) + " rests on desktop")
		for x in [box.position.x, box.end.x]:
			for z in [box.position.z, box.end.z]:
				var query := PhysicsRayQueryParameters3D.create(Vector3(x, 3.8, z), Vector3(x, 2.2, z))
				var hit: Dictionary = scene.get_world_3d().direct_space_state.intersect_ray(query)
				check(not hit.is_empty() and absf(hit.position.y - 2.34) < 0.01, str(gift.name) + " supported by desktop at " + str(Vector2(x,z)) + ": " + str(hit.get("position", "no hit")))
	for a in gifts.get_children():
		for b in gifts.get_children():
			if a.get_index() < b.get_index():
				check(not bounds(a).intersects(bounds(b)), "Gift bounds do not overlap: " + str(a.name) + "/" + str(b.name))

func expect(gifts: Node, visible_names: Array, context: String) -> void:
	for gift in gifts.get_children():
		check(gift.visible == (str(gift.name) in visible_names), context + ": " + str(gift.name))

func applicant(id: String) -> Dictionary:
	var entries: Array = Database.grandpa_applicant_data if id == "grandpa" else Database.special_applicants
	for entry in entries:
		if entry.id == id:
			var result: Dictionary = entry.duplicate(true)
			result["model_scene"] = null
			return result
	return {}

func load_saved_department(path: String) -> Node:
	SaveManager.current_save_data["current_day"] = [2, 5, 8][DEPARTMENTS.find(path)]
	var scene: Node = load(path).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await get_tree().physics_frame
	await get_tree().physics_frame
	await frames()
	scene.get_node("MainChar").set_physics_process(false)
	return scene

func _run() -> void:
	print("TEST USER DIRECTORY: ", OS.get_user_data_dir())
	check(OS.get_user_data_dir().contains("desk-gifts-test-user"), "Tests use isolated saves")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	var scene := await load_department(DEPARTMENTS[0], 2)
	var gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, [], "New game")
	check_geometry(scene, gifts)
	var panel = scene.get_node("Monitor/Screen/SubViewport/LeftSlidingPanel")
	panel.applicants = [applicant("tita_elena"), applicant("mark_krazy"), applicant("tita_elena"), applicant("mark_krazy")]
	panel.current_index = 0
	panel.load_applicant(0)
	await panel.submit_answer("legit")
	expect(gifts, ["Bread"], "Tita approval through FD panel")
	await panel.submit_answer("legit")
	expect(gifts, ["Bread", "ToyTank"], "Mark approval through FD panel")
	await panel.submit_answer("sus")
	expect(gifts, ["ToyTank"], "Tita rejection through FD panel")
	await panel.submit_answer("sus")
	expect(gifts, [], "Mark rejection through FD panel")
	await unload_department(scene)

	scene = await load_department(DEPARTMENTS[1], 5)
	gifts = scene.find_child("DeskGifts", true, false)
	check_geometry(scene, gifts)
	SaveManager.record_special_decision("mark_krazy", "legit")
	panel = scene.get_node("Monitor/Screen/SubViewport/KYCPanel")
	panel.applicants = [applicant("mark_krazy"), applicant("mark_krazy")]
	panel.current_index = 0
	panel.load_applicant(0)
	await panel.submit_answer("sus")
	expect(gifts, [], "KYC rejection updates earlier Mark approval")
	check(SaveManager.read_save(1).special_decisions.mark_krazy == "sus", "KYC rejection saved immediately")
	await panel.submit_answer("legit")
	expect(gifts, ["ToyTank"], "KYC approval refreshes gift immediately")
	check(SaveManager.read_save(1).special_decisions.mark_krazy == "legit", "KYC approval saved immediately")
	await unload_department(scene)

	scene = await load_department(DEPARTMENTS[2], 8)
	gifts = scene.find_child("DeskGifts", true, false)
	check_geometry(scene, gifts)
	panel = scene.get_node("Monitor/Screen/SubViewport/CreditScoringPanel")
	panel.applicants_list = [applicant("nurse_clara"), applicant("jericho_santur"), applicant("nurse_clara"), applicant("jericho_santur")]
	panel.current_case_index = 0
	panel.load_applicant()
	panel.slider.value = 0.6
	await panel._on_submit()
	expect(gifts, ["FirstAidKit"], "Clara approval through CS panel")
	panel.slider.value = 1.0
	await panel._on_submit()
	expect(gifts, ["FirstAidKit", "ToyCar"], "Jericho approval through CS panel")
	panel.slider.value = 0.0
	await panel._on_submit()
	expect(gifts, ["ToyCar"], "Clara rejection through CS panel")
	panel.slider.value = 0.4
	await panel._on_submit()
	expect(gifts, [], "Jericho story rejection through CS panel")
	for id in MAPPING.values():
		SaveManager.record_special_decision(id, "legit")
	expect(gifts, MAPPING.keys(), "All four approvals")
	await unload_department(scene)
	SaveManager.current_save_data = {}
	SaveManager.load_game(1)
	for path in DEPARTMENTS:
		scene = await load_saved_department(path)
		gifts = scene.find_child("DeskGifts", true, false)
		expect(gifts, MAPPING.keys(), "Approved gifts restored in " + path)
		await unload_department(scene)
	SaveManager.save_game(2, SaveManager.DEFAULT_SAVE.duplicate(true))
	SaveManager.load_game(2)
	scene = await load_saved_department(DEPARTMENTS[2])
	gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, [], "Separate slot has no gifts")
	SaveManager.current_save_data.erase("special_decisions")
	gifts.refresh()
	expect(gifts, [], "Old save without decisions remains safe")
	SaveManager.record_special_decision("grandpa", "legit")
	expect(gifts, [], "Grandpa outside secret ending does not grant yarn")
	SaveManager.current_save_data["is_grandpa_shift"] = true
	panel = scene.get_node("Monitor/Screen/SubViewport/CreditScoringPanel")
	panel.applicants_list = [applicant("grandpa"), applicant("grandpa")]
	panel.current_case_index = 0
	panel.load_applicant()
	panel.slider.value = 0.0
	await panel._on_submit()
	expect(gifts, [], "Secret Grandpa rejection")
	panel.slider.value = 0.8
	await panel._on_submit()
	expect(gifts, ["Yarn"], "Secret Grandpa approval through CS panel")
	SaveManager.current_save_data.erase("is_grandpa_shift")
	SaveManager.current_save_data["grandpa_round_completed"] = true
	gifts.refresh()
	expect(gifts, ["Yarn"], "Yarn survives completed secret shift")
	SaveManager.current_save_data.erase("grandpa_round_completed")
	SaveManager.record_ending("conflict_of_interest")
	gifts.refresh()
	expect(gifts, ["Yarn"], "Yarn remains for completed secret ending")
	await unload_department(scene)
	SaveManager.load_game(2)
	scene = await load_saved_department(DEPARTMENTS[2])
	gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, ["Yarn"], "Yarn survives encrypted save reload")
	await unload_department(scene)
	print("DESK GIFTS CHECKS: ", checks, " / FAILURES: ", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
