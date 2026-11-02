extends SceneTree

class Probe:
	extends Button
	var presses := 0
	var unhandled := 0
	func _ready():
		process_mode = Node.PROCESS_MODE_ALWAYS
		pressed.connect(func(): presses += 1)
	func _unhandled_input(event):
		if event is InputEventKey and event.pressed and event.keycode in [KEY_ENTER, KEY_ESCAPE]:
			unhandled += 1

var checks := 0
var failures: Array[String] = []
var shortcut: CanvasLayer
var probe: Probe

func _initialize():
	call_deferred("_run")

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)
		push_error("FAIL: " + message)

func key(code: Key, echoed: bool = false):
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	event.echo = echoed
	Input.parse_input_event(event)
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run():
	shortcut = root.get_node("EndingShortcuts")
	var save_manager = root.get_node("SaveManager")
	var transition = root.get_node("SceneTransition")
	check(OS.get_user_data_dir().replace("\\", "/").contains(".godot/ending-review/shortcut-userdata"), "isolated save directory")
	check(shortcut.is_processing_input(), "autoload input enabled in debug build")
	save_manager.current_save_data = {"current_day": 6, "total_score": 22, "special_decisions": {"mark_krazy": "legit"}}
	var saved_before: Dictionary = save_manager.current_save_data.duplicate(true)
	probe = Probe.new()
	probe.text = "Underlying action"
	probe.size = Vector2(200, 80)
	root.add_child(probe)
	probe.grab_focus()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var mouse_before: Input.MouseMode = Input.mouse_mode
	var expected := [
		[KEY_F1, "Algorithm Reformer", "Algorithm_Reformer.png"],
		[KEY_F2, "Another Cog in the Machine", "Another_Cog_In_The_Machine.png"],
		[KEY_F3, "Cold Efficiency", "Cold_Efficiency.png"],
		[KEY_F4, "Conflict of Interest", "Conflict_of_Interest.png"],
		[KEY_F5, "Stagnant Survival", "Stagnant_Survival.png"],
		[KEY_F6, "Terminated", "Terminated.png"],
		[KEY_F7, "The Clean Exit", "The_Clean_Exit.png"]
	]
	for entry in expected:
		await key(entry[0])
		check(shortcut._is_preview_open() and shortcut._intro.visible, entry[1] + " opens intro")
		check(shortcut._intro.title_label.text == entry[1], entry[1] + " title")
		check(shortcut._artwork.texture.resource_path.get_file() == entry[2], entry[1] + " artwork")
		check(paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, entry[1] + " pauses gameplay and shows cursor")
		await key(KEY_ENTER)
		check(shortcut._is_preview_open() and not shortcut._intro.visible, entry[1] + " first Enter reveals art")
		await key(KEY_ENTER)
		check(not shortcut._is_preview_open() and not paused, entry[1] + " second Enter closes and resumes")
		check(Input.mouse_mode == mouse_before and root.gui_get_focus_owner() == probe, entry[1] + " restores mouse and focus")
	check(probe.presses == 0 and probe.unhandled == 0, "continue key never propagates to underlying UI")
	await key(KEY_F1)
	await key(KEY_F7)
	check(shortcut._intro.title_label.text == "The Clean Exit", "F key switches open preview")
	check(not shortcut._was_paused and shortcut._previous_mouse_mode == mouse_before and shortcut._previous_focus == probe, "switch preserves initial resume state")
	await key(KEY_ESCAPE)
	check(not shortcut._is_preview_open() and not paused and Input.mouse_mode == mouse_before and root.gui_get_focus_owner() == probe, "Escape restores original state")
	check(probe.unhandled == 0, "Escape never propagates")
	paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await key(KEY_F3)
	await key(KEY_F4)
	await key(KEY_ESCAPE)
	check(paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and root.gui_get_focus_owner() == probe, "pre-paused prior state restored after switching")
	paused = false
	await key(KEY_F1, true)
	check(not shortcut._is_preview_open(), "ignores key echo")
	transition.is_transitioning = true
	await key(KEY_F2)
	check(not shortcut._is_preview_open() and not paused, "ignores shortcuts during scene transition")
	transition.is_transitioning = false
	check(save_manager.current_save_data == saved_before, "save data unchanged")
	print("ENDING SHORTCUT SMOKE: %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
