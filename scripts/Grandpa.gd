extends StaticBody3D

var can_talk: bool = false 

func interact():
	if can_talk:
		var player = get_tree().get_first_node_in_group("player")
		
		var grandpa_root = get_parent() # Assuming StaticBody3D is a child of Grandpa's main Node3D
		if grandpa_root and player:
			var target_pos = player.global_position
			# Lock Y to keep Grandpa standing upright without tilting
			target_pos.y = grandpa_root.global_position.y 
			grandpa_root.look_at(target_pos, Vector3.UP)

		# 3. Start the Dialogic timeline
		Dialogic.start("grandpa_day1")
