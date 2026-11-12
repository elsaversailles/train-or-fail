extends "res://.godot/desk_gifts_check.gd"

func department_for_day(day: int) -> String:
	return DEPARTMENTS[0 if day <= 3 else (1 if day <= 6 else 2)]

func load_current_department() -> Node:
	var scene: Node = load(department_for_day(int(SaveManager.current_save_data.current_day))).instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	await get_tree().physics_frame
	await get_tree().physics_frame
	await frames()
	scene.get_node("MainChar").set_physics_process(false)
	return scene

func check_approval(day: int, id: String, gift: String) -> void:
	SaveManager.current_slot = 1
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data.current_day = day
	if id == "grandpa":
		SaveManager.current_save_data.is_grandpa_shift = true
	var scene := await load_current_department()
	var gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, [], id + " before approval")
	if day <= 3 or day <= 6:
		var panel = scene.get_node("Monitor/Screen/SubViewport/" + ("LeftSlidingPanel" if day <= 3 else "KYCPanel"))
		panel.applicants = [applicant(id)]
		panel.current_index = 0
		panel.load_applicant(0)
		await panel.submit_answer("legit")
	else:
		var panel = scene.get_node("Monitor/Screen/SubViewport/CreditScoringPanel")
		panel.applicants_list = [applicant(id)]
		panel.current_case_index = 0
		panel.load_applicant()
		panel.slider.value = 0.8
		await panel._on_submit()
	expect(gifts, [], id + " stays hidden on approval day")
	check(SaveManager.current_save_data.desk_gift_available_days[id] == day + 1, id + " delivery day is recorded")
	await unload_department(scene)
	SaveManager.load_game(1)
	scene = await load_current_department()
	gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, [], id + " same-day reload stays hidden")
	SaveManager.current_save_data.current_day = day + 1
	SaveManager.save_game(1, SaveManager.current_save_data)
	await unload_department(scene)
	SaveManager.load_game(1)
	scene = await load_current_department()
	gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, [gift], id + " appears the next day after reload")
	SaveManager.record_special_decision(id, "legit")
	expect(gifts, [gift], id + " repeat approval keeps delivered gift")
	SaveManager.record_special_decision(id, "sus")
	expect(gifts, [], id + " rejection revokes current-run gift")
	SaveManager.record_special_decision(id, "legit")
	expect(gifts, [], id + " re-approval starts a new next-day delivery")
	SaveManager.current_save_data.current_day = day + 2
	gifts.refresh()
	expect(gifts, [gift], id + " re-approved gift arrives next day")
	await unload_department(scene)

