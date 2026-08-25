extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		
		$CollisionShape3D.set_deferred("disabled", true)
		
		# Wait 1 second before fading
		await get_tree().create_timer(1.0).timeout
		
		# Always teleport the player straight to the lobby!
		SceneTransition.change_scene("res://scene/office_lobby.tscn")
