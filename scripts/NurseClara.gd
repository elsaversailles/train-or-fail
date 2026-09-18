extends StaticBody3D

var can_talk: bool = false
var is_talking: bool = false

func interact():
	# Only allow interaction if unlocked AND not already mid-dialogue
	if can_talk and not is_talking:
		is_talking = true
		
		# 1. Turn Clara to face the player
		var player = get_tree().get_first_node_in_group("player")
		var clara_root = get_parent()
		
		if clara_root and player:
			var target_pos = player.global_position
			target_pos.y = clara_root.global_position.y
			clara_root.look_at(target_pos, Vector3.UP)
			clara_root.rotate_y(PI) # Uncomment if her model faces away from you

		# 2. Run the MC internal monologue
		Dialogic.start("clara_monologue")
		
		# 3. Wait until Dialogic fully finishes before unlocking interaction
		await Dialogic.timeline_ended
		is_talking = false
