extends StaticBody3D

var can_talk: bool = false
var is_talking: bool = false

func interact():
	var current_day = SaveManager.current_save_data.get("current_day", 1)
	
	# Only allow interaction after ambient chat unlocks on Day 8 and if not already talking
	if current_day == 8 and can_talk and not is_talking:
		is_talking = true
		
		var player = get_tree().get_first_node_in_group("player")
		var jericho_root = get_parent()
		
		if jericho_root and player:
			var target_pos = player.global_position
			target_pos.y = jericho_root.global_position.y
			jericho_root.look_at(target_pos, Vector3.UP)
			jericho_root.rotate_y(PI) # Uncomment if armature faces away from player

		Dialogic.start("jericho_monologue")
		
		# Wait for the monologue timeline to close before unlocking interaction
		await Dialogic.timeline_ended
		is_talking = false
