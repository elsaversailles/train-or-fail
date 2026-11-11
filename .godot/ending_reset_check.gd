extends Node

var checks := 0
var failures: Array[String] = []
var close_count := 0

func _ready() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error("RESET CHECK: " + message)

func frames(count := 3) -> void:
	for i in count:
		await get_tree().process_frame

func press_key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	Input.parse_input_event(event)
	await frames()
	event = InputEventKey.new()
	event.keycode = key
	Input.parse_input_event(event)
	await frames()

func fresh_manager() -> Node:
	var manager = load("res://scripts/SaveManager.gd").new()
	add_child(manager)
	return manager

func _run() -> void:
	check(OS.get_user_data_dir().contains("ending-reset-test-user"), "Uses isolated save directory")
	if not failures.is_empty():
		get_tree().quit(1)
		return
	var legacy := ConfigFile.new()
	for id in SaveManager.Catalog.ENDINGS:
		legacy.set_value("endings", id, true)
	check(legacy.save_encrypted_pass(SaveManager.COLLECTION_PATH, SaveManager.SAVE_PASSWORD) == OK, "Seed legacy collection")
	var completed := SaveManager.DEFAULT_SAVE.duplicate(true)
	completed["ending_id"] = "clean_exit"
	completed["stage_name"] = "Game Finished"
	SaveManager.save_game(1, completed)
	var inferred := SaveManager.DEFAULT_SAVE.duplicate(true)
	inferred["stage_name"] = "Game Finished"
	for id in SaveManager.Catalog.SPECIAL_IDS:
		inferred.special_decisions[id] = "legit"
	SaveManager.save_game(2, inferred)
	var unfinished := SaveManager.DEFAULT_SAVE.duplicate(true)
	unfinished["special_decisions"] = {"tita_elena": "legit"}
	SaveManager.save_game(3, unfinished)
	SaveManager._collection_generation = 0
	SaveManager._unlocked_endings.clear()
	SaveManager._collection_needs_save = false
	SaveManager._ready()
	SaveManager.load_game(3)
	var current_before := SaveManager.current_save_data.duplicate(true)
	var slot_bytes := []
	for slot in range(1, 4):
		slot_bytes.append(FileAccess.get_file_as_bytes(SaveManager.get_save_path(slot)))
	var collection_before := FileAccess.get_file_as_bytes(SaveManager.COLLECTION_PATH)
	check(SaveManager.get_unlocked_ending_count() == 7, "Legacy collection stays unlocked before reset")
	var menu = load("res://scene/main_menu.tscn").instantiate()
	add_child(menu)
	var main = menu.get_node("Main Menu")
	main._on_gallery_pressed()
	var gallery = main.get_node("EndingGallery")
	gallery.closed.connect(func(): close_count += 1)
	await frames()
	check(gallery.entries.get_child_count() == 7, "Gallery has seven entries")
	check(gallery.get_node("Window/Count").text == "7/7 endings", "Initial gallery count")
	var style: StyleBoxFlat = gallery.reset_button.get_theme_stylebox("normal")
	check(style.bg_color.r > style.bg_color.g * 2.0, "Reset button is red")
	gallery.confirm_reset_button.pressed.emit()
	check(SaveManager.get_unlocked_ending_count() == 7, "Hidden confirmation cannot reset")
	gallery.reset_button.pressed.emit()
	check(gallery.reset_confirmation.visible, "Reset opens confirmation")
	check(gallery.cancel_reset_button.has_focus(), "Cancel receives default focus")
	check(SaveManager.get_unlocked_ending_count() == 7, "Opening confirmation does not reset")
	await press_key(KEY_TAB)
	check(gallery.confirm_reset_button.has_focus(), "Tab moves to confirm")
	await press_key(KEY_TAB)
	check(gallery.cancel_reset_button.has_focus(), "Tab stays inside confirmation")
	gallery.close_button.pressed.emit()
	gallery.entries.get_child(0).pressed.emit()
	check(close_count == 0 and gallery.window.visible and not gallery.intro.visible, "Confirmation blocks background actions")
	await press_key(KEY_ESCAPE)
	check(not gallery.reset_confirmation.visible and close_count == 0, "Escape cancels only the confirmation")
	check(FileAccess.get_file_as_bytes(SaveManager.COLLECTION_PATH) == collection_before, "Escape leaves stored endings unchanged")
	gallery.reset_button.pressed.emit()
	gallery.cancel_reset_button.pressed.emit()
	check(not gallery.reset_confirmation.visible and gallery.reset_button.has_focus(), "Cancel restores focus")
	check(FileAccess.get_file_as_bytes(SaveManager.COLLECTION_PATH) == collection_before, "Cancel leaves stored endings unchanged")
	# Force an actual write error without touching real player files.
	var blocked_path := "%s.%d.tmp" % [SaveManager.COLLECTION_PATH, OS.get_process_id()]
	check(DirAccess.make_dir_absolute(blocked_path) == OK, "Create isolated write failure fixture")
	print("EXPECTED WRITE FAILURE BEGIN")
	gallery.reset_button.pressed.emit()
	gallery.confirm_reset_button.pressed.emit()
	print("EXPECTED WRITE FAILURE END")
	check(gallery.reset_confirmation.visible, "Write failure keeps confirmation open")
	check(gallery.get_node("ResetConfirmation/Dialog/Message").text.contains("Could not save"), "Write failure is visible to player")
	check(SaveManager.get_unlocked_ending_count() == 7 and SaveManager._collection_generation == 0, "Write failure preserves in-memory unlocks")
	check(FileAccess.get_file_as_bytes(SaveManager.COLLECTION_PATH) == collection_before, "Write failure preserves stored collection")
	check(DirAccess.remove_absolute(blocked_path) == OK, "Remove isolated write failure fixture")
	gallery.confirm_reset_button.pressed.emit()
	check(not gallery.reset_confirmation.visible, "Successful confirmation closes modal")
	check(SaveManager.get_unlocked_ending_count() == 0, "All endings reset")
	check(gallery.get_node("Window/Count").text == "0/7 endings", "Gallery count refreshes immediately")
	check(gallery.entries.get_child_count() == 7, "Refresh does not duplicate entries")
	for entry in gallery.entries.get_children():
		check(entry.disabled and entry.get_node("Caption").text == "Locked" and entry.get_node("Thumbnail").material != null, "Ending card is relocked")
	for slot in range(1, 4):
		check(FileAccess.get_file_as_bytes(SaveManager.get_save_path(slot)) == slot_bytes[slot-1], "Reset preserves slot %d byte-for-byte" % slot)
	check(SaveManager.current_save_data == current_before, "Reset preserves current story decisions and gifts")
	var fresh := fresh_manager()
	check(fresh.get_unlocked_ending_count() == 0, "Restart does not restore old completed saves")
	check(fresh.preserve_slot_ending(fresh.read_save(1)) and fresh.preserve_slot_ending(fresh.read_save(2)), "Old saves can still be replayed/deleted")
	check(fresh.get_unlocked_ending_count() == 0, "Preserving old saves does not undo reset")
	fresh.queue_free()
	gallery.close_button.pressed.emit()
	await frames()
	check(main.get_node("GalleryButton/Count").text == "0/7 endings", "Main menu counter updates after reset")
	main._on_gallery_pressed()
	gallery = main.get_node("EndingGallery")
	check(gallery.get_node("Window/Count").text == "0/7 endings", "Reopening gallery remains empty")
	SaveManager.record_ending("conflict_of_interest")
	check(SaveManager.is_ending_unlocked("conflict_of_interest"), "New gameplay can unlock an ending after reset")
	check(SaveManager.current_save_data.ending_collection_generation == 1, "New ending uses current collection generation")
	SaveManager.record_ending("terminated")
	check(SaveManager.get_unlocked_ending_count() == 2, "Termination can be unlocked again too")
	fresh = fresh_manager()
	check(fresh.get_unlocked_ending_count() == 2, "New unlocks persist after restart")
	fresh.queue_free()
	check(SaveManager.reset_all_endings(), "Repeated reset succeeds")
	fresh = fresh_manager()
	check(fresh.get_unlocked_ending_count() == 0 and fresh._collection_generation == 2, "Second reset suppresses previously re-earned ending")
	fresh.queue_free()
	# Recovery still works for endings earned after the latest reset.
	var recoverable := SaveManager.DEFAULT_SAVE.duplicate(true)
	recoverable["ending_id"] = "cold_efficiency"
	recoverable["ending_collection_generation"] = 2
	recoverable["stage_name"] = "Game Finished"
	SaveManager.save_game(3, recoverable)
	fresh = fresh_manager()
	check(fresh.get_unlocked_ending_count() == 1 and fresh.is_ending_unlocked("cold_efficiency"), "Current-generation save recovers interrupted collection write")
	fresh.queue_free()
	menu.queue_free()
	await frames()
	print("ENDING RESET CHECKS: ", checks, " / FAILURES: ", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)
