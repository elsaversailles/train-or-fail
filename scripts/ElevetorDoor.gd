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
		
		$CollisionShape3D.set_deferred("disabled", true)
		
		# Wait 1 second before fading
		await get_tree().create_timer(1.0).timeout
		
		# Teleport the player straight to the lobby
		SceneTransition.change_scene("res://scene/elevator.tscn")
