extends RigidBody3D

@onready var screen: Node3D = $"../Monitor/Screen"

var is_held: bool = false
var is_inserted: bool = false

# --- NEW SPRITE TARGETS ---
# We point directly inside the IdleScreen to find your two new sprites!
@onready var sprite_empty: Sprite3D = $"../IdleScreen/SpriteEmpty"
@onready var sprite_inserted: Sprite3D = $"../IdleScreen/SpriteInserted"

func _ready() -> void:
	is_held = false
	is_inserted = false
	freeze = false
	
	# Start by showing the Empty sprite and hiding the Inserted sprite
	if sprite_empty:
		sprite_empty.visible = true
	if sprite_inserted:
		sprite_inserted.visible = false

func socket_item(target_transform: Transform3D, socket_node: Node):
	if is_inserted:
		return

	screen.visible = true
	is_held = false
	is_inserted = true
	freeze = true
	
	# --- SWAP THE SPRITES ---
	# The disk is in! Hide the empty graphic, show the active graphic.
	if sprite_empty:
		sprite_empty.visible = false
	if sprite_inserted:
		sprite_inserted.visible = true

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
