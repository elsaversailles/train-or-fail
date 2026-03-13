extends RigidBody3D

var is_held = false
var is_inserted = false

func socket_item(target_transform: Transform3D):
	is_held = false
	is_inserted = true
	freeze = true 
	
	# 1. Remove from current parent (the player's hand)
	if get_parent():
		get_parent().remove_child(self)
	
	# 2. Add to the scene tree ONLY if it's currently available
	# Using call_deferred is safer for physics objects
	var main_tree = Engine.get_main_loop() 
	if main_tree:
		main_tree.root.call_deferred("add_child", self)
	
	# 3. Position it perfectly in the wall
	global_transform = target_transform
	$CollisionShape3D.set_deferred("disabled", true)

func _on_socket_body_entered(_body: Node3D) -> void:
	pass # Replace with function body.
