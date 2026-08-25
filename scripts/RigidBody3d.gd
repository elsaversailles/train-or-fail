extends RigidBody3D

var is_held = false
var is_inserted = false

func socket_item(socket_transform: Transform3D):
	is_held = false
	is_inserted = true
	# Freeze the physics so it stays in the hole
	freeze = true 
	global_transform = socket_transform
	# Disable collisions so it can't be interacted with again
	$CollisionShape3D.disabled = true


func _on_socket_area_entered(_area: Area3D) -> void:
	pass # Replace with function body.
