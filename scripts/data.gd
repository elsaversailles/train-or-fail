extends RigidBody3D

@onready var screen: Node3D = $"../Monitor/Screen"

var is_held: bool = false
var is_inserted: bool = false

# Idle Screens
@onready var sprite_empty: Sprite3D = $"../IdleScreen/SpriteEmpty"
@onready var sprite_inserted: Sprite3D = $"../IdleScreen/SpriteInserted"

# LED lights
@onready var led_red: MeshInstance3D = $"../socket/FloppyCartridge/LedRed"
@onready var led_yellow: MeshInstance3D = $"../socket/FloppyCartridge/LedYellow"
@onready var led_green: MeshInstance3D = $"../socket/FloppyCartridge/LedGreen"

# --- NEW: The Audio Player ---
# Update this path if you placed the audio node somewhere else!
@onready var insert_sound: AudioStreamPlayer3D = $InsertSound

func _ready() -> void:
	is_held = false
	is_inserted = false
	freeze = false
	
	if sprite_empty: sprite_empty.visible = true
	if sprite_inserted: sprite_inserted.visible = false
		
	set_active_led("red")

func socket_item(target_transform: Transform3D, socket_node: Node):
	if is_inserted:
		return

	is_held = false
	is_inserted = true
	freeze = true
	
	# sound effect for inserting disk
	if insert_sound:
		insert_sound.play()
		
	# While disk is sliding in LED light should be yellow
	set_active_led("yellow")

	$CollisionShape3D.set_deferred("disabled", true)

	if get_parent():
		get_parent().remove_child(self)

	socket_node.get_parent().add_child(self)

	global_transform = target_transform.translated_local(Vector3(0, -0.6, 0))

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_transform", target_transform, 2)
	tween.finished.connect(_on_insert_finished)

func _on_insert_finished():
	# Disk is fully inserted LED light should be green
	set_active_led("green")
	
	# Screen only shows after disk finished inserting
	screen.visible = true
	
	# Screen updates ONLY when fully seated!
	if sprite_empty: sprite_empty.visible = false
	if sprite_inserted: sprite_inserted.visible = true
	

func set_active_led(color_name: String):
	if led_red: led_red.material_override.emission_enabled = false
	if led_yellow: led_yellow.material_override.emission_enabled = false
	if led_green: led_green.material_override.emission_enabled = false

	match color_name:
		"red":
			if led_red: led_red.material_override.emission_enabled = true
		"yellow":
			if led_yellow: led_yellow.material_override.emission_enabled = true
		"green":
			if led_green: led_green.material_override.emission_enabled = true
