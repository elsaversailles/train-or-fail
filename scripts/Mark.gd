extends StaticBody3D

var can_talk: bool = false
var is_talking: bool = false

@export var mark_bubble: Node3D

func interact():
	var current_day = SaveManager.current_save_data.get("current_day", 1)
	
	# Day 2: Unlocked after the cashier ambient sequence
	if current_day == 2 and can_talk and not is_talking:
		is_talking = true
		
		var player = get_tree().get_first_node_in_group("player")
		var mark_root = get_parent()
		if mark_root and player:
			var target_pos = player.global_position
			target_pos.y = mark_root.global_position.y
			mark_root.look_at(target_pos, Vector3.UP)
			mark_root.rotate_y(PI)
		
		Dialogic.start("mark_day2")
		await Dialogic.timeline_ended
		is_talking = false

	# Day 4: Direct interaction with 3D chat bubble before Dialogic
	elif current_day == 4 and not is_talking:
		is_talking = true
		
		var player = get_tree().get_first_node_in_group("player")
		var mark_root = get_parent()
		if mark_root and player:
			var target_pos = player.global_position
			target_pos.y = mark_root.global_position.y
			mark_root.look_at(target_pos, Vector3.UP)
			mark_root.rotate_y(PI)
			
		if mark_bubble:
			mark_bubble.display_text("They won't accept my ID! Just because it got wet in the rain and my address says a shelter that closed down... I just want my own money back!")
			await mark_bubble.finished_displaying
			await get_tree().create_timer(3.0).timeout
			mark_bubble.visible = false
			
		Dialogic.start("mark_day4")
		await Dialogic.timeline_ended
		is_talking = false
