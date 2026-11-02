extends SceneTree

class PlayerStub:
	extends Node3D
	var is_paused := false

class ResultStub:
	extends Control
	signal continue_requested

class TransitionStub:
	extends CanvasLayer
	var calls: Array[String] = []
	func change_scene(path: String, _duration: float = 0.5):
		calls.append(path)
	func reload_scene(_duration: float = 0.5):
		calls.append("reload")

const EXPECTED := {
	"algorithm_reformer": ["Algorithm Reformer", "Your exceptional performance and ethical auditing force Maypaya Financial to re-evaluate their risk criteria, establishing you as a key asset who bridges ethics and efficiency."],
	"another_cog_in_the_machine": ["Another Cog in the Machine", "You are officially an average employee. You retain your analyst position with a modest annual cost-of-living raise.\n\nWalking home, you see a neighborhood of compromises—half the storefronts are bustling, while the other half are boarded up. You survived the system, but you didn't change it."],
	"cold_efficiency": ["Cold Efficiency", "You prioritized the company's algorithm over human empathy. You step into a spacious upper-management office with a view, but the city below feels hollow."],
	"conflict_of_interest": ["Conflict of Interest", "Management flags the unauthorized approval. You are stripped of your analyst title and reassigned to low-level administrative duty, but Lolo’s business stays alive."],
	"stagnant_survival": ["Stagnant Survival", "You stay employed at Maypaya, but corporate locks your salary, freezes promotion paths, and assigns you to endless routine data entry in a secluded corner."],
	"terminated": ["Terminated", "Excessive evaluation errors result in immediate termination for incompetence before you can make any lasting impact on the business or the community."],
	"clean_exit": ["The Clean Exit", "Rejecting the corporate grind, you hand over your badge and leave Maypaya behind to seek a fresh start, entering the job market with empty hands but a clear conscience."]
}

var checks := 0
var failures: Array[String] = []
var saver: Node
var transition: CanvasLayer

func _initialize():
	call_deferred("_run")

func check(condition: bool, label: String):
	checks += 1
	if not condition:
		failures.append(label)
		push_error("FAIL: " + label)

func click() -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(576, 324)
	return event

func enter() -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.pressed = true
	return event

func _panel_from_scene(source: String, panel_path: String) -> Control:
	# Preserve the real scene's ending UI nodes, resources, styles and anchors.
	var content := FileAccess.get_file_as_string(source).replace("\r", "")
	var resource_regex := RegEx.new()
	resource_regex.compile('(?m)^\\[ext_resource.*(?:type="Texture2D"|path="res://scene/ending_intro.tscn").*\\]$')
	var output := "[gd_scene format=3]\n\n"
	for match_result in resource_regex.search_all(content):
		output += match_result.get_string() + "\n"
	var style_regex := RegEx.new()
	style_regex.compile('(?ms)^\\[sub_resource type="StyleBox[^\\n]*\\n.*?(?=^\\[|\\z)')
	for match_result in style_regex.search_all(content):
		output += "\n" + match_result.get_string()
	var node_regex := RegEx.new()
	node_regex.compile('(?ms)^\\[node[^\\n]*\\n.*?(?=^\\[|\\z)')
	var panel_name := panel_path.get_file()
	var panel_parent := panel_path.get_base_dir()
	if panel_parent == "": panel_parent = "."
	for match_result in node_regex.search_all(content):
		var block := match_result.get_string()
		var header := block.get_slice("\n", 0)
		if header.contains('name="%s"' % panel_name) and header.contains('parent="%s"' % panel_parent):
			output += "\n" + block.replace(' parent="%s"' % panel_parent, "")
		elif header.contains('parent="%s"' % panel_path) or header.contains('parent="%s/' % panel_path):
			output += "\n" + block.replace('parent="%s"' % panel_path, 'parent="."').replace('parent="%s/' % panel_path, 'parent="')
	var path := "res://.godot/ending-review/smoke_%s_panel.tscn" % source.get_file().get_basename()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(output)
	file.close()
	var packed := load(path) as PackedScene
	check(packed != null, "Extract actual UI from " + source)
	return packed.instantiate() as Control

