extends StaticBody3D

var can_talk: bool = false

func interact():
	if can_talk:
		# 1. Turn Clara to face the player
		var player = get_tree().get_first_node_in_group("player")
		var clara_root = get_parent()
		
		if clara_root and player:
			var target_pos = player.global_position
			target_pos.y = clara_root.global_position.y
			clara_root.look_at(target_pos, Vector3.UP)
			# clara_root.rotate_y(PI) # Uncomment if her model faces away from you

		# 2. Run the MC internal monologue
		Dialogic.start("clara_monologue")
