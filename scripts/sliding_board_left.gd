extends AnimatableBody3D

@export var slide_distance: float = 5.0
@export var slide_speed: float = 5.0
var is_open: bool = false
var start_position: Vector3
var target_position: Vector3

func _ready():
	start_position = global_position
	target_position = start_position + Vector3(0, 0, slide_distance)

func _process(delta):
	var destination = target_position if is_open else start_position
	global_position = global_position.lerp(destination, slide_speed * delta)

# This function will be called by the player script
func toggle_board():
	is_open = !is_open
