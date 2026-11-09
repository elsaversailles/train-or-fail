extends SceneTree

var viewport: SubViewport
var guide: Control
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func settle() -> void:
	for frame in 3:
		await process_frame

func key(keycode: Key, backwards: bool = false) -> void:
	for is_pressed in [true,false]:
		var event := InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.shift_pressed = backwards
		event.pressed = is_pressed
		viewport.push_input(event, true)
	await settle()

func check_focus(context: String) -> void:
	checks += 1
	var focus := viewport.gui_get_focus_owner()
	if focus == null or not guide.is_ancestor_of(focus):
		failures += 1
		push_error(context + ": focus escaped to " + (str(focus.get_path()) if focus != null else "null"))

func _run() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1152,648)
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(viewport)
	var fixture := Panel.new()
	fixture.name = "PausePanel"
	fixture.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	fixture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(fixture)
	for title in ["Resume", "Settings", "Controls", "ReplayTutorial", "Reset Game", "Quit"]:
		var button := Button.new()
		button.name = title
		button.text = title
		button.position = Vector2(525,216 + 45 * fixture.get_child_count())
		button.size = Vector2(104,35)
		fixture.add_child(button)
	guide = load("res://scene/tutorial_panel.tscn").instantiate()
	fixture.add_child(guide)
	paused = true
	await settle()
	guide.open_controls()
	await settle()
	for page in 8:
		guide.current_tutorial_page = page
		guide.update_tutorial_display()
		await settle()
		guide.find_child("MovementButton",true,false).grab_focus()
		for backwards in [false,true]:
			for index in 12:
				await key(KEY_TAB, backwards)
				check_focus("page%d tab%d reverse%s" % [page,index,backwards])
		for name in ["MovementButton", "InteractionButton", "WorkGuideButton", "PrevButton", "NextButton", "CloseTutorialButton"]:
			var button: Button = guide.find_child(name,true,false)
			if button.disabled:
				continue
			for direction in [KEY_LEFT,KEY_RIGHT,KEY_UP,KEY_DOWN]:
				button.grab_focus()
				await key(direction)
				check_focus("page%d %s arrow%d" % [page,name,direction])
		print("FOCUS page ",page," passed")
	print("PAUSE_FOCUS_REVIEW checks=", checks, " failures=", failures)
	quit(0 if failures == 0 else 1)