func replay_slot(slot: int) -> void:
	var menu: Node = load("res://scene/slots_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await frames()
	menu._on_slot_clicked(slot)
	check(menu.select_btn_label.text == "Replay", "Completed slot offers Replay")
	menu._on_select_pressed()
	await SceneTransition.transition_finished
	if Dialogic.current_timeline != null:
		await Dialogic.end_timeline(true)
	await unload_department(get_tree().current_scene)

func _run() -> void:
	check(OS.get_user_data_dir().contains("desk-gifts-next-day-test-user"), "Uses isolated saves")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	await check_approval(2, "tita_elena", "Bread")
	await check_approval(3, "mark_krazy", "ToyTank")
	await check_approval(5, "mark_krazy", "ToyTank")
	await check_approval(8, "nurse_clara", "FirstAidKit")
	await check_approval(9, "jericho_santur", "ToyCar")
	await check_approval(10, "grandpa", "Yarn")
	# Real slot replay preserves the final gift, but starts other decisions fresh.
	SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
	SaveManager.current_save_data.current_day = 9
	SaveManager.record_special_decision("jericho_santur", "legit")
	SaveManager.record_special_decision("tita_elena", "legit")
	SaveManager.current_save_data.current_day = 10
	SaveManager.record_ending("algorithm_reformer")
	await replay_slot(1)
	check(SaveManager.current_save_data.current_day == 1, "Replay starts at Day 1")
	check(SaveManager.current_save_data.special_decisions.is_empty(), "Replay resets current-run decisions")
	check(SaveManager.current_save_data.desk_gifts_carried == ["jericho_santur"], "Jericho carries into actual Replay")
	var scene := await load_current_department()
	var gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, ["ToyCar"], "Final toy car is present at first desk of Replay")
	await unload_department(scene)
	SaveManager.load_game(1)
	check(SaveManager.is_desk_gift_available("jericho_santur"), "Car carryover survives save reload")
	SaveManager.current_save_data.current_day = 10
	SaveManager.current_save_data.is_grandpa_shift = true
	SaveManager.record_special_decision("grandpa", "legit")
	check(not SaveManager.is_desk_gift_available("grandpa"), "Grandpa gift remains pending on approval day")
	SaveManager.current_save_data.erase("is_grandpa_shift")
	SaveManager.record_ending("conflict_of_interest")
	await replay_slot(1)
	scene = await load_current_department()
	gifts = scene.find_child("DeskGifts", true, false)
	expect(gifts, ["ToyCar", "Yarn"], "Grandpa yarn and earlier car carry into next Replay")
	check(SaveManager.current_save_data.desk_gifts_carried.size() == 2, "Carryover has no duplicates")
	await unload_department(scene)
	SaveManager.save_game(2, SaveManager.DEFAULT_SAVE.duplicate(true))
	SaveManager.load_game(2)
	check(not SaveManager.is_desk_gift_available("grandpa") and not SaveManager.is_desk_gift_available("jericho_santur"), "Gifts do not leak into another slot")
	# Old saves infer the delivery day from the applicant schedule.
	for example in [[2, "tita_elena", 3], [3, "mark_krazy", 4], [5, "mark_krazy", 6], [8, "nurse_clara", 9], [9, "jericho_santur", 10], [10, "grandpa", 11]]:
		var legacy := SaveManager.DEFAULT_SAVE.duplicate(true)
		legacy.erase("desk_gift_available_days")
		legacy.current_day = example[0]
		legacy.special_decisions[example[1]] = "legit"
		if example[1] == "grandpa":
			legacy.is_grandpa_shift = true
		SaveManager.save_game(2, legacy)
		SaveManager.load_game(2)
		check(SaveManager.current_save_data.desk_gift_available_days[example[1]] == example[2], "Legacy delivery inferred for " + example[1])
		check(not SaveManager.is_desk_gift_available(example[1]), "Legacy same-day approval is hidden for " + example[1])
		SaveManager.current_save_data.current_day = example[2]
		check(SaveManager.is_desk_gift_available(example[1]), "Legacy next-day gift arrives for " + example[1])
	var rejected := SaveManager.DEFAULT_SAVE.duplicate(true)
	rejected.stage_name = "Game Finished"
	rejected.ending_id = "cold_efficiency"
	rejected.special_decisions = {"grandpa": "sus", "jericho_santur": "sus"}
	check(SaveManager.get_replay_desk_gifts(rejected).is_empty(), "Rejected final NPCs grant no replay gifts")
	rejected.special_decisions.grandpa = "legit"
	check(SaveManager.get_replay_desk_gifts(rejected).is_empty(), "Yarn requires Grandpa's approval ending")
	SaveManager.load_game(1)
	check(SaveManager.reset_all_endings(), "Gallery reset succeeds with carried gifts")
	check(SaveManager.is_desk_gift_available("grandpa") and SaveManager.is_desk_gift_available("jericho_santur"), "Gallery reset preserves carried desk gifts")
	check(SaveManager.delete_save(1), "Slot deletion still succeeds")
	check(not SaveManager.is_desk_gift_available("grandpa") and not SaveManager.is_desk_gift_available("jericho_santur"), "Deleting the slot clears its gifts")
	print("NEXT-DAY DESK GIFTS: ", checks, " CHECKS / ", failures.size(), " FAILURES")
	get_tree().quit(0 if failures.is_empty() else 1)