func _apartment() -> Node3D:
	var node := Node3D.new()
	node.set_script(load("res://scripts/Apartment.gd"))
	var player := PlayerStub.new()
	player.name = "Player"
	node.add_child(player)
	var result := ResultStub.new()
	result.name = "ResultPanel"
	node.add_child(result)
	var crosshair_layer := CanvasLayer.new()
	crosshair_layer.name = "CanvasLayer"
	node.add_child(crosshair_layer)
	node.add_child(_panel_from_scene("res://scene/apartment.tscn", "GameFinishedPanel"))
	for entry in [
		["ending_algorithm_reformer", "Algorithm_Reformer"],
		["ending_another_cog_in_the_machine", "Another_Cog_In_The_Machine"],
		["ending_stagnant_survival", "Stagnant_Survival"],
		["ending_clean_exit", "The_Clean_Exit"],
		["ending_cold_efficiency", "Cold_Efficiency"],
		["ending_conflict_of_interest", "Conflict_of_Interest"]
	]:
		node.set(entry[0], load("res://images/Endings/%s.png" % entry[1]))
	root.add_child(node)
	return node

func _department(name_text: String, tutorial_name: String, day: int) -> Node3D:
	saver.current_save_data = {"current_day": day}
	var node := Node3D.new()
	node.set_script(load("res://scripts/%s/%s.gd" % [name_text, name_text]))
	var player := PlayerStub.new()
	player.name = "MainChar"
	node.add_child(player)
	var layer := CanvasLayer.new()
	layer.name = "CanvasLayer"
	node.add_child(layer)
	var label := Label.new()
	label.name = "Label"
	layer.add_child(label)
	var tutorial := Control.new()
	tutorial.name = tutorial_name
	layer.add_child(tutorial)
	layer.add_child(_panel_from_scene("res://scene/%s/%s.tscn" % [name_text, name_text], "CanvasLayer/GameOverPanel"))
	root.add_child(node)
	return node

func _check_intro(node: Node, id: String, texture_name: String):
	var intro = node.ending_intro
	check(intro.visible, id + " intro visible")
	check(intro.title_label.text == EXPECTED[id][0], id + " exact title")
	check(intro.description_label.text == EXPECTED[id][1], id + " exact description")
	check(node.ending_texture_rect.texture.resource_path.ends_with(texture_name + ".png"), id + " correct artwork ready")
	var call_count: int = transition.calls.size()
	node._on_game_finished_clicked(click())
	check(transition.calls.size() == call_count, id + " blocks exit while card visible")
	intro._gui_input(click())
	check(not intro.visible, id + " click reveals artwork")
	check(node.game_finished_panel.visible, id + " artwork panel stays visible")
	check(transition.calls.size() == call_count, id + " continuation does not exit")
	node._on_game_finished_clicked(click())
	check(transition.calls.size() == call_count + 1 and transition.calls.back() == "res://scene/main_menu.tscn", id + " next click exits")

