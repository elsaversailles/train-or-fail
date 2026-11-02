extends Node

var menu: Control

func _ready() -> void:
 get_tree().create_timer(20.0).timeout.connect(func(): get_tree().quit(2))
 preview.call_deferred()

func preview() -> void:
 # These files stay inside the isolated test project via save_stub.gd.
 var first = SaveManager.DEFAULT_SAVE.duplicate(true)
 first["total_score"] = 10
 SaveManager.save_game(1, first)
 var second = SaveManager.DEFAULT_SAVE.duplicate(true)
 second["stage_name"] = "Credit L2 - Day 8"
 second["current_day"] = 8
 second["total_score"] = 27
 SaveManager.save_game(2, second)
 SaveManager.delete_save(3)
 menu = load("res://scene/slots_menu.tscn").instantiate()
 add_child(menu)
 await get_tree().process_frame
 assert(not menu.has_node("Panel/SlotInfoLabel"))
 assert(menu.slot_1.get_node("StageLabel").text == "Stage: Fraud Detection -\nDay 1")
 assert(menu.slot_1.get_node("ScoreLabel").text == "Total Score: 10")
 assert(menu.slot_2.get_node("StageLabel").text == "Stage: Credit Scoring -\nDay 8")
 assert(menu.slot_3.get_node("StageLabel").text == "Stage: Empty")
 assert(menu.format_slot_stage("KYC L1 - Day 4") == "KYC -\nDay 4")
 assert(menu.format_slot_stage("Game Finished") == "Game Finished")
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://slot-labels-preview.png")
 # Clicking the label area must still select the disk underneath it.
 click_at(menu.slot_1.get_node("ScoreLabel").get_global_rect().get_center())
 assert(menu.selected_slot == 1 and menu.select_btn.visible and menu.select_btn_label.text == "Load Game")
 click_at(menu.slot_3.get_node("StageLabel").get_global_rect().get_center())
 assert(menu.selected_slot == 3 and menu.select_btn_label.text == "New Game" and menu.delete_btn.disabled)
 click_at(menu.slot_1.get_node("SlotTitleLabel").get_global_rect().get_center())
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://slot-labels-selected.png")
 menu._on_delete_pressed()
 assert(menu.slot_1.get_node("StageLabel").text == "Stage: Empty")
 assert(menu.slot_1.get_node("ScoreLabel").text == "Total Score: 0")
 assert(menu.slot_2.get_node("ScoreLabel").text == "Total Score: 27")
 SaveManager.delete_save(2)
 print("Slot preview passed: saved/empty labels, all stage formats, label clicks, load/new actions, and deletion refresh.")
 get_tree().quit()

func click_at(point: Vector2) -> void:
 get_viewport().notify_mouse_entered()
 var motion = InputEventMouseMotion.new()
 motion.position = point
 motion.global_position = point
 get_viewport().push_input(motion, true)
 var click = InputEventMouseButton.new()
 click.position = point
 click.global_position = point
 click.button_index = MOUSE_BUTTON_LEFT
 click.pressed = true
 get_viewport().push_input(click, true)
 click = click.duplicate()
 click.pressed = false
 get_viewport().push_input(click, true)
