extends Area3D

var player_in_area: bool = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = true
		if "current_zone_prompt" in body:
			body.current_zone_prompt = "Press E to Enter"

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		if "current_zone_prompt" in body:
			body.current_zone_prompt = ""

func _unhandled_input(event: InputEvent) -> void:
	if player_in_area and event.is_action_pressed("interact"):
		player_in_area = false
		
		# 2. Disable collision to prevent double-loading
		$CollisionShape3D.set_deferred("disabled", true)
		
		# Optional: Add a short delay to simulate standing in the elevator
		await get_tree().create_timer(1.0).timeout
		
		# 3. Ask the SaveManager where to route the player today
		var default_path = "res://scene/FraudDetection/FraudDetection.tscn"
		var next_level_path = SaveManager.current_save_data.get("current_scene_path", default_path)
		
		# 4. Teleport to the correct office!
		SceneTransition.change_scene(next_level_path)
