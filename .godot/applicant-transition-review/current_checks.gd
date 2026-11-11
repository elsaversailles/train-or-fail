extends Node

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _ready() -> void:
	AudioServer.set_bus_mute(0, true)
	get_tree().create_timer(50.0).timeout.connect(func(): push_error("Check timeout"); get_tree().quit(2))
	run_checks.call_deferred()

func run_checks() -> void:
	for mode in ["fraud", "credit", "kyc"]:
		SaveManager.current_save_data = SaveManager.DEFAULT_SAVE.duplicate(true)
		SaveManager.current_save_data["current_day"] = 1 if mode == "fraud" else (7 if mode == "credit" else 4)
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1152, 648)
		add_child(viewport)
		var models := Node3D.new()
		models.name = "ModelContainer"
		viewport.add_child(models)
		var scene_name: String = {"fraud": "left_sliding_panel", "credit": "credit_scoring_panel", "kyc": "kyc_panel"}[mode]
		var panel = load("res://scene/screengameplays/%s.tscn" % scene_name).instantiate()
		viewport.add_child(panel)
		await get_tree().process_frame
		if mode != "kyc":
			await panel.set_panel_open(true).finished
			if mode == "fraud":
				panel.applicants = panel.applicants.slice(0, 2)
				panel.legit_button.pressed.emit()
				panel.legit_button.pressed.emit()
				check(panel.current_index == 1, "Fraud duplicate submission")
			else:
				panel.applicants_list = panel.applicants_list.slice(0, 2)
				panel.submit_button.pressed.emit()
				panel.submit_button.pressed.emit()
				check(panel.current_case_index == 1, "Credit duplicate submission")
			check(panel.is_transitioning and panel.grip_button.disabled, mode + " input must be locked")
			var saw_reopening := false
			while panel.is_transitioning:
				if panel.is_open:
					saw_reopening = true
					check(panel.grip_button.disabled, mode + " input unlocked during opening")
				await get_tree().process_frame
			check(saw_reopening and panel.is_open, mode + " did not automatically reopen")
			check(not panel.grip_button.disabled, mode + " grip was not restored")
			check(panel.grip_idle_timer.is_stopped(), mode + " closed grip reminder still running")
			check(is_equal_approx(panel.position.x, panel.open_x if mode == "credit" else -3.0), mode + " panel did not reach open position")
			check(models.global_position.is_equal_approx(Vector3.ZERO), mode + " model did not reach original position")
			print(mode + " next applicant automatically reopened and controls restored")
		if mode != "credit":
			var notes_pattern := RegEx.new()
			notes_pattern.compile('"(?:kyc_)?note": "([^"\\n]+)"')
			var source := FileAccess.get_file_as_string("res://scripts/ApplicantDatabase.gd")
			var max_height := 0.0
			var intended_height: float = panel.note_text_label.size.y
			panel.note_popup_panel.show()
			for match_result in notes_pattern.search_all(source):
				var formatted: String = panel.format_note_bullets(match_result.get_string(1))
				check(formatted.begins_with("• "), mode + " note missing bullet")
				panel.note_text_label.text = formatted
				await get_tree().process_frame
				await get_tree().process_frame
				var height: float = panel.note_text_label.get_minimum_size().y
				max_height = maxf(max_height, height)
				check(height <= intended_height, mode + " note overflow: " + formatted)
			print(mode + " notes max measured height ", max_height, " / ", intended_height)
		viewport.free()
		await get_tree().process_frame
	print("Current applicant checks: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
