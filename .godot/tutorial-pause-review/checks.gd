extends Node

var failures: int = 0
var checks: int = 0
var fixture: Node3D
var player: CharacterBody3D
var menu: Panel
var tutorial: Control
var monitor: Node
var resume_button: Button

func _ready() -> void:
	get_tree().root.size = Vector2i(1152, 720)
	get_tree().root.content_scale_size = Vector2i(1152, 720)
	for action in ["move_left", "move_right", "move_forward", "move_backward", "interact"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	get_tree().create_timer(25.0).timeout.connect(func(): push_error("TIMEOUT"); get_tree().quit(2))
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func child(parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	return node

func setup(department: String) -> void:
	fixture = Node3D.new()
	fixture.name = "Fixture"
	fixture.process_mode = Node.PROCESS_MODE_PAUSABLE
	player = CharacterBody3D.new()
	player.set_script(load("res://scripts/Controller.gd"))
	var head := child(player, Node3D.new(), "Head")
	var camera := child(head, Camera3D.new(), "Camera3D")
	child(camera, RayCast3D.new(), "RayCast3D")
	child(camera, Node3D.new(), "handpoint")
	child(fixture, player, "MainChar")
	menu = Panel.new()
	menu.size = Vector2(1152, 720)
	menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	menu.set_script(load("res://scripts/PausePanel.gd"))
	child(menu, Panel.new(), "SettingsPanel")
	child(menu, Panel.new(), "ConfirmQuitPanel")
	var guide := Panel.new()
	guide.set_script(load("res://guide_stub.gd"))
	child(menu, guide, "TutorialPanel")
	resume_button = Button.new()
	resume_button.position = Vector2(400, 200)
	resume_button.size = Vector2(150, 50)
	resume_button.text = "Resume"
	child(menu, resume_button, "Resume")
	resume_button.pressed.connect(menu._on_resume_pressed)
	child(fixture, menu, "PausePanel")
	var layer := child(fixture, CanvasLayer.new(), "CanvasLayer")
	child(layer, Label.new(), "InteractionLabel")
	child(layer, Control.new(), "Crosshair")
	tutorial = Control.new()
	tutorial.size = Vector2(1152, 720)
	tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial.set_script(load("res://scripts/TutorialsScript/%sTutorial.gd" % department))
	var background := child(tutorial, Panel.new(), "BackgroundPanel")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for label_name in ["MessageLabel", "StepLabel", "ContinueLabel"]:
		var label := Label.new()
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child(background, label, label_name)
	child(background, TextureRect.new(), "HighlightImage")
	child(background, Panel.new(), "Background")
	child(background, Control.new(), "TextBoxContainer")
	var timer := Timer.new()
	timer.one_shot = true
	child(background, timer, "LetterDisplayTimer")
	child(layer, tutorial, "%sTutorial" % department)
	monitor = Node.new()
	monitor.set_script(load("res://monitor_stub.gd"))
	child(fixture, monitor, "Monitor")
	get_tree().root.add_child(fixture)
	get_tree().current_scene = fixture
	player.set_physics_process(false)
	player.set_process(false)
	await get_tree().process_frame

func send_escape(echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	event.echo = echo
	get_viewport().push_input(event)

func click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_viewport().push_input(motion, true)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = position
	event.global_position = position
	get_viewport().push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	get_viewport().push_input(event, true)

func teardown() -> void:
	get_tree().paused = false
	get_tree().current_scene = self
	fixture.free()
	await get_tree().process_frame

func test_department(department: String) -> void:
	await setup(department)
	tutorial.screen_focused()
	player.set_computer_focus(player.head.global_transform, monitor)
	var step: int = tutorial.tutorial_step
	var letter: int = tutorial.letter_index
	send_escape()
	check(get_tree().paused and player.is_paused and menu.visible, "%s: Esc did not open pause menu" % department)
	check(player.is_focusing_screen and player.current_monitor == monitor and monitor.idle_calls == 0, "%s: pause lost monitor focus" % department)
	check(not tutorial.is_visible_in_tree(), "%s: tutorial covers pause menu" % department)
	await get_tree().create_timer(0.15).timeout
	check(tutorial.tutorial_step == step and tutorial.letter_index == letter and tutorial.is_typing, "%s: typewriter changed while paused" % department)
	click_at(Vector2(800, 500))
	check(tutorial.tutorial_step == step and tutorial.letter_index == letter, "%s: background click advanced paused tutorial" % department)
	send_escape(true)
	check(get_tree().paused, "%s: key repeat resumed game" % department)
	send_escape()
	check(not get_tree().paused and not player.is_paused and not menu.visible, "%s: Esc did not resume" % department)
	check(tutorial.visible and tutorial.tutorial_step == step and tutorial.letter_index == letter, "%s: resume lost tutorial state" % department)
	check(player.is_focusing_screen and monitor.idle_calls == 0, "%s: resume exited monitor" % department)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "%s: resume captured monitor mouse" % department)
	await get_tree().create_timer(0.2).timeout
	check(tutorial.letter_index > letter, "%s: typewriter did not resume" % department)
	send_escape()
	letter = tutorial.letter_index
	await get_tree().process_frame
	click_at(Vector2(450, 225))
	check(not get_tree().paused and tutorial.visible, "%s: Resume button did not resume tutorial" % department)
	check(tutorial.tutorial_step == step and tutorial.letter_index == letter and tutorial.is_typing, "%s: Resume click leaked to tutorial" % department)
	click_at(Vector2(800, 500))
	check(not tutorial.is_typing and tutorial.tutorial_step == step, "%s: resumed tutorial click did not finish text" % department)
	click_at(Vector2(800, 500))
	check(tutorial.tutorial_step == step + 1, "%s: resumed tutorial could not advance" % department)
	await teardown()

func test_initial_and_normal() -> void:
	await setup("FD")
	check(tutorial.visible and not tutorial.can_click, "FD initial instructions missing")
	send_escape()
	check(get_tree().paused and menu.visible, "FD disk tutorial could not pause")
	send_escape()
	check(not get_tree().paused and tutorial.visible and tutorial.tutorial_step == -1, "FD initial tutorial did not resume")
	tutorial.hide()
	player.set_computer_focus(player.head.global_transform, monitor)
	send_escape()
	check(not player.is_focusing_screen and not get_tree().paused and monitor.idle_calls == 1, "Normal monitor Esc behavior changed")
	send_escape()
	check(get_tree().paused, "Normal gameplay could not pause")
	menu.settings_panel.show()
	send_escape()
	check(get_tree().paused and not menu.settings_panel.visible, "Esc settings did not return to pause menu")
	menu.confirm_quit_panel.show()
	send_escape()
	check(get_tree().paused and not menu.confirm_quit_panel.visible, "Esc quit confirmation did not return to pause menu")
	menu.tutorial_panel.show()
	send_escape()
	check(get_tree().paused and not menu.tutorial_panel.visible, "Esc guide did not return to pause menu")
	send_escape()
	check(not get_tree().paused and not tutorial.visible, "Resuming normal gameplay revealed hidden tutorial")
	player.is_in_dialogue = true
	send_escape()
	check(not get_tree().paused, "Dialogue incorrectly opened pause menu")
	player.is_in_dialogue = false
	SceneTransition.is_transitioning = true
	send_escape()
	check(not get_tree().paused, "Scene transition incorrectly opened pause menu")
	SceneTransition.is_transitioning = false
	player.pause_panel = null
	menu.free()
	send_escape()
	check(not get_tree().paused and not player.is_paused, "Missing pause menu trapped the game in pause")
	await teardown()

func _run() -> void:
	print("HARNESS STARTED")
	for department in ["FD", "KYC", "CS"]:
		await test_department(department)
	await test_initial_and_normal()
	print("Tutorial pause checks: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