func _run():
	saver = root.get_node("SaveManager")
	transition = root.get_node("SceneTransition")
	transition.set_script(TransitionStub)
	saver.current_slot = 997
	print("SMOKE user data: " + OS.get_user_data_dir())
	check(OS.get_user_data_dir().replace("\\", "/").contains(".godot/ending-review/userdata"), "Save data isolated from actual player saves")
	root.size = Vector2i(1152, 648)
	var all_legit := {"tita_elena": "legit", "mark_krazy": "legit", "nurse_clara": "legit", "jericho_santur": "legit"}
	var all_sus := {"tita_elena": "sus", "mark_krazy": "sus", "nurse_clara": "sus", "jericho_santur": "sus"}
	saver.current_save_data = {"special_decisions": all_legit, "total_score": 27}
	var apartment := _apartment()
	apartment.resolve_game_ending()
	_check_intro(apartment, "algorithm_reformer", "Algorithm_Reformer")
	saver.current_save_data = {"special_decisions": {"tita_elena": "legit"}, "total_score": 30}
	apartment.resolve_game_ending()
	_check_intro(apartment, "another_cog_in_the_machine", "Another_Cog_In_The_Machine")
	saver.current_save_data["total_score"] = 27
	apartment.resolve_game_ending()
	check(apartment.choice_container.visible and not apartment.ending_intro.visible, "27 points presents choice before ending card")
	var previous: int = transition.calls.size()
	apartment._on_game_finished_clicked(click())
	check(transition.calls.size() == previous, "choice blocks exit")
	apartment.choice_survival_btn.pressed.emit()
	_check_intro(apartment, "stagnant_survival", "Stagnant_Survival")
	apartment.resolve_game_ending()
	apartment.choice_clean_exit_btn.pressed.emit()
	_check_intro(apartment, "clean_exit", "The_Clean_Exit")
	saver.current_save_data = {"special_decisions": all_sus, "total_score": 27}
	apartment.resolve_game_ending()
	check(saver.current_save_data.get("is_grandpa_shift", false), "all-sus retains Grandpa shift")
	check(transition.calls.back() == "res://scene/CreditScoring/CreditScoring.tscn", "all-sus requests bonus shift")
	for pair in [["sus", "cold_efficiency", "Cold_Efficiency"], ["legit", "conflict_of_interest", "Conflict_of_Interest"]]:
		saver.current_save_data["special_decisions"]["grandpa"] = pair[0]
		saver.current_save_data["grandpa_round_completed"] = true
		apartment.show_secret_grandpa_ending()
		check(not saver.current_save_data.has("grandpa_round_completed"), pair[1] + " clears completion flag")
		_check_intro(apartment, pair[1], pair[2])
	apartment.ending_intro.show_ending("clean_exit")
	apartment.ending_intro._gui_input(enter())
	check(not apartment.ending_intro.visible, "Enter reveals artwork")
	# Dispatch real viewport input to verify focus and event consumption.
	apartment._show_ending("clean_exit", apartment.ending_clean_exit)
	await process_frame
	previous = transition.calls.size()
	Input.parse_input_event(enter())
	await process_frame
	check(not apartment.ending_intro.visible, "routed Enter reveals artwork")
	check(transition.calls.size() == previous, "routed Enter does not exit")
	apartment._show_ending("clean_exit", apartment.ending_clean_exit)
	await process_frame
	Input.parse_input_event(click())
	await process_frame
	check(not apartment.ending_intro.visible, "routed click reveals artwork")
	check(transition.calls.size() == previous, "routed card click consumed before parent exit")
	var release := click()
	release.pressed = false
	Input.parse_input_event(release)
	Input.parse_input_event(click())
	await process_frame
	check(transition.calls.size() == previous + 1, "routed second click exits")
	apartment.queue_free()
	await process_frame
	for spec in [["FraudDetection", "FDTutorial", 1], ["KnowYourCustomer", "KYCTutorial", 4], ["CreditScoring", "CSTutorial", 7]]:
		var department := _department(spec[0], spec[1], spec[2])
		await physics_frame
		await physics_frame
		await process_frame
		department.trigger_game_over()
		var intro = department.ending_intro
		check(intro.visible and not intro.continue_enabled, spec[0] + " termination card visible and locked during fade")
		check(intro.title_label.text == EXPECTED.terminated[0] and intro.description_label.text == EXPECTED.terminated[1], spec[0] + " termination copy")
		previous = transition.calls.size()
		intro._gui_input(click())
		check(intro.visible, spec[0] + " early click cannot skip fade")
		department._on_game_over_clicked(click())
		check(transition.calls.size() == previous, spec[0] + " early click cannot retry")
		await create_timer(1.35).timeout
		check(intro.continue_enabled and department._game_over_ready, spec[0] + " continuation enabled after fade")
		intro._gui_input(click())
		check(not intro.visible and department.game_over_panel.visible, spec[0] + " click reveals termination artwork")
		check(transition.calls.size() == previous, spec[0] + " card click does not retry")
		department._on_game_over_clicked(click())
		check(transition.calls.size() == previous + 1 and transition.calls.back() == "reload", spec[0] + " next click retries")
		department.queue_free()
		await process_frame
	print("ENDING SMOKE: %d checks, %d failures" % [checks, failures.size()])
	for failure in failures: print("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)
