extends StaticBody3D

var can_talk: bool = false
var is_talking: bool = false

func interact():
	if can_talk and not is_talking:
		is_talking = true

		var player = get_tree().get_first_node_in_group("player")
		var grandpa_root = get_parent()
		if grandpa_root and player:
			var target_pos = player.global_position
			target_pos.y = grandpa_root.global_position.y
			grandpa_root.look_at(target_pos, Vector3.UP)
			grandpa_root.rotate_y(PI) # Flips Grandpa 180 degrees to face the player

		Dialogic.start("grandpa_day1")

		# Wait until the timeline concludes before allowing another interaction
		await Dialogic.timeline_ended
		is_talking = false
