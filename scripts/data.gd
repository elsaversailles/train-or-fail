extends RigidBody3D

var is_held: bool = false
var is_inserted: bool = false

func _ready() -> void:
	is_held = false
	is_inserted = false
	freeze = false

func socket_item(target_transform: Transform3D, socket_node: Node):
	if is_inserted:
		return

	is_held = false
	is_inserted = true
	freeze = true

	$CollisionShape3D.set_deferred("disabled", true)

	# Remove from hand / old parent
	if get_parent():
		get_parent().remove_child(self)

	# Add back into current level scene
	socket_node.get_parent().add_child(self)

	# Start slightly outside socket for animation
	global_transform = target_transform.translated_local(Vector3(0, -0.6, 0))

	# Smooth insert animation
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_transform", target_transform, 1)

func _on_socket_body_entered(_body: Node3D) -> void:
	pass
