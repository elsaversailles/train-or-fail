extends Area3D

func _on_body_entered(body: Node3D) -> void:
	# 1. Check if the player stepped into the elevator
	if body.is_in_group("player"):
		
		# 2. Disable collision to prevent double-loading
		$CollisionShape3D.set_deferred("disabled", true)
		
		# Optional: Add a short delay to simulate standing in the elevator
		await get_tree().create_timer(1.0).timeout
		
		# 3. Ask the SaveManager where to route the player today
		var default_path = "res://scene/FraudDetection/FraudDetection.tscn"
		var next_level_path = SaveManager.current_save_data.get("current_scene_path", default_path)
		
		# 4. Teleport to the correct office!
		SceneTransition.change_scene(next_level_path)
