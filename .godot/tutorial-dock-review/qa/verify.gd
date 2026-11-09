extends SceneTree
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var player := Node3D.new()
	player.set_script(load("res://player_stub.gd"))
	player.position = Vector3(0, 0, 5)
	player.add_to_group("player")
	root.add_child(player)
	var dock := Node3D.new()
	dock.set_script(load("res://scripts/Dock.gd"))
	var canvas := CanvasLayer.new()
	canvas.name = "CanvasLayer"
	dock.add_child(canvas)
	var label := Label.new()
	label.name = "Label"
	canvas.add_child(label)
	root.add_child(dock)
	current_scene = dock
	var dialogic := root.get_node("Dialogic")
	check(not label.visible and player.is_in_dialogue, "Dock arrival hides instructions and locks movement")
	check(dialogic.started == ["dock_arrival"], "Dock arrival timeline starts")
	dialogic.timeline_ended.emit()
	await process_frame
	check(label.visible and not player.is_in_dialogue, "Controls appear and movement unlocks after arrival")
	check(label.text.contains("Mouse: Look around") and label.text.contains("press E to talk"), "Dock instructions explain movement and interaction")
	var grandpa := Node3D.new()
	dock.add_child(grandpa)
	var interaction := StaticBody3D.new()
	interaction.set_script(load("res://scripts/dialogue/GrandpaDock.gd"))
	grandpa.add_child(interaction)
	interaction.interact()
	check(not label.visible, "Grandpa hides the actual dock tutorial label")
	check(dialogic.started.back() == "grandpa_dock", "Grandpa dialogue starts")
	dialogic.timeline_ended.emit()
	await create_timer(0.4).timeout
	check(root.get_node("SceneTransition").destination == "res://scene/office_lobby.tscn", "Dock tutorial continues to the lobby")
	print("DOCK_TUTORIAL_CHECK failures=", failures)
	quit(0 if failures == 0 else 1)
